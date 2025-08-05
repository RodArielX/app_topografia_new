// background_task.dart
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import 'location_callback_handler.dart';

const fetchBackgroundTask = "fetchBackgroundLocation";

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == fetchBackgroundTask) {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return Future.value(true);

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return Future.value(true);
      }
      if (permission == LocationPermission.deniedForever) return Future.value(true);

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await updateLocation(position); // tu función que envía datos a Supabase

      print("📍 Ubicación enviada en background: "
          "${position.latitude}, ${position.longitude}");
    }

    return Future.value(true);
  });
}
