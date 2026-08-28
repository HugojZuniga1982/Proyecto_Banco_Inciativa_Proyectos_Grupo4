import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/login_page.dart';
import '../../../proyectos/presentation/paginas/bandeja_proyectos_page.dart';
import '../../../proyectos/presentation/paginas/dashboard_gerencial_page.dart';
import 'administracion_roles_page.dart';
import 'gestion_usuarios_page.dart';
import '../../../../core/security/servicio_permisos.dart';

class MenuLateralBip extends StatelessWidget {
  final String rutaActiva;
  const MenuLateralBip({super.key, required this.rutaActiva});

  @override
  Widget build(BuildContext context) {
    final emailUsuario =
        Supabase.instance.client.auth.currentUser?.email ?? 'Usuario BIP';

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drawer Header con color primario oficial de Stitch (#24389c)
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF24389C),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.account_balance, color: Color(0xFF24389C), size: 36),
            ),
            accountName: const Text(
              'Sistema BIP Web',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(
              emailUsuario,
              style: const TextStyle(color: Colors.white70),
            ),
          ),

          // Menu Options
          Expanded(
            child: Builder(
              builder: (context) {
                final permisos = ServicioPermisos();
                final itemsMenu = <Widget>[];

                if (permisos.tiene('preinversion.dashboard.consultar')) {
                  itemsMenu.add(_buildMenuItem(
                    context,
                    title: 'Dashboard Gerencial',
                    icon: Icons.dashboard_outlined,
                    active: rutaActiva == 'dashboard',
                    onTap: () {
                      if (rutaActiva != 'dashboard') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DashboardGerencialPage(),
                          ),
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ));
                }

                if (permisos.tiene('preinversion.proyectos.consultar')) {
                  itemsMenu.add(_buildMenuItem(
                    context,
                    title: 'Bandeja de Proyectos',
                    icon: Icons.assignment_outlined,
                    active: rutaActiva == 'proyectos',
                    onTap: () {
                      if (rutaActiva != 'proyectos') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BandejaProyectosPage(),
                          ),
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ));
                }

                if (permisos.tiene('seguridad.usuarios.consultar')) {
                  itemsMenu.add(_buildMenuItem(
                    context,
                    title: 'Gestión de Usuarios',
                    icon: Icons.people_outline,
                    active: rutaActiva == 'usuarios',
                    onTap: () {
                      if (rutaActiva != 'usuarios') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GestionUsuariosPage(),
                          ),
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ));
                }

                if (permisos.tiene('seguridad.roles.consultar')) {
                  itemsMenu.add(_buildMenuItem(
                    context,
                    title: 'Perfiles y Permisos',
                    icon: Icons.security,
                    active: rutaActiva == 'roles',
                    onTap: () {
                      if (rutaActiva != 'roles') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdministracionRolesPage(),
                          ),
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ));
                }

                return ListView(
                  padding: EdgeInsets.zero,
                  children: itemsMenu,
                );
              }
            ),
          ),

          // Logout Item at the bottom
          const Divider(height: 1),
          _buildMenuItem(
            context,
            title: 'Cerrar Sesión',
            icon: Icons.logout_outlined,
            active: false,
            color: Colors.red,
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    Color? color,
  }) {
    final activeColor = color ?? const Color(0xFF24389C);

    return ListTile(
      leading: Icon(icon, color: active ? activeColor : (color ?? Colors.grey[700])),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          color: active ? activeColor : (color ?? Colors.black87),
        ),
      ),
      selected: active,
      selectedTileColor: activeColor.withValues(alpha: 0.1),
      onTap: onTap,
    );
  }
}
