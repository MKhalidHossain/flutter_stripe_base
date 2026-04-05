class StripeCheckoutRequest {
  const StripeCheckoutRequest({
    required this.amount,
    required this.currency,
    required this.description,
    this.customerId,
    this.receiptEmail,
  });

  final int amount;
  final String currency;
  final String description;
  final String? customerId;
  final String? receiptEmail;

  String get normalizedCurrency => currency.toLowerCase().trim();

  String get amountLabel => (amount / 100).toStringAsFixed(2);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'amount': amount,
      'currency': normalizedCurrency,
      'description': description.trim(),
      if ((customerId ?? '').trim().isNotEmpty)
        'customerId': customerId!.trim(),
      if ((receiptEmail ?? '').trim().isNotEmpty)
        'receiptEmail': receiptEmail!.trim(),
    };
  }
}
