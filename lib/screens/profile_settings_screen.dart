import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  bool _showPhone = true;
  bool _showEmail = true;
  bool _showLocation = true;
  bool _showPets = true;
  bool _allowMessages = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final privacy = data['privacy'] as Map<String, dynamic>? ?? {};
        
        setState(() {
          _showPhone = privacy['showPhone'] ?? true;
          _showEmail = privacy['showEmail'] ?? true;
          _showLocation = privacy['showLocation'] ?? true;
          _showPets = privacy['showPets'] ?? true;
          _allowMessages = privacy['allowMessages'] ?? true;
        });
      }
    } catch (e) {
      _showSnackBar('Failed to load settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'privacy': {
          'showPhone': _showPhone,
          'showEmail': _showEmail,
          'showLocation': _showLocation,
          'showPets': _showPets,
          'allowMessages': _allowMessages,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSnackBar('Settings saved successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to save settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveSettings,
            child: Text(
              _isLoading ? 'Saving...' : 'Save',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Control what others can see on your profile',
              style: TextStyle(
                fontSize: 16,
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSettingTile(
              'Show Phone Number',
              'Allow others to see your phone number',
              Icons.phone,
              _showPhone,
              (value) => setState(() => _showPhone = value),
            ),
            
            _buildSettingTile(
              'Show Email',
              'Allow others to see your email address',
              Icons.email,
              _showEmail,
              (value) => setState(() => _showEmail = value),
            ),
            
            _buildSettingTile(
              'Show Location',
              'Display your location on your profile',
              Icons.location_on,
              _showLocation,
              (value) => setState(() => _showLocation = value),
            ),
            
            _buildSettingTile(
              'Show Pets',
              'Display your pets information',
              Icons.pets,
              _showPets,
              (value) => setState(() => _showPets = value),
            ),
            
            _buildSettingTile(
              'Allow Messages',
              'Let others start conversations with you',
              Icons.chat,
              _allowMessages,
              (value) => setState(() => _allowMessages = value),
            ),
            
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'These settings control your profile visibility. You can change them anytime.',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: theme.hintColor,
            fontSize: 13,
          ),
        ),
        secondary: Icon(
          icon,
          color: theme.colorScheme.primary,
        ),
        value: value,
        onChanged: onChanged,
        activeColor: theme.colorScheme.primary,
      ),
    );
  }
}