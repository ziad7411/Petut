import 'package:flutter/material.dart';
import '../models/Clinic.dart';
import '../app_colors.dart';
import './booking_confirmation_screen.dart';

class ClinicDetailsScreen extends StatefulWidget {
  final Clinic clinic;

  const ClinicDetailsScreen({super.key, required this.clinic});

  @override
  State<ClinicDetailsScreen> createState() => _ClinicDetailsScreenState();
}

class _ClinicDetailsScreenState extends State<ClinicDetailsScreen> {
  String? selectedDay;
  String? selectedTime;

  final List<String> availableDays = ['Today', 'Tomorrow', 'Wednesday', 'Thursday'];
  final List<String> availableTimes = ['2:00 PM', '3:30 PM', '5:00 PM', '6:30 PM'];

  @override
  Widget build(BuildContext context) {
    final clinic = widget.clinic;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(clinic.name),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.dark,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor profile
              Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(clinic.image),
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

              const Text("Available Days", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: availableDays.map((day) {
                  final isSelected = selectedDay == day;
                  return ChoiceChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => selectedDay = day);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              const Text("Available Times", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: availableTimes.map((time) {
                  final isSelected = selectedTime == time;
                  return ChoiceChip(
                    label: Text(time),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => selectedTime = time);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              const Text("Patient Reviews", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Ahmed M.", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Very professional doctor, listened carefully and explained everything."),
                    SizedBox(height: 8),
                    Text("Sara A.", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("The clinic was clean and the staff was helpful."),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // اتصال
                      },
                      icon: const Icon(Icons.call),
                      label: const Text("اتصال"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: selectedDay != null && selectedTime != null
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookingConfirmationScreen(
                                    clinic: clinic,
                                    selectedDay: selectedDay!,
                                    selectedTime: selectedTime!,
                                  ),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.calendar_today),
                      label: const Text("احجز الآن"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        disabledBackgroundColor: Colors.grey,
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

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.gray),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
