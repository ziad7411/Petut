import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../app_colors.dart'; // Keep this if you have custom colors not in the theme
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // Profile Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  // Pet Controllers
  final _petNameController = TextEditingController();
  final _petTypeController = TextEditingController();
  final _petGenderController = TextEditingController();
  final _petAgeController = TextEditingController();
  final _petWeightController = TextEditingController();

  String? _profileImageBase64;
  String? _petImageBase64;
  File? _selectedProfileImage;
  File? _selectedPetImage;
  bool _isLoading = false;
  List<Map<String, dynamic>> _pets = [];

  // Variables to store original data for comparison
  String _originalName = '';
  String _originalPhone = '';
  String _originalLocation = '';
  String? _originalProfileImage;

  bool get _isUserAuthenticated => _auth.currentUser != null;

  @override
  void initState() {
    super.initState();
    if (_isUserAuthenticated) {
      _loadUserProfile();
      _loadUserPets();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _locationController.text = data['location'] ?? '';
            _profileImageBase64 = data['profileImage'];

            // Store original data for comparison
            _originalName = data['name'] ?? '';
            _originalPhone = data['phone'] ?? '';
            _originalLocation = data['location'] ?? '';
            _originalProfileImage = data['profileImage'];
          });
        }
      }
    } catch (e) {
      _showSnackBar('Failed to load profile: $e', Theme.of(context).colorScheme.error);
    }
  }

  Future<void> _loadUserPets() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final querySnapshot =
            await _firestore
                .collection('pets')
                .where('ownerId', isEqualTo: user.uid)
                .get();

        setState(() {
          _pets =
              querySnapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList();
        });
      }
    } catch (e) {
      _showSnackBar('Failed to load pets: $e', Theme.of(context).colorScheme.error);
    }
  }

  Future<void> _pickImage({required bool isProfile}) async {
    if (!_isUserAuthenticated) {
      _showLoginPrompt();
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          if (isProfile) {
            _selectedProfileImage = File(image.path);
          } else {
            _selectedPetImage = File(image.path);
          }
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e', Theme.of(context).colorScheme.error);
    }
  }

  Future<String?> _convertImageToBase64(File image) async {
    try {
      final bytes = await image.readAsBytes();
      if (bytes.length > 500000) {
        print(
          'Warning: Image size is ${bytes.length} bytes, consider compressing',
        );
      }
      return base64Encode(bytes);
    } catch (e) {
      _showSnackBar('Failed to process image: $e', Theme.of(context).colorScheme.error);
      return null;
    }
  }

  Widget _buildImageFromBase64(
    String base64String, {
    required double size,
    required double borderRadius,
  }) {
    try {
      final bytes = base64Decode(base64String);
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: size,
          height: size,
        ),
      );
    } catch (e) {
      return Icon(Icons.error, size: size * 0.4, color: Theme.of(context).colorScheme.secondary);
    }
  }

  // Check if any data has changed
  bool _hasDataChanged() {
    final currentName = _nameController.text.trim();
    final currentPhone = _phoneController.text.trim();
    final currentLocation = _locationController.text.trim();

    // Check if text fields changed
    if (currentName != _originalName ||
        currentPhone != _originalPhone ||
        currentLocation != _originalLocation) {
      return true;
    }

    // Check if profile image was selected
    if (_selectedProfileImage != null) {
      return true;
    }

    return false;
  }

  Future<void> _updateProfile() async {
    if (!_isUserAuthenticated) {
      _showLoginPrompt();
      return;
    }

    // Check if any data has changed
    if (!_hasDataChanged()) {
      _showSnackBar('No changes detected to update', Theme.of(context).colorScheme.secondary);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      String? imageBase64 = _profileImageBase64;
      if (_selectedProfileImage != null) {
        imageBase64 = await _convertImageToBase64(_selectedProfileImage!);
      }

      await _firestore.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'profileImage': imageBase64,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _profileImageBase64 = imageBase64;
        _selectedProfileImage = null;

        // Update original data after successful save
        _originalName = _nameController.text.trim();
        _originalPhone = _phoneController.text.trim();
        _originalLocation = _locationController.text.trim();
        _originalProfileImage = imageBase64;
      });

      _showSnackBar('Profile updated successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to update profile: $e', Theme.of(context).colorScheme.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addPet() async {
    if (!_isUserAuthenticated) {
      _showLoginPrompt();
      return;
    }

    if (_petNameController.text.trim().isEmpty ||
        _petTypeController.text.trim().isEmpty) {
      _showSnackBar('Please fill in pet name and type', Theme.of(context).colorScheme.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      String? petImageBase64;
      if (_selectedPetImage != null) {
        petImageBase64 = await _convertImageToBase64(_selectedPetImage!);
      }

      await _firestore.collection('pets').add({
        'ownerId': user.uid,
        'name': _petNameController.text.trim(),
        'type': _petTypeController.text.trim(),
        'gender': _petGenderController.text.trim(),
        'age': _petAgeController.text.trim(),
        'weight': _petWeightController.text.trim(),
        'picture': petImageBase64,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clear form
      _petNameController.clear();
      _petTypeController.clear();
      _petGenderController.clear();
      _petAgeController.clear();
      _petWeightController.clear();
      setState(() => _selectedPetImage = null);

      await _loadUserPets();
      Navigator.of(context).pop();
      _showSnackBar('Pet added successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to add pet: $e', Theme.of(context).colorScheme.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePet(String petId, String petName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Delete Pet',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge!.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to delete $petName? This action cannot be undone.',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                ),
              ),
              CustomButton(
                text: 'Delete',
                onPressed: () => Navigator.of(context).pop(true),
                customColor: Theme.of(context).colorScheme.error,
                width: 80,
                height: 40,
                fontSize: 14,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('pets').doc(petId).delete();
        await _loadUserPets();
        _showSnackBar('Pet deleted successfully', Colors.green);
      } catch (e) {
        _showSnackBar('Failed to delete pet: $e', Theme.of(context).colorScheme.error);
      }
    }
  }

  void _showAddPetDialog() {
    if (!_isUserAuthenticated) {
      _showLoginPrompt();
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxHeight: 600),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add New Pet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Pet image picker
                    GestureDetector(
                      onTap: () => _pickImage(isProfile: false),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant, // Using surfaceVariant for field-like background
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                        ),
                        child:
                            _selectedPetImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: Image.file(
                                      _selectedPetImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(
                                    Icons.pets,
                                    size: 40,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      hintText: 'Pet Name',
                      controller: _petNameController,
                      prefixIcon: Icons.pets,
                    ),
                    CustomTextField(
                      hintText: 'Pet Type (Dog, Cat, etc.)',
                      controller: _petTypeController,
                      prefixIcon: Icons.category,
                    ),
                    CustomTextField(
                      hintText: 'Gender',
                      controller: _petGenderController,
                      prefixIcon: Icons.male,
                    ),
                    CustomTextField(
                      hintText: 'Age',
                      controller: _petAgeController,
                      prefixIcon: Icons.cake,
                    ),
                    CustomTextField(
                      hintText: 'Weight',
                      controller: _petWeightController,
                      prefixIcon: Icons.monitor_weight,
                    ),

                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Cancel',
                            onPressed: () => Navigator.of(context).pop(),
                            isPrimary: false,
                            customColor: Theme.of(context).colorScheme.surfaceVariant, // Consistent with field background
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            text: _isLoading ? 'Adding...' : 'Add Pet',
                            onPressed: _isLoading ? null : _addPet,
                            isPrimary: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Sign In Required',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge!.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'You need to Log in to access this feature. Would you like to sign in now?',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                ),
              ),
              CustomButton(
                text: 'Log in',
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/login');
                },
                isPrimary: true,
                width: 80,
                height: 40,
                fontSize: 14,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ],
          ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge!.color,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Login prompt for non-authenticated users
            if (!_isUserAuthenticated)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant, // Using surfaceVariant for general container background
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.login, size: 48, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Sign In to Access Your Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create an account or sign in to manage your profile and pets',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Log in',
                            onPressed:
                                () => Navigator.pushNamed(context, '/login'),
                            isPrimary: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: 'Sign Up',
                            onPressed:
                                () => Navigator.pushNamed(context, '/signup'),
                            isPrimary: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            if (_isUserAuthenticated) ...[
              // Profile Image
              Center(
                child: GestureDetector(
                  onTap: () => _pickImage(isProfile: true),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
                    ),
                    child:
                        _selectedProfileImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: Image.file(
                                  _selectedProfileImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _profileImageBase64 != null
                            ? _buildImageFromBase64(
                                _profileImageBase64!,
                                size: 120,
                                borderRadius: 60,
                              )
                            : Icon(
                                Icons.person,
                                size: 50,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to change photo',
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color, fontSize: 12),
              ),
              const SizedBox(height: 32),

              // Profile Form
              CustomTextField(
                hintText: 'Name',
                controller: _nameController,
                prefixIcon: Icons.person,
              ),
              CustomTextField(
                hintText: 'Phone Number',
                controller: _phoneController,
                prefixIcon: Icons.phone,
              ),
              CustomTextField(
                hintText: 'Location',
                controller: _locationController,
                prefixIcon: Icons.location_on,
              ),

              const SizedBox(height: 24),

              // Update Profile Button
              CustomButton(
                text: _isLoading ? 'Updating...' : 'Update Profile',
                onPressed: _isLoading ? null : _updateProfile,
                isPrimary: true,
                width: double.infinity,
              ),

              const SizedBox(height: 32),

              // Pets Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Pets',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                  CustomButton(
                    text: 'Add Pet',
                    onPressed: _showAddPetDialog,
                    isPrimary: true,
                    icon: Icon(Icons.add, size: 18, color: Theme.of(context).colorScheme.onPrimary),
                    width: 120,
                    height: 40,
                    fontSize: 14,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Pets List
              _pets.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.pets,
                            size: 64,
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No pets added yet',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pets.length,
                      itemBuilder: (context, index) {
                        final pet = _pets[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Pet Image
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child:
                                    pet['picture'] != null
                                        ? _buildImageFromBase64(
                                            pet['picture'],
                                            size: 60,
                                            borderRadius: 30,
                                          )
                                        : Icon(
                                            Icons.pets,
                                            color: Theme.of(context).colorScheme.secondary,
                                          ),
                              ),
                              const SizedBox(width: 16),

                              // Pet Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pet['name'] ?? 'Unknown',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).textTheme.bodyLarge!.color,
                                      ),
                                    ),
                                    Text(
                                      '${pet['type'] ?? ''} • ${pet['gender'] ?? ''} • ${pet['age'] ?? ''} • ${pet['weight'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).textTheme.bodyMedium!.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Delete Button
                              IconButton(
                                onPressed:
                                    () => _deletePet(
                                        pet['id'],
                                        pet['name'] ?? 'this pet',
                                      ),
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Theme.of(context).colorScheme.error,
                                  size: 22,
                                ),
                                tooltip: 'Delete Pet',
                                splashRadius: 20,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _petNameController.dispose();
    _petTypeController.dispose();
    _petGenderController.dispose();
    _petAgeController.dispose();
    _petWeightController.dispose();
    super.dispose();
  }
}