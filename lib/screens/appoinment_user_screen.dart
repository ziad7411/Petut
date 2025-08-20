import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserBookingsScreen extends StatelessWidget {
  const UserBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text("User data not found")));
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final status = userData['status'] ?? 'pending';
        final doctorName = userData['fullName'] ?? 'Doctor';

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            automaticallyImplyLeading: false, // 🔹 يشيل زرار الرجوع
            title: Text("Welcome Doctor $doctorName"),
            backgroundColor: theme.scaffoldBackgroundColor,
            foregroundColor: theme.colorScheme.primary,
            elevation: 0,
          ),
          body: _buildBodyByStatus(theme, status, doctorName),
        );
      },
    );
  }

  Widget _buildBodyByStatus(ThemeData theme, String status, String doctorName) {
    if (status == 'approved') {
      // ✅ Approved → Show bookings
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No bookings found.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            );
          }

          final bookings = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final data = bookings[index].data() as Map<String, dynamic>;
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['clinicName'] ?? 'Unknown Clinic',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text("Doctor: ${data['doctorName']}", style: theme.textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text("Date: ${data['date']} at ${data['time']}",
                              style: theme.textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.verified, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text("Status: ${data['status']}", style: theme.textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.payment, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text("Payment: ${data['paymentMethod']}", style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } else if (status == 'pending') {
      // 🟠 Pending → Nice design
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_top, size: 80, color: Colors.orange.shade700),
            const SizedBox(height: 20),
            Text(
              "Hello Dr. $doctorName",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Your account is still under review.\nPlease wait for approval.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
            ),
          ],
        ),
      );
    } else if (status == 'rejected') {
      // 🔴 Rejected → Stylish message
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel, size: 80, color: Colors.red.shade700),
            const SizedBox(height: 20),
            Text(
              "Hello Dr. $doctorName",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Your account request was rejected.\nPlease contact support.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }

    return const Center(child: Text("Unknown status"));
  }
}
