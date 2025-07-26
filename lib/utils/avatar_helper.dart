import 'package:flutter/material.dart';

class AvatarHelper {
  static final Map<String, Map<String, dynamic>> avatarData = {
    'doctor_blue': {'icon': Icons.medical_services, 'color': Colors.blue},
    'hospital_green': {'icon': Icons.local_hospital, 'color': Colors.green},
    'healing_red': {'icon': Icons.healing, 'color': Colors.red},
    'health_purple': {'icon': Icons.health_and_safety, 'color': Colors.purple},
    'person_orange': {'icon': Icons.person, 'color': Colors.orange},
    'face_teal': {'icon': Icons.face, 'color': Colors.teal},
    'account_indigo': {'icon': Icons.account_circle, 'color': Colors.indigo},
    'person_brown': {'icon': Icons.person_outline, 'color': Colors.brown},
    'emoji_amber': {'icon': Icons.emoji_emotions, 'color': Colors.amber},
    'happy_pink': {'icon': Icons.sentiment_very_satisfied, 'color': Colors.pink},
    'heart_red': {'icon': Icons.favorite, 'color': Colors.red},
    'star_yellow': {'icon': Icons.star, 'color': Colors.yellow},
    'pets_brown': {'icon': Icons.pets, 'color': Colors.brown},
    'paw_green': {'icon': Icons.cruelty_free, 'color': Colors.green},
    'eco_green': {'icon': Icons.eco, 'color': Colors.green},
    'flower_pink': {'icon': Icons.local_florist, 'color': Colors.pink},
    'android_green': {'icon': Icons.android, 'color': Colors.green},
    'computer_blue': {'icon': Icons.computer, 'color': Colors.blue},
    'soccer_black': {'icon': Icons.sports_soccer, 'color': Colors.black},
    'fitness_red': {'icon': Icons.fitness_center, 'color': Colors.red},
  };

  static Widget buildAvatar(String? avatarId, {double size = 60}) {
    if (avatarId != null && avatarData.containsKey(avatarId)) {
      final avatar = avatarData[avatarId]!;
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 2),
          color: (avatar['color'] as Color).withOpacity(0.1),
        ),
        child: Icon(
          avatar['icon'] as IconData,
          size: size * 0.6,
          color: avatar['color'] as Color,
        ),
      );
    }
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        color: Colors.grey.withOpacity(0.1),
      ),
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: Colors.grey,
      ),
    );
  }
}