import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/Clinic.dart';
import './booking_confirmation_screen.dart';
import 'package:intl/intl.dart';
import './Signup&Login/login_screen.dart';

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
      initialDate: selectedDate ?? now,
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
    final theme = Theme.of(context);
    final clinic = widget.clinic;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(clinic.name),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
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
                        Text(clinic.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("Specialty: ${clinic.specialty ?? 'Unknown'}"),
                        Text("${clinic.rating} ★ | ${clinic.phoneNumber}"),
                        Text("Experience: ${clinic.experience ?? 'N/A'} years"),
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
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              } else {
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
    final theme = Theme.of(context);
    if (selectedDate == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(8)),
        child: Text('Please pick a date to see available times.', style: TextStyle(color: theme.hintColor)),
      );
    }
    if (_isLoadingTimes) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorLoadingTimes != null) {
      return Center(child: Text(_errorLoadingTimes!, style: TextStyle(color: theme.colorScheme.error)));
    }
    if (_availableTimes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(8)),
        child: Text('No available appointments for this day.', style: TextStyle(color: theme.hintColor)),
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
          selectedColor: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surface,
          labelStyle: TextStyle(color: isSelected ? theme.colorScheme.onPrimary : theme.textTheme.bodyLarge?.color),
        );
      }).toList(),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).hintColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}