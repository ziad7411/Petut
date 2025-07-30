import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petut/Data/card_data.dart';
import 'package:petut/Data/globelCartItem.dart';
import 'package:petut/screens/cart_screen.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  Future<void> _reorder(List<dynamic> products, BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart');

    for (var product in products) {
      await cartRef.add({
        'productName': product['productName'],
        'price': product['price'],
        'quantity': product['quantity'],
        'imageURL': product['imageURL'],
        'id': product['id'],
      });
    }

    Navigator.pushNamed(context, '/cart');
  }

  DateTime? _parseDate(dynamic createdAt) {
    if (createdAt is Timestamp) {
      return createdAt.toDate();
    } else if (createdAt is String) {
      try {
        return DateTime.parse(createdAt);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Orders")),
        body: const Center(child: Text("Please login first.")),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("My Orders"),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('orders')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No orders yet."));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderData = orders[index].data() as Map<String, dynamic>;
              final paymentInfo =
                  orderData['paymentInfo'] as Map<String, dynamic>? ?? {};
              final total = (orderData['cart']?['totalAmount'] ?? 0).toDouble();
              final paymentMethod = paymentInfo['paymentMethod'] ?? 'N/A';
              final date = _parseDate(orderData['createdAt']);
              final productList =
                  (orderData['cart']?['items'] as List<dynamic>?) ?? [];

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            date != null
                                ? DateFormat(
                                  'dd MMM yyyy – hh:mm a',
                                ).format(date)
                                : 'Unknown Date',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.payment, size: 18),
                              const SizedBox(width: 4),
                              Text(paymentMethod),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Products
                      Column(
                        children:
                            productList.map((product) {
                              final name = product['productName'] ?? 'Product';
                              final qty = product['quantity'] ?? 1;
                              final price = (product['price'] ?? 0).toDouble();
                              final subtotal = qty * price;
                              final imageUrl = product['imageURL'];

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrl ?? '',
                                        height: 50,
                                        width: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) => const Icon(
                                              Icons.image_not_supported,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "x$qty • ${subtotal.toStringAsFixed(2)} EGP",
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),

                      const SizedBox(height: 12),
                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total: ${total.toStringAsFixed(2)} EGP",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              globalCartItems.clear(); // عشان تبدأ بكارت فاضي

                              for (var product in productList) {
                                globalCartItems.add(
                                  CardData(
                                    id: product['id'],
                                    title: product['productName'],
                                    description: product['description'] ?? '',
                                    image: product['imageURL'],
                                    price: (product['price'] ?? 0).toInt(),
                                    quantity: product['quantity'] ?? 1,
                                    weight: () {
                                      final rawWeight = product['weight'];
                                      if (rawWeight == null ||
                                          rawWeight.toString().trim().isEmpty) {
                                        return "";
                                      }
                                      return rawWeight
                                          .toString()
                                          .replaceAll("g", "")
                                          .trim();
                                    }(),
                                  ),
                                );
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CartScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.shopping_cart_checkout_rounded,
                            ),
                            label: const Text("Buy Again"),
                          ),
                        ],
                      ),
                    ],
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
