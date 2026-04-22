import 'package:flutter/material.dart';
import 'package:flutter_app/core/extensions/context_ext.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo-ghabetna.jpeg', height: 150),
            const SizedBox(height: 20),
            Text(
              l.appTitle,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.tagline,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white60),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: AppColors.primaryGreen,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
