import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("Please login first.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('order')
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
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final total = (order['total'] ?? 0).toDouble();
              final paymentMethod = order['paymentMethod'] ?? 'N/A';
              final timestamp = order['createdAt'] as Timestamp?;
              final date = timestamp?.toDate();

              final productList = order['products'] as List<dynamic>?;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total: ${total.toStringAsFixed(2)} EGP",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("Payment Method: $paymentMethod"),
                      if (date != null)
                        Text("Date: ${DateFormat('yyyy-MM-dd – HH:mm').format(date)}"),
                      const SizedBox(height: 10),
                      const Divider(),
                      const Text("Products:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      if (productList != null)
                        ...productList.map((product) {
                          final title = product['title'] ?? '';
                          final qty = product['quantity'] ?? 1;
                          final price = (product['price'] ?? 0).toDouble();
                          final subtotal = qty * price;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Text("- $title x$qty = ${subtotal.toStringAsFixed(2)} EGP"),
                          );
                        }).toList(),
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
