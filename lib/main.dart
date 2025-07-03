import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:petut/firebase_options.dart';
import 'package:petut/screens/Signup&Login/login_screen.dart';
import 'package:petut/screens/Signup&Login/signup_screen.dart';
import 'package:petut/screens/Signup&Login/start_screen.dart';

import 'package:petut/screens/splash_screen.dart';
import 'package:petut/screens/main_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/start': (context) => const StartScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}
