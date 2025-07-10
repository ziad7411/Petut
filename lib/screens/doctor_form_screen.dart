import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class DoctorFormScreen extends StatefulWidget {
  const DoctorFormScreen({super.key});

  @override
  State<DoctorFormScreen> createState() => _DoctorFormScreenState();
}

class _DoctorFormScreenState extends State<DoctorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doctorNameController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _clinicPhoneController = TextEditingController();
  final _phoneController = TextEditingController();
  final _experienceController = TextEditingController();
  final _workingHoursController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();
  final _linkedinController = TextEditingController();

  File? _cardFrontImage;
  File? _cardBackImage;
  File? _idImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        switch (type) {
          case 'cardFront':
            _cardFrontImage = File(image.path);
            break;
          case 'cardBack':
            _cardBackImage = File(image.path);
            break;
          case 'id':
            _idImage = File(image.path);
            break;
        }
      });
    }
  }

  Future<String?> _convertImageToBase64(File? image) async {
    if (image == null) return null;
    final bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _cardFrontImage == null ||
        _cardBackImage == null ||
        _idImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all required fields and upload all required images',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final cardFrontBase64 = await _convertImageToBase64(_cardFrontImage);
      final cardBackBase64 = await _convertImageToBase64(_cardBackImage);
      final idBase64 = await _convertImageToBase64(_idImage);

      // Prepare social media links
      final socialMedia = <String, String>{};
      if (_facebookController.text.trim().isNotEmpty) {
        socialMedia['facebook'] = _facebookController.text.trim();
      }
      if (_instagramController.text.trim().isNotEmpty) {
        socialMedia['instagram'] = _instagramController.text.trim();
      }
      if (_twitterController.text.trim().isNotEmpty) {
        socialMedia['twitter'] = _twitterController.text.trim();
      }
      if (_linkedinController.text.trim().isNotEmpty) {
        socialMedia['linkedin'] = _linkedinController.text.trim();
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'role': 'Doctor',
        'doctorName': _doctorNameController.text.trim(),
        'clinicName': _clinicNameController.text.trim(),
        'clinicAddress': _clinicAddressController.text.trim(),
        'clinicPhone': _clinicPhoneController.text.trim(),
        'phone': _phoneController.text.trim(),
        'experience': _experienceController.text.trim(),
        'workingHours': _workingHoursController.text.trim(),
        'description': _descriptionController.text.trim(),
        'socialMedia': socialMedia,
        'cardFrontImage': cardFrontBase64,
        'cardBackImage': cardBackBase64,
        'idImage': idBase64,
        'isVerified': false, // سيتم التحقق من قبل الإدارة
        'rating': 0.0,
        'totalReviews': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      Navigator.pushReplacementNamed(context, '/profile');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    _clinicPhoneController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _workingHoursController.dispose();
    _descriptionController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.gold,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text(
                  'Doctor Information',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please provide your professional information',
                  style: TextStyle(fontSize: 14, color: AppColors.gray),
                ),
                const SizedBox(height: 24),

                // Personal Information Section
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  hintText: 'Doctor Name',
                  controller: _doctorNameController,
                  prefixIcon: Icons.person,
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Enter your full name'
                              : null,
                ),

                CustomTextField(
                  hintText: 'Personal Phone Number',
                  controller: _phoneController,
                  prefixIcon: Icons.phone,
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Enter your phone number'
                              : null,
                ),

                const SizedBox(height: 24),

                // Professional Information Section
                const Text(
                  'Professional Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  hintText: 'Clinic Name',
                  controller: _clinicNameController,
                  prefixIcon: Icons.local_hospital,
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Enter clinic name'
                              : null,
                ),

                CustomTextField(
                  hintText: 'Clinic Phone Number',
                  controller: _clinicPhoneController,
                  prefixIcon: Icons.phone,
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Enter clinic phone number'
                              : null,
                ),

                CustomTextField(
                  hintText: 'Clinic Address',
                  controller: _clinicAddressController,
                  prefixIcon: Icons.location_on,
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Enter clinic address'
                              : null,
                ),

                CustomTextField(
                  hintText: 'Years of Experience',
                  controller: _experienceController,
                  prefixIcon: Icons.work,
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Enter years of experience'
                              : null,
                ),

                CustomTextField(
                  hintText: 'Working Hours (e.g., 9 AM - 6 PM)',
                  controller: _workingHoursController,
                  prefixIcon: Icons.access_time,
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Enter working hours'
                              : null,
                ),

                CustomTextField(
                  hintText: 'Professional Description',
                  controller: _descriptionController,
                  prefixIcon: Icons.description,
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Enter professional description'
                              : null,
                ),

                const SizedBox(height: 24),

                // Social Media Section
                const Text(
                  'Social Media Links (Optional)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add your social media profiles to help clients find you',
                  style: TextStyle(fontSize: 12, color: AppColors.gray),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  hintText: 'Facebook Profile URL',
                  controller: _facebookController,
                  prefixIcon: Icons.facebook,
                ),

                CustomTextField(
                  hintText: 'Instagram Profile URL',
                  controller: _instagramController,
                  prefixIcon: Icons.camera_alt,
                ),

                CustomTextField(
                  hintText: 'Twitter Profile URL',
                  controller: _twitterController,
                  prefixIcon: Icons.flutter_dash,
                ),

                CustomTextField(
                  hintText: 'LinkedIn Profile URL',
                  controller: _linkedinController,
                  prefixIcon: Icons.work,
                ),

                const SizedBox(height: 24),

                // Documents Section
                const Text(
                  'Required Documents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please upload your professional documents for verification',
                  style: TextStyle(fontSize: 12, color: AppColors.gray),
                ),
                const SizedBox(height: 16),

                // Medical License Card (Front)
                GestureDetector(
                  onTap: () => _pickImage('cardFront'),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.fieldColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                    child:
                        _cardFrontImage != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _cardFrontImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                            : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.upload_file,
                                    color: AppColors.gray,
                                    size: 32,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Upload Medical License (Front)',
                                    style: TextStyle(color: AppColors.gray),
                                  ),
                                ],
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 16),

                // Medical License Card (Back)
                GestureDetector(
                  onTap: () => _pickImage('cardBack'),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.fieldColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                    child:
                        _cardBackImage != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _cardBackImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                            : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.upload_file,
                                    color: AppColors.gray,
                                    size: 32,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Upload Medical License (Back)',
                                    style: TextStyle(color: AppColors.gray),
                                  ),
                                ],
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 16),

                // ID Card
                GestureDetector(
                  onTap: () => _pickImage('id'),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.fieldColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                    child:
                        _idImage != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(_idImage!, fit: BoxFit.cover),
                            )
                            : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.upload_file,
                                    color: AppColors.gray,
                                    size: 32,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Upload ID Card',
                                    style: TextStyle(color: AppColors.gray),
                                  ),
                                ],
                              ),
                            ),
                  ),
                ),

                const SizedBox(height: 24),

                // Note about verification
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.gold, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your information will be reviewed and verified within 24-48 hours. You will be notified once approved.',
                          style: TextStyle(fontSize: 12, color: AppColors.dark),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                      text: 'Submit Application',
                      onPressed: _submit,
                      width: double.infinity,
                      fontSize: 20,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
