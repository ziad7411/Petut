import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:petut/Data/card_data.dart';

class Cards extends StatefulWidget {
  final CardData data;
  final VoidCallback favFunction;
  final VoidCallback onTap;
  final VoidCallback onCartTap;

  const Cards({
    super.key,
    required this.data,
    required this.favFunction,
    required this.onTap,
    required this.onCartTap,
  });

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
    final theme = Theme.of(context);

    return InkWell(
      onTap: widget.onTap,
      child: IntrinsicHeight(
        child: Card(
          elevation: 4,
          shadowColor: theme.shadowColor,
          color: theme.cardColor,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.dividerColor, width: 1.2),
          ),
          margin: const EdgeInsets.all(6),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Top Row (rating and favorite)
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: theme.colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text("${_card.rate}", style: const TextStyle(fontSize: 12)),
                    const Spacer(),
                      IconButton(
                        icon: Icon(
                          _card.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              _card.isFavorite
                                  ? Colors.red
                                  : theme.iconTheme.color,
                        ),
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;

                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "You must login to add to favorites",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            Navigator.pushNamed(context, '/login');
                            return;
                          }

                          final userId = user.uid;
                          final favRef = FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('favorites')
                              .doc(_card.id);

                          final newState = !_card.isFavorite;

                          if (newState) {
                            await favRef.set({
                              'id': _card.id,
                              'title': _card.title,
                              'image': _card.image,
                              'price': _card.price,
                              'description': _card.description,
                              'weight': _card.weight,
                              'category': _card.category,
                              'rate': _card.rate,
                              
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

                          setState(() {
                            _card.isFavorite = newState;
                          });

                          widget.favFunction();
                        },
                      ),
                    ],
                  ),

                const SizedBox(height: 6),

                /// Product image
                Center(
                  child: SizedBox(
                    height: 100,
                    width: 100,
                    child: Image.network(_card.image, fit: BoxFit.contain),
                  ),
                ),

                const SizedBox(height: 8),

                /// Title
                Text(
                  _card.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.textTheme.bodyLarge!.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                /// Description
                Text(
                  _card.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textTheme.bodySmall!.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                /// Weight and price
                Row(
                  children: [
                    if (_card.weight != 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${_card.weight} kg",
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textTheme.bodyMedium!.color,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      "\$${_card.price}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.textTheme.bodyLarge!.color,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                /// Cart button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      widget.onCartTap();
                    },
                    child: Container(
                      width: double.infinity,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
