import '../../../../core/errors/app_exception.dart';

class StripeIntentSecret {
  const StripeIntentSecret({required this.clientSecret});

  factory StripeIntentSecret.fromJson(Map<String, dynamic> json) {
    return StripeIntentSecret(
      clientSecret: _readRequiredString(json, const [
        'clientSecret',
        'client_secret',
      ]),
    );
  }

  final String clientSecret;
}

class StripePaymentSheetSession {
  const StripePaymentSheetSession({
    required this.clientSecret,
    this.customerId,
    this.customerEphemeralKeySecret,
  });

  factory StripePaymentSheetSession.fromJson(Map<String, dynamic> json) {
    return StripePaymentSheetSession(
      clientSecret: _readRequiredString(json, const [
        'paymentIntentClientSecret',
        'clientSecret',
        'client_secret',
      ]),
      customerId: _readOptionalString(json, const [
        'customerId',
        'customer_id',
      ]),
      customerEphemeralKeySecret: _readOptionalString(json, const [
        'customerEphemeralKeySecret',
        'ephemeralKey',
        'ephemeral_key',
      ]),
    );
  }

  final String clientSecret;
  final String? customerId;
  final String? customerEphemeralKeySecret;
}

class StripeCustomerSheetSession {
  const StripeCustomerSheetSession({
    required this.customerId,
    required this.customerEphemeralKeySecret,
    this.setupIntentClientSecret,
  });

  factory StripeCustomerSheetSession.fromJson(Map<String, dynamic> json) {
    return StripeCustomerSheetSession(
      customerId: _readRequiredString(json, const [
        'customerId',
        'customer_id',
      ]),
      customerEphemeralKeySecret: _readRequiredString(json, const [
        'customerEphemeralKeySecret',
        'ephemeralKey',
        'ephemeral_key',
      ]),
      setupIntentClientSecret: _readOptionalString(json, const [
        'setupIntentClientSecret',
        'setup_intent_client_secret',
      ]),
    );
  }

  final String customerId;
  final String customerEphemeralKeySecret;
  final String? setupIntentClientSecret;
}

String _readRequiredString(Map<String, dynamic> json, List<String> keys) {
  final value = _readOptionalString(json, keys);

  if (value == null) {
    throw AppException(
      'Backend response is missing one of these keys: ${keys.join(', ')}',
    );
  }

  return value;
}

String? _readOptionalString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }

  return null;
}
