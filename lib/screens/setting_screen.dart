import 'package:flutter/material.dart';
import 'package:petut/theme/theme_controller.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatelessWidget {
  final String? userName;
  final String? email;
  final String? imageUrl;

  const SettingsScreen({
    super.key,
    this.userName = "Ziad Nasser",
    this.email = "ziadnassermasloub@gmail.com",
    this.imageUrl,
  });

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
      ),
      body: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            accountName: Text(userName ?? '', style: TextStyle(color: theme.colorScheme.onPrimary)),
            accountEmail: Text(email ?? '', style: TextStyle(color: theme.colorScheme.onPrimary.withOpacity(0.8))),
            currentAccountPicture: CircleAvatar(
              backgroundColor: theme.scaffoldBackgroundColor,
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
              child: imageUrl == null
                  ? Icon(Icons.person, color: theme.colorScheme.primary, size: 40)
                  : null,
            ),
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
