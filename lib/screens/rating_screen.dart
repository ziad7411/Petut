import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class RatingScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String bookingId;

  const RatingScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.bookingId,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double _rating = 0;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get user data for username
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final username = userData['name'] ?? userData['doctorName'] ?? 'Unknown User';

      // Add rating to ratings collection
      await FirebaseFirestore.instance.collection('ratings').add({
        'doctorId': widget.doctorId,
        'userId': user.uid,
        'username': username,
        'bookingId': widget.bookingId,
        'rating': _rating,
        'comment': _commentController.text.trim().isEmpty 
            ? null 
            : _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update booking status to rated
      await FirebaseFirestore.instance
          .collection('booking')
          .doc(widget.bookingId)
          .update({'status': 'rated'});

      // Update doctor's average rating
      await _updateDoctorRating();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateDoctorRating() async {
    // Get all ratings for this doctor
    final ratingsSnapshot = await FirebaseFirestore.instance
        .collection('ratings')
        .where('doctorId', isEqualTo: widget.doctorId)
        .get();

    if (ratingsSnapshot.docs.isNotEmpty) {
      double totalRating = 0;
      for (var doc in ratingsSnapshot.docs) {
        totalRating += (doc.data()['rating'] as num).toDouble();
      }
      
      final averageRating = totalRating / ratingsSnapshot.docs.length;
      final totalReviews = ratingsSnapshot.docs.length;

      // Update doctor's rating in users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.doctorId)
          .update({
        'rating': averageRating,
        'totalReviews': totalReviews,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Rate Doctor'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How was your experience with Dr. ${widget.doctorName}?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // Star Rating
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => _rating = index + 1.0),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: theme.colorScheme.primary,
                      size: 40,
                    ),
                  );
                }),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Comment Field
            CustomTextField(
              hintText: 'Write your review (optional)',
              controller: _commentController,
              maxLines: 4,
              prefixIcon: Icons.comment,
            ),
            
            const Spacer(),
            
            // Submit Button
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(
                    text: 'Submit Rating',
                    onPressed: _submitRating,
                    width: double.infinity,
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}