import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  void _addPoint(LatLng point) {
    setState(() {
      puntos.add(point);
      if (puntos.length >= 3) {
        area = _calcularArea(puntos);
      }
    });
  }

  double _calcularArea(List<LatLng> puntos) {
    double sum = 0;
    StringBuffer pasos = StringBuffer();

    pasos.writeln("📌 Se registraron ${puntos.length} puntos del polígono.\n");
    pasos.writeln("📝 Cálculo con fórmula Shoelace:");
    pasos.writeln("1. Multiplicar longitudes * latitudes sucesivas.");
    pasos.writeln("2. Restar operaciones inversas.");
    pasos.writeln("3. Tomar valor absoluto ÷ 2.");
    pasos.writeln("4. Multiplicar por 111139 para m² aprox.\n");

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
              initialCenter: LatLng(-0.1807, -78.4678), // Quito por defecto
              initialZoom: 15,
              onTap: (tapPosition, point) => _addPoint(point),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.topografia_app',
              ),
              MarkerLayer(
                markers: puntos
                    .map(
                      (p) => Marker(
                        point: p,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                    )
                    .toList(),
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
              bottom: 100,
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(14.0),
        child: ElevatedButton.icon(
          onPressed: _guardarTerreno,
          icon: const Icon(Icons.save, color: Colors.white),
          label: const Text("Guardar Terreno"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}

