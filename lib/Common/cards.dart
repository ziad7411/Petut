import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:petut/Data/card_data.dart';
import 'package:petut/app_colors.dart';

class Cards extends StatefulWidget {
  final CardData data;
  final VoidCallback favFunction;

  const Cards({super.key, required this.data, required this.favFunction});

  @override
  State<Cards> createState() => _CardsState();
}

class _CardsState extends State<Cards> {
  late CardData _card;

  @override
  void initState() {
    super.initState();
    _card = widget.data;
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Card(
        elevation: 3,
        shadowColor: AppColors.gray,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.gray, width: 1.2),
        ),
        margin: const EdgeInsets.all(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: AppColors.gold, size: 16),
                  const SizedBox(width: 4),
                  Text("${_card.rate}", style: const TextStyle(fontSize: 12)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _card.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _card.isFavorite ? Colors.red : AppColors.gray,
                    ),
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;

                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("You must login to add to favorites"),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final userId = user.uid;
                      final favRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('favorites')
                          .doc(_card.id);

                      bool newState = !_card.isFavorite;

                      // Update Firebase first
                      if (newState) {
                        await favRef.set({
                          'id': _card.id,
                          'title': _card.title,
                          'image': _card.image,
                          'price': _card.price,
                          'description': _card.description,
                          'weight': _card.weight,
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Added to favorites successfully"),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else {
                        await favRef.delete();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Removed from favorites"),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }

                      // Then update UI state
                      setState(() {
                        _card.isFavorite = newState;
                      });

                      widget.favFunction();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Center(
                child: SizedBox(
                  height: 100,
                  width: 100,
                  child: Image.network(_card.image, fit: BoxFit.contain),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _card.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.dark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              Text(
                _card.description,
                style: const TextStyle(fontSize: 11, color: AppColors.gray),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  if (_card.weight != 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.fieldColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${_card.weight} kg",
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    "\$${_card.price}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.dark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.fieldColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
