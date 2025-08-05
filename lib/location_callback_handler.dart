import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> updateLocation(Position position) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user != null) {
    try {
      await supabase.from('usuarios').update({
        'lat': position.latitude,
        'lng': position.longitude,
        'last_update': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (e) {
      print("❌ Error al enviar ubicación: $e");
    }
  }
}
