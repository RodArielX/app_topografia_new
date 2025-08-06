import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_page.dart';
import 'map_page.dart';
import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authService = AuthService();
  String? rol;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = _authService.currentUser; // ✅ ahora funciona
    if (user == null) return;

    final response = await Supabase.instance.client
        .from('usuarios')
        .select('rol')
        .eq('id', user.id)
        .maybeSingle();

    setState(() {
      rol = response?['rol'] ?? 'topografo';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (rol == null) {
      return Scaffold(
        backgroundColor: Colors.blueAccent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                "Cargando tu perfil...",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            ],
          ),
        ),
      );
    }

    // Si es admin -> va al panel de administración
    if (rol == 'admin') {
      return const AdminPage();
    } else {
      // Caso contrario -> topógrafo (mapa en tiempo real)
      return const MapPage();
    }
  }
}

