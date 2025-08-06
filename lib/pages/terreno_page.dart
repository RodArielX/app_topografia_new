import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class TerrenoPage extends StatefulWidget {
  const TerrenoPage({super.key});

  @override
  State<TerrenoPage> createState() => _TerrenoPageState();
}

class _TerrenoPageState extends State<TerrenoPage> {
  final supabase = Supabase.instance.client;

  List<LatLng> puntos = [];
  double? area;
  String? _explicacionArea;

  List<Marker> otherMarkers = [];
  RealtimeChannel? channel;

  LatLng? myPosition;

  @override
  void initState() {
    super.initState();
    _loadOtherTopografos();
    _subscribeToChanges();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }
    }

    Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);

    setState(() {
      myPosition = LatLng(pos.latitude, pos.longitude);
    });
  }

  void _addPoint(LatLng point) {
    setState(() {
      puntos.add(point);
      if (puntos.length >= 3) {
        area = _calcularArea(puntos);
      }
    });
  }

  void _addCurrentLocationPoint() {
    if (myPosition != null) {
      _addPoint(myPosition!);
    }
  }

  void _removeLastPoint() {
    if (puntos.isNotEmpty) {
      setState(() {
        puntos.removeLast();
        if (puntos.length >= 3) {
          area = _calcularArea(puntos);
        } else {
          area = null;
          _explicacionArea = null;
        }
      });
    }
  }

  double _calcularArea(List<LatLng> puntos) {
    double sum = 0;
    StringBuffer pasos = StringBuffer();

    pasos.writeln("📌 Se registraron ${puntos.length} puntos del polígono.\n");
    pasos.writeln("📝 Fórmula Shoelace aplicada paso a paso:\n");

    for (int i = 0; i < puntos.length; i++) {
      int j = (i + 1) % puntos.length;
      double paso = (puntos[i].longitude * puntos[j].latitude) -
          (puntos[j].longitude * puntos[i].latitude);
      pasos.writeln(" • Paso $i: $paso");
      sum += paso;
    }

    double resultado = (sum.abs() / 2.0) * 111139;
    pasos.writeln("\n✅ Área obtenida: ${resultado.toStringAsFixed(2)} m²");

    _explicacionArea = pasos.toString();
    return resultado;
  }

  Future<void> _guardarTerreno() async {
    final user = supabase.auth.currentUser;
    if (user == null || puntos.length < 3) return;

    await supabase.from('terrenos').insert({
      'user_id': user.id,
      'nombre': "Terreno ${DateTime.now().millisecondsSinceEpoch}",
      'coordenadas': jsonEncode(
        puntos.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      ),
      'area': area,
      'explicacion': _explicacionArea,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Terreno guardado con éxito"),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        puntos.clear();
        area = null;
        _explicacionArea = null;
      });
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
                width: 70,
                height: 70,
                child: const Icon(Icons.person_pin_circle,
                    color: Colors.red, size: 36),
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
                width: 70,
                height: 70,
                child: const Icon(Icons.person_pin_circle,
                    color: Colors.red, size: 36),
              ),
            );
          });
        }
      },
    );

    channel!.subscribe();
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
        title: const Text("📐 Registrar Terreno"),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              center: myPosition ?? LatLng(-0.1807, -78.4678),
              zoom: 15,
              onTap: (tapPosition, point) => _addPoint(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.topografia_app',
              ),
              MarkerLayer(
                markers: [
                  if (myPosition != null)
                    Marker(
                      point: myPosition!,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  ...puntos.map(
                    (p) => Marker(
                      point: p,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 30,
                      ),
                    ),
                  ),
                  ...otherMarkers,
                ],
              ),
              if (puntos.length >= 3)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: puntos,
                      color: Colors.green.withOpacity(0.3),
                      borderColor: Colors.green,
                      borderStrokeWidth: 3,
                    ),
                  ],
                ),
            ],
          ),

          if (area != null)
            Positioned(
              bottom: 200,
              left: 20,
              right: 20,
              child: Card(
                elevation: 4,
                color: Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    "📏 Área: ${area!.toStringAsFixed(2)} m²",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: _guardarTerreno,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text("Guardar Terreno"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _addCurrentLocationPoint,
                icon: const Icon(Icons.add_location, color: Colors.white),
                label: const Text("Agregar mi ubicación"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _removeLastPoint,
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text("Borrar último punto"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
