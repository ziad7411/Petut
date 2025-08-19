// services/api_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petut/Data/Product.dart';

// 🛑 كاش داخلي (هيفضل طول ما الأبلكيشن شغال)
List<Product>? _cachedProducts;

Future<List<Product>> fetchProducts({bool forceRefresh = false}) async {
  try {
    // ✅ لو عندنا كاش ومش طالب refresh نرجع الداتا المخزنة
    if (_cachedProducts != null && !forceRefresh) {
      return _cachedProducts!;
    }

    // 🟢 غير كده نجيبها من Firebase
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('products').get();

    final products = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Product.fromFirebase(data, doc.id);
    }).toList();

    // نخزنها في الكاش
    _cachedProducts = products;

    return products;
  } catch (e) {
    throw Exception("Failed to load products from Firebase: $e");
  }
}
