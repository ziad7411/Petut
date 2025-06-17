import 'package:flutter/material.dart';
import 'package:petut/Data/card_data.dart';
import 'package:petut/app_colors.dart';

class Cards extends StatefulWidget {
  final CardData data;
  final VoidCallback favFunction;

  const Cards({
    super.key,
    required this.data,
    required this.favFunction,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 6,
        shadowColor: AppColors.gray,
        color: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.gray, width: 2),
        ),
        margin: const EdgeInsets.all(6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.gold, size: 16),
                      Text("${_card.rate}", style: const TextStyle(fontSize: 12)),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _card.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _card.isFavorite ? Colors.red : AppColors.gray,
                        ),
                        onPressed: () {
                          setState(() {
                            _card.isFavorite = !_card.isFavorite;
                          });
                          widget.favFunction();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Center(
                    child: Image.asset(
                      _card.image,
                      height: 60,
                      width: 100,
                      fit: BoxFit.fill,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _card.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.dark,
                    ),
                  ),
                  Text(
                    _card.description,
                    style: TextStyle(fontSize: 11, color: AppColors.gray),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _card.weight != 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                              decoration: BoxDecoration(
                                color: AppColors.fieldColor,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                "${_card.weight}kg",
                                style: TextStyle(fontSize: 12, color: AppColors.dark),
                              ),
                            )
                          : const SizedBox.shrink(),
                      const Spacer(),
                      Text(
                        "${_card.price} \$",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.dark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border.all(color: AppColors.gray),
              ),
              padding: const EdgeInsets.symmetric(vertical: 6),
              alignment: Alignment.center,
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
