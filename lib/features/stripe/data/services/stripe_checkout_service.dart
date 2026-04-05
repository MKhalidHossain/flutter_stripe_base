import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../../core/config/app_env.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/backend_client.dart';
import '../models/stripe_backend_models.dart';
import '../models/stripe_checkout_request.dart';

abstract class StripeCheckoutGateway {
  Future<bool> isPlatformPaySupported();

  Future<String> checkoutWithPaymentSheet(StripeCheckoutRequest request);

  Future<String> checkoutWithCardField(StripeCheckoutRequest request);

  Future<String> checkoutWithCardForm(StripeCheckoutRequest request);

  Future<String> checkoutWithPlatformPay(StripeCheckoutRequest request);

  Future<String> openCustomerSheet({String? customerId});
}

class StripeCheckoutService implements StripeCheckoutGateway {
  StripeCheckoutService({required this.env, required this.backendClient});

  final AppEnv env;
  final BackendClient backendClient;

  @override
  Future<bool> isPlatformPaySupported() async {
    if (kIsWeb) {
      return false;
    }

    return Stripe.instance.isPlatformPaySupported(
      googlePay: IsGooglePaySupportedParams(testEnv: env.googlePayTestEnv),
    );
  }

  @override
  Future<String> checkoutWithPaymentSheet(StripeCheckoutRequest request) async {
    try {
      final session = StripePaymentSheetSession.fromJson(
        await backendClient.post('/payment-sheet', data: request.toJson()),
      );

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: env.appName,
          paymentIntentClientSecret: session.clientSecret,
          customerId: session.customerId,
          customerEphemeralKeySecret: session.customerEphemeralKeySecret,
          allowsDelayedPaymentMethods: true,
          returnURL: '${env.returnUrlScheme}://stripe-redirect',
          style: ThemeMode.system,
          billingDetailsCollectionConfiguration:
              const BillingDetailsCollectionConfiguration(
                email: CollectionMode.automatic,
                name: CollectionMode.always,
                address: AddressCollectionMode.full,
              ),
          appearance: _paymentSheetAppearance(),
          applePay: env.hasApplePaySetup
              ? PaymentSheetApplePay(
                  merchantCountryCode: env.merchantCountryCode,
                  buttonType: PlatformButtonType.pay,
                )
              : null,
          googlePay: PaymentSheetGooglePay(
            merchantCountryCode: env.merchantCountryCode,
            currencyCode: request.normalizedCurrency.toUpperCase(),
            testEnv: env.googlePayTestEnv,
            amount: request.amountLabel,
            label: env.appName,
            buttonType: PlatformButtonType.pay,
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      return 'Payment Sheet payment completed successfully.';
    } on StripeException catch (error) {
      throw AppException(
        _stripeMessage(error, defaultMessage: 'Payment Sheet failed.'),
      );
    }
  }

  @override
  Future<String> checkoutWithCardField(StripeCheckoutRequest request) {
    return _checkoutWithManualCardEntry(
      request,
      successMessage: 'CardField payment completed successfully.',
    );
  }

  @override
  Future<String> checkoutWithCardForm(StripeCheckoutRequest request) {
    return _checkoutWithManualCardEntry(
      request,
      successMessage: 'CardForm payment completed successfully.',
    );
  }

  @override
  Future<String> checkoutWithPlatformPay(StripeCheckoutRequest request) async {
    try {
      final paymentIntent = StripeIntentSecret.fromJson(
        await backendClient.post('/payment-intents', data: request.toJson()),
      );

      await Stripe.instance.confirmPlatformPayPaymentIntent(
        clientSecret: paymentIntent.clientSecret,
        confirmParams: _platformPayParams(request),
      );

      return 'Platform Pay payment completed successfully.';
    } on StripeException catch (error) {
      throw AppException(
        _stripeMessage(error, defaultMessage: 'Platform Pay failed.'),
      );
    }
  }

  @override
  Future<String> openCustomerSheet({String? customerId}) async {
    try {
      final session = StripeCustomerSheetSession.fromJson(
        await backendClient.post(
          '/customer-sheet',
          data: <String, dynamic>{
            if ((customerId ?? '').trim().isNotEmpty) 'customerId': customerId,
          },
        ),
      );

      await Stripe.instance.initCustomerSheet(
        customerSheetInitParams: CustomerSheetInitParams(
          customerId: session.customerId,
          customerEphemeralKeySecret: session.customerEphemeralKeySecret,
          setupIntentClientSecret: session.setupIntentClientSecret,
          merchantDisplayName: env.appName,
          returnURL: '${env.returnUrlScheme}://stripe-redirect',
          appearance: _paymentSheetAppearance(),
          applePayEnabled:
              env.hasApplePaySetup &&
              defaultTargetPlatform == TargetPlatform.iOS,
          googlePayEnabled: defaultTargetPlatform == TargetPlatform.android,
        ),
      );

      await Stripe.instance.presentCustomerSheet();
      return 'Customer Sheet opened successfully.';
    } on StripeException catch (error) {
      throw AppException(
        _stripeMessage(error, defaultMessage: 'Customer Sheet failed.'),
      );
    }
  }

  Future<String> _checkoutWithManualCardEntry(
    StripeCheckoutRequest request, {
    required String successMessage,
  }) async {
    try {
      final paymentIntent = StripeIntentSecret.fromJson(
        await backendClient.post('/payment-intents', data: request.toJson()),
      );

      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntent.clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(
              email: request.receiptEmail?.trim().isEmpty == true
                  ? null
                  : request.receiptEmail?.trim(),
            ),
          ),
        ),
      );

