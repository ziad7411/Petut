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

class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({super.key});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _picker = ImagePicker();

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _petNameController = TextEditingController();
  final _petTypeController = TextEditingController();
  final _petGenderController = TextEditingController();
  final _petAgeController = TextEditingController();
  final _petWeightController = TextEditingController();
  String? profileImageBase64;
   String? _selectedGender;

  // State
  File? _selectedProfileImage, _selectedPetImage;
  String? _selectedAvatar;
  bool _isLoading = false;
  bool _hasPet = false;
   final List<String> _genders = ['male', 'female'];

  // Form keys
  final _formKey = GlobalKey<FormState>();
  final _petFormKey = GlobalKey<FormState>();

  // Validation methods
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    if (value.trim().length > 50) return 'Name must be less than 50 characters';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim()))
      return 'Name can only contain letters and spaces';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'Phone number is required';

    // Remove all non-digit characters
    final digitsOnly = value.trim().replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length != 11) {
      return 'Phone number must be exactly 11 digits';
    }

    if (!digitsOnly.startsWith('01')) {
      return 'Phone number must start with 01';
    }

    return null;
  }


  String? _validatePetName(String? value) {
    if (!_hasPet) return null;
    if (value == null || value.trim().isEmpty) return 'Pet name is required';
    if (value.trim().length < 2)
      return 'Pet name must be at least 2 characters';
    if (value.trim().length > 30)
      return 'Pet name must be less than 30 characters';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim()))
      return 'Pet name can only contain letters and spaces';
    return null;
  }

  String? _validatePetType(String? value) {
    if (!_hasPet) return null;
    if (value == null || value.trim().isEmpty) return 'Pet type is required';
    if (value.trim().length < 2)
      return 'Pet type must be at least 2 characters';
    if (value.trim().length > 20)
      return 'Pet type must be less than 20 characters';
    return null;
  }

  String? _validatePetGender(String? value) {
    if (!_hasPet) return null;
    if (value == null || value.trim().isEmpty) return 'Gender is required';
    final gender = value.trim().toLowerCase();
    if (gender != 'male' && gender != 'female' && gender != 'unknown') {
      return 'Please enter: Male, Female, or Unknown';
    }
    return null;
  }

  String? _validatePetAge(String? value) {
    if (!_hasPet) return null;
    if (value == null || value.trim().isEmpty) return 'Age is required';
    if (!RegExp(r'^\d+$').hasMatch(value.trim())) return 'Age must be a number';
    final age = int.tryParse(value.trim());
    if (age == null || age < 0 || age > 50)
      return 'Age must be between 0 and 50';
    return null;
  }

  String? _validatePetWeight(String? value) {
    if (!_hasPet) return null;
    if (value == null || value.trim().isEmpty) return 'Weight is required';
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(value.trim()))
      return 'Weight must be a valid number';
    final weight = double.tryParse(value.trim());
    if (weight == null || weight < 0 || weight > 200)
      return 'Weight must be between 0 and 200 kg';
    return null;
  }

  Future<void> _pickImage({required bool isProfile}) async {
    if (isProfile) {
      // Show options: Avatar or Camera
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choose Profile Picture'),
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
          final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
          if (image != null) {
            setState(() {
              _selectedProfileImage = File(image.path);
              _selectedAvatar = null;
            });
          }
        } catch (e) {
          _showSnackBar(
            'Failed to pick image: $e',
            Theme.of(context).colorScheme.error,
          );
        }
      } else if (choice == 'camera') {
        try {
          final XFile? image = await _picker.pickImage(source: ImageSource.camera);
          if (image != null) {
            setState(() {
              _selectedProfileImage = File(image.path);
              _selectedAvatar = null;
            });
          }
        } catch (e) {
          _showSnackBar(
            'Failed to pick image: $e',
            Theme.of(context).colorScheme.error,
          );
        }
      }
    } else {
      try {
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          setState(() {
            _selectedPetImage = File(image.path);
          });
        }
      } catch (e) {
        _showSnackBar(
          'Failed to pick image: $e',
          Theme.of(context).colorScheme.error,
        );
      }
    }
  }

