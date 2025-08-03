import 'package:flutter/material.dart';
import 'package:petut/Data/card_data.dart';
import 'package:petut/Data/globelCartItem.dart';
import 'package:petut/screens/cart_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final CardData data;

  const ProductDetailsScreen({super.key, required this.data});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int quantity = 1;

  void _addToCart() {
    final index = globalCartItems.indexWhere((item) => item.id == widget.data.id);
    if (index != -1) {
      // If item exists, just increase quantity
      globalCartItems[index].quantity += quantity;
    } else {
      // Otherwise, add new item
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
          category: widget.data.category,
        ),
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Added to cart!")),
    );
  }

  void _buyNow() {
    _addToCart();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // --- FIX: Corrected the type casting error here ---
    double totalPrice = (widget.data.price * quantity).toDouble();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: theme.iconTheme,
        title: Text(
          widget.data.title,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.network(widget.data.image, height: 180),
            ),
            const SizedBox(height: 12),
            Text(
              widget.data.title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              widget.data.description,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.star, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 4),
                Text('${widget.data.rate}', style: theme.textTheme.bodyMedium),
                const Spacer(),
                const Text("In stock", style: TextStyle(color: Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(label: Text('${widget.data.weight} Kg')),
                const SizedBox(width: 10),
                Text('Code: ${widget.data.id}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (quantity > 1) {
                      setState(() {
                        quantity--;
                      });
                    }
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$quantity', style: theme.textTheme.titleMedium),
                IconButton(
                  onPressed: () {
                    setState(() {
                      quantity++;
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
                const Spacer(),
                Text(
                  '${totalPrice.toStringAsFixed(2)} EGP',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _addToCart,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: BorderSide(color: theme.colorScheme.primary),
                      foregroundColor: theme.colorScheme.primary,
                    ),
                    child: const Text('Add to Cart'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _buyNow,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Buy Now'),
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