import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String> checkUserState() async {
    final user = _auth.currentUser;

    if (user == null) {
      return 'not_logged_in';
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      return 'incomplete_form';
    }

    final data = doc.data();
    final name = data?['fullName'];
    final phone = data?['phone'];
    final role = data?['role'];

    if (name == null || name.isEmpty || phone == null || phone.isEmpty) {
      return 'incomplete_form_${role ?? "unknown"}';
    }

    // لو دكتور → تأكد من وجود بيانات تفصيلية كافية
  if (role == 'doctor') {
  final docSnapshot = await _firestore
      .collection('users')
      .doc(user.uid)
      .get();

  if (!docSnapshot.exists) {
    return 'incomplete_form_doctor';
  }

  final data = docSnapshot.data();
  final doctorDetails = data?['doctorDetails'] as Map<String, dynamic>?;

  final experience = data?['experience'] ?? doctorDetails?['experience'];
  final description = doctorDetails?['description'];
  final profileImage = data?['profileImage'];
  final cardFrontImage = doctorDetails?['cardFrontImage'];
  final cardBackImage = doctorDetails?['cardBackImage'];
  final idImage = doctorDetails?['idImage'];

  if (experience == null || experience.isEmpty ||
      description == null || description.isEmpty ||
      profileImage == null || profileImage.isEmpty ||
      cardFrontImage == null || cardFrontImage.isEmpty ||
      cardBackImage == null || cardBackImage.isEmpty ||
      idImage == null || idImage.isEmpty) {
    return 'incomplete_form_doctor';
  }

  return 'doctor_home';
}



    // لو مش دكتور → روح لصفحة المستخدم
    return 'user_home';
  }
}
