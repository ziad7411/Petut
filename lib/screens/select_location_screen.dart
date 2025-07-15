import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({super.key});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  LatLng selectedLocation = LatLng(30.033333, 31.233334); // Cairo default
  final MapController _mapController = MapController();

  void _handleTap(LatLng latLng) async {
    setState(() {
      selectedLocation = latLng;
    });

    List<Placemark> placemarks = await placemarkFromCoordinates(
      latLng.latitude,
      latLng.longitude,
    );

    if (placemarks.isNotEmpty) {
      final Placemark place = placemarks.first;
      final address = "${place.street}, ${place.locality}, ${place.country}";
      Navigator.pop(context, address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Location')),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: selectedLocation,
          zoom: 13,
          onTap: (_, latLng) => _handleTap(latLng),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.petut',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: selectedLocation,
                width: 50,
                height: 50,
                child: const Icon(Icons.location_on, size: 40, color: Colors.red),
              )
            ],
          ),
        ],
      ),
    );
  }
}
