import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  final supabase = Supabase.instance.client;

  // Pedir permisos
  Future<bool> checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // Obtener ubicación actual
  Future<Position?> getCurrentLocation() async {
    if (await checkPermission()) {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    }
    return null;
  }

  // Publicar ubicación en Supabase
  Future<void> publishLocation() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final position = await getCurrentLocation();
    if (position == null) return;

    await supabase.from('ubicaciones').insert({
      'user_id': user.id,
      'latitud': position.latitude,
      'longitud': position.longitude,
    });
  }
}
