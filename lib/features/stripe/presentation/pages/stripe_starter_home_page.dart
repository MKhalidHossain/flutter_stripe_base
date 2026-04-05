import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/models/stripe_checkout_request.dart';
import '../controllers/stripe_starter_controller.dart';
import '../widgets/starter_section_card.dart';

enum StripeFlowView {
  overview('Overview'),
  paymentSheet('Payment Sheet'),
  cardField('CardField'),
  cardForm('CardForm'),
  platformPay('Platform Pay'),
  customerSheet('Customer Sheet');

  const StripeFlowView(this.label);

  final String label;
}

class StripeStarterHomePage extends StatefulWidget {
  const StripeStarterHomePage({
    super.key,
    this.controller,
    this.configurationError,
  });

  final StripeStarterController? controller;
  final String? configurationError;

  @override
  State<StripeStarterHomePage> createState() => _StripeStarterHomePageState();
}

class _StripeStarterHomePageState extends State<StripeStarterHomePage> {
  final TextEditingController _amountController = TextEditingController(
    text: '1000',
  );
  final TextEditingController _currencyController = TextEditingController(
    text: 'usd',
  );
  final TextEditingController _descriptionController = TextEditingController(
    text: 'Starter checkout',
  );
  final TextEditingController _customerIdController = TextEditingController();
  final TextEditingController _receiptEmailController = TextEditingController();

