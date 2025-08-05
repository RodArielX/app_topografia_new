import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Registro de usuario
  Future<AuthResponse> signUp(String email, String password, String nombre) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user != null) {
      // Insertar en la tabla usuarios
      await _supabase.from('usuarios').insert({
        'id': user.id,
        'email': email,
        'nombre': nombre,
        'rol': 'topografo',
      });
    }
    return response;
  }

  // Login
  Future<AuthResponse> signIn(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Obtener usuario actual
  User? get currentUser => _supabase.auth.currentUser;
}
