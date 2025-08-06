import 'package:flutter/material.dart';
import 'package:fluttermoji/fluttermoji.dart';

class AvatarSelectionScreen extends StatefulWidget {
  const AvatarSelectionScreen({super.key});

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  String? selectedAvatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Choose Avatar',
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.colorScheme.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Customize your avatar',
              style: TextStyle(
                fontSize: 18,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 200,
              width: 200,
              child: ClipOval(
                child: FluttermojiCircleAvatar(
                  radius: 100,
                  backgroundColor: theme.colorScheme.surface,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FluttermojiCustomizer(
                scaffoldWidth: MediaQuery.of(context).size.width,
                autosave: true,
                theme: FluttermojiThemeData(
                  boxDecoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  iconColor: theme.colorScheme.primary,
                  selectedIconColor: theme.colorScheme.onPrimary,
                  labelTextStyle: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await FluttermojiController().setFluttermoji();
                    if (mounted) {
                      Navigator.pop(context, 'fluttermoji_avatar');
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context, 'fluttermoji_avatar');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Avatar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}