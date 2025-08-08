import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:io';
import 'dart:convert';
import '../models/Post.dart';
import '../widgets/custom_button.dart';
import '../widgets/edit_image_widget.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;

  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late TextEditingController _contentController;
  late String _selectedTopic;
  File? _selectedImage;
  bool _isLoading = false;
  bool _imageChanged = false;

  final List<String> _topics = ['Adoption', 'Breeding', 'Others'];

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.post.content);
    _selectedTopic = widget.post.topic;
  }



  Future<void> _updatePost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageBase64;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        imageBase64 = base64Encode(bytes);
      }

      final updateData = {
        'content': _contentController.text.trim(),
        'topic': _selectedTopic,
      };

      if (_imageChanged && imageBase64 != null) {
        updateData['imageUrl'] = imageBase64;
      }

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .update(updateData);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Post'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Topic Selection
            const Text('Topic', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _topics.map((topic) {
                final isSelected = _selectedTopic == topic;
                return ChoiceChip(
                  label: Text(topic),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedTopic = topic),
                  selectedColor: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surface,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            // Content Input
            const Text('Content', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Edit your post...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
            const SizedBox(height: 24),
            
            // Image Selection
            EditImageWidget(
              selectedImage: _selectedImage,
              existingImageBase64: widget.post.imageUrl,
              onImageSelected: (image) => setState(() => _selectedImage = image),
              onImageChanged: () => setState(() => _imageChanged = true),
            ),
            const Spacer(),
            
            // Update Button
            CustomButton(
              text: _isLoading ? 'Updating...' : 'Update Post',
              onPressed: _isLoading ? null : _updatePost,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}