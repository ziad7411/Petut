import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:petut/widgets/custom_text_field.dart'; // Assuming you have this
import 'package:petut/widgets/custom_button.dart'; // Assuming you have this

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
          
          // Update text controllers as well
          governorateController.text = governorate ?? '';
          cityController.text = city ?? '';
          streetController.text = street ?? '';
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

    Navigator.pop(context, selectedData.values.join(', '));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Select Address'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
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
            activeColor: theme.colorScheme.primary,
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
                        child: Icon(Icons.location_on,
                            size: 40, color: theme.colorScheme.error),
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
                CustomTextField(
                  controller: governorateController,
                  hintText: governorate ?? 'Governorate',
                ),
                CustomTextField(
                  controller: cityController,
                  hintText: city ?? 'City / Area',
                ),
                CustomTextField(
                  controller: streetController,
                  hintText: street ?? 'Street & House No.',
                ),
                const SizedBox(height: 10),
                CustomButton(
                  onPressed: _submit,
                  text: 'Confirm Address',
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
