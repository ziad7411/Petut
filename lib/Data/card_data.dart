class CardData {
  final String id;
  final double rate;
  final String image;
  final String title;
  final String description;
  final double weight;
  final int price;
  bool isFavorite;

  CardData({
    required this.id,
    required this.rate,
    required this.image,
    required this.title,
    required this.description,
     this.weight=0,
    required this.price,
    this.isFavorite = false,
  });
}


