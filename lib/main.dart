import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:petut/firebase_options.dart';
import 'package:petut/screens/Signup&Login/reset_password_screen.dart';
import 'package:petut/screens/appoinment_user_screen.dart';
import 'package:petut/screens/privacy_policy.dart';
import 'package:petut/screens/terms_of_service.dart';
import 'package:petut/services/notification_service.dart';
import 'package:petut/services/support_notification_service.dart';
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
import 'package:petut/screens/contact_us_screen.dart';
import 'package:petut/theme/theme_controller.dart';
import 'package:petut/theme/theme_light.dart';
import 'package:petut/theme/theme_dark.dart';
import 'package:provider/provider.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 رسالة في الخلفية: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize chat notifications safely
  try {
    await NotificationService.initialize();
    await SupportNotificationService.initialize();
  } catch (e) {
    print('Failed to initialize notifications: $e');
  }

  // OneSignal removed for web compatibility

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
        '/reset_password': (context) => const ResetPasswordScreen(),
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
        '/settings': (context) => const SettingsScreen(),
        '/cart': (context) => const CartScreen(),
        '/bookingHistory': (context) => const UserBookingsScreen(),
        '/contactUs': (context) => const ContactUsScreen(),
        '/terms': (context) => const TermsOfServiceScreen(),
        '/privacy': (context) => const PrivacyPolicyScreen(),
      },
    );
  }
}