  StripeFlowView _selectedFlow = StripeFlowView.overview;
  bool _cardFieldComplete = false;
  bool _cardFormComplete = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.loadCapabilities();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _currencyController.dispose();
    _descriptionController.dispose();
    _customerIdController.dispose();
    _receiptEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    if (controller == null) {
      return _buildScaffold();
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    final controller = widget.controller;
    final canRunFlows = controller != null && widget.configurationError == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Stripe Starter')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            StarterSectionCard(
              title: 'Reusable Stripe base project',
              description:
                  'This starter removes the insecure client-side secret key pattern and replaces it with a backend-first structure. It also shows 5 common Stripe usage patterns in one project.',
              trailing: Chip(
                label: const Text('5 flows'),
                avatar: const Icon(Icons.credit_score_rounded, size: 18),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      Chip(label: Text('Payment Sheet')),
                      Chip(label: Text('CardField')),
                      Chip(label: Text('CardForm')),
                      Chip(label: Text('Apple Pay / Google Pay')),
                      Chip(label: Text('Customer Sheet')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Use these patterns for one-time payments, saved cards, wallet payments, and reusable backend contracts. Subscriptions and webhooks build on the same backend shape documented in README.md.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (widget.configurationError != null) ...[
              StarterSectionCard(
                title: 'Configuration required',
                description:
                    'The app still renders so you can see the starter structure, but Stripe actions are disabled until the environment is fixed.',
                trailing: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFC2410C),
                ),
                child: Text(
                  widget.configurationError!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF9A3412),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            StarterSectionCard(
              title: 'Checkout request playground',
              description:
                  'Every demo button below uses this same reusable request model. Amount uses the smallest currency unit, so 1000 means 10.00 USD.',
              child: Column(
                children: [
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      helperText: 'Example: 1000 = 10.00',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _currencyController,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      helperText: 'Example: usd',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customerIdController,
                    decoration: const InputDecoration(
                      labelText: 'Customer ID',
                      helperText:
                          'Optional. Leave empty if your backend creates the customer.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _receiptEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Receipt Email',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: StripeFlowView.values
                  .map(
                    (flow) => ChoiceChip(
                      label: Text(flow.label),
                      selected: _selectedFlow == flow,
                      onSelected: (_) {
                        setState(() {
                          _selectedFlow = flow;
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            _buildSelectedFlow(canRunFlows: canRunFlows),
            if (controller != null && controller.isBusy) ...[
              const SizedBox(height: 16),
              StarterSectionCard(
                title: 'Running flow',
                description:
                    'Keep the app open while Stripe completes the current action.',
                child: Row(
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        controller.activeFlow ?? 'Stripe action in progress',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFlow({required bool canRunFlows}) {
    switch (_selectedFlow) {
      case StripeFlowView.overview:
        return _buildOverviewPanel();
      case StripeFlowView.paymentSheet:
        return _buildPaymentSheetPanel(canRunFlows);
      case StripeFlowView.cardField:
        return _buildCardFieldPanel(canRunFlows);
      case StripeFlowView.cardForm:
        return _buildCardFormPanel(canRunFlows);
      case StripeFlowView.platformPay:
        return _buildPlatformPayPanel(canRunFlows);
      case StripeFlowView.customerSheet:
        return _buildCustomerSheetPanel(canRunFlows);
    }
  }

  Widget _buildOverviewPanel() {
    return Column(
      children: [
        StarterSectionCard(
          title: 'How many ways can you use Stripe here?',
          description:
              'This project is arranged around 5 reusable client patterns. Most production apps start with Payment Sheet, then add the others only when the product needs them.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('1. Payment Sheet: fastest full-screen checkout flow.'),
              SizedBox(height: 8),
              Text(
                '2. CardField: one-line card entry with your own checkout UI.',
              ),
              SizedBox(height: 8),
              Text('3. CardForm: expanded multi-line card form.'),
              SizedBox(height: 8),
              Text('4. Platform Pay: Apple Pay or Google Pay wallet checkout.'),
              SizedBox(height: 8),
              Text(
                '5. Customer Sheet: let users manage saved payment methods.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StarterSectionCard(
          title: 'Backend contract used by this starter',
          description:
              'Never place the Stripe secret key in Flutter. These endpoints are expected from your secure backend, and you can rename them if your server uses different routes.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'POST /payment-sheet -> create PaymentIntent and optional customer/ephemeral key',
              ),
              SizedBox(height: 8),
              Text(
                'POST /payment-intents -> create PaymentIntent for CardField/CardForm/Platform Pay',
              ),
              SizedBox(height: 8),
              Text(
                'POST /customer-sheet -> create customer session data for saved cards',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSheetPanel(bool canRunFlows) {
    return StarterSectionCard(
      title: 'Payment Sheet',
      description:
          'Recommended default for most Flutter apps. Stripe handles payment method selection, wallet buttons, validation, and authentication for you.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Flow: Flutter -> backend /payment-sheet -> initPaymentSheet -> presentPaymentSheet.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: canRunFlows
                ? () => _runRequestFlow(widget.controller!.payWithPaymentSheet)
                : null,
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Run Payment Sheet'),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFieldPanel(bool canRunFlows) {
    return StarterSectionCard(
      title: 'CardField custom flow',
      description:
          'Use this when you need your own layout but still want Stripe to tokenize card details securely. Only one card widget is rendered at a time in this starter to avoid platform conflicts.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_supportsManualCardWidgets)
            CardField(
              onCardChanged: (details) {
                setState(() {
                  _cardFieldComplete = details?.complete ?? false;
                });
              },
              enablePostalCode: true,
              decoration: const InputDecoration(labelText: 'Card details'),
            )
          else
            const Text(
              'CardField demo is intended for Android and iOS. Use Payment Sheet for the base mobile implementation.',
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: canRunFlows && _supportsManualCardWidgets
                ? () => _runRequestFlow(
                    widget.controller!.payWithCardField,
                    requiresCardField: true,
                  )
                : null,
            icon: const Icon(Icons.credit_card_outlined),
            label: const Text('Charge With CardField'),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFormPanel(bool canRunFlows) {
    return StarterSectionCard(
      title: 'CardForm custom flow',
      description:
          'Use this when you want a larger multi-line card form. The backend contract is the same as CardField: your server creates the PaymentIntent and Flutter confirms it.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_supportsManualCardWidgets)
            CardFormField(
              onCardChanged: (details) {
                setState(() {
                  _cardFormComplete = details?.complete ?? false;
                });
              },
              style: CardFormStyle(
                borderRadius: 16,
                backgroundColor: Colors.white,
                borderColor: const Color(0xFFD8E2F1),
                textColor: const Color(0xFF111827),
                placeholderColor: const Color(0xFF7A8699),
              ),
            )
          else
            const Text(
              'CardForm demo is intended for Android and iOS. Use Payment Sheet for the base mobile implementation.',
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: canRunFlows && _supportsManualCardWidgets
                ? () => _runRequestFlow(
                    widget.controller!.payWithCardForm,
                    requiresCardForm: true,
                  )
                : null,
            icon: const Icon(Icons.view_agenda_outlined),
            label: const Text('Charge With CardForm'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformPayPanel(bool canRunFlows) {
    final controller = widget.controller;
    final showNativeButton =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    return StarterSectionCard(
      title: 'Platform Pay',
      description:
          'Use this for Apple Pay or Google Pay. Merchant configuration is required on the native platform and on your Stripe dashboard.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller?.isPlatformPaySupported == true
                ? 'Wallet support detected on this device.'
                : 'Wallet support is not available yet on this device or merchant setup is incomplete.',
          ),
          const SizedBox(height: 16),
          if (showNativeButton &&
              canRunFlows &&
              controller?.isPlatformPaySupported == true)
            PlatformPayButton(
              onPressed: () =>
                  _runRequestFlow(widget.controller!.payWithPlatformPay),
              type: PlatformButtonType.buy,
              appearance: PlatformButtonStyle.black,
            )
          else
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.phone_iphone_outlined),
              label: const Text('Run on Android or iOS'),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerSheetPanel(bool canRunFlows) {
    return StarterSectionCard(
      title: 'Customer Sheet',
      description:
          'Use this to let users view, add, and remove saved payment methods. Your backend must return a Stripe Customer and an ephemeral key.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Flow: Flutter -> backend /customer-sheet -> initCustomerSheet -> presentCustomerSheet.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: canRunFlows ? () => _runCustomerSheet() : null,
            icon: const Icon(Icons.manage_accounts_outlined),
            label: const Text('Open Customer Sheet'),
          ),
        ],
      ),
    );
  }

  Future<void> _runRequestFlow(
    Future<StripeActionResult> Function(StripeCheckoutRequest request) action, {
    bool requiresCardField = false,
    bool requiresCardForm = false,
  }) async {
    try {
      final request = _readRequest();

      if (requiresCardField && !_cardFieldComplete) {
        throw const AppException(
          'Complete the CardField before confirming the payment.',
        );
      }

      if (requiresCardForm && !_cardFormComplete) {
        throw const AppException(
          'Complete the CardForm before confirming the payment.',
        );
      }

      final result = await action(request);
      _showResult(result);
    } on AppException catch (error) {
      _showSnackBar(error.message, isSuccess: false);
    }
  }

  Future<void> _runCustomerSheet() async {
    final controller = widget.controller;
    if (controller == null) {
      return;
    }

    final result = await controller.openCustomerSheet(
      customerId: _customerIdController.text.trim().isEmpty
          ? null
          : _customerIdController.text.trim(),
    );
    _showResult(result);
  }

  StripeCheckoutRequest _readRequest() {
    final amount = int.tryParse(_amountController.text.trim());
    final currency = _currencyController.text.trim().toLowerCase();
    final description = _descriptionController.text.trim();

    if (amount == null || amount <= 0) {
      throw const AppException(
        'Amount must be a positive integer in the smallest currency unit.',
      );
    }

    if (currency.isEmpty) {
      throw const AppException('Currency is required.');
    }

    if (description.isEmpty) {
      throw const AppException('Description is required.');
    }

    return StripeCheckoutRequest(
      amount: amount,
      currency: currency,
      description: description,
      customerId: _customerIdController.text.trim().isEmpty
          ? null
          : _customerIdController.text.trim(),
      receiptEmail: _receiptEmailController.text.trim().isEmpty
          ? null
          : _receiptEmailController.text.trim(),
    );
  }

  void _showResult(StripeActionResult result) {
    _showSnackBar(result.message, isSuccess: result.isSuccess);
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess
            ? const Color(0xFF166534)
            : const Color(0xFFB42318),
      ),
    );
  }

  bool get _supportsManualCardWidgets => !kIsWeb;
}
