// models/Clinic.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Clinic {
  final String id; // This will be the doctor's UID
  final String name; // Clinic name
  final String doctorName;
  final String address; // The text address
  final String image;
  final double rating;
  final double price;
  final String experience;
  final String? specialty;
  final String phoneNumber; // Clinic phone number
  final List<String> workingDays;
  final Map<String, dynamic> workingHours;
  final GeoPoint location; // The GeoPoint for coordinates

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
    required this.workingDays,
    required this.workingHours,
    required this.location,
  });

  // This factory helps create a Clinic object from different Firestore documents
  factory Clinic.fromCombinedData(Map<String, dynamic> combinedData) {
    // Safely extract working hours and convert to the correct type
    Map<String, dynamic> hours = {};
    if (combinedData['workingHours'] is Map) {
      hours = Map<String, dynamic>.from(combinedData['workingHours']);
    }

    return Clinic(
      id: combinedData['doctorId'] ?? '',
      name: combinedData['name'] ?? 'No Name',
      doctorName: combinedData['fullName'] ?? 'Unknown Doctor',
      address: combinedData['address'] ?? 'No Location', // <-- هذا هو العنوان النصي
      image: combinedData['profileImage'] ?? '',
      rating: (combinedData['rating'] ?? 0.0).toDouble(),
      price: (combinedData['price'] ?? 0.0).toDouble(),
      experience: combinedData['experience'] ?? 'N/A',
      specialty: combinedData['specialization'], // Can be null
      phoneNumber: combinedData['phone'] ?? '',
      workingDays: hours.keys.toList(),
      workingHours: hours,
      location: combinedData['location'] ?? const GeoPoint(0, 0), // <-- وهذا هو حقل الإحداثيات
    );
  }
}