import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListaTerrenosPage extends StatefulWidget {
  const ListaTerrenosPage({super.key});

  @override
  State<ListaTerrenosPage> createState() => _ListaTerrenosPageState();
}

class _ListaTerrenosPageState extends State<ListaTerrenosPage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🌍 Terrenos Guardados"),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        elevation: 4,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase.from('terrenos').select(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final terrenos = snapshot.data!;
          if (terrenos.isEmpty) {
            return const Center(
              child: Text(
                "📭 No hay terrenos registrados",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: terrenos.length,
            itemBuilder: (context, index) {
              final terreno = terrenos[index];
              final coords = (jsonDecode(terreno['coordenadas']) as List)
                  .map((p) => LatLng(p['lat'], p['lng']))
                  .toList();

              return Card(
                elevation: 5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade600,
                    child: const Icon(Icons.landscape, color: Colors.white),
                  ),
                  title: Text(
                    terreno['nombre'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Área: ${terreno['area'].toStringAsFixed(2)} m²",
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TerrenoDetallePage(
                          nombre: terreno['nombre'],
                          puntos: coords,
                          area: terreno['area'],
                          explicacion: terreno['explicacion'], // explicación
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class TerrenoDetallePage extends StatelessWidget {
  final String nombre;
  final List<LatLng> puntos;
  final double area;
  final String? explicacion;

  const TerrenoDetallePage({
    super.key,
    required this.nombre,
    required this.puntos,
    required this.area,
    this.explicacion,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(nombre),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: puntos.first,
          initialZoom: 16,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.topografia_app',
          ),
          PolygonLayer(
            polygons: [
              Polygon(
                points: puntos,
                color: Colors.green.withOpacity(0.3),
                borderColor: Colors.green.shade900,
                borderStrokeWidth: 3,
              ),
            ],
          ),
          MarkerLayer(
            markers: puntos
                .map(
                  (p) => Marker(
                    point: p,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on,
                        color: Colors.blueAccent, size: 32),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "📏 Área total: ${area.toStringAsFixed(2)} m²",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87),
            ),
            const SizedBox(height: 12),
            if (explicacion != null && explicacion!.isNotEmpty)
              ExpansionTile(
                title: const Text(
                  "📘 Ver explicación del cálculo",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      explicacion!,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}


