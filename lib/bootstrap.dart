import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'app/stripe_starter_app.dart';
import 'core/config/app_env.dart';
import 'core/errors/app_exception.dart';
import 'core/network/backend_client.dart';
import 'features/stripe/data/services/stripe_checkout_service.dart';
import 'features/stripe/presentation/controllers/stripe_starter_controller.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  StripeStarterController? controller;
  String? configurationError;

  try {
    final env = AppEnv.fromDotEnv();

    Stripe.publishableKey = env.publishableKey;
    Stripe.merchantIdentifier = env.hasApplePaySetup
        ? env.merchantIdentifier
        : null;
    Stripe.urlScheme = env.returnUrlScheme;
    Stripe.setReturnUrlSchemeOnAndroid = true;

    await Stripe.instance.applySettings();

    controller = StripeStarterController(
      gateway: StripeCheckoutService(
        env: env,
        backendClient: BackendClient(baseUrl: env.backendBaseUrl),
      ),
    );
  } on AppException catch (error) {
    configurationError = error.message;
  } on StripeConfigException catch (error) {
    configurationError = error.message;
  } catch (error) {
    configurationError =
        'Stripe starter initialization failed. Check your .env values and backend URL.\n$error';
  }

  runApp(
    StripeStarterApp(
      controller: controller,
      configurationError: configurationError,
    ),
  );
}
