import 'package:cloud_firestore/cloud_firestore.dart';

class Clinic {
  final String name;
  final String location;
  final String phoneNumber;
  final double price;
  final String image;
  final double rating;
  final bool isOpen;
  final String? specialty;     // جديد
  final int? experience;       // جديد

  Clinic({
    required this.name,
    required this.location,
    required this.phoneNumber,
    required this.price,
    required this.image,
    required this.rating,
    required this.isOpen,
    this.specialty,            // جديد
    this.experience,           // جديد
  });

  factory Clinic.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Clinic(
      name: data['doctorName'] ?? 'Unnamed',
      location: data['clinicAddress'] ?? '',
      phoneNumber: data['clinicPhone'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      image: data['image'] ?? 'https://via.placeholder.com/150',
      rating: (data['rating'] ?? 0).toDouble(),
      isOpen: data['isOpen'] ?? false,
      specialty: data['specialty'], // ممكن تكون null
      experience: data['experience'], // ممكن تكون null
    );
  }
}
