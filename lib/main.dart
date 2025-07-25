import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:petut/firebase_options.dart';
import 'package:petut/screens/Signup&Login/login_screen.dart';
import 'package:petut/screens/Signup&Login/signup_screen.dart';
import 'package:petut/screens/Signup&Login/start_screen.dart';
import 'package:petut/screens/cart_screen.dart';
import 'package:petut/screens/favorites_screen.dart';
import 'package:petut/screens/goToDoctorDashboard.dart';
import 'package:petut/screens/my_order_screen.dart';
import 'package:petut/screens/setting_screen.dart';
import 'package:petut/screens/splash_screen.dart';
import 'package:petut/screens/main_screen.dart';
import 'package:petut/screens/role_selection_screen.dart';
import 'package:petut/screens/doctor_form_screen.dart';
import 'package:petut/screens/customer_form_screen.dart';
import 'package:petut/screens/profile_screen.dart';
import 'package:petut/theme/theme_controller.dart';
import 'package:petut/theme/theme_light.dart';
import 'package:petut/theme/theme_dark.dart';
import 'package:provider/provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeController(),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeController.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/start': (context) => const StartScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainScreen(),
        '/role_selection': (context) => const RoleSelectionScreen(),
        '/doctor_form': (context) => const DoctorFormScreen(),
        '/customer_form': (context) => const CustomerFormScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/goToWebPage': (context) => const GoToWebPage(),
        '/myOrders': (context) => const MyOrdersScreen(),
        '/favourites': (context) => const FavoritesScreen(),
        '/settings':(context)=> const SettingsScreen(),
        '/cart': (context) => const CartScreen(),
       },
    );
  }
}
