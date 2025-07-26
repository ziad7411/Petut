import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:petut/screens/booking_loading_screen.dart';
import '../models/Clinic.dart';
import '../widgets/custom_button.dart';

// Enum to manage payment method state
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
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  // Use the enum for state, default to card payment
  PaymentMethodType _selectedPaymentMethod = PaymentMethodType.card;

  // Helper getter to display the correct text for the selected payment method
  String get _selectedPaymentMethodText {
    switch (_selectedPaymentMethod) {
      case PaymentMethodType.card:
        return "Visa / Mastercard";
      case PaymentMethodType.cash:
        return "Cash on arrival";
    }
  }

  // REFACTORED: This function now shows a bottom sheet with radio buttons for payment selection.
  void _changePaymentMethod() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Use StatefulBuilder to manage the state within the modal sheet
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select payment method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  RadioListTile<PaymentMethodType>(
                    title: const Text("💳 Visa / Mastercard"),
                    value: PaymentMethodType.card,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      if (value != null) {
                        // Update the state on the main screen
                        setState(() {
                          _selectedPaymentMethod = value;
                        });
                        // Close the modal
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
                        setState(() {
                          _selectedPaymentMethod = value;
                        });
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
    // Navigate to your custom loading screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookingLoadingScreen()),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("You must be logged in to book.");
      }

      final formattedDate = DateFormat('yyyy-MM-dd').format(widget.selectedDate);

      await FirebaseFirestore.instance.collection('bookings').add({
        'doctorId': widget.clinic.id,
        'userId': user.uid,
        'date': formattedDate,
        'time': widget.selectedTime,
        'clinicName': widget.clinic.name,
        'doctorName': widget.clinic.name,
        'price': widget.clinic.price,
        // Save the selected payment method's display text
        'paymentMethod': _selectedPaymentMethodText,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'booked',
      });

    } catch (e) {
      if (mounted) {
        // Pop the loading screen to show the error on the confirmation screen
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
        title: const Text('Confirm appointment', style: TextStyle(fontWeight: FontWeight.bold)),
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                    backgroundImage: NetworkImage(widget.clinic.image),
                    onBackgroundImageError: (exception, stackTrace) {},
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.clinic.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(widget.clinic.location),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, color: theme.colorScheme.primary, size: 18),
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
              const Text("Billing details", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _infoRow("Consultation fee", "${widget.clinic.price} EGP"),
              _infoRow("Service fee & tax", "FREE"),
              _infoRow("Total payable", "${widget.clinic.price} EGP", isBold: true),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Payment method", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                      onPressed: _changePaymentMethod,
                      child: const Text("CHANGE"),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      ),
                  ),
                ],
              ),
              // Display the text of the selected payment method
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
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal))
        ],
      ),
    );
  }
}