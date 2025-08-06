import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../utils/avatar_helper.dart';
import '../services/simple_chat_service.dart';
import 'chat_screen.dart';

class ProfileViewScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userImage;

  const ProfileViewScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userImage,
  });

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> userPets = [];
  Map<String, dynamic> privacySettings = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Load user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (userDoc.exists) {
        userData = userDoc.data();
        privacySettings = userData?['privacy'] ?? {
          'showPhone': true,
          'showEmail': true,
          'showLocation': true,
          'showPets': true,
          'allowMessages': true,
        };
      }

      // Load user pets
      final petsSnapshot = await FirebaseFirestore.instance
          .collection('pets')
          .where('ownerId', isEqualTo: widget.userId)
          .get();
      
      userPets = petsSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _startChat() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      _showLoginDialog();
      return;
    }
    
    try {
      final chatId = await SimpleChatService.createOrGetChat(widget.userId);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chatId,
              otherUserId: widget.userId,
              otherUserName: widget.userName,
              otherUserImage: widget.userImage,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting chat: $e')),
      );
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In Required'),
        content: const Text('You need to sign in to start a chat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwnProfile = currentUserId == widget.userId;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.userName),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildUserAvatar(widget.userImage, widget.userName, 50),
                          const SizedBox(height: 16),
                          Text(
                            widget.userName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isOwnProfile && userData?['phone'] != null && privacySettings['showPhone'] == true) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.phone, size: 16, color: theme.hintColor),
                                const SizedBox(width: 4),
                                Text(
                                  userData!['phone'],
                                  style: TextStyle(
                                    color: theme.hintColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (!isOwnProfile && userData?['email'] != null && privacySettings['showEmail'] == true) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.email, size: 16, color: theme.hintColor),
                                const SizedBox(width: 4),
                                Text(
                                  userData!['email'],
                                  style: TextStyle(
                                    color: theme.hintColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (isOwnProfile && userData?['phone'] != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.phone, size: 16, color: theme.hintColor),
                                const SizedBox(width: 4),
                                Text(
                                  userData!['phone'],
                                  style: TextStyle(
                                    color: theme.hintColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (isOwnProfile && userData?['email'] != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.email, size: 16, color: theme.hintColor),
                                const SizedBox(width: 4),
                                Text(
                                  userData!['email'],
                                  style: TextStyle(
                                    color: theme.hintColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (userData?['location'] != null && privacySettings['showLocation'] == true) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_on, size: 16, color: theme.hintColor),
                                const SizedBox(width: 4),
                                Text(
                                  userData!['location'],
                                  style: TextStyle(
                                    color: theme.hintColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (!isOwnProfile && privacySettings['allowMessages'] == true)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _startChat,
                                icon: const Icon(Icons.chat),
                                label: const Text('Start Chat'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Pets Section
                  if (isOwnProfile || privacySettings['showPets'] == true) ...[
                    if (userPets.isNotEmpty) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pets (${userPets.length})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...userPets.map((pet) => _buildPetCard(pet, theme)),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.pets,
                                size: 48,
                                color: theme.hintColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No pets registered',
                                style: TextStyle(
                                  color: theme.hintColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ] else if (!isOwnProfile) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.pets_outlined,
                              size: 48,
                              color: theme.hintColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pet information is private',
                              style: TextStyle(
                                color: theme.hintColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                ],
              ),
            ),
    );
  }

  Widget _buildPetCard(Map<String, dynamic> pet, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          // Pet Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: theme.colorScheme.primary.withOpacity(0.1),
            ),
            child: pet['picture'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(pet['picture']),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.pets,
                          color: theme.colorScheme.primary,
                          size: 30,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.pets,
                    color: theme.colorScheme.primary,
                    size: 30,
                  ),
          ),
          const SizedBox(width: 12),
          // Pet Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pet['type'] ?? 'Unknown'} • ${pet['gender'] ?? 'Unknown'}',
                  style: TextStyle(
                    color: theme.hintColor,
                    fontSize: 14,
                  ),
                ),
                if (pet['age'] != null || pet['weight'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${pet['age'] != null ? '${pet['age']} years' : ''}'
                    '${pet['age'] != null && pet['weight'] != null ? ' • ' : ''}'
                    '${pet['weight'] != null ? '${pet['weight']} kg' : ''}',
                    style: TextStyle(
                      color: theme.hintColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(String? imageData, String? userName, double radius) {
    if (imageData != null && imageData.isNotEmpty) {
      if (imageData == 'fluttermoji_avatar') {
        return AvatarHelper.buildAvatar(imageData, size: radius * 2);
      }
      try {
        final imageBytes = base64Decode(imageData);
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(imageBytes),
        );
      } catch (e) {
        return _buildTextAvatar(userName ?? 'U', radius);
      }
    }
    return _buildTextAvatar(userName ?? 'U', radius);
  }

  Widget _buildTextAvatar(String userName, double radius) {
    final initials = userName.isNotEmpty 
        ? userName.trim().split(' ').map((name) => name.isNotEmpty ? name[0].toUpperCase() : '').take(2).join()
        : 'U';
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.6,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}