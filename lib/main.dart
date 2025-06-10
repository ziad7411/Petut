import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/services_screen.dart';
import 'screens/health_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/custom_button.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CustomButton Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const CatalogScreen(),
    const ServicesScreen(),
    const HealthScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _navBarItems = [
    const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    const BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Catalog'),
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
        color: Colors.white,
        height: kBottomNavigationBarHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_navBarItems.length, (index) {
            return GestureDetector(
              onTap: () => _onItemTapped(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: _currentIndex == index ? const Color.fromARGB(255, 255, 213, 0) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    (_navBarItems[index].icon as Icon).icon != null
                        ? Icon((_navBarItems[index].icon as Icon).icon, size: 20, color: Colors.grey) 
                        : const SizedBox.shrink(),
                    const SizedBox(height: 2), 
                    Text(_navBarItems[index].label!, style: const TextStyle(color: Colors.grey, fontSize: 12)), 
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class ButtonTestScreen extends StatelessWidget {
  const ButtonTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CustomButton Test')),
      body: SingleChildScrollView( 
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomButton(
                text: 'Primary Button',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Primary Button Pressed')),
                  );
                },
              ),
              const SizedBox(height: 10), 
              CustomButton(
                text: 'Secondary Button',
                isPrimary: false,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Secondary Button Pressed')),
                  );
                },
              ),
              const SizedBox(height: 10), 
              CustomButton(
                text: 'Custom Color & Icon',
                icon: Icons.thumb_up,
                customColor: Colors.green,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Custom Color Button Pressed')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}