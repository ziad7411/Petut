import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:petut/Data/globelCartItem.dart';
import 'package:petut/screens/main_screen.dart';
import 'package:petut/screens/payment_screen.dart';

class PaymentMethodScreen extends StatefulWidget {
  final String name;
  final String phone;
  final String address;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final DateTime deliveryTime; // ✅ أضف وقت التوصيل

  const PaymentMethodScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.address,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.deliveryTime, // ✅ أضف هنا
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  int? selectedIntegrationId;

  Future<void> saveOrderToFirestore(String paymentMethod) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final orderData = {
      'deliveryInfo': {
        'name': widget.name,
        'phone': widget.phone,
        'address': widget.address,
        'deliveryTime': DateFormat('yyyy-MM-dd HH:mm').format(widget.deliveryTime), // ✅ احفظ الوقت هنا
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

    final orderId = FirebaseFirestore.instance.collection('orders').doc().id;

    // 1. سجل الأوردر في orders/{userId}/userOrders/{orderId}
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(user.uid)
        .collection('userOrders')
        .doc(orderId)
        .set(orderData);

    // 2. سجل الأوردر كمان في users/{userId}/orders/{orderId}
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .doc(orderId)
        .set(orderData);

    // 3. امسح محتوى السلة
    globalCartItems.clear();
  }

  void _goToPayment() async {
    if (selectedIntegrationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a payment method.")),
      );
      return;
    }

    String method = '';
    if (selectedIntegrationId == 5189805) {
      method = 'cash';
    } else if (selectedIntegrationId == 5189728) {
      method = 'card';
    }

    await saveOrderToFirestore(method);

    if (method == 'cash') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You will pay with Cash on Delivery.")),
      );

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
          deliveryFee: widget.deliveryFee,
          subtotal: widget.subtotal,
          total: widget.total,
          products: globalCartItems,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Payment Method")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            RadioListTile<int>(
              value: 5189805,
              groupValue: selectedIntegrationId,
              onChanged: (value) => setState(() => selectedIntegrationId = value),
              title: const Text("💵 Cash"),
            ),
            RadioListTile<int>(
              value: 5189728,
              groupValue: selectedIntegrationId,
              onChanged: (value) => setState(() => selectedIntegrationId = value),
              title: const Text("💳 Visa / Mastercard"),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _goToPayment,
              child: const Text("Proceed to Pay"),
            ),
          ],
        ),
      ),
    );
  }
}
