import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../app_colors.dart';
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
  final _locationController = TextEditingController();
  final _petNameController = TextEditingController();
  final _petTypeController = TextEditingController();
  final _petGenderController = TextEditingController();
  final _petAgeController = TextEditingController();
  final _petWeightController = TextEditingController();

  // State
  File? _selectedProfileImage, _selectedPetImage;
  bool _isLoading = false;
  bool _hasPet = false;

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

  String? _validateLocation(String? value) {
    if (value == null || value.trim().isEmpty) return 'Location is required';
    if (value.trim().length < 3)
      return 'Location must be at least 3 characters';
    if (value.trim().length > 100)
      return 'Location must be less than 100 characters';
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
      _showSnackBar(
        'Failed to pick image: $e',
        AppColors.getErrorColor(context),
      );
    }
  }

  Future<String?> _convertImageToBase64(File image) async {
    try {
      final bytes = await image.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      _showSnackBar(
        'Failed to process image: $e',
        AppColors.getErrorColor(context),
      );
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

      // Convert profile image
      String? profileImageBase64;
      if (_selectedProfileImage != null) {
        profileImageBase64 = await _convertImageToBase64(
          _selectedProfileImage!,
        );
      }

      // Save user profile
      await _firestore.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'profileImage': profileImageBase64,
        'role': 'Customer',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Save pet if exists
      if (_hasPet) {
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
      }

      _showSnackBar('Profile created successfully!', Colors.green);
      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      _showSnackBar(
        'Failed to save profile: $e',
        AppColors.getErrorColor(context),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Complete Your Profile',
          style: TextStyle(
            color: AppColors.getTextColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.getBackgroundColor(context),
        elevation: 0,
        foregroundColor: AppColors.getTextColor(context),
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
                      color: AppColors.getSurfaceColor(context),
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(
                        color: AppColors.getPrimaryColor(context),
                        width: 3,
                      ),
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
                            : Icon(
                              Icons.person,
                              size: 50,
                              color: AppColors.getSecondaryTextColor(context),
                            ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tap to add photo',
                  style: TextStyle(
                    color: AppColors.getSecondaryTextColor(context),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Profile Information
              Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(context),
                ),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                hintText: 'Full Name',
                controller: _nameController,
                prefixIcon: Icons.person,
                keyboardType: TextInputType.name,
                validator: _validateName,
                customFillColor: AppColors.fieldColor,
              ),
              CustomTextField(
                hintText: 'Phone Number',
                controller: _phoneController,
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                validator: _validatePhone,
                customFillColor: AppColors.fieldColor,
              ),
              CustomTextField(
                hintText: 'Location',
                controller: _locationController,
                prefixIcon: Icons.location_on,
                validator: _validateLocation,
                customFillColor: AppColors.fieldColor,
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
                      color: AppColors.getTextColor(context),
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
                    activeColor: AppColors.gold,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Do you have a pet?',
                style: TextStyle(
                  color: AppColors.getSecondaryTextColor(context),
                  fontSize: 14,
                ),
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
                              color: AppColors.getSurfaceColor(context),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: AppColors.getPrimaryColor(context),
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
                                      color: AppColors.getSecondaryTextColor(
                                        context,
                                      ),
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
                        customFillColor: AppColors.fieldColor,
                      ),
                      CustomTextField(
                        hintText: 'Pet Type (Dog, Cat, etc.)',
                        controller: _petTypeController,
                        prefixIcon: Icons.category,
                        validator: _validatePetType,
                        customFillColor: AppColors.fieldColor,
                      ),
                      CustomTextField(
                        hintText: 'Gender (Male/Female/Unknown)',
                        controller: _petGenderController,
                        prefixIcon: Icons.male,
                        validator: _validatePetGender,
                        customFillColor: AppColors.fieldColor,
                      ),
                      CustomTextField(
                        hintText: 'Age (years)',
                        controller: _petAgeController,
                        keyboardType: TextInputType.number,
                        maxLength: 2,
                        prefixIcon: Icons.cake,
                        validator: _validatePetAge,
                        customFillColor: AppColors.fieldColor,
                      ),
                      CustomTextField(
                        hintText: 'Weight (kg)',
                        controller: _petWeightController,
                        prefixIcon: Icons.monitor_weight,
                        validator: _validatePetWeight,
                        customFillColor: AppColors.fieldColor,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // Save Button
              CustomButton(
                text: _isLoading ? 'Saving...' : 'Complete Profile',
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
