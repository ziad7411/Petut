// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:petut/Data/Product.dart';


Future<List<Product>> fetchProducts() async {
  final response = await http.get(Uri.parse('https://6864317c88359a373e97c861.mockapi.io/API/V1/products'));
  if (response.statusCode == 200) {
    List data = json.decode(response.body);
    return data.map((e) => Product.fromJson(e)).toList();
  } else {
    throw Exception("Failed to load data");
  }
}
