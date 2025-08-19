import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petut/app_colors.dart';
import 'package:petut/screens/side_draw.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/custom_button.dart';

class DoctorDashboardPage extends StatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  String doctorName = '';
  bool isLoading = true;
  DateTime? selectedDate;

  final Uri webUrl = Uri.parse('https://petutpetcare.vercel.app/login');

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

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted && doc.exists && doc.data() != null) {
        setState(() {
          doctorName = doc.data()!['doctorName'] ?? '';
        });
      }
    } catch (e) {
      _showErrorSnackBar('Could not fetch doctor details.');
    } finally {
      if (mounted) {
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

  Future<void> _updateStatus(String bookingId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection("bookings")
        .doc(bookingId)
        .update({"status": newStatus});
  }

  String _formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.getBackgroundColor(context);
    final textPrimary = AppColors.getTextPrimaryColor(context);
    final surface = AppColors.getSurfaceColor(context);
    final accent = AppColors.getAccentColor(context);

    return Scaffold(
      backgroundColor: bgColor,
      drawer: const SideDraw(),
      appBar: AppBar(
        title: const Text("Doctor Dashboard"),
        backgroundColor: bgColor,
        elevation: 0,
        foregroundColor: textPrimary,
        automaticallyImplyLeading: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  Text(
                    "Welcome Doctor ${doctorName.isNotEmpty ? doctorName : ''}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 20),

                  CustomButton(
                    text: "Open Web Dashboard",
                    onPressed: _launchWeb,
                  ),
                  const SizedBox(height: 30),

                  // اختيار اليوم
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                    label: Text(selectedDate == null
                        ? "Choose a date"
                        : _formatDate(selectedDate!)),
                  ),

                  const Divider(height: 40),

                  // عرض المواعيد
                  selectedDate == null
                      ? Text("Select a day to view appointments",
                          style: TextStyle(color: textPrimary))
                      : StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("bookings")
                              .where("doctorId",
                                  isEqualTo:
                                      FirebaseAuth.instance.currentUser!.uid)
                              .where("date",
                                  isEqualTo: _formatDate(selectedDate!))
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Text("No bookings for this day",
                                  style: TextStyle(color: textPrimary));
                            }

                            return ListView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: snapshot.data!.docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;

                                return Card(
                                  color: surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  elevation: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "⏰ ${data['time']}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: textPrimary,
                                              ),
                                            ),
                                            Chip(
                                              label: Text(
                                                data['status'],
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors
                                                      .getTextPrimaryColor(
                                                          context),
                                                ),
                                              ),
                                              backgroundColor: data['status'] ==
                                                      "booked"
                                                  ? AppColors.getPrimaryColor(
                                                          context)
                                                      .withOpacity(
                                                          0.2) // Booked
                                                  : data['status'] ==
                                                          "confirmed"
                                                      ? AppColors
                                                              .getAccentColor(
                                                                  context)
                                                          .withOpacity(
                                                              0.2) // Confirmed
                                                      : AppColors
                                                              .getSecondaryColor(
                                                                  context)
                                                          .withOpacity(
                                                              0.2), // Cancelled
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                            "👤 Patient: ${data['customerName']}",
                                            style:
                                                TextStyle(color: textPrimary)),
                                        Text(
                                            "📞 Phone: ${data['customerPhone']}",
                                            style:
                                                TextStyle(color: textPrimary)),
                                        Text("🏥 Clinic: ${data['clinicName']}",
                                            style:
                                                TextStyle(color: textPrimary)),
                                        Text("💵 Price: ${data['price']} EGP",
                                            style:
                                                TextStyle(color: textPrimary)),
                                        Text(
                                            "💳 Payment: ${data['paymentMethod']}",
                                            style:
                                                TextStyle(color: textPrimary)),
                                        const SizedBox(height: 12),

                                        // أزرار التحكم
                                        Row(
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () => _updateStatus(
                                                  doc.id, "confirmed"),
                                              icon: const Icon(Icons.check),
                                              label: const Text("Confirm"),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: accent,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            ElevatedButton.icon(
                                              onPressed: () => _updateStatus(
                                                  doc.id, "cancelled"),
                                              icon: const Icon(Icons.close),
                                              label: const Text("Cancel"),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.red.shade400,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        )
                ],
              ),
            ),
    );
  }
}
