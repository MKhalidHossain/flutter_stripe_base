import 'package:flutter/material.dart';

import '../features/stripe/presentation/controllers/stripe_starter_controller.dart';
import '../features/stripe/presentation/pages/stripe_starter_home_page.dart';
import 'theme/app_theme.dart';

class StripeStarterApp extends StatelessWidget {
  const StripeStarterApp({super.key, this.controller, this.configurationError});

  final StripeStarterController? controller;
  final String? configurationError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Stripe Starter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: StripeStarterHomePage(
        controller: controller,
        configurationError: configurationError,
      ),
    );
  }
}
