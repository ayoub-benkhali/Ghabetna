import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo-ghabetna.jpeg',height: 150,),
            const SizedBox(height: 24,),
            Text(
              'Ghabetna',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 1
              ),
            ),
            const SizedBox(height: 8,),
            Text('Surveillance forestiére intelligent',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white60
              ),
            ),
            const SizedBox(height: 48,),
            const CircularProgressIndicator(
              color: AppColors.primaryGreen,
              strokeWidth: 2,
            )
          ],
        ),
      ),
    );
  }
}
