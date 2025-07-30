// models/Clinic.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Clinic {
  final String id;
  final String name;
  final String doctorName;
  final String address;
  final String image;
  final double rating;
  final double price;
  final String experience;
  final String? specialty;
  final String phoneNumber; // اسمه phoneNumber ليكون أوضح
  final List<dynamic> workingHours; // <-- تم تغييره إلى List
  final List<String> workingDays;
  final GeoPoint location;

  Clinic({
    required this.id,
    required this.name,
    required this.doctorName,
    required this.address,
    required this.image,
    required this.rating,
    required this.price,
    required this.experience,
    this.specialty,
    required this.phoneNumber,
    required this.workingHours,
    required this.workingDays,
    required this.location,
  });

  factory Clinic.fromCombinedData(Map<String, dynamic> combinedData) {
    
    final List<dynamic> hoursList = combinedData['workingHours'] as List<dynamic>? ?? [];
   
    final List<String> days = hoursList.map<String>((e) => e['day'] as String).toList();
    // -------------------------

    return Clinic(
      id: combinedData['doctorId'] ?? '',
      name: combinedData['name'] ?? 'No Name',
      doctorName: combinedData['fullName'] ?? 'Unknown Doctor',
      address: combinedData['address'] ?? 'No Location',
      image: combinedData['profileImage'] ?? '',
      rating: (combinedData['rating'] ?? 0.0).toDouble(),
      price: (combinedData['price'] ?? 0.0).toDouble(),
      experience: combinedData['experience'] ?? 'N/A',
      specialty: combinedData['specialization'],
      phoneNumber: combinedData['phone'] ?? '',
      workingHours: hoursList, 
      workingDays: days,       
      location: combinedData['location'] ?? const GeoPoint(0, 0),
    );
  }
}