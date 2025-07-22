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

  bool useMap = true;

  String? governorate;
  String? city;
  String? street;

  final governorateController = TextEditingController();
  final cityController = TextEditingController();
  final streetController = TextEditingController();

  void _handleTap(LatLng latLng) async {
    setState(() {
      selectedLocation = latLng;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        setState(() {
          governorate = place.administrativeArea;
          city = place.locality ?? place.subAdministrativeArea;
          street = "${place.street}, ${place.subLocality}";
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching address: $e')),
      );
    }
  }

  void _submit() {
    final selectedData = {
      "governorate": governorateController.text.trim().isNotEmpty
          ? governorateController.text.trim()
          : governorate ?? '',
      "city": cityController.text.trim().isNotEmpty
          ? cityController.text.trim()
          : city ?? '',
      "street": streetController.text.trim().isNotEmpty
          ? streetController.text.trim()
          : street ?? '',
    };

    if (selectedData.values.any((element) => element.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    Navigator.pop(context, selectedData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Address')),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Use Map'),
            value: useMap,
            onChanged: (val) {
              setState(() {
                useMap = val;
              });
            },
          ),
          if (useMap)
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: selectedLocation,
                  zoom: 13,
                  onTap: (_, latLng) => _handleTap(latLng),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.petut',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: selectedLocation,
                        width: 50,
                        height: 50,
                        child: const Icon(Icons.location_on,
                            size: 40, color: Colors.red),
                      )
                    ],
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextFormField(
                  controller: governorateController,
                  decoration: InputDecoration(
                    labelText: 'Governorate',
                    hintText: governorate ?? '',
                  ),
                ),
                TextFormField(
                  controller: cityController,
                  decoration: InputDecoration(
                    labelText: 'City / Area',
                    hintText: city ?? '',
                  ),
                ),
                TextFormField(
                  controller: streetController,
                  decoration: InputDecoration(
                    labelText: 'Street & House No.',
                    hintText: street ?? '',
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Confirm Address'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
