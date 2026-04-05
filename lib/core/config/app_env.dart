import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../errors/app_exception.dart';

class AppEnv {
  const AppEnv({
    required this.appName,
    required this.publishableKey,
    required this.backendBaseUrl,
    required this.merchantIdentifier,
    required this.merchantCountryCode,
    required this.defaultCurrency,
    required this.returnUrlScheme,
    required this.googlePayTestEnv,
  });

  factory AppEnv.fromDotEnv() {
    final publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']?.trim() ?? '';
    final backendBaseUrl = dotenv.env['STRIPE_BACKEND_URL']?.trim() ?? '';

    if (publishableKey.isEmpty) {
      throw const AppException('Missing STRIPE_PUBLISHABLE_KEY in .env.');
    }

    if (backendBaseUrl.isEmpty) {
      throw const AppException(
        'Missing STRIPE_BACKEND_URL in .env. This starter expects a secure backend.',
      );
    }

    return AppEnv(
      appName: dotenv.env['APP_NAME']?.trim().isNotEmpty == true
          ? dotenv.env['APP_NAME']!.trim()
          : 'Flutter Stripe Starter',
      publishableKey: publishableKey,
      backendBaseUrl: backendBaseUrl,
      merchantIdentifier:
          dotenv.env['STRIPE_MERCHANT_IDENTIFIER']?.trim() ?? '',
      merchantCountryCode: (dotenv.env['STRIPE_MERCHANT_COUNTRY_CODE'] ?? 'US')
          .toUpperCase(),
      defaultCurrency: (dotenv.env['STRIPE_DEFAULT_CURRENCY'] ?? 'usd')
          .toLowerCase(),
      returnUrlScheme:
          (dotenv.env['STRIPE_RETURN_URL_SCHEME'] ?? 'flutterstripestarter')
              .trim(),
      googlePayTestEnv:
          (dotenv.env['STRIPE_GOOGLE_PAY_TEST_ENV'] ?? 'true').toLowerCase() ==
          'true',
    );
  }

  final String appName;
  final String publishableKey;
  final String backendBaseUrl;
  final String merchantIdentifier;
  final String merchantCountryCode;
  final String defaultCurrency;
  final String returnUrlScheme;
  final bool googlePayTestEnv;

  bool get hasApplePaySetup => merchantIdentifier.isNotEmpty;
}
