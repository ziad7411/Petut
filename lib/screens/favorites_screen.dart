import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:petut/Common/cards.dart';
import 'package:petut/Data/card_data.dart';
import 'package:petut/Data/globelCartItem.dart';
import 'package:petut/screens/product_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Future<List<CardData>> getFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return CardData(
        id: data['id'] ?? '',
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        image: data['image'] ?? '',
        price: (data['price'] ?? 0).toDouble(),
        weight: data['weight'] ?? '',
        rate: (data['rate'] ?? 5).toDouble(),
        isFavorite: true,
        category: data['category'] ?? '',
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          "Favorites",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        iconTheme: IconThemeData(color: theme.iconTheme.color),
      ),
      body: FutureBuilder<List<CardData>>(
        future: getFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 80, color: theme.hintColor),
                  const SizedBox(height: 12),
                  Text(
                    "No favorites yet.",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.hintColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final favs = snapshot.data!;

          return ListView.builder(
            
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: favs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Cards(
                    data: favs[index],
                    favFunction: () {},
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductDetailsScreen(data: favs[index]),
                        ),
                      );
                    },
                    onCartTap: () {
                      final selectedProduct = favs[index];
                      final indexInCart = globalCartItems.indexWhere(
                        (item) => item.id == selectedProduct.id,
                      );

                      if (indexInCart >= 0) {
                        globalCartItems[indexInCart].quantity++;
                      } else {
                        globalCartItems.add(
                          CardData(
                            id: selectedProduct.id,
                            title: selectedProduct.title,
                            description: selectedProduct.description,
                            image: selectedProduct.image,
                            price: selectedProduct.price,
                            weight: selectedProduct.weight,
                            rate: selectedProduct.rate,
                            isFavorite: selectedProduct.isFavorite,
                            quantity: 1,
                            category: selectedProduct.category,
                          ),
                        );
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Added to cart")),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
