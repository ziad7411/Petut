import 'dart:async';
import 'package:flutter/material.dart';
import '../app_colors.dart';
import './home_screen.dart';

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

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _iconAnimation =
        CurvedAnimation(parent: _iconController, curve: Curves.easeOutBack);

    _iconController.forward();

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        showText = true;
      });
    });

    Timer(const Duration(seconds: 2), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = AppColors.getBackgroundColor(context);
    final primaryTextColor = AppColors.getTextPrimaryColor(context);
    final secondaryTextColor = AppColors.getTextSecondaryColor(context);

    return Scaffold(
      backgroundColor: backgroundColor,
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
                  child: Text(
                    "Appointment Confirmed!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedOpacity(
                  opacity: showText ? 1 : 0,
                  duration: const Duration(milliseconds: 800),
                  child: Text(
                    "Your appointment has been booked successfully.\nReturning to home...",
                    style: TextStyle(
                      fontSize: 16,
                      color: secondaryTextColor,
                    ),
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