      return successMessage;
    } on StripeException catch (error) {
      throw AppException(
        _stripeMessage(error, defaultMessage: 'Card payment failed.'),
      );
    }
  }

  PlatformPayConfirmParams _platformPayParams(StripeCheckoutRequest request) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return PlatformPayConfirmParams.applePay(
        applePay: ApplePayParams(
          merchantCountryCode: env.merchantCountryCode,
          currencyCode: request.normalizedCurrency.toUpperCase(),
          cartItems: [
            ApplePayCartSummaryItem.immediate(
              label: request.description,
              amount: request.amountLabel,
            ),
          ],
        ),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return PlatformPayConfirmParams.googlePay(
        googlePay: GooglePayParams(
          testEnv: env.googlePayTestEnv,
          merchantCountryCode: env.merchantCountryCode,
          currencyCode: request.normalizedCurrency.toUpperCase(),
          merchantName: env.appName,
        ),
      );
    }

    throw const AppException(
      'Platform Pay is only available on Android and iOS devices.',
    );
  }

  PaymentSheetAppearance _paymentSheetAppearance() {
    return const PaymentSheetAppearance(
      colors: PaymentSheetAppearanceColors(
        primary: Color(0xFF0A66FF),
        background: Color(0xFFFFFFFF),
        componentBackground: Color(0xFFF4F7FB),
        componentBorder: Color(0xFFD8E2F1),
        componentDivider: Color(0xFFD8E2F1),
        primaryText: Color(0xFF111827),
        componentText: Color(0xFF111827),
        placeholderText: Color(0xFF7A8699),
      ),
      primaryButton: PaymentSheetPrimaryButtonAppearance(
        colors: PaymentSheetPrimaryButtonTheme(
          light: PaymentSheetPrimaryButtonThemeColors(
            background: Color(0xFF0A66FF),
            text: Color(0xFFFFFFFF),
            border: Color(0xFF0A66FF),
          ),
        ),
      ),
    );
  }

  String _stripeMessage(
    StripeException error, {
    required String defaultMessage,
  }) {
    final localized = error.error.localizedMessage?.trim();
    final generic = error.error.message?.trim();

    if (error.error.code == FailureCode.Canceled) {
      return 'Action canceled by user.';
    }

    if (localized != null && localized.isNotEmpty) {
      return localized;
    }

    if (generic != null && generic.isNotEmpty) {
      return generic;
    }

    return defaultMessage;
  }
}

class PreviewStripeCheckoutService implements StripeCheckoutGateway {
  @override
  Future<bool> isPlatformPaySupported() async => false;

  @override
  Future<String> checkoutWithPaymentSheet(StripeCheckoutRequest request) async {
    return 'Preview mode: Payment Sheet button is wired correctly.';
  }

  @override
  Future<String> checkoutWithCardField(StripeCheckoutRequest request) async {
    return 'Preview mode: CardField flow is wired correctly.';
  }

  @override
  Future<String> checkoutWithCardForm(StripeCheckoutRequest request) async {
    return 'Preview mode: CardForm flow is wired correctly.';
  }

  @override
  Future<String> checkoutWithPlatformPay(StripeCheckoutRequest request) async {
    return 'Preview mode: Platform Pay flow is wired correctly.';
  }

  @override
  Future<String> openCustomerSheet({String? customerId}) async {
    return 'Preview mode: Customer Sheet flow is wired correctly.';
  }
}
