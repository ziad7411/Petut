// screens/doctors_list_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import './clinic_details_screen.dart';
import '../models/Clinic.dart';

// كلاس مساعد لتخزين العيادة والمسافة معًا
class ClinicWithDistance {
  final Clinic clinic;
  final double? distance;

  ClinicWithDistance({required this.clinic, this.distance});
}

class ClinicsScreen extends StatefulWidget {
  const ClinicsScreen({super.key});

  @override
  State<ClinicsScreen> createState() => _ClinicsScreenState();
}

class _ClinicsScreenState extends State<ClinicsScreen> {
  LatLng? userLocation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'distance'; // الترتيب الافتراضي
  double _minRating = 0.0;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    // ... (هذه الدالة صحيحة ولا تحتاج لتعديل)
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);

      if (mounted) {
        setState(() {
          userLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch(e) {
      print('Location error: $e');
    }
  }

  ImageProvider? _getImageProvider(String? imageBase64) {
    // ... (هذه الدالة صحيحة ولا تحتاج لتعديل)
    if (imageBase64 == null || imageBase64.isEmpty) return null;
    try {
      final bytes = base64Decode(imageBase64);
      return MemoryImage(bytes);
    } catch (e) {
      return null;
    }
  }

  // دالة لجلب البيانات الكاملة لعيادة واحدة
  Future<ClinicWithDistance?> _fetchClinicData(DocumentSnapshot clinicDoc) async {
    final clinicData = clinicDoc.data() as Map<String, dynamic>;
    final doctorId = clinicData['doctorId'];
    if (doctorId == null) return null;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(doctorId).get();
      if (!userDoc.exists) return null;

      final detailsDoc = await FirebaseFirestore.instance.collection('users').doc(doctorId).collection('doctorsDetails').doc('details').get();
      
      final doctorData = userDoc.data()!;
      final detailsData = detailsDoc.exists ? detailsDoc.data()! : <String, dynamic>{};
      
      final combinedData = {...doctorData, ...clinicData, ...detailsData};
      
      // هنا نستخدم الموديل الآمن لتحويل البيانات
      final clinic = Clinic.fromCombinedData(combinedData);
      
      // هنا نحسب المسافة بالشكل الصحيح باستخدام GeoPoint
      final distance = userLocation != null
          ? Geolocator.distanceBetween(
              userLocation!.latitude,
              userLocation!.longitude,
              clinic.location.latitude,
              clinic.location.longitude,
            ) / 1000 // to KM
          : null;

      return ClinicWithDistance(clinic: clinic, distance: distance);
    } catch (e) {
      print("Error fetching data for doctor $doctorId: $e");
      return null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        title: const Text('Find a Veterinarian', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (uid != null)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
              builder: (context, snapshot) {
                // ... (كود عرض الصورة الشخصية للمستخدم كما هو)
                return CircleAvatar(); // Placeholder
              },
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // الجزء الأول: الخريطة (كما هو)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              height: 200,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: theme.colorScheme.surface),
              clipBehavior: Clip.hardEdge,
              child: FlutterMap(
                options: MapOptions(center: userLocation ?? LatLng(30.0444, 31.2357), zoom: 13),
                children: [
                  TileLayer(
                    urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: 'com.example.petut',
                  ),
                  if (userLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: userLocation!,
                          child: Icon(Icons.location_on, size: 40, color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          // الجزء الثاني: مربع البحث والفلترة (كما هو)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value.toLowerCase().trim()),
                      decoration: InputDecoration(
                        hintText: 'Search clinic or doctor name',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.filter_list, color: theme.colorScheme.primary),
                    onPressed: () => _showFilterSheet(context),
                  ),
                ],
              ),
            ),
          ),
          // الجزء الثالث: قائمة العيادات بالطريقة الصحيحة والفعالة
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('clinics').where('status', isEqualTo: 'active').snapshots(),
            builder: (context, clinicSnapshot) {
              if (clinicSnapshot.hasError) return const SliverFillRemaining(child: Center(child: Text('An error occurred')));
              if (clinicSnapshot.connectionState == ConnectionState.waiting) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              if (!clinicSnapshot.hasData || clinicSnapshot.data!.docs.isEmpty) {
                return const SliverFillRemaining(child: Center(child: Text('No clinics found')));
              }

              final clinicDocs = clinicSnapshot.data!.docs;

              // نستخدم FutureBuilder لانتظار تحميل بيانات كل العيادات مرة واحدة
              return FutureBuilder<List<ClinicWithDistance?>>(
                future: Future.wait(clinicDocs.map((doc) => _fetchClinicData(doc)).toList()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const SliverFillRemaining(child: Center(child: Text('Could not load clinic details.')));
                  }

                  // 1. فلترة أي بيانات لم يتم تحميلها بنجاح
                  List<ClinicWithDistance> clinicsWithDistances = snapshot.data!.whereType<ClinicWithDistance>().toList();

                  // 2. تطبيق فلتر البحث والتقييم
                  clinicsWithDistances = clinicsWithDistances.where((item) {
                    final clinic = item.clinic;
                    final passesSearch = _searchQuery.isEmpty ||
                        clinic.name.toLowerCase().contains(_searchQuery) ||
                        clinic.doctorName.toLowerCase().contains(_searchQuery);
                    final passesRating = clinic.rating >= _minRating;
                    return passesSearch && passesRating;
                  }).toList();

                  // 3. ترتيب القائمة النهائية حسب المسافة
                  if (_sortBy == 'distance' && userLocation != null) {
                    clinicsWithDistances.sort((a, b) => a.distance!.compareTo(b.distance!));
                  }
                  
                  if (clinicsWithDistances.isEmpty) {
                    return const SliverFillRemaining(child: Center(child: Text('No clinics match your criteria.')));
                  }

                  // 4. عرض القائمة المرتبة والمفلترة
                  return SliverList.builder(
                    itemCount: clinicsWithDistances.length,
                    itemBuilder: (context, i) {
                      final item = clinicsWithDistances[i];
                      final clinic = item.clinic; // <-- نستخدم الكائن الآمن
                      final distance = item.distance;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: _getImageProvider(clinic.image),
                            ),
                            title: Text(clinic.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(clinic.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text('Dr. ${clinic.doctorName}'),
                                if (distance != null)
                                  Text('${distance.toStringAsFixed(1)} km away'),
                              ],
                            ),
                            onTap: () {
                              // نمرر الكائن الجاهز مباشرة
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ClinicDetailsScreen(clinic: clinic)));
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

 

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sort by:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                RadioListTile<String>(
                  title: const Text('Nearest (Not implemented)'),
                  value: 'distance',
                  groupValue: _sortBy,
                  onChanged: (value) {},
                ),
                RadioListTile<String>(
                  title: const Text('Price (Not implemented)'),
                  value: 'price_asc',
                  groupValue: _sortBy,
                  onChanged: (value) {},
                ),
                const SizedBox(height: 12),
                const Text('Minimum Rating:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: List.generate(5, (index) => IconButton(
                    icon: Icon(
                      index < _minRating ? Icons.star : Icons.star_border,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      setModalState(() => _minRating = index + 1.0);
                      setState(() {});
                    },
                  )),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
