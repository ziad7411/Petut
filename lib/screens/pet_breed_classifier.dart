import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import '../app_colors.dart';
import '../widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    _fetchPetsDataViaRest();
  }

  Future<String?> uploadImageToImgbb(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final apiKey = '2929b00fa2ded7b1a8c258df46705a60';
      final url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

      final response = await http.post(url, body: {'image': base64Image});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['url'];
      } else {
        debugPrint('Failed to upload image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> saveResultToFirestore({
    required String breed,
    required double confidence,
    File? imageFile,
  }) async {
    try {
      String imageUrl = '';
      if (imageFile != null) {
        final uploadedUrl = await uploadImageToImgbb(imageFile);
        if (uploadedUrl != null) imageUrl = uploadedUrl;
      }

      await FirebaseFirestore.instance.collection('ai').add({
        'breed': breed,
        'confidence': confidence,
        'image_url': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Result saved to Firestore');
    } catch (e) {
      debugPrint('❌ Error saving to Firestore: $e');
    }
  }

  /// جلب البيانات من Firebase Realtime Database باستخدام REST API
  Future<void> _fetchPetsDataViaRest() async {
    try {
      final url =
          Uri.parse("https://petut-55f40-default-rtdb.firebaseio.com/.json");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ بيانات الحيوانات من Firebase:');
        debugPrint(data.toString());
      } else {
        debugPrint('فشل في جلب البيانات، رمز الحالة: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('حصل خطأ أثناء جلب بيانات Firebase عبر REST: $e');
    }
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter =
          await Interpreter.fromAsset('assets/models/model_unquant.tflite');
      setState(() {
        _isModelLoaded = true;
        _modelStatus = 'Model loaded ✓';
      });
    } catch (e) {
      debugPrint(' Error loading model: $e');
      setState(() {
        _isModelLoaded = false;
        _modelStatus = 'Error loading model: $e';
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
      final bytes = await _selectedImage!.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to read image');

      final resized = img.copyResize(image, width: 224, height: 224);
      final input = _imageToByteListFloat32(resized);

      final output = List.filled(1 * _petLabels.length, 0.0)
          .reshape([1, _petLabels.length]);
      _interpreter!.run(input, output);

      final predictions = output[0] as List<double>;
      final maxIndex = _argmax(predictions);
      final confidence = predictions[maxIndex];

      setState(() {
        if (confidence < 0.3) {
          _result =
              'No pet detected in the image.\nPlease use a clear pet photo.';
          _hasError = true;
        } else {
          _result =
              'Breed: ${_petLabels[maxIndex]}\nConfidence: ${(confidence * 100).toStringAsFixed(1)}%';
          // حفظ النتيجة مع رفع الصورة
          saveResultToFirestore(
            breed: _petLabels[maxIndex],
            confidence: confidence,
            imageFile: _selectedImage,
          );
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

  List _imageToByteListFloat32(img.Image image) {
    return List.generate(
      1,
      (_) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            final pixel = image.getPixel(x, y);
            return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
          },
        ),
      ),
    );
  }

  int _argmax(List<double> list) {
    double max = list[0];
    int index = 0;
    for (int i = 1; i < list.length; i++) {
      if (list[i] > max) {
        max = list[i];
        index = i;
      }
    }
    return index;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        title: Text('Pet Breed Classifier',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(children: [
            // Model status indicator
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
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            // Image picker area
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
                        offset: Offset(0, 5))
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
                            height: double.infinity)),
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
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : null,
              ),
            const SizedBox(height: 30),
            if (_result.isNotEmpty && !_hasError)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== Result Header =====
                    Text(
                      "Analysis Complete",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orangeAccent,
                      ),
                    ),
                    const SizedBox(height: 15),
          
                    // ===== Breed Card =====
                    Card(
                      color: const Color(0xFF1A1A2E),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _result.split("\n")[0], // Breed
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _result.split("\n")[1], // Confidence
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
          
                    const SizedBox(height: 15),
          
                    // ===== Info Card =====
                    Card(
                      color: const Color(0xFF1A1A2E),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Key Information",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _chip("Type", "Dog"),
                                _chip("Lifespan", "10-12 years"),
                                _chip("Energy", "High"),
                                _chip("Friendly", "Yes"),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
          
                    const SizedBox(height: 15),
          
                    // ===== Care Info =====
                    Card(
                      color: const Color(0xFF1A1A2E),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("Care Information",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            SizedBox(height: 8),
                            Text(
                              "America’s most popular dog breed. Extremely social and energetic. Requires daily exercise and mental stimulation.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
          
                    const SizedBox(height: 15),
          
                    // ===== Recommended Products =====
                    Card(
                      color: const Color(0xFF1A1A2E),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Recommended Products",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(height: 10),
                            _productTile("🐾 Fetch toys"),
                            _productTile("❄️ Cooling mat"),
                            _productTile("🥩 Premium dog food"),
                            _productTile("🏃 Running leash"),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _chip(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text("$title: $value",
          style: const TextStyle(color: Colors.white, fontSize: 13)),
    );
  }

  Widget _productTile(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(10),
      ),
      child:
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
    );
  }
}
