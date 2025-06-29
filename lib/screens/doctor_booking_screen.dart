import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../app_colors.dart';

class DoctorBookingScreen extends StatefulWidget {
  final Doctor doctor;
  const DoctorBookingScreen({super.key, required this.doctor});

  @override
  State<DoctorBookingScreen> createState() => _DoctorBookingScreenState();
}

class _DoctorBookingScreenState extends State<DoctorBookingScreen> {
  final List<String> _daysOfWeek = ["Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri"];
  final List<String> _availableTimes = ['10:00 AM', '01:00 PM', '03:30 PM', '06:00 PM'];
  int? _selectedDayIndex;
  int? _selectedTimeIndex;

  @override
  Widget build(BuildContext context) {
    final selectedDay = _selectedDayIndex != null ? _daysOfWeek[_selectedDayIndex!] : null;
    final selectedTime = _selectedTimeIndex != null ? _availableTimes[_selectedTimeIndex!] : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.dark,
        title: const Text("Booking Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.grey.shade300,
                    child: const Icon(Icons.person, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.doctor.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(widget.doctor.specialty),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(widget.doctor.rating.toString()),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Select Day
            const Text("Select Day", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _daysOfWeek.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedDayIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDayIndex = index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.gold : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppColors.gold : AppColors.fieldColor),
                      ),
                      child: Center(
                        child: Text(
                          _daysOfWeek[index],
                          style: TextStyle(color: isSelected ? Colors.white : AppColors.dark),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Select Time
            const Text("Select Time", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(_availableTimes.length, (index) {
                final isSelected = _selectedTimeIndex == index;
                return ChoiceChip(
                  label: Text(_availableTimes[index]),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedTimeIndex = index),
                  selectedColor: AppColors.gold,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.dark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: isSelected ? AppColors.gold : AppColors.fieldColor),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Summary
            const Divider(height: 32),
            const Text("Booking Summary", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Doctor: ${widget.doctor.name}"),
            Text("Day: ${selectedDay ?? '-'}"),
            Text("Time: ${selectedTime ?? '-'}"),
            Text("Price: ${widget.doctor.price} EGP", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 100), // To avoid hiding behind bottom button
          ],
        ),
      ),

      // Confirm Button fixed at bottom
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.dark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            if (_selectedDayIndex == null || _selectedTimeIndex == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Please select both day and time."),
                backgroundColor: Colors.red,
              ));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Booking Confirmed!"),
                backgroundColor: Colors.green,
              ));
            }
          },
          child: const Text("Confirm Booking", style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
