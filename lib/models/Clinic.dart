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
  // معالجة workingHours
  final List<dynamic> hoursList = (combinedData['workingHours'] is List)
      ? combinedData['workingHours'] as List<dynamic>
      : [];

  final List<String> days = hoursList
      .map<String>((e) => (e is Map && e.containsKey('day')) ? e['day'] as String : "")
      .where((day) => day.isNotEmpty)
      .toList();

  // معالجة location
  GeoPoint location;
  if (combinedData['location'] is GeoPoint) {
    location = combinedData['location'];
  } else if (combinedData['latitude'] != null && combinedData['longitude'] != null) {
    location = GeoPoint(
      (combinedData['latitude'] as num).toDouble(),
      (combinedData['longitude'] as num).toDouble(),
    );
  } else {
    location = const GeoPoint(0, 0);
  }

  // معالجة السعر (ممكن يبقى String أو Number)
  double price = 0.0;
  if (combinedData['price'] is num) {
    price = (combinedData['price'] as num).toDouble();
  } else if (combinedData['price'] is String) {
    price = double.tryParse(combinedData['price']) ?? 0.0;
  }

  return Clinic(
    id: combinedData['clinicId'] ?? combinedData['doctorId'] ?? '',
    name: combinedData['name'] ?? 'No Name',
    doctorName: combinedData['doctorName'] ??
        combinedData['fullName'] ??
        combinedData['name'] ??
        'Unknown Doctor',
    address: combinedData['address'] ?? 'No Location',
    image: combinedData['profileImage'] ?? '',
    rating: (combinedData['rating'] ?? 0.0).toDouble(),
    price: price,
    experience: combinedData['experience'] ?? 'N/A',
    specialty: combinedData['specialization'],
    phoneNumber: combinedData['phone'] ?? '',
    workingHours: hoursList,
    workingDays: days,
    location: location,
  );
}


}