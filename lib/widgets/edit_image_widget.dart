import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import '../services/image_cropper_service.dart';

class EditImageWidget extends StatelessWidget {
  final File? selectedImage;
  final String? existingImageBase64;
  final Function(File?) onImageSelected;
  final Function() onImageChanged;
  final double height;

  const EditImageWidget({
    super.key,
    required this.selectedImage,
    required this.existingImageBase64,
    required this.onImageSelected,
    required this.onImageChanged,
    this.height = 200,
  });

  Future<void> _pickNewImage() async {
    final File? croppedImage = await ImageCropperService.pickAndCropImage();
    if (croppedImage != null) {
      onImageSelected(croppedImage);
      onImageChanged();
    }
  }

  Future<void> _editCurrentImage() async {
    File? imageToEdit;
    
    if (selectedImage != null) {
      imageToEdit = selectedImage;
    } else if (existingImageBase64 != null) {
      final bytes = base64Decode(existingImageBase64!);
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(bytes);
      imageToEdit = tempFile;
    }
    
    if (imageToEdit != null) {
      final File? editedImage = await ImageCropperService.cropExistingImage(imageToEdit.path);
      if (editedImage != null) {
        onImageSelected(editedImage);
        onImageChanged();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              onPressed: _pickNewImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('New Image'),
            ),
          ],
        ),
        if (selectedImage != null) ...[
          const SizedBox(height: 8),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  selectedImage!,
                  height: height,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                        onPressed: _editCurrentImage,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                        onPressed: () {
                          onImageSelected(null);
                          onImageChanged();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ] else if (existingImageBase64 != null) ...[
          const SizedBox(height: 8),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  base64Decode(existingImageBase64!),
                  height: height,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                    onPressed: _editCurrentImage,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}