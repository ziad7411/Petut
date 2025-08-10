import 'package:flutter/material.dart';
import 'dart:io';
import '../services/image_cropper_service.dart';

class ImagePickerWidget extends StatelessWidget {
  final File? selectedImage;
  final Function(File?) onImageSelected;
  final String buttonText;
  final double height;

  const ImagePickerWidget({
    super.key,
    required this.selectedImage,
    required this.onImageSelected,
    this.buttonText = 'Add & Crop Image',
    this.height = 200,
  });

  Future<void> _pickImage() async {
    final File? croppedImage = await ImageCropperService.pickAndCropImage();
    if (croppedImage != null) {
      onImageSelected(croppedImage);
    }
  }

  Future<void> _editImage() async {
    if (selectedImage == null) return;
    final File? editedImage = await ImageCropperService.cropExistingImage(selectedImage!.path);
    if (editedImage != null) {
      onImageSelected(editedImage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: Text(buttonText),
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
                        onPressed: _editImage,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                        onPressed: () => onImageSelected(null),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}