import 'package:flutter/material.dart';
import 'package:petut/app_colors.dart';
import 'home_screen.dart';
import 'services_screen.dart';
import 'health_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const ServicesScreen(),
  const HealthScreen(), 
    const FavoritesScreen(),
    const ProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _navBarItems = [
    const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    const BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Services'),
    const BottomNavigationBarItem(icon: Icon(Icons.health_and_safety), label: 'Health'),
    const BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorite'),
    const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
  color: AppColors.background,
  height: kBottomNavigationBarHeight,
  child: Row(
    children: List.generate(_navBarItems.length, (index) {
      return Expanded(
        child: GestureDetector(
          onTap: () => _onItemTapped(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: _currentIndex == index ? AppColors.gold : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if ((_navBarItems[index].icon as Icon).icon != null)
                  Icon((_navBarItems[index].icon as Icon).icon,
                      size: 20, color: AppColors.gray),
                const SizedBox(height: 2),
                Text(
                  _navBarItems[index].label!,
                  style: const TextStyle(color: AppColors.gray, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }),
  ),
),

    );
  }
}
