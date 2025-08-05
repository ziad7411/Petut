import 'package:flutter/material.dart';
import 'package:petut/screens/my_order_screen.dart';
import 'home_screen.dart';
import 'health_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const MyOrdersScreen(),
    const HealthScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
  ];

  final List<IconData> _icons = [
    FontAwesomeIcons.house,
    FontAwesomeIcons.receipt,
    FontAwesomeIcons.heartPulse,
    FontAwesomeIcons.solidHeart,
    FontAwesomeIcons.user,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        height: 60.0,
        backgroundColor: Colors.transparent,
        color: theme.colorScheme.surface,
        buttonBackgroundColor: theme.colorScheme.primary,
        animationDuration: const Duration(milliseconds: 300),
        items: _icons.map((icon) {
          int index = _icons.indexOf(icon);
          return Icon(
            icon,
            size: 32,
            color: _currentIndex == index
                ? Colors.white
                : theme.colorScheme.primary,
          );
        }).toList(),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
