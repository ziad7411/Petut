import 'package:flutter/material.dart';
import 'package:petut/Data/card_data.dart';
import 'package:petut/Data/globelCartItem.dart';
import 'package:petut/widgets/custom_button.dart';

class ProductDetailsScreen extends StatefulWidget {
  final CardData data;

  const ProductDetailsScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = theme.textTheme.bodyLarge?.color;
    final totalPrice = widget.data.price * quantity;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          widget.data.title,
          style: theme.textTheme.titleMedium?.copyWith(color: textColor),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.data.image,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.data.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.data.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.orange, size: 20),
                const SizedBox(width: 4),
                Text('${widget.data.rate}', style: theme.textTheme.bodyMedium),
                const Spacer(),
                Text(
                  'In stock',
                  style: TextStyle(color: Colors.green.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text('${widget.data.weight} Kg'),
                  backgroundColor:
                      colorScheme.secondaryContainer.withOpacity(0.2),
                  labelStyle: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 12),
                Text(
                  'Code: ${widget.data.id}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (quantity > 1) setState(() => quantity--);
                  },
                  icon: Icon(Icons.remove_circle_outline, color: textColor),
                ),
                Text('$quantity', style: theme.textTheme.titleMedium),
                IconButton(
                  onPressed: () => setState(() => quantity++),
                  icon: Icon(Icons.add_circle_outline, color: textColor),
                ),
                const Spacer(),
                Text(
                  '${totalPrice.toStringAsFixed(2)} EGP',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Add to Cart',
                    onPressed: () {
                      final index = globalCartItems.indexWhere(
                          (item) => item.id == widget.data.id);
                      if (index != -1) {
                        globalCartItems[index].quantity += quantity;
                      } else {
                        globalCartItems.add(
                          CardData(
                            id: widget.data.id,
                            rate: widget.data.rate,
                            image: widget.data.image,
                            title: widget.data.title,
                            description: widget.data.description,
                            weight: widget.data.weight,
                            price: widget.data.price,
                            isFavorite: widget.data.isFavorite,
                            quantity: quantity,
                          ),
                        );
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Item added to cart")),
                      );
                    },
                    isPrimary: false,
                    icon: const Icon(Icons.shopping_cart_outlined),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Buy Now',
                    onPressed: () {
                      // TODO: Buy‑now logic
                    },
                    isPrimary: true,
                    icon: const Icon(Icons.payment_outlined),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
