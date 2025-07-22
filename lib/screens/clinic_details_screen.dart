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

              _infoRow(Icons.location_on, clinic.location, grayColor),
              _infoRow(Icons.attach_money, "${clinic.price} EGP", grayColor),
              _infoRow(Icons.timer, clinic.isOpen ? "Open Now" : "Closed", grayColor),

              const SizedBox(height: 24),

              Text("Available Days",
                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
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
                    selectedColor: accentColor.withOpacity(0.2),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              Text("Available Times",
                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
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
                    selectedColor: accentColor.withOpacity(0.2),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              Text("Patient Reviews",
                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Ahmed M.",
                        style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    Text("Very professional doctor, listened carefully and explained everything.",
                        style: TextStyle(color: grayColor)),
                    const SizedBox(height: 8),
                    Text("Sara A.",
                        style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    Text("The clinic was clean and the staff was helpful.",
                        style: TextStyle(color: grayColor)),
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
                      label: const Text("Call"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: surfaceColor,
                        foregroundColor: textColor,
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

  Widget _infoRow(IconData icon, String text, Color iconColor) {
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
