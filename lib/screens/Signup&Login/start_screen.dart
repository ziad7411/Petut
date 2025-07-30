import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:petut/widgets/custom_button.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  // دالة طلب صلاحية الإشعارات
  void requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Accepted Notifications');
    } else {
      print('❌ Rejected Notifications');
    }
  }
  void getToken() async {
  String? token = await FirebaseMessaging.instance.getToken();
  print('📱 FCM Token: $token');
}


  @override
  void initState() {
    super.initState();
    requestNotificationPermission();
    getToken();
     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Message received in foreground: ${message.notification?.title}');
      print('📩 Message body: ${message.notification?.body}');
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  print('📲 User tapped on notification: ${message.notification?.title}');

});

  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/petut.png',
                        height: MediaQuery.of(context).size.height * 0.45,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome to Pet Care',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your best friend deserves the best care.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: 40),
                      CustomButton(
                        text: 'Sign Up',
                        width: double.infinity,
                        isPrimary: false,
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Login',
                        width: double.infinity,
                        isPrimary: true,
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/main');
                  },
                  child: Text(
                    'Skip',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.hintColor,
                    ),
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
