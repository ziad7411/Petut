import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_colors.dart';
import './clinic_details_screen.dart';
import '../models/Clinic.dart';

class ClinicsScreen extends StatefulWidget {
  const ClinicsScreen({super.key});

  @override
  State<ClinicsScreen> createState() => _ClinicsScreenState();
}

class _ClinicsScreenState extends State<ClinicsScreen> {
  LatLng? userLocation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'distance';
  double _minRating = 0.0;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // Handle the case where the user denies permission
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (mounted) {
      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.dark,
        title: const Text(
          'Find a Vet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (uid != null)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
              builder: (context, snapshot) {
                String? imageUrl;
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  imageUrl = data['profileImage'];
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                        ? NetworkImage(imageUrl)
                        : const AssetImage('assets/doctor.jpg') as ImageProvider,
                  ),
                );
              },
            ),
        ],
      ),
      // REFACTOR: Replaced Column with CustomScrollView to make the map scrollable.
      body: CustomScrollView(
        slivers: [
          // SLIVER 1: The Map
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.shade200,
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      center: userLocation ?? LatLng(30.0444, 31.2357),
                      zoom: 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: "https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png",
                        userAgentPackageName: 'com.example.petut',
                      ),
                      if (userLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: userLocation!,
                              child: const Icon(
                                Icons.person_pin_circle,
                                size: 40,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.access_time),
                      label: const Text('After hours care'),
                      onPressed: () {},
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.local_hospital),
                      label: const Text('Emergency Services'),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
          // SLIVER 2: Search and Filter Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase().trim();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search clinic or doctor name',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.orange),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Sort by:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ListTile(
                                title: const Text('Nearest'),
                                leading: Radio<String>(
                                  value: 'distance',
                                  groupValue: _sortBy,
                                  onChanged: (value) {
                                    if (value != null) setState(() => _sortBy = value);
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                              ListTile(
                                title: const Text('Price (Low to High)'),
                                leading: Radio<String>(
                                  value: 'price_asc',
                                  groupValue: _sortBy,
                                  onChanged: (value) {
                                    if (value != null) setState(() => _sortBy = value);
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                              ListTile(
                                title: const Text('Price (High to Low)'),
                                leading: Radio<String>(
                                  value: 'price_desc',
                                  groupValue: _sortBy,
                                  onChanged: (value) {
                                    if (value != null) setState(() => _sortBy = value);
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text('Minimum Rating:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              StatefulBuilder(
                                builder: (context, setModalState) {
                                  return Row(
                                    children: List.generate(5, (index) => IconButton(
                                      icon: Icon(
                                        index < _minRating ? Icons.star : Icons.star_border,
                                        color: Colors.orange,
                                      ),
                                      onPressed: () {
                                        // Use setModalState to update the bottom sheet's UI
                                        setModalState(() {
                                           _minRating = index + 1.0;
                                        });
                                        // Use setState to update the main screen's UI after the sheet is closed
                                        setState((){});
                                      },
                                    )),
                                  );
                                }
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // SLIVER 3: Clinic List
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'Doctor')
                .where('isVerified', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const SliverFillRemaining(
                  child: Center(child: Text('An error occurred while loading')),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              List<QueryDocumentSnapshot> docs = snapshot.data!.docs;

              docs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final clinicName = data['clinicName']?.toString().toLowerCase() ?? '';
                final doctorName = data['doctorName']?.toString().toLowerCase() ?? '';
                final rating = (data['rating'] ?? 0.0).toDouble();
                return (clinicName.contains(_searchQuery) || doctorName.contains(_searchQuery)) &&
                    rating >= _minRating;
              }).toList();

              // Sorting logic...
              if (_sortBy == 'distance' && userLocation != null) {
                  docs.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    // Assuming you store lat/lng in Firestore
                    final aLat = (aData['lat'] ?? 0.0).toDouble();
                    final aLng = (aData['lng'] ?? 0.0).toDouble();
                    final bLat = (bData['lat'] ?? 0.0).toDouble();
                    final bLng = (bData['lng'] ?? 0.0).toDouble();

                    final aDist = Geolocator.distanceBetween(userLocation!.latitude, userLocation!.longitude, aLat, aLng);
                    final bDist = Geolocator.distanceBetween(userLocation!.latitude, userLocation!.longitude, bLat, bLng);
                    return aDist.compareTo(bDist);
                  });
              } else if (_sortBy == 'price_asc' || _sortBy == 'price_desc') {
                  docs.sort((a, b) {
                    final aPrice = ((a.data() as Map<String, dynamic>)['price'] ?? 0.0).toDouble();
                    final bPrice = ((b.data() as Map<String, dynamic>)['price'] ?? 0.0).toDouble();
                    return _sortBy == 'price_asc' ? aPrice.compareTo(bPrice) : bPrice.compareTo(aPrice);
                  });
              }


              if (docs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/images/4939569d-6a3c-4878-8960-803e5521f119.jpg', width: 200),
                        const SizedBox(height: 16),
                        const Text('There is no data yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              // REFACTOR: Replaced ListView with SliverList
              return SliverList.separated(
                itemCount: docs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  // FIX: Use the updated Clinic model which now includes the document ID
                  final clinic = Clinic.fromFirestore(docs[i]);
                  final rating = clinic.rating;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: (clinic.image.isNotEmpty)
                              ? Image.network(
                                  clinic.image,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => 
                                    Container(
                                        width: 50, height: 50, color: Colors.grey.shade200, 
                                        child: const Icon(Icons.local_hospital, color: Colors.orange)
                                    ),
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.local_hospital, color: Colors.orange, size: 28),
                                ),
                        ),
                        title: Text(
                          clinic.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(clinic.location),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.verified, size: 16, color: Colors.orange),
                                const SizedBox(width: 4),
                                Text('Dr. ${clinic.name}'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(5, (index) => Icon(
                                index < rating ? Icons.star : Icons.star_border,
                                color: Colors.orange,
                                size: 16,
                              )),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // The clinic object now correctly contains the ID.
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ClinicDetailsScreen(clinic: clinic),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}