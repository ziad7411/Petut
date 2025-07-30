// services/api_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petut/Data/Product.dart';

Future<List<Product>> fetchProducts() async {
  try {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('products').get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Product.fromFirebase(data, doc.id);
    }).toList();
  } catch (e) {
    throw Exception("Failed to load products from Firebase: $e");
  }
}
