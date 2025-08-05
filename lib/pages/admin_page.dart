import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';
import 'admin_locations.dart';
import 'lista_terrenos_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final supabase = Supabase.instance.client;

  Future<void> _logout(BuildContext context) async {
    await supabase.auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
    }
  }

  Future<void> _deleteUser(String id) async {
    await supabase.from('usuarios').delete().eq('id', id);
  }

  Future<void> _toggleActivo(String id, bool activo) async {
    await supabase.from('usuarios').update({'activo': !activo}).eq('id', id);
  }

  void _showAddUserDialog(BuildContext context) {
    final nombreController = TextEditingController();
    final emailController = TextEditingController();
    final rolController = TextEditingController(text: "topografo");

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("➕ Agregar Usuario"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: "Nombre",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField(
                value: "topografo",
                items: const [
                  DropdownMenuItem(value: "topografo", child: Text("Topógrafo")),
                  DropdownMenuItem(value: "admin", child: Text("Administrador")),
                ],
                onChanged: (value) {
                  rolController.text = value.toString();
                },
                decoration: const InputDecoration(
                  labelText: "Rol",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar"),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await supabase.from('usuarios').insert({
                  'nombre': nombreController.text,
                  'email': emailController.text,
                  'rol': rolController.text,
                  'activo': true,
                });
                if (context.mounted) Navigator.pop(ctx);
              },
              icon: const Icon(Icons.check),
              label: const Text("Agregar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue.shade800,
          title: const Text(
            "📊 Panel de Administración",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.people), text: "Usuarios"),
              Tab(icon: Icon(Icons.map), text: "Ubicaciones"),
              Tab(icon: Icon(Icons.landscape), text: "Terrenos"),
            ],
          ),
          actions: [
            IconButton(
              tooltip: "Cerrar sesión",
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // 🔹 Lista de usuarios con tarjetas
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('usuarios').stream(primaryKey: ['id']).execute(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final usuarios = snapshot.data!;
                if (usuarios.isEmpty) {
                  return const Center(
                    child: Text("No hay usuarios registrados 👥"),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: usuarios.length,
                  itemBuilder: (context, index) {
                    final user = usuarios[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: user['activo'] ? Colors.green : Colors.red,
                          child: Icon(
                            user['rol'] == 'admin' ? Icons.verified_user : Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          "${user['nombre']} (${user['rol']})",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(user['email']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: user['activo'] ? "Desactivar" : "Activar",
                              icon: Icon(
                                user['activo'] ? Icons.pause_circle : Icons.play_circle,
                                color: Colors.orange,
                              ),
                              onPressed: () => _toggleActivo(user['id'], user['activo']),
                            ),
                            IconButton(
                              tooltip: "Eliminar usuario",
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteUser(user['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // 🔹 Ubicaciones
            const AdminLocations(),

            // 🔹 Terrenos
            const ListaTerrenosPage(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _showAddUserDialog(context);
          },
          icon: const Icon(Icons.person_add),
          label: const Text("Usuario"),
        ),
      ),
    );
  }
}

