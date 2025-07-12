import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../app_colors.dart';
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

    // Change messages every second
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (msgIndex < messages.length - 1) {
        setState(() {
          msgIndex++;
          loadingText = messages[msgIndex];
        });
      }
    });

    // After 3 seconds, go to success screen
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BookingSuccessScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie Animation
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.gray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
