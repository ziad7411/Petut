import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:petut/screens/get_current_location.dart';
import 'package:petut/widgets/custom_text_field.dart';
import 'package:petut/widgets/custom_button.dart';

class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({super.key});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  LatLng? selectedLocation;
  final MapController _mapController = MapController();

  bool useMap = true;

  String? governorate;
  String? city;
  String? street;

  final governorateController = TextEditingController();
  final cityController = TextEditingController();
  final streetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

void _loadUserLocation() async {
  try {
    LatLng userLocation = await getCurrentLocation();
    setState(() {
      selectedLocation = userLocation;
    });

    // هنا نخلي الماب تتحرك للمكان الحالي
    _mapController.move(userLocation, 15.0);
  } catch (e) {
    print("Error getting location: $e");
    setState(() {
      selectedLocation = LatLng(30.033333, 31.233334); // fallback Cairo
    });

    _mapController.move(selectedLocation!, 12.0);
  }
}


  void _handleTap(LatLng latLng) async {
    setState(() {
      selectedLocation = latLng;
    });

    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latLng.latitude, latLng.longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        setState(() {
          governorate = place.administrativeArea ?? 'Cairo';
          city =
              place.locality ?? place.subAdministrativeArea ?? 'Unknown City';
          street = place.street?.isNotEmpty == true
              ? "${place.street}, ${place.subLocality ?? ''}"
              : 'Selected Location';

          governorateController.text = governorate ?? 'Cairo';
          cityController.text = city ?? 'Unknown City';
          streetController.text = street ?? 'Selected Location';
        });
      }
    } catch (e) {
      print('Geocoding error: $e');
    }
  }

  void _submit() {
    if (selectedLocation == null) return;

    final gov = governorateController.text.trim().isNotEmpty
        ? governorateController.text.trim()
        : (governorate ?? 'Cairo');
    final cityName = cityController.text.trim().isNotEmpty
        ? cityController.text.trim()
        : (city ?? 'Selected Area');
    final streetName = streetController.text.trim().isNotEmpty
        ? streetController.text.trim()
        : (street ?? 'Selected Location');

    final result = {
      'address': [gov, cityName, streetName].join(', '),
      'governorate': gov,
      'city': cityName,
      'street': streetName,
      'lat': selectedLocation!.latitude,
      'lng': selectedLocation!.longitude,
    };

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final LatLng defaultLocation =
        selectedLocation ?? LatLng(30.033333, 31.233334);

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
                  center: defaultLocation,
                  zoom: 13,
                  onTap: (_, latLng) => _handleTap(latLng),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.petut',
                  ),
                  if (selectedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: selectedLocation!,
                          width: 50,
                          height: 50,
                          child: Icon(
                            Icons.location_on,
                            size: 40,
                            color: theme.colorScheme.error,
                          ),
                        ),
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
