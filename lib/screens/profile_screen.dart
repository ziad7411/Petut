import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'avatar_selection_screen.dart';
import '../utils/avatar_helper.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'profile_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _picker = ImagePicker();

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _petNameController = TextEditingController();
  final _petTypeController = TextEditingController();
  final _petGenderController = TextEditingController();
  final _petAgeController = TextEditingController();
  final _petWeightController = TextEditingController();

  // State
  String? _profileImageBase64;
  String? _selectedAvatar;
  File? _selectedProfileImage, _selectedPetImage;
  bool _isLoading = false;
  List<Map<String, dynamic>> _pets = [];
  String _originalName = '', _originalPhone = '', _originalLocation = '';
  String? _originalProfileImage;
  bool _isDoctor = false;
  bool _isEditingName = false;

  // Form keys
  final _profileFormKey = GlobalKey<FormState>();
  final _petFormKey = GlobalKey<FormState>();

  bool get _isUserAuthenticated => _auth.currentUser != null;

  @override
  void initState() {
    super.initState();
    if (_isUserAuthenticated) _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Load profile
      final profileDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (profileDoc.exists) {
        final data = profileDoc.data()!;
        if (mounted) {
          setState(() {
            _nameController.text = data['fullName'] ?? data['name'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _locationController.text = data['location'] ?? '';
            _profileImageBase64 = data['profileImage'];
            _originalName = data['fullName'] ?? data['name'] ?? '';
            _originalPhone = data['phone'] ?? '';
            _originalLocation = data['location'] ?? '';
            _originalProfileImage = data['profileImage'];
            _isDoctor = data['role'] == 'doctor';
          });
        }
      }

      // Load pets
      final petsSnapshot = await _firestore
          .collection('pets')
          .where('ownerId', isEqualTo: user.uid)
          .get();
      if (mounted) {
        setState(() {
          _pets = petsSnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
      }
    } catch (e) {
      _showSnackBar(
        'Failed to load data: $e',
        Theme.of(context).colorScheme.error,
      );
    }
  }

  Future<void> _pickImage({required bool isProfile}) async {
    if (!_isUserAuthenticated) {
      _showLoginPrompt();
      return;
    }

    if (isProfile) {
      // Show options for profile image
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Change Profile Picture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.face),
                title: const Text('Choose Avatar'),
                onTap: () => Navigator.pop(context, 'avatar'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Upload from Gallery'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              if (_profileImageBase64 != null ||
                  _selectedAvatar != null ||
                  _selectedProfileImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Picture',
                      style: TextStyle(color: Colors.red)),
                  onTap: () => Navigator.pop(context, 'delete'),
                ),
            ],
          ),
        ),
      );

      if (choice == 'avatar') {
        final selectedAvatar = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (_) => const AvatarSelectionScreen(),
          ),
        );
        if (selectedAvatar != null) {
          setState(() {
            _selectedAvatar = selectedAvatar;
            _selectedProfileImage = null;
          });
        }
      } else if (choice == 'gallery') {
        try {
          final XFile? image =
              await _picker.pickImage(source: ImageSource.gallery);
          if (image != null) {
            setState(() {
              _selectedProfileImage = File(image.path);
              _selectedAvatar = null;
            });
          }
        } catch (e) {
          _showSnackBar(
              'Failed to pick image: $e', Theme.of(context).colorScheme.error);
        }
      } else if (choice == 'camera') {
        try {
          final XFile? image =
              await _picker.pickImage(source: ImageSource.camera);
          if (image != null) {
            setState(() {
              _selectedProfileImage = File(image.path);
              _selectedAvatar = null;
            });
          }
        } catch (e) {
          _showSnackBar(
              'Failed to pick image: $e', Theme.of(context).colorScheme.error);
        }
      } else if (choice == 'delete') {
        setState(() {
          _selectedProfileImage = null;
          _selectedAvatar = null;
          _profileImageBase64 = null;
        });
      }
    } else {
      // Pet image picker (unchanged)
      try {
        final XFile? image =
            await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          setState(() {
            _selectedPetImage = File(image.path);
          });
        }
      } catch (e) {
        _showSnackBar(
            'Failed to pick image: $e', Theme.of(context).colorScheme.error);
      }
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      const String apiKey = '2929b00fa2ded7b1a8c258df46705a60';

      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

      final response = await http.post(url, body: {
        'image': base64Image,
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['url']; // 🔥 رابط مباشر من imgbb
      } else {
        _showSnackBar(
          'Upload failed: ${response.body}',
          Theme.of(context).colorScheme.error,
        );
        return null;
      }
    } catch (e) {
      _showSnackBar(
        'Failed to upload image: $e',
        Theme.of(context).colorScheme.error,
      );
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
      return Icon(
        Icons.error,
        size: size * 0.4,
        color: Theme.of(context).colorScheme.secondary,
      );
    }
  }

  Widget _buildProfileAvatar(
      String? profileImage, String userName, double size) {
    if (profileImage != null && profileImage.isNotEmpty) {
      // Check if it's fluttermoji avatar
      if (profileImage == 'fluttermoji_avatar') {
        return AvatarHelper.buildAvatar(profileImage, size: size);
      }
      // Check if it's base64 image
      try {
        final bytes = base64Decode(profileImage);
        return ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: size,
            height: size,
          ),
        );
      } catch (e) {
        // Fallback to text avatar
        return _buildTextAvatar(userName, size);
      }
    }

    // Default text avatar
    return _buildTextAvatar(userName, size);
  }

  Widget _buildTextAvatar(String userName, double size) {
    final initials = userName.isNotEmpty
        ? userName
            .trim()
            .split(' ')
            .map((name) => name.isNotEmpty ? name[0].toUpperCase() : '')
            .take(2)
            .join()
        : 'U';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        color: Theme.of(context).colorScheme.primary,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Validation methods
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    if (value.trim().length > 50) return 'Name must be less than 50 characters';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digitsOnly = value.trim().replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length != 11) {
      return 'Phone number must be exactly 11 digits';
    }
    if (!digitsOnly.startsWith('01')) {
      return 'Phone number must start with 01';
    }
    return null;
  }

  String? _validateLocation(String? value) {
    if (value == null || value.trim().isEmpty) return 'Location is required';
    if (value.trim().length < 3)
      return 'Location must be at least 3 characters';
    if (value.trim().length > 100)
      return 'Location must be less than 100 characters';
    return null;
  }

  String? _validatePetName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Pet name is required';
    return null;
  }

  String? _validatePetType(String? value) {
    if (value == null || value.trim().isEmpty) return 'Pet type is required';
    return null;
  }

  String? _validatePetGender(String? value) {
    if (value == null || value.trim().isEmpty) return 'Gender is required';
    final gender = value.trim().toLowerCase();
    if (gender != 'male' && gender != 'female' && gender != 'unknown') {
      return 'Please enter: Male, Female, or Unknown';
    }
    return null;
  }

  String? _validatePetAge(String? value) {
    if (value == null || value.trim().isEmpty) return 'Age is required';
    if (!RegExp(r'^\d+$').hasMatch(value.trim())) return 'Age must be a number';
    final age = int.tryParse(value.trim());
    if (age == null || age < 0 || age > 50)
      return 'Age must be between 0 and 50';
    return null;
  }

  String? _validatePetWeight(String? value) {
    if (value == null || value.trim().isEmpty) return 'Weight is required';
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(value.trim()))
      return 'Weight must be a valid number';
    final weight = double.tryParse(value.trim());
    if (weight == null || weight < 0 || weight > 200)
      return 'Weight must be between 0 and 200 kg';
    return null;
  }

  bool _hasDataChanged() {
    final currentName = _nameController.text.trim();
    final currentPhone = _phoneController.text.trim();
    final currentLocation = _locationController.text.trim();

    return currentName != _originalName ||
        currentPhone != _originalPhone ||
        currentLocation != _originalLocation ||
        _selectedProfileImage != null ||
        _selectedAvatar != null;
  }

  Future<void> _updateName() async {
    if (!_isUserAuthenticated) return;

    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == _originalName) {
      setState(() => _isEditingName = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'fullName': newName,
        'name': newName,
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _originalName = newName;
        _isEditingName = false;
      });

      _showSnackBar('Name updated successfully!', Colors.green);
    } catch (e) {
      _showSnackBar(
          'Failed to update name: $e', Theme.of(context).colorScheme.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_isUserAuthenticated) {
      _showLoginPrompt();
      return;
    }
    if (!_profileFormKey.currentState!.validate()) {
      return;
    }
    if (!_hasDataChanged()) {
      _showSnackBar(
        'No changes detected to update',
        Theme.of(context).colorScheme.secondary,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      String? imageUrl = _profileImageBase64;

      if (_selectedAvatar != null) {
        imageUrl =
            _selectedAvatar; // 🔹 لو اختار Avatar بنخزن الـ ID أو الرابط بتاعه
      } else if (_selectedProfileImage != null) {
        imageUrl = await _uploadImage(
            _selectedProfileImage!); // 🔥 رفع على imgbb ورجوع URL
      }

      await _firestore.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'email': user.email,
        'profileImage': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _profileImageBase64 = imageUrl;
          _selectedProfileImage = null;
          _selectedAvatar = null;
          _originalName = _nameController.text.trim();
          _originalPhone = _phoneController.text.trim();
          _originalLocation = _locationController.text.trim();
          _originalProfileImage = imageUrl;
        });
      }

      _showSnackBar('Profile updated successfully!', Colors.green);
    } catch (e) {
      _showSnackBar(
        'Failed to update profile: $e',
        Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addPet() async {
    if (!_isUserAuthenticated) {
      _showLoginPrompt();
      return;
    }
    if (!_petFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

    String? petImageUrl;
if (_selectedPetImage != null) {
  petImageUrl = await _uploadImage(_selectedPetImage!); // 🔥 رفع الصورة على imgbb
}

      await _firestore.collection('pets').add({
        'ownerId': user.uid,
        'name': _petNameController.text.trim(),
        'type': _petTypeController.text.trim(),
        'gender': _petGenderController.text.trim(),
        'age': _petAgeController.text.trim(),
        'weight': _petWeightController.text.trim(),
        'picture': petImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _clearPetForm();
      await _loadUserData();
      if (mounted) Navigator.of(context).pop();
      _showSnackBar('Pet added successfully!', Colors.green);
    } catch (e) {
      _showSnackBar(
        'Failed to add pet: $e',
        Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearPetForm() {
    _petNameController.clear();
    _petTypeController.clear();
    _petGenderController.clear();
    _petAgeController.clear();
    _petWeightController.clear();
    setState(() => _selectedPetImage = null);
  }

  Future<void> _deletePet(String petId, String petName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Delete Pet',
              style: TextStyle(
                  color: theme.textTheme.bodyLarge!.color,
                  fontWeight: FontWeight.bold)),
          content: Text(
              'Are you sure you want to delete $petName? This action cannot be undone.',
              style: TextStyle(color: theme.textTheme.bodyMedium!.color)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel',
                  style: TextStyle(color: theme.textTheme.bodyMedium!.color)),
            ),
            CustomButton(
              text: 'Delete',
              onPressed: () => Navigator.of(context).pop(true),
              customColor: theme.colorScheme.error,
              width: 80,
              height: 40,
              fontSize: 14,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _firestore.collection('pets').doc(petId).delete();
        await _loadUserData();
        _showSnackBar('Pet deleted successfully', Colors.green);
      } catch (e) {
        _showSnackBar(
            'Failed to delete pet: $e', Theme.of(context).colorScheme.error);
      }
    }
  }

  void _showAddPetDialog() {
    if (!_isUserAuthenticated) {
      _showLoginPrompt();
      return;
    }
    _clearPetForm();

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxHeight: 600),
            child: SingleChildScrollView(
              child: Form(
                key: _petFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Add New Pet',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge!.color)),
                        IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.close,
                                color: theme.iconTheme.color)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => _pickImage(isProfile: false),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                              color: theme.colorScheme.primary, width: 2),
                        ),
                        child: _selectedPetImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.file(_selectedPetImage!,
                                    fit: BoxFit.cover))
                            : Icon(Icons.pets,
                                size: 40, color: theme.colorScheme.secondary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                        hintText: 'Pet Name',
                        controller: _petNameController,
                        prefixIcon: Icons.pets,
                        validator: _validatePetName),
                    CustomTextField(
                        hintText: 'Pet Type (Dog, Cat, etc.)',
                        controller: _petTypeController,
                        prefixIcon: Icons.category,
                        validator: _validatePetType),
                    CustomTextField(
                        hintText: 'Gender (Male/Female/Unknown)',
                        controller: _petGenderController,
                        prefixIcon: Icons.male,
                        validator: _validatePetGender),
                    CustomTextField(
                        hintText: 'Age (years)',
                        controller: _petAgeController,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.cake,
                        validator: _validatePetAge),
                    CustomTextField(
                        hintText: 'Weight (kg)',
                        controller: _petWeightController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        prefixIcon: Icons.monitor_weight,
                        validator: _validatePetWeight),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                            child: CustomButton(
                                text: 'Cancel',
                                onPressed: () => Navigator.of(context).pop(),
                                isPrimary: false)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: CustomButton(
                                text: _isLoading ? 'Adding...' : 'Add Pet',
                                onPressed: _isLoading ? null : _addPet,
                                isPrimary: true)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Sign In Required',
              style: TextStyle(
                  color: theme.textTheme.bodyLarge!.color,
                  fontWeight: FontWeight.bold)),
          content: Text(
              'You need to Log in to access this feature. Would you like to sign in now?',
              style: TextStyle(color: theme.textTheme.bodyMedium!.color)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel',
                  style: TextStyle(color: theme.textTheme.bodyMedium!.color)),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: color));
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Profile',
            style: TextStyle(color: theme.textTheme.bodyLarge!.color)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.textTheme.bodyLarge!.color,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: theme.iconTheme.color),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/main');
            }
          },
        ),
        actions: _isUserAuthenticated
            ? [
                IconButton(
                  icon: Icon(Icons.settings, color: theme.iconTheme.color),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProfileSettingsScreen()),
                  ),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (!_isUserAuthenticated)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.login,
                        size: 48, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text('Sign In to Access Your Profile',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge!.color)),
                    const SizedBox(height: 8),
                    Text(
                        'Create an account or sign in to manage your profile and pets',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: theme.textTheme.bodyMedium!.color,
                            fontSize: 14)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child: CustomButton(
                                text: 'Log in',
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/login'),
                                isPrimary: true)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: CustomButton(
                                text: 'Sign Up',
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/signup'),
                                isPrimary: false)),
                      ],
                    ),
                  ],
                ),
              ),
            if (_isUserAuthenticated) ...[
              Center(
                child: GestureDetector(
                  onTap: () => _pickImage(isProfile: true),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(
                          color: theme.colorScheme.primary, width: 3),
                    ),
                    child: _selectedProfileImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.file(_selectedProfileImage!,
                                fit: BoxFit.cover))
                        : _selectedAvatar != null
                            ? AvatarHelper.buildAvatar(_selectedAvatar,
                                size: 120)
                            : _buildProfileAvatar(
                                _profileImageBase64, _nameController.text, 120),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Tap to change photo',
                  style: TextStyle(
                      color: theme.textTheme.bodyMedium!.color, fontSize: 12)),
              const SizedBox(height: 32),
              // Name Section with Edit Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _isEditingName
                          ? TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: 'Enter your name',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: theme.hintColor),
                              ),
                              style: TextStyle(
                                  fontSize: 16,
                                  color: theme.textTheme.bodyLarge!.color),
                              onSubmitted: (_) => _updateName(),
                            )
                          : Text(
                              _nameController.text.isEmpty
                                  ? 'Add your name'
                                  : _nameController.text,
                              style: TextStyle(
                                fontSize: 16,
                                color: _nameController.text.isEmpty
                                    ? theme.hintColor
                                    : theme.textTheme.bodyLarge!.color,
                              ),
                            ),
                    ),
                    if (_isEditingName)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: _updateName,
                            icon: Icon(Icons.check,
                                color: Colors.green, size: 20),
                            tooltip: 'Save',
                          ),
                          IconButton(
                            onPressed: () {
                              _nameController.text = _originalName;
                              setState(() => _isEditingName = false);
                            },
                            icon:
                                Icon(Icons.close, color: Colors.red, size: 20),
                            tooltip: 'Cancel',
                          ),
                        ],
                      )
                    else
                      IconButton(
                        onPressed: () => setState(() => _isEditingName = true),
                        icon: Icon(Icons.edit,
                            color: theme.colorScheme.primary, size: 20),
                        tooltip: 'Edit name',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Form(
                key: _profileFormKey,
                child: Column(
                  children: [
                    CustomTextField(
                        hintText: 'Phone Number',
                        controller: _phoneController,
                        prefixIcon: Icons.phone,
                        validator: _validatePhone),
                    CustomTextField(
                        hintText: 'Location',
                        controller: _locationController,
                        prefixIcon: Icons.location_on,
                        validator: _validateLocation),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                  text: _isLoading ? 'Updating...' : 'Update Profile',
                  onPressed: _isLoading ? null : _updateProfile,
                  isPrimary: true,
                  width: double.infinity),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Pets',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge!.color)),
                  CustomButton(
                    text: 'Add Pet',
                    onPressed: _showAddPetDialog,
                    isPrimary: true,
                    icon: Icon(Icons.add,
                        size: 18, color: theme.colorScheme.onPrimary),
                    width: 120,
                    height: 40,
                    fontSize: 14,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _pets.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.pets,
                              size: 64,
                              color:
                                  theme.colorScheme.secondary.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text('No pets added yet',
                              style: TextStyle(
                                  color: theme.colorScheme.secondary
                                      .withOpacity(0.7),
                                  fontSize: 16)),
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
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                    color: theme.scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(30)),
                                child: pet['picture'] != null
                                    ? _buildImageFromBase64(pet['picture'],
                                        size: 60, borderRadius: 30)
                                    : Icon(Icons.pets,
                                        color: theme.colorScheme.secondary),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(pet['name'] ?? 'Unknown',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: theme
                                                .textTheme.bodyLarge!.color)),
                                    Text(
                                        '${pet['type'] ?? ''} • ${pet['gender'] ?? ''} • ${pet['age'] ?? ''} years • ${pet['weight'] ?? ''} kg',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: theme
                                                .textTheme.bodyMedium!.color)),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _deletePet(
                                    pet['id'], pet['name'] ?? 'this pet'),
                                icon: Icon(Icons.delete_outline,
                                    color: theme.colorScheme.error, size: 22),
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
}
