import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../app_colors.dart';

class ClinicsScreen extends StatefulWidget {
  const ClinicsScreen({super.key});

  @override
  State<ClinicsScreen> createState() => _ClinicsScreenState();
}

class _ClinicsScreenState extends State<ClinicsScreen> {
  LatLng? userLocation;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      userLocation = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/doctor.jpg'),
              radius: 18,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Map and action buttons
          Container(
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
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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

          // List of clinics or image placeholder
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'Doctor')
                  .where('isVerified', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('An error occurred while loading'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                // Sort by distance if location is available
                if (userLocation != null) {
                  docs.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;

                    final aLat = aData['lat'] ?? 0.0;
                    final aLng = aData['lng'] ?? 0.0;
                    final bLat = bData['lat'] ?? 0.0;
                    final bLng = bData['lng'] ?? 0.0;

                    final aDist = Geolocator.distanceBetween(
                        userLocation!.latitude, userLocation!.longitude, aLat, aLng);
                    final bDist = Geolocator.distanceBetween(
                        userLocation!.latitude, userLocation!.longitude, bLat, bLng);

                    return aDist.compareTo(bDist);
                  });
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/4939569d-6a3c-4878-8960-803e5521f119.jpg',
                          width: 200,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'There is no data yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: docs.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return Container(
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
                          child: Image.asset(
                            'assets/images/clinic.png',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          data['clinicName'] ?? 'Unknown Name',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(data['clinicAddress'] ?? 'Unknown Address'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text('Dr. ${data['doctorName'] ?? '---'}'),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {},
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
