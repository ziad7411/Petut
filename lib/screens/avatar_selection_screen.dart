import 'package:flutter/material.dart';

class AvatarSelectionScreen extends StatefulWidget {
  const AvatarSelectionScreen({super.key});

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  String? selectedAvatar;
  
  final List<Map<String, dynamic>> avatars = [
    // Professional
    {'icon': Icons.medical_services, 'color': Colors.blue, 'id': 'doctor_blue'},
    {'icon': Icons.local_hospital, 'color': Colors.green, 'id': 'hospital_green'},
    {'icon': Icons.healing, 'color': Colors.red, 'id': 'healing_red'},
    {'icon': Icons.health_and_safety, 'color': Colors.purple, 'id': 'health_purple'},
    
    // People
    {'icon': Icons.person, 'color': Colors.orange, 'id': 'person_orange'},
    {'icon': Icons.face, 'color': Colors.teal, 'id': 'face_teal'},
    {'icon': Icons.account_circle, 'color': Colors.indigo, 'id': 'account_indigo'},
    {'icon': Icons.person_outline, 'color': Colors.brown, 'id': 'person_brown'},
    
    // Fun & Friendly
    {'icon': Icons.emoji_emotions, 'color': Colors.amber, 'id': 'emoji_amber'},
    {'icon': Icons.sentiment_very_satisfied, 'color': Colors.pink, 'id': 'happy_pink'},
    {'icon': Icons.favorite, 'color': Colors.red, 'id': 'heart_red'},
    {'icon': Icons.star, 'color': Colors.yellow, 'id': 'star_yellow'},
    
    // Animals
    {'icon': Icons.pets, 'color': Colors.brown, 'id': 'pets_brown'},
    {'icon': Icons.cruelty_free, 'color': Colors.green, 'id': 'paw_green'},
    
    // Nature
    {'icon': Icons.eco, 'color': Colors.green, 'id': 'eco_green'},
    {'icon': Icons.local_florist, 'color': Colors.pink, 'id': 'flower_pink'},
    
    // Tech
    {'icon': Icons.android, 'color': Colors.green, 'id': 'android_green'},
    {'icon': Icons.computer, 'color': Colors.blue, 'id': 'computer_blue'},
    
    // Sports
    {'icon': Icons.sports_soccer, 'color': Colors.black, 'id': 'soccer_black'},
    {'icon': Icons.fitness_center, 'color': Colors.red, 'id': 'fitness_red'},
  ];

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
              'Select your profile avatar',
              style: TextStyle(
                fontSize: 18,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: avatars.length,
                itemBuilder: (context, index) {
                  final avatar = avatars[index];
                  final avatarId = avatar['id']!;
                  final isSelected = selectedAvatar == avatarId;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAvatar = avatarId;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected 
                              ? theme.colorScheme.primary 
                              : theme.colorScheme.outline,
                          width: isSelected ? 3 : 1,
                        ),
                        color: theme.colorScheme.surface,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: (avatar['color'] as Color).withOpacity(0.1),
                        ),
                        child: Icon(
                          avatar['icon'] as IconData,
                          size: 40,
                          color: avatar['color'] as Color,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedAvatar != null
                    ? () => Navigator.pop(context, selectedAvatar)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Select Avatar',
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