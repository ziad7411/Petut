class CardData {
  final String id;
  final double rate;
  final String image;
  final String title;
  final String description;
  final double price;
  bool isFavorite;
  int quantity;
  final String category;
  final String? weight; 

  CardData({
    required this.id,
    this.rate = 0,
    required this.image,
    required this.title,
    required this.description,
    required this.price,
    this.isFavorite = false,
    this.quantity = 1,
    this.category = "",
    this.weight,
  });

  factory CardData.fromFirebase(Map<String, dynamic> json, String id) {
    return CardData(
      id: id,
      rate: double.tryParse(json['rate'].toString()) ?? 0,
      image: json['imageURL'] ?? '',
      title: json['productName'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0,
      category: json['category'] ?? '',
      weight: json['weight'] ?? '',
    );
  }
}
