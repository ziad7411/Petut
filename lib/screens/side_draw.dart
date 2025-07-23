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
  String? imageData;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
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

  Widget _buildProfileImage(Color fallbackColor) {
    if (imageData == null || imageData!.isEmpty) {
      return Icon(Icons.person, color: fallbackColor, size: 40);
    }

    final isUrl = imageData!.startsWith('http');

    if (isUrl) {
      return Image.network(
        imageData!,
        fit: BoxFit.cover,
        width: 60,
        height: 60,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.person, color: fallbackColor, size: 40);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(color: fallbackColor),
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
        return Icon(Icons.person, color: fallbackColor, size: 40);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = Provider.of<ThemeController>(context);

    // 🌗 Colors from theme
    final primaryColor = AppColors.getPrimaryColor(context);
    final backgroundColor = AppColors.getBackgroundColor(context);
    final textPrimary = AppColors.getTextPrimaryColor(context);
    final textSecondary = AppColors.getTextSecondaryColor(context);

    return Drawer(
      child: Container(
        color: backgroundColor,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: primaryColor.withOpacity(0.9)),
              accountName: Text(
                user != null ? (name ?? 'Loading...') : "Guest",
                style: TextStyle(
                  color: backgroundColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                user?.email ?? "Please login to continue",
                style: TextStyle(color: backgroundColor.withOpacity(0.9)),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: backgroundColor,
                child: ClipOval(child: _buildProfileImage(primaryColor)),
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (user == null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                      child: CustomButton(
                        text: 'Login',
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: CustomButton(
                        text: 'Sign Up',
                        isPrimary: false,
                        onPressed: () => Navigator.pushNamed(context, '/signup'),
                      ),
                    ),
                  ] else ...[
                    SizedBox(height: 16),
                    _buildListTile(Icons.person, "Profile", () => Navigator.pushNamed(context, '/profile'), primaryColor, textPrimary),
                    _buildListTile(Icons.history, "History", () => Navigator.pushNamed(context, '/myOrders'), primaryColor, textPrimary),
                    _buildListTile(Icons.favorite, "Favorites", () => Navigator.pushNamed(context, '/favorites'), primaryColor, textPrimary),
                    _buildListTile(Icons.settings, "Settings", () => Navigator.pushNamed(context, '/settings'), primaryColor, textPrimary),
                    ListTile(
                      leading: Icon(Icons.logout, color: Colors.redAccent),
                      title: Text("Logout", style: TextStyle(color: textPrimary)),
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushNamedAndRemoveUntil(context, '/signup', (route) => false);
                      },
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Dark Mode', style: TextStyle(fontSize: 16, color: textPrimary)),
                  Switch(
                    value: themeProvider.isDark,
                    activeColor: primaryColor,
                    onChanged: (value) => themeProvider.toggleTheme(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(
      IconData icon, String title, VoidCallback onTap, Color iconColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: TextStyle(color: textColor)),
        onTap: onTap,
      ),
    );
  }
}
