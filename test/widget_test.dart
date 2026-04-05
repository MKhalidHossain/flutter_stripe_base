import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_stripe_base/app/stripe_starter_app.dart';

void main() {
  testWidgets('renders starter overview', (WidgetTester tester) async {
    await tester.pumpWidget(
      const StripeStarterApp(configurationError: 'Missing .env configuration'),
    );

    expect(find.text('Flutter Stripe Starter'), findsOneWidget);
    expect(find.text('Reusable Stripe base project'), findsOneWidget);
    expect(find.text('Payment Sheet'), findsWidgets);
  });
}
