import 'package:flutter/material.dart';
import '../models/clinic.dart';
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

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = AppColors.getBackgroundColor(context);
    final Color textPrimary = AppColors.getTextPrimaryColor(context);
    final Color surfaceColor = AppColors.getSurfaceColor(context);
    final Color accentColor = AppColors.getAccentColor(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text('Confirm appointment', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "${widget.clinic.price} EGP",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textPrimary),
              ),
            ),
            Expanded(
              child: CustomButton(
                text: "Confirm and pay",
                onPressed: () {},
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
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.getPrimaryColor(context),
                    child: const Icon(Icons.local_hospital, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.clinic.name,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        Text(widget.clinic.location, style: TextStyle(color: textPrimary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, color: accentColor, size: 18),
                            const SizedBox(width: 4),
                            Text("${widget.clinic.rating}/5", style: TextStyle(color: textPrimary)),
                            const SizedBox(width: 12),
                            const Icon(Icons.call, size: 18, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(widget.clinic.phoneNumber, style: TextStyle(color: textPrimary)),
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
                  color: surfaceColor,
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, color: accentColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Appointment time", style: TextStyle(color: textPrimary)),
                          Text(
                            "${widget.selectedDay}, ${widget.selectedTime}",
                            style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
                          )
                        ],
                      ),
                    ),
                    Icon(Icons.timer, size: 20, color: textPrimary.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text("Starts soon", style: TextStyle(color: textPrimary.withOpacity(0.8)))
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: surfaceColor,
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_offer, color: accentColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Apply coupon code\nUnlock offers with coupon code",
                        style: TextStyle(color: textPrimary),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text("APPLY"),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text("Billing details", style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
              const SizedBox(height: 8),
              _infoRow("Consultation fee", "${widget.clinic.price} EGP", textPrimary),
              _infoRow("Service fee & tax", "FREE", textPrimary),
              _infoRow("Total payable", "${widget.clinic.price} EGP", textPrimary, isBold: true),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "You will get reward points after successful consultation. Learn more",
                  style: TextStyle(fontSize: 13, color: textPrimary),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Payment method", style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
                  TextButton(onPressed: _changePaymentMethod, child: const Text("CHANGE")),
                ],
              ),
              Text(selectedPaymentMethod, style: TextStyle(color: textPrimary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color textColor, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textColor)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: textColor))
        ],
      ),
    );
  }
}
