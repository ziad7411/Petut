import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Clinic.dart';
import '../app_colors.dart';
import '../widgets/custom_button.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Clinic clinic;
  final String selectedDay;
  final String selectedTime;

  const BookingConfirmationScreen({
    super.key,
    required this.clinic,
    required this.selectedDay,
    required this.selectedTime,
  });

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  String selectedPaymentMethod = "Visa •••• 1234";

  void _changePaymentMethod() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select payment method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text("Visa •••• 1234"),
                onTap: () {
                  setState(() => selectedPaymentMethod = "Visa •••• 1234");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text("MasterCard •••• 5678"),
                onTap: () {
                  setState(() => selectedPaymentMethod = "MasterCard •••• 5678");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text("Vodafone Cash"),
                onTap: () {
                  setState(() => selectedPaymentMethod = "Vodafone Cash");
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmAndPay() async {
    try {
      await FirebaseFirestore.instance.collection('appointments').add({
        'clinicName': widget.clinic.name,
        'clinicPhone': widget.clinic.phoneNumber,
        'clinicLocation': widget.clinic.location,
        'day': widget.selectedDay,
        'time': widget.selectedTime,
        'price': widget.clinic.price,
        'paymentMethod': selectedPaymentMethod,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment confirmed!")),
      );

      Navigator.pop(context); // أو تقدر تروح لصفحة success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Confirm appointment', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        foregroundColor: AppColors.dark,
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
                onPressed: _confirmAndPay,
              ),
            )
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.local_hospital, color: Colors.white, size: 32),
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
                            const Icon(Icons.star, color: AppColors.gold, size: 18),
                            const SizedBox(width: 4),
                            Text("${widget.clinic.rating}/5"),
                            const SizedBox(width: 12),
                            const Icon(Icons.call, size: 18, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(widget.clinic.phoneNumber),
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
                  color: Colors.grey.shade100,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event, color: AppColors.gold),
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
                    const Icon(Icons.timer, size: 20, color: AppColors.gray),
                    const SizedBox(width: 4),
                    const Text("Starts soon")
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer, color: AppColors.gold),
                    const SizedBox(width: 12),
                    const Expanded(child: Text("Apply coupon code\nUnlock offers with coupon code")),
                    TextButton(
                      onPressed: () {},
                      child: const Text("APPLY"),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text("Billing details", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _infoRow("Consultation fee", "${widget.clinic.price} EGP"),
              _infoRow("Service fee & tax", "FREE"),
              _infoRow("Total payable", "${widget.clinic.price} EGP", isBold: true),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "You will get reward points after successful consultation. Learn more",
                  style: TextStyle(fontSize: 13),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Payment method", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(onPressed: _changePaymentMethod, child: const Text("CHANGE")),
                ],
              ),
              Text(selectedPaymentMethod),
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
