import 'dart:async';
import 'package:flutter/material.dart';
import './main_screen.dart';

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
  late Timer _navigationTimer;

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
      if (mounted) {
        setState(() {
          showText = true;
        });
      }
    });

    // FIX: Navigate to MainScreen and clear all previous routes.
    // This ensures the BottomNavigationBar is always present.
    _navigationTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _navigationTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                      color: theme.textTheme.bodyLarge?.color,
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
                    style: TextStyle(fontSize: 16, color: theme.hintColor),
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