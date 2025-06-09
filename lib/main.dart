// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MainApp());
// }

// class MainApp extends StatelessWidget {
//   const MainApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       home: Scaffold(
//         body: Center(
//           child: Text('Hello World!'),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import './widgets/custom_button.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CustomButton Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ButtonTestScreen(),
    );
  }
}

class ButtonTestScreen extends StatelessWidget {
  const ButtonTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CustomButton Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomButton(
              text: 'Primary Button',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Primary Button Pressed')),
                );
              },
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Secondary Button',
              isPrimary: false,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Secondary Button Pressed')),
                );
              },
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Custom Color & Icon',
              icon: Icons.thumb_up,
              customColor: Colors.green,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Custom Color Button Pressed')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
