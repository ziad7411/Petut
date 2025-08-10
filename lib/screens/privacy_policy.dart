import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Privacy Policy")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("1. Information We Collect",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  "We collect information you provide directly to us, such as when you create an account, book an appointment, or contact us. This may include your name, email address, phone number, and information about your pet."),
              SizedBox(height: 16),

              Text("2. Information We Collect Automatically",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  "When you use our Services, we may automatically collect information about your device and usage, including your IP address, operating system, browser type, and pages you've visited."),
              SizedBox(height: 16),

              Text("3. How We Use Your Information",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  "We use the information we collect to:\n\n• Provide, maintain, and improve our Services.\n• Process transactions and send you related information, including confirmations and invoices.\n• Communicate with you about products, services, offers, and events.\n• Monitor and analyze trends, usage, and activities in connection with our Services.\n• Personalize the Services and provide advertisements, content, or features that match user profiles or interests."),
              SizedBox(height: 16),

              Text("4. How We Share Your Information",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  "We may share your information with third-party vendors and service providers that perform services on our behalf, such as payment processing and data analysis. We may also share information with veterinary clinics and other partners to facilitate bookings and services. We do not sell your personal information to third parties."),
              SizedBox(height: 16),

              Text("5. Data Security",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  "We take reasonable measures to help protect information about you from loss, theft, misuse, and unauthorized access, disclosure, alteration, and destruction."),
              SizedBox(height: 16),

              Text("6. Your Choices",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  "You may update, correct, or delete information about you at any time by logging into your account or contacting us. You may also opt out of receiving promotional emails from us by following the instructions in those emails."),
              SizedBox(height: 16),

              Text("7. Changes to this Policy",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  "We may change this Privacy Policy from time to time. If we make changes, we will notify you by revising the date at the top of the policy and, in some cases, we may provide you with additional notice."),
            ],
          ),
        ),
      ),
    );
  }
}
