class Product {
  final String id;
  final String name;
  final double price;
  final double rate;
  final String weight;
  final String details;
  final String category;
  final String brand;
  final String image;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.rate,
    required this.weight,
    required this.details,
    required this.category,
    required this.brand,
    required this.image,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'],
      price: json['price'] * 1.0,
      rate: json['rate'] * 1.0,
      weight: json['weight'],
      details: json['details'],
      category: json['category'],
      brand: json['brand'],
      image: json['image'],
    );
  }
}
