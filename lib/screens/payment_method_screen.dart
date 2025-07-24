import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:petut/Data/globelCartItem.dart';
import 'package:petut/screens/main_screen.dart';
import 'package:petut/screens/payment_screen.dart';
import 'package:petut/widgets/custom_button.dart';

class PaymentMethodScreen extends StatefulWidget {
  final String name;
  final String phone;
  final String address;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final DateTime deliveryTime;

  const PaymentMethodScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.address,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.deliveryTime,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  int? selectedIntegrationId;

 Future<void> saveOrderToFirestore(String paymentMethod) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final firestore = FirebaseFirestore.instance;
  final orderId = firestore.collection('orders').doc().id;

  final orderData = {
    'orderId': orderId,
    'userId': user.uid,
    'deliveryInfo': {
      'name': widget.name,
      'phone': widget.phone,
      'address': widget.address,
      'deliveryTime': DateFormat('yyyy-MM-dd HH:mm').format(widget.deliveryTime),
    },
    'paymentInfo': {
      'subtotal': widget.subtotal,
      'deliveryFee': widget.deliveryFee,
      'total': widget.total,
      'paymentMethod': paymentMethod,
    },
    'products': globalCartItems.map((item) => {
      'name': item.title,
      'price': item.price,
      'quantity': item.quantity,
    }).toList(),
    'timestamp': FieldValue.serverTimestamp(),
    'status': 'pending',
  };

  WriteBatch batch = firestore.batch();

  // اكتب في /orders/{orderId}
  final globalOrderRef = firestore.collection('orders').doc(orderId);
  batch.set(globalOrderRef, orderData);

  // اكتب في /users/{uid}/orders/{orderId}
  final userOrderRef = firestore.collection('users').doc(user.uid).collection('orders').doc(orderId);
  batch.set(userOrderRef, orderData);

  await batch.commit();
}


  void _goToPayment() async {
    if (selectedIntegrationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a payment method.")),
      );
      return;
    }

    String method = (selectedIntegrationId == 5189805) ? 'cash' : 'card';

    await saveOrderToFirestore(method);

    if (method == 'cash') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You will pay with Cash on Delivery.")),
      );
      globalCartItems.clear();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          amount: (widget.total * 100).toInt(),
          name: widget.name,
          phone: widget.phone,
          email: 'example@email.com',
          integrationId: selectedIntegrationId!,
          address: widget.address,
          paymentMethod: method,
          subtotal: widget.subtotal,
          deliveryFee: widget.deliveryFee,
          total: widget.total,
          products: globalCartItems,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Select Payment Method"),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Choose your payment method", style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Card(
              child: RadioListTile<int>(
                value: 5189805,
                groupValue: selectedIntegrationId,
                onChanged: (value) => setState(() => selectedIntegrationId = value),
                title: const Text("💵 Cash on Delivery"),
              ),
            ),
            Card(
              child: RadioListTile<int>(
                value: 5189728,
                groupValue: selectedIntegrationId,
                onChanged: (value) => setState(() => selectedIntegrationId = value),
                title: const Text("💳 Visa / Mastercard"),
              ),
            ),
            const Spacer(),
            CustomButton(
              text: "Proceed to Pay",
              onPressed: _goToPayment,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}