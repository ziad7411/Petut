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
import 'package:petut/screens/pet_breed_classifier.dart';
import 'package:petut/theme/theme_controller.dart';
import 'package:petut/theme/theme_light.dart';
import 'package:petut/theme/theme_dark.dart';
import 'package:petut/widgets/app_wrapper.dart'; 
import 'package:provider/provider.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 رسالة في الخلفية: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    await NotificationService.initialize();
    await SupportNotificationService.initialize();
  } catch (e) {
    print('Failed to initialize notifications: $e');
  }

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
       
        '/': (context) => AppWrapper(
              child: const SplashScreen(),
              routeName: '/',
            ),
        '/reset_password': (context) => AppWrapper(
              child: const ResetPasswordScreen(),
              routeName: '/reset_password',
            ),
        '/start': (context) => AppWrapper(
              child: const StartScreen(),
              routeName: '/start',
            ),
        '/signup': (context) => AppWrapper(
              child: const SignUpScreen(),
              routeName: '/signup',
            ),
        '/login': (context) => AppWrapper(
              child: const LoginScreen(),
              routeName: '/login',
            ),
        '/main': (context) => AppWrapper(
              child: const MainScreen(),
              routeName: '/main',
            ),
        '/role_selection': (context) => AppWrapper(
              child: const RoleSelectionScreen(),
              routeName: '/role_selection',
            ),
        '/doctor_form': (context) => AppWrapper(
              child: const DoctorFormScreen(),
              routeName: '/doctor_form',
            ),
        '/customer_form': (context) => AppWrapper(
              child: const CustomerFormScreen(),
              routeName: '/customer_form',
            ),
        '/profile': (context) => AppWrapper(
              child: const ProfileScreen(),
              routeName: '/profile',
            ),
        '/goToWebPage': (context) => AppWrapper(
              child: const GoToWebPage(),
              routeName: '/goToWebPage',
            ),
        '/myOrders': (context) => AppWrapper(
              child: const MyOrdersScreen(),
              routeName: '/myOrders',
            ),
        '/favourites': (context) => AppWrapper(
              child: const FavoritesScreen(),
              routeName: '/favourites',
            ),
        '/settings': (context) => AppWrapper(
              child: const SettingsScreen(),
              routeName: '/settings',
            ),
        '/cart': (context) => AppWrapper(
              child: const CartScreen(),
              routeName: '/cart',
            ),
        '/bookingHistory': (context) => AppWrapper(
              child: const UserBookingsScreen(),
              routeName: '/bookingHistory',
            ),
        '/contactUs': (context) => AppWrapper(
              child: const ContactUsScreen(),
              routeName: '/contactUs',
            ),
        '/terms': (context) => AppWrapper(
              child: const TermsOfServiceScreen(),
              routeName: '/terms',
            ),
        '/privacy': (context) => AppWrapper(
              child: const PrivacyPolicyScreen(),
              routeName: '/privacy',
            ),
        '/petClassifier': (context) => AppWrapper(
              child: const PetBreedClassifier(),
              routeName: '/petClassifier',
            ),
      },
    );
  }
}
