import 'package:flutter/material.dart';
import '../../../../models/models.dart';
import '../../services/rol_service.dart';
import 'pagina_prueba_permisos.dart';
import 'menu_lateral_bip.dart';
import '../../../../core/security/servicio_permisos.dart';
import 'acceso_denegado_widget.dart';

class AdministracionRolesPage extends StatefulWidget {
  final bool isEmbedded;
  final void Function(String tab, Proyecto? proyecto)? onNavigate;

  const AdministracionRolesPage({
    super.key,
    this.isEmbedded = false,
    this.onNavigate,
  });

  @override
  State<AdministracionRolesPage> createState() =>
      _AdministracionRolesPageState();
}

class _AdministracionRolesPageState extends State<AdministracionRolesPage> {
  final _rolService = RolService();
  List<Map<String, dynamic>> _roles = [];
  String? _rolSeleccionadoId;
  List<NodoRecurso> _arbol = [];
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarRoles();
  }

  Future<void> _cargarRoles() async {
    try {
      final roles = await _rolService.obtenerRoles();
      setState(() => _roles = roles);
    } catch (e) {
      _mostrarMensaje('Error al cargar roles: $e', esError: true);
    }
  }

  Future<void> _seleccionarRol(String idRol) async {
    setState(() {
      _rolSeleccionadoId = idRol;
      _cargando = true;
    });
    try {
      final arbol = await _rolService.obtenerArbolPermisos(idRol);
      setState(() {
        _arbol = arbol;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarMensaje('Error al cargar permisos: $e', esError: true);
    }
  }

  Future<void> _guardar() async {
    if (_rolSeleccionadoId == null) return;

    final List<String> otorgados = [];
    void extraer(NodoRecurso nodo) {
      for (var p in nodo.permisos) {
        if (p.estaOtorgado) otorgados.add(p.id);
      }
      for (var h in nodo.hijos) {
        extraer(h);
      }
    }

    for (var raiz in _arbol) {
      extraer(raiz);
    }

    try {
      await _rolService.guardarPermisos(_rolSeleccionadoId!, otorgados);
      _mostrarMensaje('Permisos actualizados correctamente.');
    } catch (e) {
      _mostrarMensaje('Error al guardar cambios: $e', esError: true);
    }
  }

  void _mostrarMensaje(String texto, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: esError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!ServicioPermisos().tiene('seguridad.roles.consultar')) {
      return const AccesoDenegadoWidget(
        permisoRequerido: 'seguridad.roles.consultar',
        tituloSeccion: 'Perfiles y Permisos',
      );
    }

    if (widget.isEmbedded) {
      return _buildBody(context);
    }

    return Scaffold(
      drawer: const MenuLateralBip(rutaActiva: 'roles'),
      appBar: AppBar(
        title: const Text('Administración de Perfiles y Permisos'),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.science_outlined),
            label: const Text('Ir a Pruebas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaginaPruebaPermisos(),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        if (widget.isEmbedded) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perfiles y Permisos',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF191C1E),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Administración de roles del sistema y asignación de permisos',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Ir a Pruebas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF24389C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaginaPruebaPermisos(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
        Expanded(
          child: Row(
            children: [
          // Panel Izquierdo: Lista de Perfiles / Roles
          SizedBox(
            width: 320,
            child: Card(
              margin: const EdgeInsets.all(8),
              child: ListView.separated(
                itemCount: _roles.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final rol = _roles[i];
                  final seleccionado = rol['id'] == _rolSeleccionadoId;
                  return ListTile(
                    title: Text(
                      rol['nombre'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(rol['codigo'] ?? ''),
                    selected: seleccionado,
                    selectedTileColor: Colors.blue.withValues(alpha: 0.1),
                    onTap: () => _seleccionarRol(rol['id']),
                  );
                },
              ),
            ),
          ),

          // Panel Derecho: Árbol de Permisos
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(8),
              child: _rolSeleccionadoId == null
                  ? const Center(
                      child: Text(
                        'Seleccione un perfil para visualizar su árbol de permisos.',
                      ),
                    )
                  : _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          color: Colors.amber.shade100,
                          child: Row(
                            children: [
                              const Text(
                                'Asignar Permisos a un Perfil de Sistema',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.save),
                                label: const Text('Guardar Permisos'),
                                onPressed: _guardar,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(12),
                            children: _arbol
                                .map(
                                  (nodo) => _WidgetNodoArbol(
                                    nodo: nodo,
                                    onRefrescar: () => setState(() {}),
                                  ),
                                )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WidgetNodoArbol extends StatelessWidget {
  final NodoRecurso nodo;
  final VoidCallback onRefrescar;

  const _WidgetNodoArbol({required this.nodo, required this.onRefrescar});

  @override
  Widget build(BuildContext context) {
    final estado = nodo.estadoSeleccion;

    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (nodo.hijos.isNotEmpty || nodo.permisos.isNotEmpty)
                IconButton(
                  iconSize: 18,
                  icon: Icon(
                    nodo.estaExpandido
                        ? Icons.remove_circle_outline
                        : Icons.add_circle_outline,
                  ),
                  onPressed: () {
                    nodo.estaExpandido = !nodo.estaExpandido;
                    onRefrescar();
                  },
                )
              else
                const SizedBox(width: 32),

              Checkbox(
                value: estado == EstadoSeleccion.indeterminado
                    ? null
                    : (estado == EstadoSeleccion.marcado),
                tristate: true,
                onChanged: (val) {
                  nodo.seleccionarEnCascada(val ?? false);
                  onRefrescar();
                },
              ),
              const Icon(Icons.folder_open, size: 18, color: Colors.blueGrey),
              const SizedBox(width: 8),
              Text(
                nodo.nombre,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (nodo.estaExpandido) ...[
            ...nodo.permisos.map(
              (p) => Padding(
                padding: const EdgeInsets.only(left: 48.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: p.estaOtorgado,
                      onChanged: (val) {
                        p.estaOtorgado = val ?? false;
                        onRefrescar();
                      },
                    ),
                    const Icon(Icons.key, size: 14, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text(p.nombre),
                  ],
                ),
              ),
            ),
            ...nodo.hijos.map(
              (hijo) => _WidgetNodoArbol(nodo: hijo, onRefrescar: onRefrescar),
            ),
          ],
        ],
      ),
    );
  }
}
