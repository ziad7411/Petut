import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:petut/firebase_options.dart';
import 'package:petut/screens/Signup&Login/reset_password_screen.dart';
import 'package:petut/screens/appoinment_user_screen.dart';
import 'package:petut/screens/doctor_booking_screen.dart';
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

import 'package:petut/screens/support_tickets_list_screen.dart';
import 'package:petut/screens/pet_breed_classifier.dart';
import 'package:petut/theme/theme_controller.dart';
import 'package:petut/theme/theme_light.dart';
import 'package:petut/theme/theme_dark.dart';
import 'package:petut/widgets/app_wrapper.dart';
import 'package:provider/provider.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 Background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Geolocator.requestPermission();
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
              routeName: '/',
              child: const SplashScreen(),
            ),
        '/reset_password': (context) => AppWrapper(
              routeName: '/reset_password',
              child: const ResetPasswordScreen(),
            ),
        '/start': (context) => AppWrapper(
              routeName: '/start',
              child: const StartScreen(),
            ),
        '/signup': (context) => AppWrapper(
              routeName: '/signup',
              child: const SignUpScreen(),
            ),
        '/login': (context) => AppWrapper(
              routeName: '/login',
              child: const LoginScreen(),
            ),
        '/main': (context) => AppWrapper(
              routeName: '/main',
              child: const MainScreen(),
            ),
        '/role_selection': (context) => AppWrapper(
              routeName: '/role_selection',
              child: const RoleSelectionScreen(),
            ),
        '/doctor_form': (context) => AppWrapper(
              routeName: '/doctor_form',
              child: const DoctorFormScreen(),
            ),
        '/customer_form': (context) => AppWrapper(
              routeName: '/customer_form',
              child: const CustomerFormScreen(),
            ),
        '/profile': (context) => AppWrapper(
              routeName: '/profile',
              child: const ProfileScreen(),
            ),
        '/myOrders': (context) => AppWrapper(
              routeName: '/myOrders',
              child: const MyOrdersScreen(),
            ),
        '/favourites': (context) => AppWrapper(
              routeName: '/favourites',
              child: const FavoritesScreen(),
            ),
        '/settings': (context) => AppWrapper(
              routeName: '/settings',
              child: const SettingsScreen(),
            ),
        '/cart': (context) => AppWrapper(
              routeName: '/cart',
              child: const CartScreen(),
            ),
        '/bookingHistory': (context) => AppWrapper(
              routeName: '/bookingHistory',
              child: const UserBookingsScreen(),
            ),
        '/support': (context) => AppWrapper(
              routeName: '/support',
              child: const SupportTicketsListScreen(),
            ),
        '/terms': (context) => AppWrapper(
              routeName: '/terms',
              child: const TermsOfServiceScreen(),
            ),
        '/privacy': (context) => AppWrapper(
              routeName: '/privacy',
              child: const PrivacyPolicyScreen(),
            ),
        '/petClassifier': (context) => AppWrapper(
              routeName: '/petClassifier',
              child: const PetBreedClassifier(),
            ),
        '/doctorBooking': (context) => AppWrapper(
              routeName: '/doctorBooking',
              child: DoctorDashboardPage(),
            ),
      },
    );
  }
}
