import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:petut/Data/card_data.dart';
import 'package:url_launcher/url_launcher.dart';
import 'order_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final int amount;
  final String name;
  final String phone;
  final String email;
  final int integrationId;
  final String address;
  final String paymentMethod;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final List<CardData> products;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.name,
    required this.phone,
    required this.email,
    required this.integrationId,
    required this.address,
    required this.paymentMethod,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.products,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final String apiKey = 'ZXlKaGJHY2lPaUpJVXpVeE1pSXNJblI1Y0NJNklrcFhWQ0o5LmV5SmpiR0Z6Y3lJNklrMWxjbU5vWVc1MElpd2ljSEp2Wm1sc1pWOXdheUk2TVRBMk1EUTROQ3dpYm1GdFpTSTZJbWx1YVhScFlXd2lmUS5oR3JuSHhNTHZud282VmczdFFkNWFmOGx3X3lYamNsRkNvSnBJRWVTRE16dDhNQ25tVlJ5M1hQd2cyVDNWQVY3X0xaS0c1YmIwSDgtU0J5Z05fcGtOUQ==';
  final String iframeId = '940025';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    startPaymentFlow();
  }

  Future<void> startPaymentFlow() async {
    try {
      final authRes = await http.post(
        Uri.parse('https://accept.paymob.com/api/auth/tokens'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'api_key': apiKey}),
      );
      final authToken = jsonDecode(authRes.body)['token'];

      final orderRes = await http.post(
        Uri.parse('https://accept.paymob.com/api/ecommerce/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'auth_token': authToken,
          'delivery_needed': false,
          'amount_cents': widget.amount,
          'currency': 'EGP',
          'items': [],
        }),
      );
      final orderId = jsonDecode(orderRes.body)['id'];

      final paymentRes = await http.post(
        Uri.parse('https://accept.paymob.com/api/acceptance/payment_keys'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'auth_token': authToken,
          'amount_cents': widget.amount,
          'expiration': 3600,
          'order_id': orderId,
          'billing_data': {
            "apartment": "NA",
            "email": widget.email,
            "floor": "NA",
            "first_name": widget.name,
            "street": "NA",
            "building": "NA",
            "phone_number": widget.phone,
            "shipping_method": "NA",
            "postal_code": "NA",
            "city": "NA",
            "country": "NA",
            "last_name": widget.name,
            "state": "NA"
          },
          'currency': 'EGP',
          'integration_id': widget.integrationId,
        }),
      );
      final paymentKey = jsonDecode(paymentRes.body)['token'];

      final finalUrl =
          'https://accept.paymob.com/api/acceptance/iframes/$iframeId?payment_token=$paymentKey';

      if (await canLaunchUrl(Uri.parse(finalUrl))) {
        await launchUrl(Uri.parse(finalUrl), mode: LaunchMode.externalApplication);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const OrderSuccessScreen(),
            ),
          );
        }
      } else {
        throw 'Could not launch payment URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Processing Payment..."),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : const Text("Redirecting to payment..."),
      ),
    );
  }
}