import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // Obtener usuario actual
  User? get currentUser => supabase.auth.currentUser;

  // Iniciar sesión
  Future<void> signIn(String email, String password) async {
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (res.session == null) {
      throw Exception("❌ No se pudo iniciar sesión. Revisa tus credenciales.");
    }
  }

  // Registrarse (signUp estándar Supabase)
  Future<void> signUp(String email, String password, String nombre) async {
    final res = await supabase.auth.signUp(email: email, password: password);

    if (res.user == null) {
      throw Exception("❌ No se pudo registrar usuario.");
    }

    final userId = res.user!.id;
    print("Nuevo usuario ID: $userId");

    // Insertar datos extra en tabla usuarios
    final insert = await supabase.from('usuarios').insert({
      'id': userId,
      'nombre': nombre,
      'email': email,
      'rol': 'topografo', // Rol por defecto
      'activo': true,
    });

    if (insert.error != null) {
      // Si error por política, mostrar mensaje personalizado
      if (insert.error!.message.contains("violates row-level security policy")) {
        throw Exception("Confirma tu email e inicia sesión de nuevo.");
      }
      throw Exception("Error insertando usuario: ${insert.error!.message}");
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}

