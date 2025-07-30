class Product {
  final String id;
  final String name;
  final String details;
  final String image;
  final double rate;
  final double price;
  final String category;
  final String weight;

  Product({
    required this.id,
    required this.name,
    required this.details,
    required this.image,
    required this.rate,
    required this.price,
    required this.category,
    required this.weight
  });

  factory Product.fromFirebase(Map<String, dynamic> json, String id) {
    return Product(
      id: id,
      name: json['productName'] ?? '',
      details: json['description'] ?? '',
      image: json['imageURL'] ?? '',
      rate: double.tryParse(json['rate'].toString()) ?? 0.0,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      category: json['category'] ?? '',
      weight: json['weight'] ?? '',

    );
  }
}
