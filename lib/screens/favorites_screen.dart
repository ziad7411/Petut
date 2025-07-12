import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:petut/Common/cards.dart';
import 'package:petut/Data/card_data.dart';
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
        id: data['id'],
        title: data['title'],
        description: data['description'],
        image: data['image'],
        price: data['price'],
        weight: data['weight'],
        rate: 5,
        isFavorite: true,
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
              child: Text(
                "No favorites yet.",
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor),
              ),
            );
          }

          final favs = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: favs.length,
            itemBuilder: (context, index) {
              return Cards(
                data: favs[index],
                favFunction: () {}, // إذا حبيت تحدث الصفحة بعد الإزالة
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailsScreen(data: favs[index]),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
