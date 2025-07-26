import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
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
    // Set default sort to distance
    _sortBy = 'distance';
  }

  Future<void> _getUserLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      if (mounted) {
        setState(() {
          userLocation = LatLng(position.latitude, position.longitude);
          // Automatically set to distance sorting when location is available
          if (_sortBy != 'distance') {
            _sortBy = 'distance';
          }
        });
      }
    } catch(e) {
      // Handle location errors silently
      print('Location error: $e');
    }
  }

  // Helper method to handle base64 image conversion
  ImageProvider? _getImageProvider(String imageBase64) {
    try {
      final bytes = base64Decode(imageBase64);
      return MemoryImage(bytes);
    } catch (e) {
      // If base64 decode fails, return null to show default icon
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
        title: const Text(
          'Find a Veterinarian',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (uid != null)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
              builder: (context, snapshot) {
                String? imageBase64;
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  imageBase64 = data['profileImage'];
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    backgroundImage: imageBase64 != null && imageBase64.isNotEmpty 
                        ? _getImageProvider(imageBase64!) 
                        : null,
                    child: imageBase64 == null || imageBase64.isEmpty
                        ? Icon(Icons.person, size: 20, color: theme.colorScheme.primary)
                        : null,
                  ),
                );
              },
            ),
        ],
      ),
      // REESTRUTURAÇÃO: Substituí a Coluna por CustomScrollView para tornar o mapa rolável.
      body: CustomScrollView(
        slivers: [
          // SLIVER 1: O Mapa
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.surface,
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
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Location pin background
                                  Icon(
                                    Icons.location_on,
                                    size: 40,
                                    color: theme.colorScheme.primary,
                                  ),
                                  // Pet icon inside
                                  Positioned(
                                    top: 6,
                                    child: Icon(
                                      Icons.pets,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            icon: const Icon(Icons.access_time, size: 16),
                            label: const Text('After Hours', style: TextStyle(fontSize: 12)),
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary,
                              side: BorderSide(color: theme.colorScheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            icon: const Icon(Icons.local_hospital, size: 16),
                            label: const Text('Emergency', style: TextStyle(fontSize: 12)),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // SLIVER 2: Barra de Pesquisa e Filtro
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
                        fillColor: theme.colorScheme.surface,
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
                    icon: Icon(Icons.filter_list, color: theme.colorScheme.primary),
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
                                        color: theme.colorScheme.primary,
                                      ),
                                      onPressed: () {
                                        // Usa setModalState para atualizar a UI da folha inferior
                                        setModalState(() {
                                           _minRating = index + 1.0;
                                        });
                                        // Usa setState para atualizar a UI da tela principal após o fechamento da folha
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
          // SLIVER 3: Lista de Clínicas
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'Doctor')
                // Temporarily removed isVerified filter
                // .where('isVerified', isEqualTo: true)
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

              // Sort logic - Always sort by distance first if user location is available
              if (userLocation != null) {
                if (_sortBy == 'distance') {
                  docs.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    
                    // Use default Cairo coordinates if no location data
                    final aLat = (aData['lat'] ?? 30.0444).toDouble();
                    final aLng = (aData['lng'] ?? 31.2357).toDouble();
                    final bLat = (bData['lat'] ?? 30.0444).toDouble();
                    final bLng = (bData['lng'] ?? 31.2357).toDouble();

                    final aDist = Geolocator.distanceBetween(
                      userLocation!.latitude, 
                      userLocation!.longitude, 
                      aLat, 
                      aLng
                    );
                    final bDist = Geolocator.distanceBetween(
                      userLocation!.latitude, 
                      userLocation!.longitude, 
                      bLat, 
                      bLng
                    );
                    
                    // Debug: Print distances to verify sorting
                    print('Clinic A: ${aData['clinicName']} - Distance: ${aDist.toStringAsFixed(0)}m');
                    print('Clinic B: ${bData['clinicName']} - Distance: ${bDist.toStringAsFixed(0)}m');
                    
                    return aDist.compareTo(bDist); // Ascending order (nearest first)
                  });
                }
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
                        Text('No clinics available yet', style: TextStyle(fontSize: 18, color: theme.hintColor)),
                      ],
                    ),
                  ),
                );
              }

              // REESTRUTURAÇÃO: Substituí ListView por SliverList
              return SliverList.separated(
                itemCount: docs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  // CORREÇÃO: Usa o modelo Clinic atualizado que agora inclui o ID do documento
                  final clinic = Clinic.fromFirestore(docs[i]);
                  final rating = clinic.rating;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.local_hospital, 
                            color: theme.colorScheme.primary, 
                            size: 28
                          ),
                        ),
                        title: Text(
                          clinic.name, // Now shows clinic name correctly
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
                                Icon(Icons.verified, size: 16, color: theme.colorScheme.primary),
                                const SizedBox(width: 4),
                                Text('Dr. ${clinic.name}'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                ...List.generate(5, (index) => Icon(
                                  index < rating ? Icons.star : Icons.star_border,
                                  color: theme.colorScheme.primary,
                                  size: 16,
                                )),
                                const SizedBox(width: 8),
                                if (userLocation != null)
                                  Icon(Icons.location_on, size: 12, color: theme.hintColor),
                                if (userLocation != null)
                                  const SizedBox(width: 2),
                                if (userLocation != null)
                                  Text(
                                    '${(Geolocator.distanceBetween(
                                      userLocation!.latitude,
                                      userLocation!.longitude,
                                      (docs[i].data() as Map<String, dynamic>)['lat'] ?? 30.0444,
                                      (docs[i].data() as Map<String, dynamic>)['lng'] ?? 31.2357,
                                    ) / 1000).toStringAsFixed(1)}km',
                                    style: TextStyle(fontSize: 10, color: theme.hintColor),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // O objeto clinic agora contém corretamente o ID.
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
      // Add bottom padding to prevent last card cutoff
      bottomNavigationBar: const SizedBox(height: 80),
    );
  }
}