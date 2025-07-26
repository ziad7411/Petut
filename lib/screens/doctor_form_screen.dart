import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petut/screens/select_location_screen.dart';
import 'package:petut/screens/avatar_selection_screen.dart';
import 'package:petut/utils/avatar_helper.dart';
import 'package:intl/intl.dart';
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
  final _priceController = TextEditingController();

  String? _selectedSpecialty;
  String? _selectedGender;
  
  final List<String> _specialties = [
    'General Veterinarian',
    'Small Animal Medicine',
    'Large Animal Medicine', 
    'Exotic Animal Medicine',
    'Veterinary Surgery',
    'Veterinary Dentistry',
    'Emergency Medicine',
    'Internal Medicine'
  ];
  
  final List<String> _genders = ['Male', 'Female'];

  File? _profileImage;
  String? _selectedAvatar;
  File? _cardFrontImage;
  File? _cardBackImage;
  File? _idImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  
  double? _selectedLat;
  double? _selectedLng;

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final List<String> _selectedDays = [];
  final List<String> _daysOfWeek = [
    'Saturday',
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  bool _hasClinic = false;

  Future<void> _pickImage(String type) async {
    if (type == 'profile') {
      // Show options: Avatar, Gallery, or Camera
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
            _profileImage = null;
          });
        }
      } else if (choice == 'gallery') {
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          setState(() {
            _profileImage = File(image.path);
            _selectedAvatar = null;
          });
        }
      } else if (choice == 'camera') {
        final XFile? image = await _picker.pickImage(source: ImageSource.camera);
        if (image != null) {
          setState(() {
            _profileImage = File(image.path);
            _selectedAvatar = null;
          });
        }
      }
    } else {
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
  }

  // -- تعديل: إزالة الـ builder من منتقي الوقت ليعتمد على ثيم التطبيق --
  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          isStartTime
              ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
              : (_endTime ?? const TimeOfDay(hour: 18, minute: 0)),
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
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields correctly'),
        ),
      );
      return;
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one working day')),
      );
      return;
    }

    // Validate required ID documents (profile image is optional)
    if (_cardFrontImage == null ||
        _cardBackImage == null ||
        _idImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required ID documents')),
      );
      return;
    }

    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your working hours')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      String? profileBase64;
      if (_selectedAvatar != null) {
        profileBase64 = _selectedAvatar; // Store avatar path
      } else if (_profileImage != null) {
        profileBase64 = await _convertImageToBase64(_profileImage);
      }
      final cardFrontBase64 = await _convertImageToBase64(_cardFrontImage);
      final cardBackBase64 = await _convertImageToBase64(_cardBackImage);
      final idBase64 = await _convertImageToBase64(_idImage);

      final socialMedia = <String, String>{};
      if (_facebookController.text.trim().isNotEmpty)
        socialMedia['facebook'] = _facebookController.text.trim();
      if (_instagramController.text.trim().isNotEmpty)
        socialMedia['instagram'] = _instagramController.text.trim();
      if (_twitterController.text.trim().isNotEmpty)
        socialMedia['twitter'] = _twitterController.text.trim();
      if (_linkedinController.text.trim().isNotEmpty)
        socialMedia['linkedin'] = _linkedinController.text.trim();

      // Store all doctor data in users collection
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'role': 'Doctor',
        'fullName': _doctorNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'uid': user.uid,
        'gender': _selectedGender,
      }, SetOptions(merge: true));
     
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection("doctorsDetails")
          .add({
            'experience': _experienceController.text.trim(),
            'description': _descriptionController.text.trim(),
            'socialMedia': socialMedia,
            'profileImage': profileBase64,
            'cardFrontImage': cardFrontBase64,
            'cardBackImage': cardBackBase64,
            'idImage': idBase64,
            'isVerified': false,
            'rating': 0.0,
            'totalReviews': 0,
          });
      if (_hasClinic) {
        await FirebaseFirestore.instance.collection('clinics').doc(user.uid).set({
          'doctorid': user.uid,
          'workingHours': _workingHoursController.text.trim(),
          'day': _selectedDays,
          'openTime':
              _startTime != null
                  ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                  : null,
          'closeTime':
              _endTime != null
                  ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
                  : null,
          'clinicName': _clinicNameController.text.trim(),
          'clinicAddress': _clinicAddressController.text.trim(),
          'clinicPhone': _clinicPhoneController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      Navigator.pushReplacementNamed(context, '/goToWebPage');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // -- تعديل: استخدام متغير الثيم لجميع الألوان في الواجهة --
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.appBarTheme.foregroundColor,
        title: Text(
          'Doctor Registration',
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
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please provide your professional information',
                  style: TextStyle(fontSize: 14, color: theme.hintColor),
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: () => _pickImage('profile'),
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
                          : _profileImage != null
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
                                  color: theme.hintColor,
                                ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Tap to choose avatar',
                    style: TextStyle(color: theme.hintColor, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  hintText: 'Doctor Name',
                  controller: _doctorNameController,
                  prefixIcon: Icons.person,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Enter your full name';
                    if (value.trim().length < 2)
                      return 'Name must be at least 2 characters';
                    if (value.trim().length > 50)
                      return 'Name must be less than 50 characters';
                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim()))
                      return 'Name can only contain letters and spaces';
                    return null;
                  },
                ),
                CustomTextField(
                  hintText: 'Personal Phone Number',
                  controller: _phoneController,
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Enter your phone number';
                    final digitsOnly = value.trim().replaceAll(
                      RegExp(r'[^\d]'),
                      '',
                    );
                    if (digitsOnly.length != 11)
                      return 'Phone number must be exactly 11 digits';
                    if (!digitsOnly.startsWith('01'))
                      return 'Phone number must start with 01';
                    return null;
                  },
                ),
                
                // Gender Dropdown
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
                    prefixIcon: Icon(Icons.person_outline, color: theme.hintColor),
                  ),
                  hint: Text('Select Gender', style: TextStyle(color: theme.hintColor)),
                  items: _genders.map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Please select your gender';
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                Text(
                  'Professional Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(

                  hintText: 'Clinic Name',
                  controller: _clinicNameController,
                  prefixIcon: Icons.local_hospital,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Enter clinic name';
                    if (value.trim().length < 2)
                      return 'Clinic name must be at least 2 characters';
                    if (value.trim().length > 100)
                      return 'Clinic name must be less than 100 characters';
                    return null;
                  },
                ),
                CustomTextField(
                  hintText: 'Clinic Phone Number',
                  controller: _clinicPhoneController,
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Enter clinic phone number';
                    final digitsOnly = value.trim().replaceAll(
                      RegExp(r'[^\d]'),
                      '',
                    );
                    if (digitsOnly.length != 11)
                      return 'Phone number must be exactly 11 digits';
                    if (!digitsOnly.startsWith('01'))
                      return 'Phone number must start with 01';
                    return null;
                  },
                ),
                CustomTextField(
                  hintText: 'Clinic Address',
                  controller: _clinicAddressController,
                  prefixIcon: Icons.location_on,
                  readOnly: true,
                  onTap: () async {
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SelectLocationScreen(),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _clinicAddressController.text = result['address'] ?? '';
                        _selectedLat = result['lat'];
                        _selectedLng = result['lng'];
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Enter clinic address';
                    if (value.trim().length < 5)
                      return 'Address must be at least 5 characters';
                    if (value.trim().length > 200)
                      return 'Address must be less than 200 characters';
                    return null;
                  },
                ),
                CustomTextField(

                  hintText: 'Years of Experience',
                  controller: _experienceController,
                  prefixIcon: Icons.work,
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Enter years of experience';
                    if (!RegExp(r'^\d+$').hasMatch(value.trim()))
                      return 'Experience must be a number';
                    final experience = int.tryParse(value.trim());
                    if (experience == null || experience < 0 || experience > 50)
                      return 'Experience must be between 0 and 50 years';
                    return null;
                  },
                ),
                
                // Specialty Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedSpecialty,
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
                    prefixIcon: Icon(Icons.medical_services, color: theme.hintColor),
                  ),
                  hint: Text('Select Specialty', style: TextStyle(color: theme.hintColor)),
                  items: _specialties.map((specialty) {
                    return DropdownMenuItem(
                      value: specialty,
                      child: Text(specialty, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSpecialty = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Please select your specialty';
                    return null;
                  },
                ),
                
                CustomTextField(
                  hintText: 'Consultation Fee (EGP)',
                  controller: _priceController,
                  prefixIcon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Enter consultation fee';
                    final price = double.tryParse(value.trim());
                    if (price == null || price < 50 || price > 1000)
                      return 'Fee must be between 50 and 1000 EGP';
                    return null;
                  },
                ),
                
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Text(
                    'Working Hours',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
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
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, color: theme.hintColor),
                              const SizedBox(width: 12),
                              Text(
                                _startTime?.format(context) ?? 'Start Time',
                                style: TextStyle(
                                  color:
                                      _startTime != null
                                          ? theme.textTheme.bodyLarge?.color
                                          : theme.hintColor,
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
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, color: theme.hintColor),
                              const SizedBox(width: 12),
                              Text(
                                _endTime?.format(context) ?? 'End Time',
                                style: TextStyle(
                                  color:
                                      _endTime != null
                                          ? theme.textTheme.bodyLarge?.color
                                          : theme.hintColor,
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
                const SizedBox(height: 24),
                Text(
                  'Select your working days:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                ..._daysOfWeek.map((day) {
                  return CheckboxListTile(
                    title: Text(
                      day,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    ),
                    value: _selectedDays.contains(day),
                    onChanged: (bool? selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                      });
                    },
                    activeColor: theme.colorScheme.primary,
                    checkColor: theme.colorScheme.onPrimary,
                    controlAffinity: ListTileControlAffinity.leading,
                    tileColor: theme.colorScheme.surface,
                  );
                }).toList(),
                const SizedBox(height: 16),
                CustomTextField(
                  hintText: 'Professional Description',
                  controller: _descriptionController,
                  prefixIcon: Icons.description,
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'Enter professional description';
                    if (value.trim().length < 10)
                      return 'Description must be at least 10 characters';
                    if (value.trim().length > 500)
                      return 'Description must be less than 500 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Social Media Links (Optional)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your social media profiles to help clients find you',
                  style: TextStyle(fontSize: 12, color: theme.hintColor),
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
                Text(
                  'Required Documents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please upload your professional documents for verification',
                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                ),
                const SizedBox(height: 16),
                _buildImagePicker(
                  'cardFront',
                  'Upload Medical License (Front)',
                ),
                const SizedBox(height: 16),
                _buildImagePicker('cardBack', 'Upload Medical License (Back)'),
                const SizedBox(height: 16),
                _buildImagePicker('id', 'Upload ID Card'),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your information will be reviewed and verified within 24-48 hours. You will be notified once approved.',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // --- Clinic Section Switch ---
                Row(
                  children: [
                    Text(
                      'Clinic Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Switch(
                      value: _hasClinic,
                      onChanged: (value) {
                        setState(() {
                          _hasClinic = value;
                          if (!value) {
                            _clinicNameController.clear();
                            _clinicAddressController.clear();
                            _clinicPhoneController.clear();
                          }
                        });
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Do you have a clinic?',
                  style: TextStyle(color: theme.hintColor, fontSize: 14),
                ),
                if (_hasClinic) ...[
                  const SizedBox(height: 16),
                  CustomTextField(
                    hintText: 'Clinic Name',
                    controller: _clinicNameController,
                    prefixIcon: Icons.local_hospital,
                    validator: (value) {
                      if (!_hasClinic) return null;
                      if (value == null || value.trim().isEmpty)
                        return 'Enter clinic name';
                      if (value.trim().length < 2)
                        return 'Clinic name must be at least 2 characters';
                      if (value.trim().length > 100)
                        return 'Clinic name must be less than 100 characters';
                      return null;
                    },
                  ),
                  CustomTextField(
                    hintText: 'Clinic Phone Number',
                    controller: _clinicPhoneController,
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    validator: (value) {
                      if (!_hasClinic) return null;
                      if (value == null || value.trim().isEmpty)
                        return 'Enter clinic phone number';
                      final digitsOnly = value.trim().replaceAll(
                        RegExp(r'[^\d]'),
                        '',
                      );
                      if (digitsOnly.length != 11)
                        return 'Phone number must be exactly 11 digits';
                      if (!digitsOnly.startsWith('01'))
                        return 'Phone number must start with 01';
                      return null;
                    },
                  ),
                  CustomTextField(
                    hintText: 'Clinic Address',
                    controller: _clinicAddressController,
                    prefixIcon: Icons.location_on,
                    readOnly: true,
                    onTap: () async {
                      final selectedAddress = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SelectLocationScreen(),
                        ),
                      );
                      if (selectedAddress != null &&
                          selectedAddress is String) {
                        _clinicAddressController.text = selectedAddress;
                      }
                    },
                    validator: (value) {
                      if (!_hasClinic) return null;
                      if (value == null || value.trim().isEmpty)
                        return 'Enter clinic address';
                      if (value.trim().length < 5)
                        return 'Address must be at least 5 characters';
                      if (value.trim().length > 200)
                        return 'Address must be less than 200 characters';
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                      text: 'Submit Application',
                      onPressed: _submit,
                      width: double.infinity,
                      fontSize: 20,
                    ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(String type, String label) {
    final theme = Theme.of(context);
    File? imageFile;
    switch (type) {
      case 'cardFront':
        imageFile = _cardFrontImage;
        break;
      case 'cardBack':
        imageFile = _cardBackImage;
        break;
      case 'id':
        imageFile = _idImage;
        break;
    }

    return GestureDetector(
      onTap: () => _pickImage(type),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.primary, width: 2),
        ),
        child:
            imageFile != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(imageFile, fit: BoxFit.cover),
                )
                : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file, color: theme.hintColor, size: 32),
                      const SizedBox(height: 8),
                      Text(label, style: TextStyle(color: theme.hintColor)),
                    ],
                  ),
                ),
      ),
    );
  }
}
