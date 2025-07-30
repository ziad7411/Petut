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
      final detailsSnap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('doctorsDetails')
          .limit(1)
          .get();

      if (detailsSnap.docs.isEmpty) {
        return 'incomplete_form_doctor';
      }

      final details = detailsSnap.docs.first.data();
      final experience = details['experience'];
      final description = details['description'];
      final socialMedia = details['socialMedia'];
      final profileImage = details['profileImage'];
      final cardFrontImage = details['cardFrontImage'];
      final cardBackImage = details['cardBackImage'];
      final idImage = details['idImage'];

      if (experience == null || experience.isEmpty ||
          description == null || description.isEmpty ||
          socialMedia == null ||
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
