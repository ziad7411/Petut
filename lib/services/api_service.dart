import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/doctor.dart';

Future<List<Doctor>> fetchDoctors() async {
  const String apiUrl = 'https://jsonplaceholder.typicode.com/users';

  try {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Doctor.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load doctors (${response.statusCode})');
    }
  } catch (e) {
    throw Exception('Failed to load doctors: $e');
  }
}
