import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petut/theme/theme_controller.dart';
import 'package:petut/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';

class SideDraw extends StatefulWidget {
  const SideDraw({super.key});

  @override
  State<SideDraw> createState() => _SideDrawState();
}

class _SideDrawState extends State<SideDraw> {
  String? name;
  String? imageData; // ممكن تكون URL أو Base64

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
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          name = data?['name'] ?? 'Guest';
          imageData = data?['profileImage'];
        });
      }
    }
  }

  Widget _buildProfileImage() {
    if (imageData == null || imageData!.isEmpty) {
      return Icon(Icons.person, color: AppColors.gold, size: 40);
    }

    // Check if it's a URL (simple check)
    final isUrl = imageData!.startsWith('http');

    if (isUrl) {
      return Image.network(
        imageData!,
        fit: BoxFit.cover,
        width: 60,
        height: 60,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.person, color: AppColors.gold, size: 40);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          );
        },
      );
    } else {
      try {
        final imageBytes = base64Decode(imageData!);
        return Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          width: 60,
          height: 60,
        );
      } catch (e) {
        return Icon(Icons.person, color: AppColors.gold, size: 40);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = Provider.of<ThemeController>(context);

    return Drawer(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.9)),
              accountName: Text(
                user != null ? (name ?? 'Loading...') : "Guest",
                style: TextStyle(
                  color: AppColors.background,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                user?.email ?? "Please login to continue",
                style: TextStyle(color: AppColors.background.withOpacity(0.9)),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppColors.background,
                child: ClipOval(child: _buildProfileImage()),
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
                    SizedBox(height: 16),
                    ListTile(
                      leading: Icon(Icons.person, color: AppColors.gold),
                      title: Text("Profile"),
                      onTap: () {
                        Navigator.pushNamed(context, '/profile');
                      },
                    ),
                    SizedBox(height: 12),
                    ListTile(
                      leading: Icon(Icons.history, color: AppColors.gold),
                      title: Text("History"),
                      onTap: () {
                        Navigator.pushNamed(context, '/myOrders');
                      },
                    ),
                    SizedBox(height: 12),

                    ListTile(
                      leading: Icon(Icons.favorite, color: AppColors.gold),
                      title: Text("Favorites"),
                      onTap: () {
                        Navigator.pushNamed(context, '/favorites');
                      },
                    ),
                    SizedBox(height: 12),

                    ListTile(
                      leading: Icon(Icons.settings, color: AppColors.gold),
                      title: Text("Settings"),
                      onTap: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                    SizedBox(height: 12),

                    ListTile(
                      leading: Icon(Icons.logout, color: Colors.redAccent),
                      title: Text("Logout"),
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/signup',
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
                  Text('Dark Mode', style: TextStyle(fontSize: 16)),
                  Switch(
                    value: themeProvider.isDark,
                    activeColor: AppColors.gold,
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
