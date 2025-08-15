import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';
import '../app_colors.dart';
import '../widgets/custom_button.dart';

class PetBreedClassifier extends StatefulWidget {
  const PetBreedClassifier({super.key});

  @override
  State<PetBreedClassifier> createState() => _PetBreedClassifierState();
}

class _PetBreedClassifierState extends State<PetBreedClassifier> {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;
  String _modelStatus = 'Loading model...';

  File? _selectedImage;
  bool _isAnalyzing = false;
  String _result = '';
  bool _hasError = false;

  final List<String> _petLabels = [
    'Golden Retriever',
    'Labrador Retriever',
    'Shih Tzu',
    'Maine Coon',
    'Persian Cat',
    'Ragdoll',
    'Turtle',
    'Hamster'
  ];

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('models/model_unquant.tflite');
      setState(() {
        _isModelLoaded = true;
        _modelStatus = 'Model loaded ✓';
      });
    } catch (_) {
      setState(() {
        _isModelLoaded = false;
        _modelStatus = 'Error loading model';
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _result = '';
          _hasError = false;
        });
      }
    } catch (_) {
      _showError('Error picking image');
    }
  }

  Future<void> _classifyImage() async {
    if (_selectedImage == null || _interpreter == null) {
      _showError('Please select an image and make sure the model is loaded');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _hasError = false;
    });

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('Failed to read image');

      final resized = img.copyResize(image, width: 224, height: 224);
      final input = _imageToByteListFloat32(resized);

      final output = List.filled(1 * _petLabels.length, 0.0)
          .reshape([1, _petLabels.length]);
      _interpreter!.run(input, output);

      final predictions = output[0] as List<double>;
      final maxIndex = _argmax(predictions);
      final maxConfidence = predictions[maxIndex];

      setState(() {
        if (maxConfidence < 0.3) {
          _result =
              'No pet detected in the image.\nPlease use a clear pet photo.';
          _hasError = true;
        } else {
          _result =
              'Breed: ${_petLabels[maxIndex]}\nConfidence: ${(maxConfidence * 100).toStringAsFixed(1)}%';
        }
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _hasError = true;
        _result = 'Error analyzing image: $e';
      });
    }
  }

  Float32List _imageToByteListFloat32(img.Image image) {
    final buffer = Float32List(224 * 224 * 3);
    int index = 0;
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = image.getPixel(x, y);
        buffer[index++] = pixel.r / 255.0;
        buffer[index++] = pixel.g / 255.0;
        buffer[index++] = pixel.b / 255.0;
      }
    }
    return buffer;
  }

  int _argmax(List<double> list) {
    double max = list[0];
    int maxIndex = 0;
    for (int i = 1; i < list.length; i++) {
      if (list[i] > max) {
        max = list[i];
        maxIndex = i;
      }
    }
    return maxIndex;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Pet Breed Classifier',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: _isModelLoaded
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _isModelLoaded ? Colors.green : Colors.orange),
              ),
              child: Text(
                _modelStatus,
                style: TextStyle(
                  color: _isModelLoaded ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.getSurfaceColor(context),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: AppColors.getPrimaryColor(context), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: _selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate,
                              size: 50,
                              color: AppColors.getPrimaryColor(context)),
                          const SizedBox(height: 10),
                          Text('Tap to select image from gallery',
                              style: TextStyle(
                                  color: AppColors.getPrimaryColor(context),
                                  fontWeight: FontWeight.bold)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.file(_selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            if (_selectedImage != null)
              CustomButton(
                text: 'Analyze Image',
                onPressed:
                    _isModelLoaded && !_isAnalyzing ? _classifyImage : null,
                width: double.infinity,
                height: 50,
                customColor: AppColors.getPrimaryColor(context),
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : null,
              ),
            const SizedBox(height: 30),
            if (_result.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _hasError
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border:
                      Border.all(color: _hasError ? Colors.red : Colors.green),
                ),
                child: Column(
                  children: [
                    Icon(
                        _hasError
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        size: 40,
                        color: _hasError ? Colors.red : Colors.green),
                    const SizedBox(height: 10),
                    Text(_hasError ? 'Error' : 'Result',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _hasError ? Colors.red : Colors.green)),
                    const SizedBox(height: 10),
                    Text(_result,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            color: _hasError
                                ? Colors.red[700]
                                : Colors.green[700])),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}


