import 'package:flutter/material.dart';
import 'package:petut/screens/my_order_screen.dart';
import 'home_screen.dart';
import 'health_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  final List<BottomNavigationBarItem> _navBarItems = [
    BottomNavigationBarItem(
      icon: FaIcon(FontAwesomeIcons.house),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: FaIcon(FontAwesomeIcons.receipt),
      label: 'My Orders',
    ),
    BottomNavigationBarItem(
      icon: FaIcon(FontAwesomeIcons.heartPulse),
      label: 'Health',
    ),
    BottomNavigationBarItem(
      icon: FaIcon(FontAwesomeIcons.solidHeart),
      label: 'Favorite',
    ),
    BottomNavigationBarItem(
      icon: FaIcon(FontAwesomeIcons.user),
      label: 'Profile',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        color: theme.scaffoldBackgroundColor,
        height: kBottomNavigationBarHeight + 10,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_navBarItems.length, (index) {
            final isSelected = _currentIndex == index;
            final item = _navBarItems[index];

            return Expanded(
              child: GestureDetector(
                onTap: () => _onItemTapped(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconTheme(
                        data: IconThemeData(
                          size: 22,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.hintColor,
                        ),
                        child: item.icon,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label!,
                        style: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.hintColor,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
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
