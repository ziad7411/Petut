import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Terms of Service")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("1. Introduction",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  "Welcome to PET.CARE! These Terms of Service (\"Terms\") govern your use of our website, mobile application, and the services we offer (collectively, the \"Services\"). By creating an account or using our Services, you agree to be bound by these Terms."),
              SizedBox(height: 16),

              Text("2. Services Provided",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  "PET.CARE provides a platform to connect pet owners with veterinary clinics, pet supply stores, and other pet-related services. This includes booking appointments, purchasing products, and accessing information. We are a platform provider and are not responsible for the services rendered by third-party clinics or vendors."),
              SizedBox(height: 16),

              Text("3. User Accounts",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  "To access most features, you must register for an account. You agree to provide accurate, current, and complete information during the registration process. You are responsible for safeguarding your password and for all activities that occur under your account."),
              SizedBox(height: 16),

              Text("4. User Conduct",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  "You agree not to use the Services for any unlawful purpose or in any way that could harm our platform, our users, or third parties. This includes, but is not limited to, harassment, uploading malicious content, and attempting to gain unauthorized access to our systems."),
              SizedBox(height: 16),

              Text("5. Bookings and Payments",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  "When you book a service or purchase a product through PET.CARE, you are entering into an agreement directly with the third-party provider. All payments are processed through our secure payment gateway. Please review the cancellation and refund policies of the specific vendor before making a purchase."),
              SizedBox(height: 16),

              Text("6. Limitation of Liability",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  "To the fullest extent permitted by law, PET.CARE shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of profits or revenues, whether incurred directly or indirectly, or any loss of data, use, goodwill, or other intangible losses, resulting from your use of our Services."),
              SizedBox(height: 16),

              Text("7. Changes to Terms",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  "We may modify these Terms at any time. We will provide notice of any significant changes. Your continued use of the Services after such changes constitutes your acceptance of the new Terms."),
            ],
          ),
        ),
      ),
    );
  }
}
