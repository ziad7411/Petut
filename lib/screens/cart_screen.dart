import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petut/Data/globelCartItem.dart';
import 'package:petut/screens/Signup&Login/login_screen.dart';
import 'package:petut/screens/delivery_screen.dart';
import 'package:petut/widgets/custom_button.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  double get totalPrice {
    return globalCartItems.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  void increaseQty(int index) {
    setState(() {
      globalCartItems[index].quantity++;
    });
  }

  void decreaseQty(int index) {
    setState(() {
      if (globalCartItems[index].quantity > 1) {
        globalCartItems[index].quantity--;
      } else {
        globalCartItems.removeAt(index);
      }
    });
  }

  void removeItem(int index) {
    setState(() {
      globalCartItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Cart'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          if (globalCartItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Text(
                    "Items in Cart: ${globalCartItems.fold<int>(0, (sum, item) => sum + item.quantity)}",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: globalCartItems.isEmpty
                ? Center(
                    child: Text(
                      "Cart is empty",
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    itemCount: globalCartItems.length,
                    itemBuilder: (context, index) {
                      final item = globalCartItems[index];
                      return Card(
                        margin:
                            const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.image,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(item.description,
                                        style: theme.textTheme.bodyMedium),
                                    const SizedBox(height: 4),
                                    Text("Weight: ${item.weight} Kg",
                                        style: theme.textTheme.bodyMedium),
                                    Text("Unit Price: ${item.price} EGP",
                                        style: theme.textTheme.bodyMedium),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () => decreaseQty(index),
                                          icon: const Icon(Icons.remove),
                                        ),
                                        Text("${item.quantity}",
                                            style: theme.textTheme.bodyMedium),
                                        IconButton(
                                          onPressed: () => increaseQty(index),
                                          icon: const Icon(Icons.add),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    onPressed: () => removeItem(index),
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                  ),
                                  Text(
                                    "${item.price * item.quantity} EGP",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (globalCartItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    "Total: ${totalPrice.toStringAsFixed(2)} EGP",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: "Proceed to Delivery",
                    onPressed: () {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DeliveryScreen( subtotal: totalPrice,),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
