import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';
import 'terreno_page.dart';
import 'lista_terrenos_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final supabase = Supabase.instance.client;
  LatLng? myPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  /// Obtiene la ubicación actual del dispositivo (solo para mostrar en el mapa)
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    setState(() {
      myPosition = LatLng(pos.latitude, pos.longitude);
    });
  }

  Future<void> _logout(BuildContext context) async {
    await supabase.auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📍 Mapa de Topografía"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Cerrar sesión",
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.blue.shade700),
              accountName: const Text("Topógrafo"),
              accountEmail: Text(supabase.auth.currentUser?.email ?? ""),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blue),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_location_alt, color: Colors.green),
              title: const Text("Registrar Terreno"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TerrenoPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.blueAccent),
              title: const Text("Ver Terrenos"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ListaTerrenosPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Cerrar Sesión"),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: myPosition == null
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text("📍 Obteniendo ubicación...",
                      style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : FlutterMap(
              options: MapOptions(
                initialCenter: myPosition!,
                initialZoom: 16,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.topografia_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: myPosition!,
                      width: 80,
                      height: 80,
                      child: const Icon(Icons.location_on,
                          color: Colors.blue, size: 42),
                    ),
                  ],
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue.shade700,
        icon: const Icon(Icons.my_location, color: Colors.white),
        label: const Text("Mi ubicación"),
        onPressed: _getCurrentLocation,
      ),
    );
  }
}

