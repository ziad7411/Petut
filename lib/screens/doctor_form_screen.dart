// الكود الكامل بعد تعديل workingHours إلى array of objects

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petut/screens/avatar_selection_screen.dart';
import 'package:petut/utils/avatar_helper.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../screens/goToDoctorDashboard.dart';

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
  final _descriptionController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female'];

  File? _profileImage;
  String? _selectedAvatar;
  File? _cardFrontImage;
  File? _cardBackImage;
  File? _idImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _workingSchedule = [];
  final List<String> _daysOfWeek = ['Saturday','Sunday','Monday','Tuesday','Wednesday','Thursday','Friday'];

  @override
  void initState() {
    super.initState();
    // Initialize working schedule as array of objects
    for (String day in _daysOfWeek) {
      _workingSchedule.add({
        'day': day,
        'isSelected': false,
        'startTime': null,
        'endTime': null,
      });
    }
  }

  bool _hasClinic = false;

  Future<void> _pickImage(String type) async {
    if (type == 'profile') {
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
          MaterialPageRoute(builder: (_) => const AvatarSelectionScreen()),
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

  Future<void> _selectTime(String day, bool isStartTime) async {
    final dayIndex = _workingSchedule.indexWhere((item) => item['day'] == day);
    if (dayIndex == -1) return;

    final initialTime = isStartTime
        ? (_workingSchedule[dayIndex]['startTime'] ?? const TimeOfDay(hour: 9, minute: 0))
        : (_workingSchedule[dayIndex]['endTime'] ?? const TimeOfDay(hour: 18, minute: 0));

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _workingSchedule[dayIndex]['startTime'] = picked;
        } else {
          _workingSchedule[dayIndex]['endTime'] = picked;
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
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields correctly')),
      );
      return;
    }

    if (_hasClinic) {
      final selectedDays = _workingSchedule.where((item) => item['isSelected'] == true).toList();
      if (selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one working day for the clinic')),
        );
        return;
      }
      for (var dayItem in selectedDays) {
        if (dayItem['startTime'] == null || dayItem['endTime'] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please set start and end times for ${dayItem['day']}')),
          );
          return;
        }
      }
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      String? profileBase64 = _selectedAvatar ?? (await _convertImageToBase64(_profileImage));

      final Map<String, dynamic> doctorData = {
        'uid': user.uid,
        'fullName': _doctorNameController.text.trim(),
        'email': user.email,
        'phone': _phoneController.text.trim(),
        'gender': _selectedGender,
        'role': 'Doctor',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'profileImage': profileBase64,
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'experience': _experienceController.text.trim(),
        'rating': 0.0,
        'specialization': 'Veterinarian',
      };
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(doctorData, SetOptions(merge: true));

      if (_hasClinic) {
        final List<Map<String, String>> formattedWorkingHours = [];
        for (var dayItem in _workingSchedule) {
          if (dayItem['isSelected'] == true) {
            final startTime = dayItem['startTime'] as TimeOfDay?;
            final endTime = dayItem['endTime'] as TimeOfDay?;
            if (startTime != null && endTime != null) {
              formattedWorkingHours.add({
                'day': dayItem['day'],
                'openTime': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                'closeTime': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
              });
            }
          }
        }

        final Map<String, dynamic> clinicData = {
          'doctorId': user.uid,
          'email': user.email,
          'name': _clinicNameController.text.trim(),
          'phone': _clinicPhoneController.text.trim(),
          'address': _clinicAddressController.text.trim(),
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'workingHours': formattedWorkingHours,
          'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        };
        DocumentReference clinicRef = await FirebaseFirestore.instance.collection('clinics').add(clinicData);
        await clinicRef.update({'clinicId': clinicRef.id});
      }

      final cardFrontBase64 = await _convertImageToBase64(_cardFrontImage);
      final cardBackBase64 = await _convertImageToBase64(_cardBackImage);
      final idBase64 = await _convertImageToBase64(_idImage);
      final socialMedia = <String, String>{};
      if (_facebookController.text.trim().isNotEmpty) socialMedia['facebook'] = _facebookController.text.trim();
      if (_instagramController.text.trim().isNotEmpty) socialMedia['instagram'] = _instagramController.text.trim();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection("doctorsDetails").doc("details").set({
        'experience': _experienceController.text.trim(),
        'description': _descriptionController.text.trim(),
        'socialMedia': socialMedia,
        'cardFrontImage': cardFrontBase64,
        'cardBackImage': cardBackBase64,
        'idImage': idBase64,
      }, SetOptions(merge: true));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GoToWebPage()),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \${e.toString()}')));
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
                                  child: Image.file(_profileImage!, fit: BoxFit.cover),
                                )
                              : Icon(Icons.person, size: 50, color: theme.hintColor),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(child: Text('Tap to choose avatar', style: TextStyle(color: theme.hintColor, fontSize: 12))),
                const SizedBox(height: 32),
                Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                const SizedBox(height: 16),
                CustomTextField(
                  hintText: 'Doctor Name',
                  controller: _doctorNameController,
                  prefixIcon: Icons.person,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Enter your full name';
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
                    if (value == null || value.trim().isEmpty) return 'Enter your phone number';
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    prefixIcon: Icon(Icons.person_outline, color: theme.hintColor),
                  ),
                  hint: Text('Select Gender', style: TextStyle(color: theme.hintColor)),
                  items: _genders.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
                  onChanged: (value) => setState(() => _selectedGender = value),
                  validator: (value) => value == null ? 'Please select your gender' : null,
                ),
                const SizedBox(height: 24),
                
                 Text('Professional Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                const SizedBox(height: 16),
                CustomTextField(
                  hintText: 'Years of Experience',
                  controller: _experienceController,
                  prefixIcon: Icons.work,
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                   validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Enter years of experience';
                    return null;
                  },
                ),
                CustomTextField(
                  hintText: 'Consultation Fee (EGP)',
                  controller: _priceController,
                  prefixIcon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                   validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Enter consultation fee';
                    return null;
                  },
                ),
                CustomTextField(
                  hintText: 'Professional Description',
                  controller: _descriptionController,
                  prefixIcon: Icons.description,
                  maxLines: 4,
                   validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Enter professional description';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Clinic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                    Switch(
                      value: _hasClinic,
                      onChanged: (value) {
                        setState(() {
                          _hasClinic = value;
                          if (!value) {
                            _workingSchedule.clear();
                          }
                        });
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                  ],
                ),
                Text('Do you have a clinic?', style: TextStyle(color: theme.hintColor, fontSize: 14)),
                
                if (_hasClinic) ...[
                  const SizedBox(height: 16),
                  CustomTextField(
                    hintText: 'Clinic Name',
                    controller: _clinicNameController,
                    prefixIcon: Icons.local_hospital,
                    validator: (value) => (_hasClinic && (value == null || value.trim().isEmpty)) ? 'Enter clinic name' : null,
                  ),
                   CustomTextField(
                    hintText: 'Clinic Phone Number',
                    controller: _clinicPhoneController,
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    validator: (value) => (_hasClinic && (value == null || value.trim().isEmpty)) ? 'Enter clinic phone' : null,
                  ),
                  CustomTextField(
                    hintText: 'Clinic Address',
                    controller: _clinicAddressController,
                    prefixIcon: Icons.location_on,
                    validator: (value) => (_hasClinic && (value == null || value.trim().isEmpty)) ? 'Enter clinic address' : null,
                  ),
                  const SizedBox(height: 24),
                  Text('Clinic Working Hours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                  const SizedBox(height: 8),
                  ..._daysOfWeek.map((day) => _buildDayTimePicker(day)).toList(),
                ],
                
                const SizedBox(height: 24),
                Text('Social Media Links (Optional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                const SizedBox(height: 16),
                CustomTextField(hintText: 'Facebook Profile URL', controller: _facebookController, prefixIcon: Icons.facebook),
                CustomTextField(hintText: 'Instagram Profile URL', controller: _instagramController, prefixIcon: Icons.camera_alt),
                const SizedBox(height: 24),
                Text('Required Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                const SizedBox(height: 16),
                _buildImagePicker('cardFront', 'Upload Medical License (Front)'),
                const SizedBox(height: 16),
                _buildImagePicker('cardBack', 'Upload Medical License (Back)'),
                const SizedBox(height: 16),
                _buildImagePicker('id', 'Upload ID Card'),
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

  Widget _buildDayTimePicker(String day) {
    final theme = Theme.of(context);
    final dayIndex = _workingSchedule.indexWhere((item) => item['day'] == day);
    final isSelected = dayIndex != -1 ? _workingSchedule[dayIndex]['isSelected'] : false;

    return Column(
      children: [
        CheckboxListTile(
          title: Text(day, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
          value: isSelected,
          onChanged: (bool? selected) {
            setState(() {
              if (dayIndex != -1) {
                _workingSchedule[dayIndex]['isSelected'] = selected ?? false;
                if (!selected!) {
                  _workingSchedule[dayIndex]['startTime'] = null;
                  _workingSchedule[dayIndex]['endTime'] = null;
                }
              }
            });
          },
          activeColor: theme.colorScheme.primary,
          checkColor: theme.colorScheme.onPrimary,
          controlAffinity: ListTileControlAffinity.leading,
          tileColor: theme.colorScheme.surface.withOpacity(0.5),
        ),
        if (isSelected)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Row(
              children: [
                Expanded(child: _buildTimePickerButton(day, true)),
                const SizedBox(width: 12),
                Expanded(child: _buildTimePickerButton(day, false)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTimePickerButton(String day, bool isStart) {
    final theme = Theme.of(context);
    final dayIndex = _workingSchedule.indexWhere((item) => item['day'] == day);
    final time = dayIndex != -1 
        ? (isStart ? _workingSchedule[dayIndex]['startTime'] : _workingSchedule[dayIndex]['endTime'])
        : null;
    final label = isStart ? 'Start Time' : 'End Time';

    return ElevatedButton.icon(
      onPressed: () => _selectTime(day, isStart),
      icon: Icon(Icons.access_time, size: 18),
      label: Text(time?.format(context) ?? label),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: time != null ? theme.textTheme.bodyLarge?.color : theme.hintColor,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        child: imageFile != null
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
