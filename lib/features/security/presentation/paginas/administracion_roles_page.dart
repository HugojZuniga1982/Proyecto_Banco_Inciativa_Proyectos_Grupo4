import 'package:flutter/material.dart';
import 'package:proyecto_programacion_movil_grupo_4/models/models.dart';
import '../../services/services.dart';
import 'gestion_usuarios_page.dart';
import 'pagina_prueba_permisos.dart';

class AdministracionRolesPage extends StatefulWidget {
  const AdministracionRolesPage({super.key});

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
    return Scaffold(
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
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.people_outline),
            label: const Text('Gestionar Usuarios y Roles'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GestionUsuariosPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Panel Izquierdo: Lista de Perfiles / Roles
          SizedBox(
            width: 320,
            child: Card(
              margin: const EdgeInsets.all(8),
              child: ListView.separated(
                itemCount: _roles.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
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
                    selectedTileColor: Colors.blue.withOpacity(0.1),
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
