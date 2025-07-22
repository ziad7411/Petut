import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// NEW: Import Firebase Auth to check login status
import 'package:firebase_auth/firebase_auth.dart';
import '../models/Clinic.dart';
import '../app_colors.dart';
import './booking_confirmation_screen.dart'; 
import 'package:intl/intl.dart';
// NEW: Import your login screen. Make sure the path is correct.
import './Signup&Login/login_screen.dart'; // Make sure you have a LoginScreen

class ClinicDetailsScreen extends StatefulWidget {
  final Clinic clinic;

  const ClinicDetailsScreen({super.key, required this.clinic});

  @override
  State<ClinicDetailsScreen> createState() => _ClinicDetailsScreenState();
}

class _ClinicDetailsScreenState extends State<ClinicDetailsScreen> {
  DateTime? selectedDate;
  String? selectedTime;

  List<String> _availableTimes = [];
  bool _isLoadingTimes = false;
  String? _errorLoadingTimes;

  String getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  Future<void> _fetchAvailableTimes() async {
    if (selectedDate == null) return;

    setState(() {
      _isLoadingTimes = true;
      _errorLoadingTimes = null;
      _availableTimes = [];
      selectedTime = null;
    });

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.clinic.id).get();
      final data = doc.data() as Map<String, dynamic>;
      final startTimeStr = data['startTime'] as String?;
      final endTimeStr = data['endTime'] as String?;

      if (startTimeStr == null || endTimeStr == null) {
        throw Exception("Doctor's working hours are not set.");
      }

      final List<String> allTimeSlots = [];
      final startParts = startTimeStr.split(':').map(int.parse).toList();
      final endParts = endTimeStr.split(':').map(int.parse).toList();

      DateTime slotTime = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, startParts[0], startParts[1]);
      final endTime = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, endParts[0], endParts[1]);
      
      while(slotTime.isBefore(endTime)) {
        allTimeSlots.add(DateFormat.jm().format(slotTime));
        slotTime = slotTime.add(const Duration(minutes: 30));
      }

      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
      final bookingSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('doctorId', isEqualTo: widget.clinic.id)
          .where('date', isEqualTo: formattedDate)
          .get();

      final List<String> bookedTimes = bookingSnapshot.docs.map((doc) => doc['time'] as String).toList();
      final available = allTimeSlots.where((slot) => !bookedTimes.contains(slot)).toList();

      if (mounted) {
        setState(() {
          _availableTimes = available;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorLoadingTimes = 'Failed to load times. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTimes = false;
        });
      }
    }
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );

    if (picked != null) {
      final pickedDay = getDayName(picked);
      final availableDays = widget.clinic.workingDays;

      if (!availableDays.contains(pickedDay)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Doctor not available on $pickedDay")),
        );
        setState(() {
          selectedDate = null;
          selectedTime = null;
          _availableTimes = [];
        });
        return;
      }

      setState(() {
        selectedDate = picked;
      });
      _fetchAvailableTimes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinic = widget.clinic;
    final bgColor = AppColors.getBackgroundColor(context);
    final textColor = AppColors.getTextPrimaryColor(context);
    final surfaceColor = AppColors.getSurfaceColor(context);
    final grayColor = AppColors.getTextSecondaryColor(context);
    final accentColor = AppColors.getAccentColor(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(clinic.name, style: TextStyle(color: textColor)),
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(clinic.image),
                    onBackgroundImageError: (exception, stackTrace) {},
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(clinic.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            )),
                        const SizedBox(height: 4),
                        Text("Specialty: ${clinic.specialty ?? 'Unknown'}", style: TextStyle(color: grayColor)),
                        Text("${clinic.rating} ★ | ${clinic.phoneNumber}", style: TextStyle(color: grayColor)),
                        Text("Experience: ${clinic.experience ?? 'N/A'} years", style: TextStyle(color: grayColor)),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),
              _infoRow(Icons.location_on, clinic.location),
              _infoRow(Icons.attach_money, "${clinic.price} EGP"),
              _infoRow(Icons.timer, clinic.isOpen ? "Open Now" : "Closed"),
              const SizedBox(height: 24),
              const Text("Choose Appointment Day", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(selectedDate != null ? DateFormat.yMMMd().format(selectedDate!) : "Pick a date"),
              ),
              const SizedBox(height: 24),
              const Text("Available Times", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildAvailableTimesWidget(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: selectedDate != null && selectedTime != null
                          ? () {
                              // FIX: Check if user is logged in before proceeding.
                              final user = FirebaseAuth.instance.currentUser;

                              if (user == null) {
                                // If user is not logged in, navigate to LoginScreen.
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              } else {
                                // If user is logged in, proceed to booking confirmation.
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BookingConfirmationScreen(
                                      clinic: clinic,
                                      selectedDay: DateFormat('EEEE, MMM d').format(selectedDate!),
                                      selectedTime: selectedTime!,
                                      selectedDate: selectedDate!,
                                    ),
                                  ),
                                );
                              }
                            }
                          : null,
                      icon: const Icon(Icons.calendar_today),
                      label: const Text("Book Appointment"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        disabledBackgroundColor: grayColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableTimesWidget() {
    if (selectedDate == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
        child: Text('Please pick a date to see available times.', style: TextStyle(color: Colors.grey.shade700)),
      );
    }
    if (_isLoadingTimes) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorLoadingTimes != null) {
      return Center(child: Text(_errorLoadingTimes!, style: const TextStyle(color: Colors.red)));
    }
    if (_availableTimes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
        child: Text('No available appointments for this day.', style: TextStyle(color: Colors.grey.shade700)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableTimes.map((time) {
        final isSelected = selectedTime == time;
        return ChoiceChip(
          label: Text(time),
          selected: isSelected,
          onSelected: (selected) {
            setState(() => selectedTime = time);
          },
          selectedColor: AppColors.gold,
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
        );
      }).toList(),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: iconColor),
            ),
          ),
        ],
      ),
    );
  }
}
