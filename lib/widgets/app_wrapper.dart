import 'package:flutter/material.dart';
import 'floating_help_button.dart';

class AppWrapper extends StatelessWidget {
  final Widget child;
  final String? routeName;

  const AppWrapper({super.key, required this.child, this.routeName});

  static const List<String> excludedRoutes = [
    '/',
    '/start',
    '/login',
    '/signup',
    '/reset_password',
    '/role_selection',
    '/doctor_form',
    '/customer_form',
  ];

  bool get shouldShowHelpButton {
    print('Route name: $routeName');
    print(
        'Should show help button: ${routeName != null && !excludedRoutes.contains(routeName)}');

    if (routeName == null) {
      return true;
    }
    return !excludedRoutes.contains(routeName);
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child, 
        if (shouldShowHelpButton) const FloatingHelpButton(), 
      ],
    );
  }
}
