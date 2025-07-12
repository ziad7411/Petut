import 'package:cloud_firestore/cloud_firestore.dart';

class Clinic {
  final String name;
  final String location;
  final String phoneNumber;
  final double price;
  final String image;
  final double rating;
  final bool isOpen;
  final String? specialty;
  final int? experience;

  Clinic({
    required this.name,
    required this.location,
    required this.phoneNumber,
    required this.price,
    required this.image,
    required this.rating,
    required this.isOpen,
    this.specialty,
    this.experience,
  });

  factory Clinic.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // التعامل مع 'experience' بشكل آمن
    int? parsedExperience;
    if (data['experience'] != null) { // لو حقل الخبرة موجود
      if (data['experience'] is String) { // ولو كان نوعه نص
        parsedExperience = int.tryParse(data['experience']); // حاول تحوله لرقم صحيح، ولو فشل يرجع null
      } else if (data['experience'] is int) { // ولو كان نوعه رقم صحيح أصلاً
        parsedExperience = data['experience']; // استخدمه زي ما هو
      }
    }

    return Clinic(
      name: data['doctorName'] ?? 'Unnamed',
      location: data['clinicAddress'] ?? '',
      phoneNumber: data['clinicPhone'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      image: data['profileImage'] ?? 'https://via.placeholder.com/150',
      rating: (data['rating'] ?? 0).toDouble(),
      isOpen: data['isOpen'] ?? false,
      specialty: data['specialty'],
      experience: parsedExperience, // استخدم القيمة اللي تم تحويلها بأمان
    );
  }
}