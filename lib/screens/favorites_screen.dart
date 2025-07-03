import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:petut/Common/cards.dart';
import 'package:petut/Data/card_data.dart';
import 'package:petut/app_colors.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Favorites")),
      body: FutureBuilder<List<CardData>>(
        future: getFavorites(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final favs = snapshot.data!;
          if (favs.isEmpty) return const Center(child: Text("No favorites yet."));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: favs.length,
            itemBuilder: (context, index) {
              return Cards(
                data: favs[index],
                favFunction: () {},
              );
            },
          );
        },
      ),
    );
  }
}
