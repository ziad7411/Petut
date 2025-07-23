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
    
    const MyOrdersScreen(),
    const HealthScreen(),
    const HomeScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _navBarItems = [
    BottomNavigationBarItem(
      icon: FaIcon(FontAwesomeIcons.user),
      label: 'Profile',
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
      icon: FaIcon(FontAwesomeIcons.house),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: FaIcon(FontAwesomeIcons.solidHeart),
      label: 'Favorite',
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
      extendBody: true, // لتظهر المنحنيات فوق الخلفية
      body: _pages[_currentIndex],
      bottomNavigationBar: Stack(
        children: [
          // الخلفية المنحنية للبار
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipPath(
              clipper: NavBarClipper(),
              child: Container(
                height: 70,
                color: theme.scaffoldBackgroundColor,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 8),
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
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          color: Colors.transparent,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSlide(
                                offset: isSelected ? const Offset(0, -0.3) : Offset.zero,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutBack,
                                child: AnimatedScale(
                                  scale: isSelected ? 1.3 : 1.0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutBack,
                                  child: IconTheme(
                                    data: IconThemeData(
                                      size: 24,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.hintColor,
                                    ),
                                    child: item.icon,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.label!,
                                style: TextStyle(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.hintColor,
                                  fontSize: 12,
                                  fontWeight:
                                      isSelected ? FontWeight.bold : FontWeight.normal,
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
            ),
          ),
        ],
      ),
    );
  }
}

class NavBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    const curveHeight = 20.0;
    const centerWidth = 80.0;

    path.lineTo((size.width - centerWidth) / 2, 0);

    path.quadraticBezierTo(
      size.width / 2,
      -curveHeight,
      (size.width + centerWidth) / 2,
      0,
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
