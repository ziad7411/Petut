import 'dart:convert'; // <-- إضافة مهمة لعرض الصورة
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:petut/screens/booking_loading_screen.dart';
import '../models/Clinic.dart';
import '../widgets/custom_button.dart';
import './Signup&Login/login_screen.dart';

enum PaymentMethodType { card, cash }

class BookingConfirmationScreen extends StatefulWidget {
  final Clinic clinic;
  final String selectedDay;
  final String selectedTime;
  final DateTime selectedDate;

  const BookingConfirmationScreen({
    super.key,
    required this.clinic,
    required this.selectedDay,
    required this.selectedTime,
    required this.selectedDate,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  PaymentMethodType _selectedPaymentMethod = PaymentMethodType.card;

  // ============= التعديل رقم 1: إضافة هذه الدالة المساعدة =============
  ImageProvider? _getImageProvider(String? imageBase64) {
    if (imageBase64 == null || imageBase64.isEmpty) {
      return const AssetImage('assets/images/default_avatar.png'); // تأكد من وجود صورة افتراضية
    }
    try {
      final bytes = base64Decode(imageBase64);
      return MemoryImage(bytes);
    } catch (e) {
      print("Error decoding image: $e");
      return const AssetImage('assets/images/default_avatar.png');
    }
  }
  // =================================================================

  String get _selectedPaymentMethodText {
    switch (_selectedPaymentMethod) {
      case PaymentMethodType.card:
        return "Visa / Mastercard";
      case PaymentMethodType.cash:
        return "Cash on arrival";
    }
  }

  void _changePaymentMethod() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select payment method",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  RadioListTile<PaymentMethodType>(
                    title: const Text("💳 Visa / Mastercard"),
                    value: PaymentMethodType.card,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedPaymentMethod = value);
                        Navigator.pop(context);
                      }
                    },
                  ),
                  RadioListTile<PaymentMethodType>(
                    title: const Text("💵 Cash on arrival"),
                    value: PaymentMethodType.cash,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedPaymentMethod = value);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmBooking() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookingLoadingScreen()),
    );

    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      final userData = userDoc.data() ?? {};
      final customerName = userData['fullName'] ?? 'Unknown Customer';
      final customerPhone = userData['phone'] ?? '';
      final customerEmail = user.email ?? '';

      final formattedDate = DateFormat('yyyy-MM-dd').format(widget.selectedDate);

      DocumentReference bookingRef =
          await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user.uid,
        'clinicId': widget.clinic.id,
        'doctorId': widget.clinic.id,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerEmail': customerEmail,
        'date': formattedDate,
        'time': widget.selectedTime,
        'clinicName': widget.clinic.name,
        'doctorName': widget.clinic.doctorName,
        'price': widget.clinic.price,
        'paymentMethod': _selectedPaymentMethodText,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'booked',
      });

      await bookingRef.update({
        'bookingId': bookingRef.id,
      });
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Booking failed: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: const Text('Confirm appointment',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "${widget.clinic.price} EGP",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            Expanded(
              child: CustomButton(
                text: "Confirm and pay",
                onPressed: _confirmBooking,
              ),
            )
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    // ============= التعديل رقم 2: استخدام الدالة الجديدة =============
                    backgroundImage: _getImageProvider(widget.clinic.image),
                    onBackgroundImageError: (exception, stackTrace) {},
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.clinic.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        // ============= التعديل رقم 3: استخدام العنوان النصي =============
                        Text(widget.clinic.address),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star,
                                color: theme.colorScheme.primary, size: 18),
                            const SizedBox(width: 4),
                            Text("${widget.clinic.rating}/5"),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surface,
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Appointment time"),
                          Text(
                            "${widget.selectedDay}, ${widget.selectedTime}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text("Billing details",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _infoRow("Consultation fee", "${widget.clinic.price} EGP"),
              _infoRow("Service fee & tax", "FREE"),
              _infoRow("Total payable", "${widget.clinic.price} EGP",
                  isBold: true),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Payment method",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: _changePaymentMethod,
                    child: const Text("CHANGE"),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Text(_selectedPaymentMethodText),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal))
        ],
      ),
    );
  }
}