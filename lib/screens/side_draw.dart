import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petut/theme/theme_controller.dart';
import 'package:petut/widgets/custom_button.dart';
import 'package:provider/provider.dart';

class SideDraw extends StatefulWidget {
  const SideDraw({super.key});

  @override
  State<SideDraw> createState() => _SideDrawState();
}

class _SideDrawState extends State<SideDraw> {
  String? name;
  String? imageData;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (mounted && doc.exists) {
        final data = doc.data();
        setState(() {
          name = data?['name'] ?? 'Guest';
          imageData = data?['profileImage'];
        });
      }
    }
  }

  Widget _buildProfileImage(ThemeData theme) {
    if (imageData == null || imageData!.isEmpty) {
      return Icon(Icons.person, color: theme.colorScheme.primary, size: 40);
    }

    try {
      final imageBytes = base64Decode(imageData!);
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        width: 60,
        height: 60,
      );
    } catch (e) {
      return Icon(Icons.person, color: theme.colorScheme.primary, size: 40);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = Provider.of<ThemeController>(context);
    final theme = Theme.of(context);

    return Drawer(
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              accountName: Text(
                user != null ? (name ?? 'Loading...') : "Guest",
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                user?.email ?? "Please login to continue",
                style: TextStyle(color: theme.colorScheme.onPrimary.withOpacity(0.9)),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: theme.scaffoldBackgroundColor,
                child: ClipOval(child: _buildProfileImage(theme)),
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (user == null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8,
                      ),
                      child: CustomButton(
                        text: 'Login',
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: CustomButton(
                        text: 'Sign Up',
                        isPrimary: false,
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    ListTile(
                      leading: Icon(Icons.person, color: theme.colorScheme.primary),
                      title: const Text("Profile"),
                      onTap: () {
                        Navigator.pushNamed(context, '/profile');
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: Icon(Icons.history, color: theme.colorScheme.primary),
                      title: const Text("History"),
                      onTap: () {
                        Navigator.pushNamed(context, '/myOrders');
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: Icon(Icons.favorite, color: theme.colorScheme.primary),
                      title: const Text("Favorites"),
                      onTap: () {
                        Navigator.pushNamed(context, '/favorites');
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: Icon(Icons.settings, color: theme.colorScheme.primary),
                      title: const Text("Settings"),
                      onTap: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: Icon(Icons.logout, color: theme.colorScheme.error),
                      title: const Text("Logout"),
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/start',
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Dark Mode', style: TextStyle(fontSize: 16)),
                  Switch(
                    value: themeProvider.isDark,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
