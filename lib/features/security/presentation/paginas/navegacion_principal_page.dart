import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/security/servicio_permisos.dart';
import '../../../proyectos/presentation/paginas/bandeja_proyectos_page.dart';
import '../../../proyectos/presentation/paginas/dashboard_gerencial_page.dart';
import '../../../proyectos/presentation/paginas/ficha_proyecto_page.dart';
import '../../../../models/proyecto.dart';
import '../../../auth/presentation/login_page.dart';
import 'administracion_roles_page.dart';
import 'gestion_usuarios_page.dart';
import 'package:proyecto_programacion_movil_grupo_4/features/proyectos/presentation/paginas/reportes_page.dart';

class NavegacionPrincipalPage extends StatefulWidget {
  const NavegacionPrincipalPage({super.key});

  @override
  State<NavegacionPrincipalPage> createState() => _NavegacionPrincipalPageState();
}

class _NavegacionPrincipalPageState extends State<NavegacionPrincipalPage> {
  String _activeTab = 'proyectos';
  Proyecto? _proyectoAEditar;
  bool _sidebarExpanded = true;

  void _onNavigate(String tab, Proyecto? proyecto) {
    setState(() {
      _activeTab = tab;
      _proyectoAEditar = proyecto;
    });
  }

  Widget _buildActiveBody() {
  switch (_activeTab) {
    case 'dashboard':
      return DashboardGerencialPage(
        isEmbedded: true,
        onNavigate: _onNavigate,
      );
    case 'reportes':
      return const ReportesPage();
    case 'registro':
      return FichaProyectoPage(
        isEmbedded: true,
        proyectoAEditar: _proyectoAEditar,
        onNavigate: _onNavigate,
      );
    case 'proyectos':
      return BandejaProyectosPage(
        isEmbedded: true,
        onNavigate: _onNavigate,
      );
    case 'usuarios':
      return GestionUsuariosPage(
        isEmbedded: true,
        onNavigate: _onNavigate,
      );
    case 'roles':
      return AdministracionRolesPage(
        isEmbedded: true,
        onNavigate: _onNavigate,
      );
    default:
      return const Center(child: Text('Módulo no encontrado'));
  }
}

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final emailUsuario =
        Supabase.instance.client.auth.currentUser?.email ?? 'admin@bip.gob';

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: Row(
          children: [
            // Left Sidebar matching Stitch styling
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: _sidebarExpanded ? 288 : 80,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(1, 0),
                  ),
                ],
              ),
              child: _buildSidebar(emailUsuario),
            ),

            // Main Content Area (Header + Body)
            Expanded(
              child: Column(
                children: [
                  // Top Header matching Stitch
                  _buildHeader(emailUsuario),

                  // Ribbon banner for non-global admin users
                  if (!ServicioPermisos().esAdministradorGlobal &&
                      ServicioPermisos().userInstitucionNombre != null)
                    Container(
                      color: const Color(0xFF24389C),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.business, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Área de Trabajo Institucional: ${ServicioPermisos().userInstitucionNombre}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Active Screen View
                  Expanded(
                    child: Container(
                      color: const Color(0xFFF7F9FC),
                      child: _buildActiveBody(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Mobile View: Scaffold with Drawer
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        drawer: Drawer(
          child: _buildSidebar(emailUsuario),
        ),
        appBar: AppBar(
          title: const Text('Sistema BIP Web'),
        ),
        body: Column(
          children: [
            if (!ServicioPermisos().esAdministradorGlobal &&
                ServicioPermisos().userInstitucionNombre != null)
              Container(
                color: const Color(0xFF24389C),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: Text(
                  'Institución: ${ServicioPermisos().userInstitucionNombre}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(child: _buildActiveBody()),
          ],
        ),
      );
    }
  }

  Widget _buildSidebar(String email) {
    final permisos = ServicioPermisos();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sidebar Logo Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFDEE0FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: Color(0xFF24389C),
                  size: 24,
                ),
              ),
              if (_sidebarExpanded) ...[
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'BIP Web',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF24389C),
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Proyectos',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Navigation Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              if (permisos.tiene('preinversion.dashboard.consultar'))
                _buildSidebarItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  tabId: 'dashboard',
                ),
                if (permisos.tiene('preinversion.dashboard.consultar'))
                _buildSidebarItem(
                icon: Icons.bar_chart_outlined,
                label: 'Reportes',
                 tabId: 'reportes',
                 ),
              _buildSidebarItem(
                icon: Icons.edit_document,
                label: 'Registro de Ficha',
                tabId: 'registro',
              ),
              if (permisos.tiene('preinversion.proyectos.consultar'))
                _buildSidebarItem(
                  icon: Icons.folder_open_outlined,
                  label: 'Bandeja de Proyectos',
                  tabId: 'proyectos',
                ),

              if (permisos.tiene('seguridad.usuarios.consultar') ||
                  permisos.tiene('seguridad.roles.consultar')) ...[
                const SizedBox(height: 16),
                if (_sidebarExpanded)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'CONFIGURACIÓN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                  )
                else
                  const Divider(),
                if (permisos.tiene('seguridad.usuarios.consultar'))
                  _buildSidebarItem(
                    icon: Icons.people_outline,
                    label: 'Gestión de Usuarios',
                    tabId: 'usuarios',
                  ),
                if (permisos.tiene('seguridad.roles.consultar'))
                  _buildSidebarItem(
                    icon: Icons.security,
                    label: 'Perfiles y Permisos',
                    tabId: 'roles',
                  ),
              ],
            ],
          ),
        ),

        // User profile info card at bottom
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFECEEF1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF24389C),
                  child: Icon(Icons.person, size: 18, color: Colors.white),
                ),
                if (_sidebarExpanded) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Usuario BIP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF191C1E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, size: 18, color: Colors.red),
                    tooltip: 'Cerrar Sesión',
                    onPressed: _cerrarSesion,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required String tabId,
  }) {
    final active = _activeTab == tabId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _activeTab = tabId;
            if (tabId != 'registro') {
              _proyectoAEditar = null;
            }
          });
          // On mobile, close drawer after tap
          final isMobile = MediaQuery.of(context).size.width <= 900;
          if (isMobile) {
            Navigator.pop(context);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFDEE0FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: active ? const Color(0xFF24389C) : Colors.grey[700],
              ),
              if (_sidebarExpanded) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      color: active ? const Color(0xFF24389C) : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String email) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Menu Toggle + Title
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    _sidebarExpanded = !_sidebarExpanded;
                  });
                },
              ),
              const SizedBox(width: 12),
              const Text(
                'Sistema BIP Web',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF191C1E),
                ),
              ),
            ],
          ),

          // Right: Search Bar + Actions + Avatar
          Row(
            children: [
              // Search input
              Container(
                width: 240,
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECEEF1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Buscar proyectos...',
                          hintStyle: TextStyle(fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13),
                        onChanged: (v) {
                          // Search trigger can be bound here if required
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Icons
              const Icon(Icons.notifications_none_outlined, color: Colors.grey),
              const SizedBox(width: 16),
              const Icon(Icons.help_outline, color: Colors.grey),
              const SizedBox(width: 20),

              // Mini Avatar
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF24389C),
                child: Icon(Icons.person, size: 18, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _cerrarSesion() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }
}
