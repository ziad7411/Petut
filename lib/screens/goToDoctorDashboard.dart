import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/custom_button.dart';
  


class GoToWebPage extends StatefulWidget {
  const GoToWebPage({super.key});

  @override
  State<GoToWebPage> createState() => _GoToWebPageState();
}

class _GoToWebPageState extends State<GoToWebPage> {
  String doctorName = '';
  bool isLoading = true;

  final Uri webUrl = Uri.parse('https://www.youtube.com/');

  @override
  void initState() {
    super.initState();
    _fetchDoctorName();
  }

  Future<void> _fetchDoctorName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && doc.exists && doc.data() != null) {
        setState(() {
          doctorName = doc.data()!['doctorName'] ?? '';
        });
      }
    } catch (e) {
      _showErrorSnackBar('Could not fetch doctor details.');
    } finally {
      if(mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _launchWeb() async {
    try {
      if (!await canLaunchUrl(webUrl)) {
        _showErrorSnackBar('Cannot open the link');
        return;
      }
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showErrorSnackBar('Error occurred while launching: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Doctor Panel"),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Welcome Doctor ${doctorName.isNotEmpty ? doctorName : ''}",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "To manage your services, go to the web panel",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: "Open Web Dashboard",
                      icon: const Icon(Icons.open_in_browser),
                      onPressed: _launchWeb,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}