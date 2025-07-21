import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petut/Data/globelCartItem.dart';

Future<void> saveOrderToFirestore({
  required String method,
  required double subtotal,
  required double deliveryFee,
  required double total,
}) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) return;

  final orderData = {
    'userId': userId,
    'paymentMethod': method,
    'timestamp': Timestamp.now(),
    'products': globalCartItems.map((item) => {
      'title': item.title,
      'price': item.price,
      'quantity': item.quantity,
      'image': item.image,
    }).toList(),
    'subtotal': subtotal,
    'deliveryFee': deliveryFee,
    'total': total,
    'status': 'pending',
  };

  // ✅ تخزين الأوردر في: users/{uid}/order
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('order')
      .add(orderData);

  // 🧹 تفريغ الكارت بعد الحفظ
  globalCartItems.clear();
}
