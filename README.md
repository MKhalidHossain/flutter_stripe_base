# Flutter Stripe Starter

Reusable Flutter base project for Stripe with a backend-first structure, guided comments in code, and starter flows for the most common mobile payment patterns.

## What this project gives you

- Clean Flutter project structure focused on Stripe instead of the default counter app.
- Safe architecture: no Stripe secret key in Flutter.
- Reusable request and service layer for backend-driven Stripe flows.
- Example UI for 5 Stripe usage patterns:
  - Payment Sheet
  - CardField
  - CardForm
  - Apple Pay / Google Pay
  - Customer Sheet
- Platform setup fixes for Android and iOS.

## How many ways can you use Stripe here?

This starter demonstrates 5 main client-side patterns:

1. Payment Sheet
2. CardField
3. CardForm
4. Platform Pay
5. Customer Sheet

For subscriptions, invoices, webhooks, off-session charges, and saved cards on future purchases, you build on the same backend contract shown below.

## Important rule

Never place `STRIPE_SECRET_KEY` in Flutter.

The old project did that. This starter removes it because the secret key must stay on your backend only.

## Project structure

```text
lib/
  app/
    stripe_starter_app.dart
    theme/app_theme.dart
  core/
    config/app_env.dart
    errors/app_exception.dart
    network/backend_client.dart
  features/
    stripe/
      data/
        models/
          stripe_backend_models.dart
          stripe_checkout_request.dart
        services/
          stripe_checkout_service.dart
      presentation/
        controllers/stripe_starter_controller.dart
        pages/stripe_starter_home_page.dart
        widgets/starter_section_card.dart
  bootstrap.dart
  main.dart
```

## Environment variables

This project reads `.env` at app startup.

Example:

```env
APP_NAME=Flutter Stripe Starter
STRIPE_PUBLISHABLE_KEY=pk_test_your_publishable_key
STRIPE_BACKEND_URL=http://10.0.2.2:4242
STRIPE_MERCHANT_IDENTIFIER=merchant.com.example.flutterStripeStarter
STRIPE_MERCHANT_COUNTRY_CODE=US
STRIPE_DEFAULT_CURRENCY=usd
STRIPE_RETURN_URL_SCHEME=flutterstripestarter
STRIPE_GOOGLE_PAY_TEST_ENV=true
```

Notes:

- `STRIPE_BACKEND_URL` is required because this starter expects your secure server to create Stripe objects.
- `10.0.2.2` is the Android emulator alias for your local machine.
- On iOS simulator, use your local machine IP or localhost depending on your server setup.
- `STRIPE_MERCHANT_IDENTIFIER` is needed for Apple Pay.

## Backend endpoints expected by this starter

You can rename these routes. If you do, update [stripe_checkout_service.dart](/Users/saa/dev/others/flutter_stripe_base/lib/features/stripe/data/services/stripe_checkout_service.dart).

### `POST /payment-sheet`

Purpose:

- Create a PaymentIntent
- Optionally create or reuse a Customer
- Optionally create an ephemeral key for saved methods

Example request:

```json
{
  "amount": 1000,
  "currency": "usd",
  "description": "Starter checkout",
  "customerId": "optional_customer_id",
  "receiptEmail": "customer@example.com"
}
```

Example response:

```json
{
  "clientSecret": "pi_xxx_secret_xxx",
  "customerId": "cus_xxx",
  "customerEphemeralKeySecret": "ek_test_xxx"
}
```

### `POST /payment-intents`

Purpose:

- Create a PaymentIntent for CardField, CardForm, or Platform Pay

Example response:

```json
{
  "clientSecret": "pi_xxx_secret_xxx"
}
```

### `POST /customer-sheet`

Purpose:

- Create or fetch a Stripe Customer
- Create an ephemeral key
- Optionally create a SetupIntent for authentication during saved card creation

Example response:

```json
{
  "customerId": "cus_xxx",
  "customerEphemeralKeySecret": "ek_test_xxx",
  "setupIntentClientSecret": "seti_xxx_secret_xxx"
}
```

## Stripe flow guide

### 1. Payment Sheet

Best when you want the easiest and most complete checkout experience.

Client flow:

1. Build a `StripeCheckoutRequest`
2. Call backend `/payment-sheet`
3. Initialize Stripe Payment Sheet
4. Present Payment Sheet

Entry point:

- [stripe_starter_home_page.dart](/Users/saa/dev/others/flutter_stripe_base/lib/features/stripe/presentation/pages/stripe_starter_home_page.dart)
- [stripe_checkout_service.dart](/Users/saa/dev/others/flutter_stripe_base/lib/features/stripe/data/services/stripe_checkout_service.dart)

### 2. CardField

Best when you need a custom checkout screen with inline card entry.

Client flow:

1. Render `CardField`
2. Call backend `/payment-intents`
3. Confirm payment with `Stripe.instance.confirmPayment`

### 3. CardForm

Best when you want a larger multi-line card form.

Flow is the same as CardField, but the widget is `CardFormField`.

### 4. Apple Pay / Google Pay

Best when you want the fastest wallet checkout on mobile.

Client flow:

1. Check wallet support on device
2. Call backend `/payment-intents`
3. Confirm with `confirmPlatformPayPaymentIntent`

### 5. Customer Sheet

Best when users need to manage saved payment methods.

Client flow:

1. Call backend `/customer-sheet`
2. Initialize Customer Sheet
3. Present Customer Sheet

## Android setup included

This starter already applies the key Android changes Stripe needs:

- `MainActivity` uses `FlutterFragmentActivity`
- App theme uses `Theme.AppCompat`
- `minSdk` is forced to at least `21`
- release build has Stripe proguard rules

Files:

- [MainActivity.kt](/Users/saa/dev/others/flutter_stripe_base/android/app/src/main/kotlin/com/example/flutter_stripe_base/MainActivity.kt)
- [build.gradle.kts](/Users/saa/dev/others/flutter_stripe_base/android/app/build.gradle.kts)
- [styles.xml](/Users/saa/dev/others/flutter_stripe_base/android/app/src/main/res/values/styles.xml)

## iOS setup included

This starter already includes:

- `platform :ios, '13.0'`
- camera usage description for card scanning
- Stripe initialization handled in Dart bootstrap instead of AppDelegate

Files:

- [Podfile](/Users/saa/dev/others/flutter_stripe_base/ios/Podfile)
- [Info.plist](/Users/saa/dev/others/flutter_stripe_base/ios/Runner/Info.plist)
- [bootstrap.dart](/Users/saa/dev/others/flutter_stripe_base/lib/bootstrap.dart)

## What to customize next

- Replace app name and bundle identifiers
- Point `STRIPE_BACKEND_URL` to your real backend
- Match backend route names if you use different endpoints
- Add webhook handling on the server for payment lifecycle events
- Add subscription endpoints if you need recurring billing
- Add app-specific business validation around amount, currency, and customer mapping

## Run the starter

```bash
flutter pub get
flutter run
```

If Stripe actions fail immediately, check:

- `.env` values
- backend server is running
- emulator/device can reach the backend URL
- Apple Pay / Google Pay merchant configuration
# stripe_base_flutter
