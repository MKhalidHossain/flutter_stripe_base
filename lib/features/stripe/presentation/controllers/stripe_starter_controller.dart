import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/models/stripe_checkout_request.dart';
import '../../data/services/stripe_checkout_service.dart';

class StripeActionResult {
  const StripeActionResult({required this.isSuccess, required this.message});

  final bool isSuccess;
  final String message;
}

class StripeStarterController extends ChangeNotifier {
  StripeStarterController({required StripeCheckoutGateway gateway})
    : _gateway = gateway;

  factory StripeStarterController.preview() {
    return StripeStarterController(gateway: PreviewStripeCheckoutService());
  }

  final StripeCheckoutGateway _gateway;

  bool isBusy = false;
  bool isPlatformPaySupported = false;
  String? activeFlow;

  Future<void> loadCapabilities() async {
    try {
      isPlatformPaySupported = await _gateway.isPlatformPaySupported();
    } catch (_) {
      isPlatformPaySupported = false;
    }

    notifyListeners();
  }

  Future<StripeActionResult> payWithPaymentSheet(
    StripeCheckoutRequest request,
  ) {
    return _run(
      label: 'Payment Sheet',
      action: () => _gateway.checkoutWithPaymentSheet(request),
    );
  }

  Future<StripeActionResult> payWithCardField(StripeCheckoutRequest request) {
    return _run(
      label: 'CardField',
      action: () => _gateway.checkoutWithCardField(request),
    );
  }

  Future<StripeActionResult> payWithCardForm(StripeCheckoutRequest request) {
    return _run(
      label: 'CardForm',
      action: () => _gateway.checkoutWithCardForm(request),
    );
  }

  Future<StripeActionResult> payWithPlatformPay(StripeCheckoutRequest request) {
    return _run(
      label: 'Platform Pay',
      action: () => _gateway.checkoutWithPlatformPay(request),
    );
  }

  Future<StripeActionResult> openCustomerSheet({String? customerId}) {
    return _run(
      label: 'Customer Sheet',
      action: () => _gateway.openCustomerSheet(customerId: customerId),
    );
  }

  Future<StripeActionResult> _run({
    required String label,
    required Future<String> Function() action,
  }) async {
    isBusy = true;
    activeFlow = label;
    notifyListeners();

    try {
      final message = await action();
      return StripeActionResult(isSuccess: true, message: message);
    } on AppException catch (error) {
      return StripeActionResult(isSuccess: false, message: error.message);
    } catch (error) {
      return StripeActionResult(
        isSuccess: false,
        message: 'Unexpected error in $label.\n$error',
      );
    } finally {
      isBusy = false;
      activeFlow = null;
      notifyListeners();
    }
  }
}
