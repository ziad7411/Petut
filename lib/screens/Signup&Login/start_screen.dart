import 'package:flutter/material.dart';
import 'package:petut/widgets/custom_button.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          children: [
            // المحتوى الرئيسي
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/petut.png',
                    height: MediaQuery.of(context).size.height * 0.45,
                  ),

                  Text(
                    'Welcome to Pet Care',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Your best friend deserves the best care.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // زر Sign Up بعرض الشاشة
                  CustomButton(
                    text: 'Sign Up',
                    width: double.infinity,
                    isPrimary: false,
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                  ),
                  const SizedBox(height: 16),

                  // زر Login بعرض الشاشة
                  CustomButton(
                    text: 'Login',
                    width: double.infinity,
                    isPrimary: true,
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                  ),
                ],
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/main');
                },
                child: Text(
                  'Skip',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.hintColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
