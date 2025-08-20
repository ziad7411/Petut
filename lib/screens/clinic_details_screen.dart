import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
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
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  List<String> _availableTimes = [];
  bool _isLoadingTimes = false;
  String? _errorLoadingTimes;
  Set<DateTime> _availableDays = {};

  String getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  @override
  void initState() {
    super.initState();
    _generateAvailableDays();
  }

  void _generateAvailableDays() {
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 30));

    for (DateTime date = now;
        date.isBefore(endDate);
        date = date.add(const Duration(days: 1))) {
      final dayName = getDayName(date);
      if (widget.clinic.workingDays.contains(dayName)) {
        _availableDays.add(DateTime(date.year, date.month, date.day));
      }
    }
  }

  ImageProvider? _getImageProvider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null; // مفيش صورة
    }

    // ✅ لو اللينك من imgbb أو أي لينك HTTP/HTTPS
    if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    }

    // 🟡 fallback: لو لسه في بيانات قديمة Base64
    try {
      final bytes = base64Decode(imageUrl);
      return MemoryImage(bytes);
    } catch (e) {
      print("Error decoding image: $e");
      return null;
    }
  }

  Uint8List _decodeBase64Image(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      print("Error decoding base64 image: $e");
      return Uint8List(0);
    }
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
      final selectedDayName = getDayName(selectedDate!);

      // ================== هذا هو الإصلاح الرئيسي ==================
      // نبحث عن اليوم المطابق داخل القائمة بدلاً من التعامل معها كخريطة
      final daySchedule = widget.clinic.workingHours.firstWhere(
        (schedule) => schedule['day'] == selectedDayName,
        orElse: () => null, // In case the day is not found
      );
      // =========================================================

      if (daySchedule == null ||
          daySchedule['openTime'] == null ||
          daySchedule['closeTime'] == null) {
        throw Exception("Doctor is not available on $selectedDayName.");
      }

      final startTimeStr = daySchedule['openTime']!;
      final endTimeStr = daySchedule['closeTime']!;

      final List<String> allTimeSlots = [];
      final startParts = startTimeStr.split(':').map(int.parse).toList();
      final endParts = endTimeStr.split(':').map(int.parse).toList();

      DateTime slotTime = DateTime(selectedDate!.year, selectedDate!.month,
          selectedDate!.day, startParts[0], startParts[1]);
      final endTime = DateTime(selectedDate!.year, selectedDate!.month,
          selectedDate!.day, endParts[0], endParts[1]);

      while (slotTime.isBefore(endTime)) {
        allTimeSlots.add(DateFormat.jm().format(slotTime));
        slotTime = slotTime.add(const Duration(minutes: 30));
      }

      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
      final bookingSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('doctorId', isEqualTo: widget.clinic.id)
          .where('date', isEqualTo: formattedDate)
          .get();

      final List<String> bookedTimes =
          bookingSnapshot.docs.map((doc) => doc['time'] as String).toList();
      final available =
          allTimeSlots.where((slot) => !bookedTimes.contains(slot)).toList();

      if (mounted) {
        setState(() {
          _availableTimes = available;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorLoadingTimes = e.toString();
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
                  Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: clinic.image.isNotEmpty
                            ? (clinic.image.startsWith('http')
                                ? Image.network(
                                    clinic.image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.local_hospital,
                                        size: 40,
                                        color: theme.colorScheme.primary,
                                      );
                                    },
                                  )
                                : Image.memory(
                                    _decodeBase64Image(clinic.image),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.local_hospital,
                                        size: 40,
                                        color: theme.colorScheme.primary,
                                      );
                                    },
                                  ))
                            : Icon(
                                Icons.local_hospital,
                                size: 40,
                                color: theme.colorScheme.primary,
                              ),
                      )),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(clinic.name,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("Specialty: ${clinic.specialty ?? 'Unknown'}"),
                        Text("${clinic.rating} ★ | ${clinic.phoneNumber}"),
                        Text("Experience: ${clinic.experience} years"),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),
              // ================== التعديل رقم 3: استخدام العنوان النصي ==================
              _infoRow(Icons.location_on, clinic.address),
              // ====================================================================
              _infoRow(Icons.attach_money, "${clinic.price} EGP"),
              _infoRow(Icons.timer, "Check available times"),
              const SizedBox(height: 24),
              const Text("Choose Appointment Day",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TableCalendar<DateTime>(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 30)),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(selectedDate, day);
                  },
                  enabledDayPredicate: (day) {
                    return _availableDays
                        .contains(DateTime(day.year, day.month, day.day));
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    if (_availableDays.contains(DateTime(selectedDay.year,
                        selectedDay.month, selectedDay.day))) {
                      setState(() {
                        selectedDate = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      _fetchAvailableTimes();
                    }
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    weekendTextStyle:
                        TextStyle(color: theme.colorScheme.primary),
                    holidayTextStyle:
                        TextStyle(color: theme.colorScheme.primary),
                    selectedDecoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    disabledTextStyle: TextStyle(
                      color: theme.hintColor.withOpacity(0.3),
                    ),
                    markerDecoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    formatButtonDecoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    formatButtonTextStyle: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text("Available Times",
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BookingConfirmationScreen(
                                      clinic: clinic,
                                      selectedDay: DateFormat('EEEE, MMM d')
                                          .format(selectedDate!),
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
        decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8)),
        child: Text('Please pick a date to see available times.',
            style: TextStyle(color: theme.hintColor)),
      );
    }
    if (_isLoadingTimes) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorLoadingTimes != null) {
      return Center(
          child: Text(_errorLoadingTimes!,
              style: TextStyle(color: theme.colorScheme.error)));
    }
    if (_availableTimes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8)),
        child: Text('No available appointments for this day.',
            style: TextStyle(color: theme.hintColor)),
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
          labelStyle: TextStyle(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.textTheme.bodyLarge?.color),
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
