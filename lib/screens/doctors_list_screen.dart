import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../services/api_service.dart';
import '../app_colors.dart';
import 'doctor_booking_screen.dart';

class DoctorsListScreen extends StatefulWidget {
  const DoctorsListScreen({super.key});

  @override
  State<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends State<DoctorsListScreen> {
  late Future<List<Doctor>> _doctorsFuture;
  List<Doctor> _allDoctors = [];
  List<Doctor> _filteredDoctors = [];
  String _searchQuery = '';
  String _selectedSpecialty = 'All';

  final List<String> _specialties = ['All', 'Dentist', 'Surgeon', 'Therapist'];

  @override
  void initState() {
    super.initState();
    _doctorsFuture = fetchDoctors();
    _doctorsFuture.then((doctors) {
      setState(() {
        _allDoctors = doctors;
        _filteredDoctors = doctors;
      });
    });
  }

  void _filterDoctors() {
    setState(() {
      _filteredDoctors = _allDoctors.where((doctor) {
        final matchesName = doctor.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesSpecialty = _selectedSpecialty == 'All' || doctor.specialty == _selectedSpecialty;
        return matchesName && matchesSpecialty;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.dark,
        title: const Text('Vet Doctors', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Doctor>>(
        future: _doctorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.gold));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: AppColors.dark)));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search & Filter Row
                Row(
                  children: [
                    // Search Field
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by name',
                          hintStyle: const TextStyle(color: AppColors.gray),
                          filled: true,
                          fillColor: AppColors.fieldColor,
                          prefixIcon: const Icon(Icons.search, color: AppColors.gray),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: AppColors.dark),
                        onChanged: (value) {
                          _searchQuery = value;
                          _filterDoctors();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Filter Dropdown
                    DropdownButton<String>(
                      value: _selectedSpecialty,
                      dropdownColor: AppColors.fieldColor,
                      style: const TextStyle(color: AppColors.dark),
                      items: _specialties.map((specialty) {
                        return DropdownMenuItem<String>(
                          value: specialty,
                          child: Text(specialty),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _selectedSpecialty = value;
                          _filterDoctors();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Doctors List
                Expanded(
                  child: _filteredDoctors.isEmpty
                      ? const Center(
                          child: Text('No doctors found.', style: TextStyle(color: AppColors.gray)))
                      : ListView.separated(
                          itemCount: _filteredDoctors.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final doctor = _filteredDoctors[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => DoctorBookingScreen(doctor: doctor),
                                ));
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: AppColors.gray.withOpacity(0.2),
                                      child: const Icon(Icons.person, color: Colors.white, size: 30),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            doctor.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: AppColors.dark,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${doctor.specialty} • ${doctor.yearsOfExperience} yrs experience",
                                            style: const TextStyle(color: AppColors.gray, fontSize: 13),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.star, color: AppColors.gold, size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                doctor.rating.toString(),
                                                style: const TextStyle(color: AppColors.gray),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "${doctor.price} EGP",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.gold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Icon(Icons.arrow_forward_ios, color: AppColors.gray, size: 16),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
