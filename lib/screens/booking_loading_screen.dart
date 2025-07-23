import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'booking_success_screen.dart';

class BookingLoadingScreen extends StatefulWidget {
  const BookingLoadingScreen({super.key});

  @override
  State<BookingLoadingScreen> createState() => _BookingLoadingScreenState();
}

class _BookingLoadingScreenState extends State<BookingLoadingScreen> {
  String loadingText = "Confirming your appointment...";
  final List<String> messages = [
    "Confirming your appointment...",
    "Processing payment...",
    "Almost done..."
  ];

  int msgIndex = 0;

  @override
  void initState() {
    super.initState();

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && msgIndex < messages.length - 1) {
        setState(() {
          msgIndex++;
          loadingText = messages[msgIndex];
        });
      } else {
        timer.cancel();
      }
    });

    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BookingSuccessScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 180,
              width: 180,
              child: Lottie.asset(
                'assets/animations/Catloader.json',
                repeat: true,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loadingText,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}