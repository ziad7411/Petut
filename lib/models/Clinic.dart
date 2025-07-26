import 'package:cloud_firestore/cloud_firestore.dart';

class Clinic {
  final String id;
  final String name;
  final String location;
  final String phoneNumber;
  final double price;
  final String image;
  final double rating;
  final bool isOpen;
  final String? specialty;
  final int? experience;
  final List<String> workingDays;
  final String? startTime;
  final String? endTime;

  Clinic({
    required this.id,
    required this.name,
    required this.location,
    required this.phoneNumber,
    required this.price,
    required this.image,
    required this.rating,
    required this.isOpen,
    required this.workingDays,
    this.specialty,
    this.experience,
    this.startTime,
    this.endTime,
  });

  factory Clinic.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // FIX: Add robust parsing to handle different data types from Firestore.
    // This prevents crashes if the data is not in the expected format.

    double parsedPrice = 0.0;
    if (data['price'] is String) {
      parsedPrice = double.tryParse(data['price']) ?? 0.0;
    } else if (data['price'] is num) {
      parsedPrice = (data['price'] as num).toDouble();
    }

    int? parsedExperience;
    if (data['experience'] is String) {
      parsedExperience = int.tryParse(data['experience']);
    } else if (data['experience'] is num) {
      parsedExperience = (data['experience'] as num).toInt();
    }

    return Clinic(
      id: doc.id,
      name: data['clinicName']?.toString() ?? 'Unnamed Clinic',
      location: data['clinicAddress']?.toString() ?? '',
      phoneNumber: data['clinicPhone']?.toString() ?? '',
      price: parsedPrice,
      image: data['profileImage']?.toString() ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      isOpen: data['isOpen'] as bool? ?? false,
      specialty: data['specialty']?.toString(),
      experience: parsedExperience,
      // Use ?.toList() for safety, though List.from is usually fine.
      workingDays: List<String>.from(data['workingDays'] ?? []),
      startTime: data['startTime']?.toString(),
      endTime: data['endTime']?.toString(),
    );
  }
}
