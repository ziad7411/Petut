import 'dart:async';
import 'package:flutter/material.dart';
import '../app_colors.dart';

class BookingSuccessScreen extends StatefulWidget {
  const BookingSuccessScreen({super.key});

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<double> _iconAnimation;
  bool showText = false;

  @override
  void initState() {
    super.initState();

    // Icon Animation
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _iconAnimation =
        CurvedAnimation(parent: _iconController, curve: Curves.easeOutBack);

    _iconController.forward();

    // Show text after short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        showText = true;
      });
    });

    // Navigate back to home after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.popUntil(context, (route) => route.isFirst);
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _iconAnimation,
                  child: const Icon(Icons.check_circle_rounded,
                      color: Colors.green, size: 100),
                ),
                const SizedBox(height: 24),
                AnimatedOpacity(
                  opacity: showText ? 1 : 0,
                  duration: const Duration(milliseconds: 600),
                  child: const Text(
                    "Appointment Confirmed!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedOpacity(
                  opacity: showText ? 1 : 0,
                  duration: const Duration(milliseconds: 800),
                  child: const Text(
                    "Your appointment has been booked successfully.\nReturning to home...",
                    style: TextStyle(fontSize: 16, color: AppColors.gray),
                    textAlign: TextAlign.center,
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
