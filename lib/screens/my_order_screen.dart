import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

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
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('orders') // Corrected collection name
            .orderBy('timestamp', descending: true) // Corrected field name
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
            padding: const EdgeInsets.all(8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderData = orders[index].data() as Map<String, dynamic>;
              final deliveryInfo = orderData['deliveryInfo'] as Map<String, dynamic>? ?? {};
              final paymentInfo = orderData['paymentInfo'] as Map<String, dynamic>? ?? {};
              
              final total = (paymentInfo['total'] ?? 0).toDouble();
              final paymentMethod = paymentInfo['paymentMethod'] ?? 'N/A';
              final timestamp = orderData['timestamp'] as Timestamp?;
              final date = timestamp?.toDate();

              final productList = orderData['products'] as List<dynamic>?;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                elevation: 2,
                shadowColor: Colors.black.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total: ${total.toStringAsFixed(2)} EGP",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text("Payment Method: $paymentMethod"),
                      if (date != null)
                        Text("Date: ${DateFormat('yyyy-MM-dd – HH:mm').format(date)}"),
                      const SizedBox(height: 10),
                      const Divider(),
                      const Text("Products:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      if (productList != null)
                        ...productList.map((product) {
                          final name = product['name'] ?? 'Unknown Product';
                          final qty = product['quantity'] ?? 1;
                          final price = (product['price'] ?? 0).toDouble();
                          final subtotal = qty * price;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Text("- $name x$qty = ${subtotal.toStringAsFixed(2)} EGP"),
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