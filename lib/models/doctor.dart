class Doctor {
  final int id;
  final String name;
  final String specialty;
  final double rating;
  final int yearsOfExperience;
  final int price;
  final String image;

  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.yearsOfExperience,
    required this.price,
    required this.image,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'No Name',
      specialty: json['specialty'] ?? 'No Specialty',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      yearsOfExperience: json['yearsOfExperience'] ?? 0,
      price: json['price'] ?? 0,
      image: json['image'] ?? '',
    );
  }
}
