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
  List<Marker> otherMarkers = [];
  RealtimeChannel? channel;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation().then((_) {
      _updateMyPositionInDB();
      _loadOtherTopografos();
      _subscribeToChanges();
    });
  }

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

  Future<void> _updateMyPositionInDB() async {
    final user = supabase.auth.currentUser;
    if (user != null && myPosition != null) {
      await supabase.from('usuarios').update({
        'lat': myPosition!.latitude,
        'lng': myPosition!.longitude,
        'last_update': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    }
  }

  Future<void> _loadOtherTopografos() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('usuarios')
        .select('id, nombre, lat, lng')
        .not('lat', 'is', null)
        .not('lng', 'is', null)
        .neq('id', user.id);

    setState(() {
      otherMarkers = (response as List)
          .map((e) => Marker(
                point: LatLng(e['lat'], e['lng']),
                width: 80,
                height: 80,
                child: const Icon(Icons.person_pin_circle,
                    color: Colors.red, size: 40),
              ))
          .toList();
    });
  }

  void _subscribeToChanges() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    channel = supabase.channel('usuarios-changes');

    channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'usuarios',
      callback: (payload) {
        final data = payload.newRecord;
        if (data == null) return;

        if (data['id'] != user.id && data['lat'] != null && data['lng'] != null) {
          setState(() {
            otherMarkers.removeWhere((m) =>
                m.point.latitude == data['lat'] && m.point.longitude == data['lng']);
            otherMarkers.add(
              Marker(
                point: LatLng(data['lat'], data['lng']),
                width: 80,
                height: 80,
                child: const Icon(Icons.person_pin_circle,
                    color: Colors.red, size: 40),
              ),
            );
          });
        }
      },
    );

    channel!.subscribe();
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
  void dispose() {
    channel?.unsubscribe();
    super.dispose();
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
        child: ListView(
          padding: EdgeInsets.zero,
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
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
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
                    ...otherMarkers,
                  ],
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue.shade700,
        icon: const Icon(Icons.my_location, color: Colors.white),
        label: const Text("Actualizar"),
        onPressed: () async {
          await _getCurrentLocation();
          await _updateMyPositionInDB();
        },
      ),
    );
  }
}
