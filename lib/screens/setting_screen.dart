import 'package:flutter/material.dart';
import 'package:petut/app_colors.dart';


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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.gold),
            accountName: Text(userName ?? ''),
            accountEmail: Text(email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.background,
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
              child: imageUrl == null
                  ? Icon(Icons.person, color: AppColors.gold, size: 40)
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
              value: theme.brightness == Brightness.dark,
              onChanged: (val) {
                // TODO: Implement theme toggle with Provider or Bloc
              },
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
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  // TODO: Logout logic
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
