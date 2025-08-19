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

// كلاس لجعل الخريطة قابلة للطي عند السكرول
class _MapHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _MapHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = shrinkOffset / maxExtent;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    
    return Opacity(
      opacity: opacity,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_MapHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
           minHeight != oldDelegate.minHeight ||
           child != oldDelegate.child;
  }
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
  String _sortBy = 'distance_asc'; // الترتيب الافتراضي من الأقرب للأبعد
  double _minRating = 0.0;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
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
    
    print("🏥 Processing clinic: ${clinicDoc.id}");
    print("📋 Clinic data: $clinicData");
    print("👨‍⚕️ Doctor ID: $doctorId");
    
    if (doctorId == null) {
      print("❌ No doctorId found for clinic ${clinicDoc.id}");
      return null;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(doctorId).get();
      print("👤 User doc exists: ${userDoc.exists}");
      
      if (!userDoc.exists) {
        print("❌ User document not found for doctorId: $doctorId");
        return null;
      }

final detailsDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(doctorId)
    .get();
          print("📄 Details doc exists: ${detailsDoc.exists}");
      
      final doctorData = userDoc.data()!;
      final detailsData = detailsDoc.exists ? detailsDoc.data()! : <String, dynamic>{};
      
      print("👨‍⚕️ Doctor data: $doctorData");
      print("📋 Details data: $detailsData");
      
      final combinedData = {...doctorData, ...clinicData, ...detailsData};
      print("🔄 Combined data: $combinedData");
      
      // هنا نستخدم الموديل الآمن لتحويل البيانات
      final clinic = Clinic.fromCombinedData(combinedData);
      print("✅ Clinic created successfully: ${clinic.name}");
      
      // حساب المسافة باستخدام lat/lng المحفوظة في البيانات
      final clinicLat = (combinedData['latitude'] ?? 30.0444).toDouble();
      final clinicLng = (combinedData['longitude'] ?? 31.2357).toDouble();
      
      final distance = userLocation != null
          ? Geolocator.distanceBetween(
              userLocation!.latitude,
              userLocation!.longitude,
              clinicLat,
              clinicLng,
            ) / 1000 // to KM
          : null;

      return ClinicWithDistance(clinic: clinic, distance: distance);
    } catch (e) {
      print("❌ Error fetching data for doctor $doctorId: $e");
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
                if (!snapshot.hasData || snapshot.hasError) {
                  return CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(Icons.person, size: 20, color: theme.colorScheme.primary),
                  );
                }
                
                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                if (userData == null) {
                  return CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(Icons.person, size: 20, color: theme.colorScheme.primary),
                  );
                }
                
                final profileImage = userData['profileImage'] as String?;
                final userName = userData['fullName'] as String? ?? 'User';
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: profileImage != null && profileImage.isNotEmpty 
                        ? _getImageProvider(profileImage) 
                        : null,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: profileImage == null || profileImage.isEmpty ? Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ) : null,
                  ),
                );
              },
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // الجزء الأول: الخريطة القابلة للطي
          SliverPersistentHeader(
            pinned: false,
            floating: false,
            delegate: _MapHeaderDelegate(
              minHeight: 0,
              maxHeight: 200,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
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
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(Icons.location_on, size: 40, color: theme.colorScheme.primary),
                                Positioned(
                                  top: 6,
                                  child: Icon(Icons.pets, size: 16, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          // الجزء الثاني: مربع البحث والفلترة
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
          // الجزء الثالث: قائمة العيادات
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('clinics').where('status', whereIn: ['active', 'pending']).snapshots(),
            builder: (context, clinicSnapshot) {
              if (clinicSnapshot.hasError) return const SliverFillRemaining(child: Center(child: Text('An error occurred')));
              if (clinicSnapshot.connectionState == ConnectionState.waiting) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              if (!clinicSnapshot.hasData || clinicSnapshot.data!.docs.isEmpty) {
                return const SliverFillRemaining(child: Center(child: Text('No clinics found')));
              }

              final clinicDocs = clinicSnapshot.data!.docs;

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

                  // 3. ترتيب القائمة حسب الخيار المحدد
                  if (userLocation != null) {
                    switch (_sortBy) {
                      case 'distance_asc':
                        clinicsWithDistances.sort((a, b) => (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));
                        break;
                      case 'distance_desc':
                        clinicsWithDistances.sort((a, b) => (b.distance ?? 0).compareTo(a.distance ?? 0));
                        break;
                      case 'price_asc':
                        clinicsWithDistances.sort((a, b) => a.clinic.price.compareTo(b.clinic.price));
                        break;
                      case 'price_desc':
                        clinicsWithDistances.sort((a, b) => b.clinic.price.compareTo(a.clinic.price));
                        break;
                      default:
                        clinicsWithDistances.sort((a, b) => (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));
                    }
                  } else {
                    // إذا لم يكن هناك موقع، رتب حسب السعر
                    switch (_sortBy) {
                      case 'price_asc':
                        clinicsWithDistances.sort((a, b) => a.clinic.price.compareTo(b.clinic.price));
                        break;
                      case 'price_desc':
                        clinicsWithDistances.sort((a, b) => b.clinic.price.compareTo(a.clinic.price));
                        break;
                    }
                  }
                  
                  if (clinicsWithDistances.isEmpty) {
                    return const SliverFillRemaining(child: Center(child: Text('No clinics match your criteria.')));
                  }

                  // 4. عرض القائمة المرتبة والمفلترة
                  return SliverList.separated(
                    itemCount: clinicsWithDistances.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final item = clinicsWithDistances[i];
                      final clinic = item.clinic;
                      final distance = item.distance;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.local_hospital, color: theme.colorScheme.primary, size: 28),
                              ),
                            ),
                            title: Text(clinic.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(clinic.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.verified, size: 16, color: theme.colorScheme.primary),
                                    const SizedBox(width: 4),
                                    Text('Dr. ${clinic.doctorName}'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    ...List.generate(5, (index) => Icon(
                                      index < clinic.rating ? Icons.star : Icons.star_border,
                                      color: theme.colorScheme.primary,
                                      size: 16,
                                    )),
                                    if (distance != null) ...[
                                      const SizedBox(width: 8),
                                      Icon(Icons.location_on, size: 12, color: theme.hintColor),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${distance.toStringAsFixed(1)}km',
                                        style: TextStyle(fontSize: 10, color: theme.hintColor),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
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
      // Add bottom padding to prevent last card cutoff
      bottomNavigationBar: const SizedBox(height: 80),
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
                  title: const Text('Nearest to Farthest'),
                  value: 'distance_asc',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    if (value != null) setState(() => _sortBy = value);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Farthest to Nearest'),
                  value: 'distance_desc',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    if (value != null) setState(() => _sortBy = value);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Price (Low to High)'),
                  value: 'price_asc',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    if (value != null) setState(() => _sortBy = value);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Price (High to Low)'),
                  value: 'price_desc',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    if (value != null) setState(() => _sortBy = value);
                    Navigator.pop(context);
                  },
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