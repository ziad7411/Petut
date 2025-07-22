import 'package:flutter/material.dart';
import 'package:petut/screens/doctors_list_screen.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This screen simply displays the ClinicsScreen, which is already theme-aware.
    return const ClinicsScreen();
  }
}