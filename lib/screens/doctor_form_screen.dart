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

  File? _profileImage;
  File? _cardFrontImage;
  File? _cardBackImage;
  File? _idImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        switch (type) {
          case 'profile':
            _profileImage = File(image.path);
            break;
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

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          isStartTime
              ? (_startTime ?? TimeOfDay(hour: 9, minute: 0))
              : (_endTime ?? TimeOfDay(hour: 18, minute: 0)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.gold,
              onPrimary: AppColors.background,
              surface: AppColors.background,
              onSurface: AppColors.dark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
        _updateWorkingHours();
      });
    }
  }

  void _updateWorkingHours() {
    if (_startTime != null && _endTime != null) {
      final startTimeStr = _startTime!.format(context);
      final endTimeStr = _endTime!.format(context);
      _workingHoursController.text = '$startTimeStr - $endTimeStr';
    }
  }

  Future<String?> _convertImageToBase64(File? image) async {
    if (image == null) return null;
    final bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> _submit() async {
    // التحقق من صحة النموذج
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields correctly'),
          backgroundColor: AppColors.getErrorColor(context),
        ),
      );
      return;
    }

    // التحقق من صورة البروفيل
    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload your profile photo'),
          backgroundColor: AppColors.getErrorColor(context),
        ),
      );
      return;
    }

    // التحقق من صورة رخصة الطبيب (الوجه الأمامي)
    if (_cardFrontImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload the front of your medical license'),
          backgroundColor: AppColors.getErrorColor(context),
        ),
      );
      return;
    }

    // التحقق من صورة رخصة الطبيب (الوجه الخلفي)
    if (_cardBackImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload the back of your medical license'),
          backgroundColor: AppColors.getErrorColor(context),
        ),
      );
      return;
    }

    // التحقق من صورة الهوية
    if (_idImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload your ID card'),
          backgroundColor: AppColors.getErrorColor(context),
        ),
      );
      return;
    }

    // التحقق من تحديد ساعات العمل
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select your working hours'),
          backgroundColor: AppColors.getErrorColor(context),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final profileBase64 = await _convertImageToBase64(_profileImage);
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
        'profileImage': profileBase64,
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
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.getErrorColor(context),
        ),
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
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.getBackgroundColor(context),
        elevation: 0,
        foregroundColor: AppColors.getTextColor(context),
        title: Text(
          'Doctor Registration',
          style: TextStyle(
            color: AppColors.getTextColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.getPrimaryColor(context),
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
                Text(
                  'Doctor Information',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please provide your professional information',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 24),

                // Profile Image
                Center(
                  child: GestureDetector(
                    onTap: () => _pickImage('profile'),
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
                          _profileImage != null
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: Image.file(
                                  _profileImage!,
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

                // Personal Information Section
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  hintText: 'Doctor Name',
                  controller: _doctorNameController,
                  prefixIcon: Icons.person,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your full name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    if (value.trim().length > 50) {
                      return 'Name must be less than 50 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
                      return 'Name can only contain letters and spaces';
                    }
                    return null;
                  },
                ),

                CustomTextField(
                  hintText: 'Personal Phone Number',
                  controller: _phoneController,
                  prefixIcon: Icons.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your phone number';
                    }
                    // Remove all non-digit characters
                    final digitsOnly = value.trim().replaceAll(
                      RegExp(r'[^\d]'),
                      '',
                    );
                    if (digitsOnly.length != 11) {
                      return 'Phone number must be exactly 11 digits';
                    }
                    if (!digitsOnly.startsWith('01')) {
                      return 'Phone number must start with 01';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Professional Information Section
                Text(
                  'Professional Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  hintText: 'Clinic Name',
                  controller: _clinicNameController,
                  prefixIcon: Icons.local_hospital,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter clinic name';
                    }
                    if (value.trim().length < 2) {
                      return 'Clinic name must be at least 2 characters';
                    }
                    if (value.trim().length > 100) {
                      return 'Clinic name must be less than 100 characters';
                    }
                    return null;
                  },
                ),

                CustomTextField(
                  hintText: 'Clinic Phone Number',
                  controller: _clinicPhoneController,
                  prefixIcon: Icons.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter clinic phone number';
                    }
                    // Remove all non-digit characters
                    final digitsOnly = value.trim().replaceAll(
                      RegExp(r'[^\d]'),
                      '',
                    );
                    if (digitsOnly.length != 11) {
                      return 'Phone number must be exactly 11 digits';
                    }
                    if (!digitsOnly.startsWith('01')) {
                      return 'Phone number must start with 01';
                    }
                    return null;
                  },
                ),

                CustomTextField(
                  hintText: 'Clinic Address',
                  controller: _clinicAddressController,
                  prefixIcon: Icons.location_on,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter clinic address';
                    }
                    if (value.trim().length < 5) {
                      return 'Address must be at least 5 characters';
                    }
                    if (value.trim().length > 200) {
                      return 'Address must be less than 200 characters';
                    }
                    return null;
                  },
                ),

                CustomTextField(
                  hintText: 'Years of Experience',
                  controller: _experienceController,
                  prefixIcon: Icons.work,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter years of experience';
                    }
                    if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
                      return 'Experience must be a number';
                    }
                    final experience = int.tryParse(value.trim());
                    if (experience == null ||
                        experience < 0 ||
                        experience > 50) {
                      return 'Experience must be between 0 and 50 years';
                    }
                    return null;
                  },
                ),

                // Working Hours with Time Picker
                Text(
                  'Working Hours',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectTime(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.getSurfaceColor(context),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: AppColors.getSecondaryTextColor(context),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _startTime?.format(context) ?? 'Start Time',
                                style: TextStyle(
                                  color:
                                      _startTime != null
                                          ? AppColors.getTextColor(context)
                                          : AppColors.getSecondaryTextColor(
                                            context,
                                          ),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectTime(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.getSurfaceColor(context),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: AppColors.getSecondaryTextColor(context),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _endTime?.format(context) ?? 'End Time',
                                style: TextStyle(
                                  color:
                                      _endTime != null
                                          ? AppColors.getTextColor(context)
                                          : AppColors.getSecondaryTextColor(
                                            context,
                                          ),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  hintText: 'Professional Description',
                  controller: _descriptionController,
                  prefixIcon: Icons.description,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter professional description';
                    }
                    if (value.trim().length < 10) {
                      return 'Description must be at least 10 characters';
                    }
                    if (value.trim().length > 500) {
                      return 'Description must be less than 500 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Social Media Section
                Text(
                  'Social Media Links (Optional)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your social media profiles to help clients find you',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getSecondaryTextColor(context),
                  ),
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
                Text(
                  'Required Documents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please upload your professional documents for verification',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 16),

                // Medical License Card (Front)
                GestureDetector(
                  onTap: () => _pickImage('cardFront'),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.getSurfaceColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.getPrimaryColor(context),
                        width: 2,
                      ),
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
                            : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.upload_file,
                                    color: AppColors.getSecondaryTextColor(
                                      context,
                                    ),
                                    size: 32,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Upload Medical License (Front)',
                                    style: TextStyle(
                                      color: AppColors.getSecondaryTextColor(
                                        context,
                                      ),
                                    ),
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
                      color: AppColors.getSurfaceColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.getPrimaryColor(context),
                        width: 2,
                      ),
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
                            : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.upload_file,
                                    color: AppColors.getSecondaryTextColor(
                                      context,
                                    ),
                                    size: 32,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Upload Medical License (Back)',
                                    style: TextStyle(
                                      color: AppColors.getSecondaryTextColor(
                                        context,
                                      ),
                                    ),
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
                      color: AppColors.getSurfaceColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.getPrimaryColor(context),
                        width: 2,
                      ),
                    ),
                    child:
                        _idImage != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(_idImage!, fit: BoxFit.cover),
                            )
                            : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.upload_file,
                                    color: AppColors.getSecondaryTextColor(
                                      context,
                                    ),
                                    size: 32,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Upload ID Card',
                                    style: TextStyle(
                                      color: AppColors.getSecondaryTextColor(
                                        context,
                                      ),
                                    ),
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
                    color: AppColors.getPrimaryColor(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.getPrimaryColor(
                        context,
                      ).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.getPrimaryColor(context),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your information will be reviewed and verified within 24-48 hours. You will be notified once approved.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.getTextColor(context),
                          ),
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
