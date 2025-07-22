import 'package:flutter/material.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            accountName: Text(
              userName ?? '',
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onPrimary),
            ),
            accountEmail: Text(
              email ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: theme.colorScheme.onPrimary,
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
              value: isDark,
              onChanged: (val) {
                // TODO: استخدم Provider أو Bloc لتغيير الثيم
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
