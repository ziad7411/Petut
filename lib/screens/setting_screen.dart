import 'package:flutter/material.dart';
import 'package:petut/theme/theme_controller.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../utils/avatar_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? userName;
  String? email;
  String? profileImage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          final data = doc.data()!;
          setState(() {
            userName = data['name'] ?? 'User';
            email = user.email ?? 'No email';
            profileImage = data['profileImage'];
            isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            userName = 'User';
            email = user.email ?? 'No email';
            isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          userName = 'Guest';
          email = 'Please login';
          isLoading = false;
        });
      }
    }
  }

  Widget _buildProfileImage(ThemeData theme) {
    if (profileImage != null && profileImage!.isNotEmpty) {
      // Check if it's an avatar ID
      if (AvatarHelper.avatarData.containsKey(profileImage)) {
        return AvatarHelper.buildAvatar(profileImage, size: 60);
      }
      // Check if it's base64 image
      try {
        final imageBytes = base64Decode(profileImage!);
        return ClipOval(
          child: Image.memory(
            imageBytes,
            fit: BoxFit.cover,
            width: 60,
            height: 60,
          ),
        );
      } catch (e) {
        return _buildTextAvatar(theme);
      }
    }
    return _buildTextAvatar(theme);
  }

  Widget _buildTextAvatar(ThemeData theme) {
    final initials = userName != null && userName!.isNotEmpty 
        ? userName!.trim().split(' ').map((name) => name.isNotEmpty ? name[0].toUpperCase() : '').take(2).join()
        : 'U';
    
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: theme.colorScheme.primary,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeController>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.iconTheme.color),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/main');
            }
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(color: theme.colorScheme.primary),
                  accountName: Text(
                    userName ?? 'Loading...',
                    style: TextStyle(color: theme.colorScheme.onPrimary),
                  ),
                  accountEmail: Text(
                    email ?? 'Loading...',
                    style: TextStyle(color: theme.colorScheme.onPrimary.withOpacity(0.8)),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: theme.scaffoldBackgroundColor,
                    child: _buildProfileImage(theme),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  onTap: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change Password'),
                  onTap: () {
                    // TODO: Navigate to change password screen
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('Dark Mode'),
                  trailing: Switch(
                    value: themeProvider.isDark,
                    onChanged: (val) {
                      themeProvider.toggleTheme();
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                if (FirebaseAuth.instance.currentUser != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushNamedAndRemoveUntil(context, '/start', (route) => false);
                        },
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