Future<void> loaduser() async {

    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (mounted && doc.exists) {
      final data = doc.data();
      setState(() {
        _nameController.text = data?['fullName'] ?? 'Guest';
        profileImageBase64 = data?['profileImage'];
         _phoneController.text = data?['phone'] ?? '';
      });
    }
}
Future<String?> uploadImageToImgbb(File? imageFile) async {
  if (imageFile == null) return null;

  const String apiKey = '2929b00fa2ded7b1a8c258df46705a60';

  try {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

    final response = await http.post(url, body: {
      'image': base64Image,
    });

    print("📤 Response: ${response.body}");

    if (response.statusCode == 200) {
  final data = json.decode(response.body);
  print("✅ Upload success: ${data['data']['url']}");
  return data['data']['url'];
} else {
  print('❌ Upload failed: code=${response.statusCode}, body=${response.body}');
  return null;
}

  } catch (e) {
    print('❌ Error uploading image: $e');
    return null;
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

  Future<void> _saveCustomerData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_hasPet && !_petFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Convert profile image or use avatar
      
     // ✅ Convert profile image or use avatar
String? profileImageBase64;
if (_selectedAvatar != null) {
  profileImageBase64 = _selectedAvatar; // Store avatar path
} else if (_selectedProfileImage != null) {
  profileImageBase64 = await uploadImageToImgbb(_selectedProfileImage!);

  // 🟢 Retry مرة تانية لو أول مرة فشلت
  if (profileImageBase64 == null) {
    print("⚠️ First upload failed, retrying...");
    profileImageBase64 = await uploadImageToImgbb(_selectedProfileImage!);
  }
}



      // Save user profile
      await _firestore.collection('users').doc(user.uid).set({
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profileImage': profileImageBase64,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'gender': _selectedGender,
      }, SetOptions(merge: true));

      // Save pet if exists
      if (_hasPet) {
        String? petImageBase64;
        if (_selectedPetImage != null) {
          petImageBase64 = await uploadImageToImgbb(_selectedPetImage!);
        }

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('pets')
            .add({
              'ownerId': user.uid,
              'name': _petNameController.text.trim(),
              'type': _petTypeController.text.trim(),
              'gender': _petGenderController.text.trim(),
              'age': int.tryParse(_petAgeController.text.trim()),
              'weight': double.tryParse(_petWeightController.text.trim()),
              'picture': petImageBase64,
              'createdAt': FieldValue.serverTimestamp(),
            });
      }

      _showSnackBar('Profile created successfully!', Colors.green);
      if (mounted) Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      _showSnackBar(
        'Failed to save profile: $e',
        Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
  }

  Widget _buildTextAvatar(String userName, double size, ThemeData theme) {
    final initials = userName.isNotEmpty 
        ? userName.trim().split(' ').map((name) => name.isNotEmpty ? name[0].toUpperCase() : '').take(2).join()
        : 'U';
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        color: theme.colorScheme.primary,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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
        title: Text(
          'Complete Your Profile',
          style: TextStyle(
            color: theme.appBarTheme.foregroundColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image
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
                        color: theme.colorScheme.primary,
                        width: 3,
                      ),
                    ),
                    child: _selectedAvatar != null
                        ? AvatarHelper.buildAvatar(_selectedAvatar, size: 120)
                        : _selectedProfileImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: Image.file(
                                  _selectedProfileImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _buildTextAvatar(_nameController.text, 120, theme),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tap to add photo',
                  style: TextStyle(color: theme.hintColor, fontSize: 12),
                ),
              ),
              const SizedBox(height: 32),

              // Profile Information
              Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                hintText: 'Full Name',
                controller: _nameController,
                prefixIcon: Icons.person,
                keyboardType: TextInputType.name,
                validator: _validateName,
              ),
              CustomTextField(
                hintText: 'Phone Number',
                controller: _phoneController,
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                validator: _validatePhone,
              ),
               DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: theme.hintColor,
                    ),
                  ),
                  hint: Text(
                    'Select Gender',
                    style: TextStyle(color: theme.hintColor),
                  ),
                  items:
                      _genders
                          .map(
                            (gender) => DropdownMenuItem(
                              value: gender,
                              child: Text(gender),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _selectedGender = value),
                  validator:
                      (value) =>
                          value == null ? 'Please select your gender' : null,
                ),

              const SizedBox(height: 32),

              // Pet Section
              Row(
                children: [
                  Text(
                    'Pet Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Switch(
                    value: _hasPet,
                    onChanged: (value) {
                      setState(() {
                        _hasPet = value;
                        if (!value) {
                          _clearPetForm();
                        }
                      });
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Do you have a pet?',
                style: TextStyle(color: theme.hintColor, fontSize: 14),
              ),

              if (_hasPet) ...[
                const SizedBox(height: 16),
                Form(
                  key: _petFormKey,
                  child: Column(
                    children: [
                      // Pet Image
                      Center(
                        child: GestureDetector(
                          onTap: () => _pickImage(isProfile: false),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
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
                                      color: theme.hintColor,
                                    ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        hintText: 'Pet Name',
                        controller: _petNameController,
                        prefixIcon: Icons.pets,
                        validator: _validatePetName,
                      ),
                      CustomTextField(
                        hintText: 'Pet Type (Dog, Cat, etc.)',
                        controller: _petTypeController,
                        prefixIcon: Icons.category,
                        validator: _validatePetType,
                      ),
                      CustomTextField(
                        hintText: 'Gender (Male/Female/Unknown)',
                        controller: _petGenderController,
                        prefixIcon: Icons.male,
                        validator: _validatePetGender,
                      ),
                      CustomTextField(
                        hintText: 'Age (years)',
                        controller: _petAgeController,
                        keyboardType: TextInputType.number,
                        maxLength: 2,
                        prefixIcon: Icons.cake,
                        validator: _validatePetAge,
                      ),
                      CustomTextField(
                        hintText: 'Weight (kg)',
                        controller: _petWeightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        prefixIcon: Icons.monitor_weight,
                        validator: _validatePetWeight,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // Save Button
              CustomButton(
                text: _isLoading ? 'Saving..' : 'Complete Profile',
                onPressed: _isLoading ? null : _saveCustomerData,
                isPrimary: true,
                width: double.infinity,
                fontSize: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
