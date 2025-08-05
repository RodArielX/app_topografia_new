import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminLocations extends StatefulWidget {
  const AdminLocations({super.key});

  @override
  State<AdminLocations> createState() => _AdminLocationsState();
}

class _AdminLocationsState extends State<AdminLocations> {
  final supabase = Supabase.instance.client;

  /// Convierte `last_update` en formato legible (ej: "hace 15s")
  String _timeAgo(String? isoDate) {
    if (isoDate == null) return "⏳ sin actualizar";
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final diff = DateTime.now().difference(date);

      if (diff.inSeconds < 60) return "⏱ hace ${diff.inSeconds}s";
      if (diff.inMinutes < 60) return "⏱ hace ${diff.inMinutes}m";
      if (diff.inHours < 24) return "📅 hace ${diff.inHours}h";
      return "📍 ${date.day}/${date.month} ${date.hour}:${date.minute}";
    } catch (e) {
      return "❌ fecha inválida";
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('usuarios')
          .stream(primaryKey: ['id'])
          .eq('rol', 'topografo') // solo topógrafos
          .execute(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final usuarios = snapshot.data!;
        final topografosConUbicacion =
            usuarios.where((u) => u['lat'] != null && u['lng'] != null).toList();

        if (topografosConUbicacion.isEmpty) {
          return const Center(
            child: Text(
              "⚠️ No hay ubicaciones activas",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          );
        }

        // Crear marcadores personalizados
        final markers = topografosConUbicacion.map((u) {
          final nombre = u['nombre'] ?? 'Topógrafo';
          final lastUpdate = _timeAgo(u['last_update']);

          return Marker(
            point: LatLng(u['lat'], u['lng']),
            width: 150,
            height: 80,
            child: Column(
              children: [
                const Icon(Icons.location_on, color: Colors.blue, size: 40),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))
                    ],
                  ),
                  child: Text(
                    "$nombre\n$lastUpdate",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          );
        }).toList();

        // Centrar en el último topógrafo conectado
        final lastLocation = topografosConUbicacion.last;
        final center = LatLng(lastLocation['lat'], lastLocation['lng']);

        return Scaffold(
          body: FlutterMap(
            options: MapOptions(
              center: center,
              zoom: 14,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate, // sin rotación
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.topografia_app',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              setState(() {}); // Forzar actualización
            },
            icon: const Icon(Icons.refresh),
            label: const Text("Actualizar"),
          ),
        );
      },
    );
  }
}


