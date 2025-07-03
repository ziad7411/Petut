import 'package:flutter/material.dart';
import 'package:petut/Common/cards.dart';
import 'package:petut/Data/Product.dart';
import 'package:petut/Data/fetchProducts.dart';
import 'package:petut/app_colors.dart';
import 'package:petut/Data/card_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petut/screens/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Product>> futureProducts;
  String selectedCategory = 'All';
  Set<String> favoriteIds = {};

  final List<String> categories = ["All", "Cats", "Dogs", "Birds"];

  @override
  void initState() {
    super.initState();
    futureProducts = fetchProducts();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .get();

    setState(() {
      favoriteIds = snapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  List<Product> filterByCategory(List<Product> products, String category) {
    if (category == "All") return products;
    return products.where((p) {
      final lowerName = p.name.toLowerCase();
      if (category == "Cats") return lowerName.contains("cat");
      if (category == "Dogs") return lowerName.contains("dog");
      if (category == "Birds") return lowerName.contains("bird");
      return false;
    }).toList();
  }

  CardData convertProductToCard(Product product) {
    return CardData(
      id: product.id.toString(),
      title: product.name,
      description: product.details,
      image: product.image,
      price: product.price.toInt(),
      rate: product.rate,
      weight: double.tryParse(product.weight.replaceAll("g", "")) != null
          ? double.parse(product.weight.replaceAll("g", "")) / 1000
          : 0,
      isFavorite: favoriteIds.contains(product.id.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Home',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.dark,
          ),
        ),
        actions: [
          iconContainer(
  Icons.search,
  AppColors.gray,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchScreen()),
    );
  },
),
          SizedBox(width: 8),
          iconContainer(Icons.shopping_cart_outlined, AppColors.gold),
          SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: categories.map((category) {
                final isSelected = category == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isSelected ? AppColors.gold : AppColors.fieldColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.dark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: futureProducts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final allProducts = snapshot.data!;
                final filtered = filterByCategory(
                  allProducts,
                  selectedCategory,
                );

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    const itemWidth = 180;
                    final crossAxisCount = (screenWidth / itemWidth)
                        .floor()
                        .clamp(1, 2);

                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 300,
                      ),
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        final cardData = convertProductToCard(product);

                        return Cards(
                          data: cardData,
                          favFunction: () async {
                            await loadFavorites();
                            setState(() {});
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget iconContainer(IconData icon, Color color,{VoidCallback? onTap}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.fieldColor),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18),
        color: color,
        onPressed: onTap,
      ),
    );
  }
}
