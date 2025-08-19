import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petut/screens/Signup&Login/auth_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // خلي التنقل بعد ما الأنيميشن يخلص
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        navigateUser();
      }
    });
  }

  void navigateUser() async {
    String status = await AuthHelper.checkUserState();

    switch (status) {
      case 'not_logged_in':
        Navigator.pushReplacementNamed(context, '/start');
        break;
      case 'incomplete_form_doctor':
        Navigator.pushReplacementNamed(context, '/doctor_form');
        break;
      case 'incomplete_form_customer':
        Navigator.pushReplacementNamed(context, '/customer_form');
        break;
      case 'doctor_home':
        Navigator.pushReplacementNamed(context, '/doctorBooking');
        break;
      case 'user_home':
        Navigator.pushReplacementNamed(context, '/main');
        break;
      default:
        Navigator.pushReplacementNamed(context, '/start');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  flex: 6,
                  child: Center(
                    child: Image.asset(
                      'assets/images/petut.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'With us, pets live like royalty',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                        strokeWidth: 2.5,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
