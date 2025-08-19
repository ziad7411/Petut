import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

Future<LatLng> getCurrentLocation() async {
  // اطلب الصلاحيات
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception("خدمة تحديد الموقع غير مفعلة");
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception("تم رفض صلاحية الموقع");
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception("صلاحية الموقع مرفوضة نهائياً");
  }

  // احصل على الإحداثيات
  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  return LatLng(position.latitude, position.longitude);
}
