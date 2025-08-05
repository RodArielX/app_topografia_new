import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';

import 'pages/auth_page.dart';
import 'pages/home_page.dart';
import 'location_callback_handler.dart';
import 'background_task.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gbrdjjlhcxhbzbrzybwn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdicmRqamxoY3hoYnpicnp5YnduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM5NDQ1NTcsImV4cCI6MjA2OTUyMDU1N30.kY4vdIknblqW3V2s9EwY_Z4pW5ZpLHs0a3df3-j1Wfg', 
  );

  if (kIsWeb) {
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        bool enabled = await Geolocator.isLocationServiceEnabled();
        if (!enabled) return;

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) return;
        }
        if (permission == LocationPermission.deniedForever) return;

        Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await updateLocation(pos);
        print("🌐 Ubicación enviada desde Web: ${pos.latitude}, ${pos.longitude}");
      } catch (e) {
        print("Error obteniendo ubicación en Web: $e");
      }
    });
  } else {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );

    await Workmanager().registerPeriodicTask(
      "locationTask",
      "updateLocationTask",
      frequency: const Duration(minutes: 15),
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Topografía App',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue.shade300,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade900,
          foregroundColor: Colors.white,
          elevation: 3,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      home: session == null ? const AuthPage() : const HomePage(),
    );
  }
}



