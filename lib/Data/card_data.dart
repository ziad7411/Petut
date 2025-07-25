class CardData {
  final String id;
  final double rate;
  final String image;
  final String title;
  final String description;
  final double weight;
  final int price;
  bool isFavorite;
  int quantity;
  final String category;

  CardData({
    required this.id,
     this.rate = 0,
    required this.image,
    required this.title,
    required this.description,
     this.weight=0,
    required this.price,
    this.isFavorite = false,
    this.quantity = 1,
    this.category = "",
  });
}


