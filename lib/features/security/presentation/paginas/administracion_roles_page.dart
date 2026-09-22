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

  Map<String, dynamic>? get _rolSeleccionado {
    try {
      return _roles.firstWhere((r) => r['id'] == _rolSeleccionadoId);
    } catch (_) {
      return null;
    }
  }

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
      _mostrarMensaje('Permisos del perfil actualizados correctamente.');
    } catch (e) {
      _mostrarMensaje('Error al guardar cambios: $e', esError: true);
    }
  }

  void _abrirModalCrearRol() {
    final nombreCtrl = TextEditingController();
    final codigoCtrl = TextEditingController();
    final descripcionCtrl = TextEditingController();
    bool codigoModificadoManualmente = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.add_moderator, color: Color(0xFF24389C)),
                  SizedBox(width: 8),
                  Text('Crear Nuevo Perfil / Rol'),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Defina el nombre y descripción del nuevo perfil de acceso. Tras guardarlo, podrá configurar sus permisos en el panel derecho.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nombreCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Perfil *',
                          hintText: 'Ej. Usuario de Consulta, Auditor Externo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        onChanged: (val) {
                          if (!codigoModificadoManualmente) {
                            // Generar sugerencia de código en mayúsculas
                            final sugerido = val
                                .trim()
                                .toUpperCase()
                                .replaceAll(RegExp(r'[^A-Z0-9\s]'), '')
                                .replaceAll(RegExp(r'\s+'), '_');
                            setModalState(() {
                              codigoCtrl.text = sugerido;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: codigoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Código Identificador *',
                          hintText: 'Ej. USUARIO_CONSULTA',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.code),
                        ),
                        onChanged: (_) {
                          codigoModificadoManualmente = true;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descripcionCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descripción Funcional',
                          hintText: 'Detalle el propósito y alcance que tendrá este perfil en el sistema BIP...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Crear Perfil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF24389C),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (nombreCtrl.text.trim().isEmpty || codigoCtrl.text.trim().isEmpty) {
                      _mostrarMensaje('El nombre y código del perfil son requeridos.', esError: true);
                      return;
                    }
                    Navigator.pop(context);
                    try {
                      final nuevoRol = await _rolService.crearRol(
                        codigo: codigoCtrl.text.trim(),
                        nombre: nombreCtrl.text.trim(),
                        descripcion: descripcionCtrl.text.trim(),
                      );
                      _mostrarMensaje('Perfil "${nuevoRol['nombre']}" creado exitosamente. Configure sus permisos.');
                      await _cargarRoles();
                      if (nuevoRol['id'] != null) {
                        _seleccionarRol(nuevoRol['id']);
                      }
                    } catch (e) {
                      _mostrarMensaje('Error al crear perfil: $e', esError: true);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
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
            icon: const Icon(Icons.add_moderator),
            label: const Text('Nuevo Perfil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF24389C),
              foregroundColor: Colors.white,
            ),
            onPressed: _abrirModalCrearRol,
          ),
          const SizedBox(width: 8),
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
    final esMovil = MediaQuery.of(context).size.width < 768;

    return Column(
      children: [
        if (widget.isEmbedded) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
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
                        'Administración de roles institucionales y asignación de permisos de acceso',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_moderator),
                  label: const Text('Nuevo Perfil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF24389C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _abrirModalCrearRol,
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Ir a Pruebas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              if (!esMovil || _rolSeleccionadoId == null)
                Expanded(
                  flex: esMovil ? 1 : 0,
                  child: SizedBox(
                    width: esMovil ? null : 340,
                    child: Card(
                      margin: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.shield, size: 18, color: Color(0xFF24389C)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Perfiles (${_roles.length})',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle, color: Color(0xFF24389C)),
                                  tooltip: 'Crear nuevo perfil',
                                  onPressed: _abrirModalCrearRol,
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView.separated(
                              itemCount: _roles.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final rol = _roles[i];
                                final seleccionado = rol['id'] == _rolSeleccionadoId;
                                return ListTile(
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: seleccionado
                                        ? const Color(0xFF24389C)
                                        : Colors.grey.shade200,
                                    child: Icon(
                                      Icons.admin_panel_settings_outlined,
                                      size: 16,
                                      color: seleccionado ? Colors.white : Colors.grey.shade700,
                                    ),
                                  ),
                                  title: Text(
                                    rol['nombre'] ?? '',
                                    style: TextStyle(
                                      fontWeight: seleccionado ? FontWeight.bold : FontWeight.w600,
                                      color: seleccionado ? const Color(0xFF24389C) : Colors.black87,
                                    ),
                                  ),
                                  subtitle: Text(
                                    rol['codigo'] ?? '',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                  selected: seleccionado,
                                  selectedTileColor: const Color(0xFFEEF2FF),
                                  onTap: () => _seleccionarRol(rol['id']),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Panel Derecho: Árbol de Permisos
              if (!esMovil || _rolSeleccionadoId != null)
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    child: _rolSeleccionadoId == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.security, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                const Text(
                                  'Seleccione un perfil de la lista izquierda para configurar sus permisos.',
                                  style: TextStyle(color: Colors.grey, fontSize: 15),
                                ),
                              ],
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
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2FF),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                      border: Border(bottom: BorderSide(color: Colors.indigo.shade100)),
                                    ),
                                    child: Row(
                                      children: [
                                        if (esMovil)
                                          IconButton(
                                            icon: const Icon(Icons.arrow_back),
                                            onPressed: () => setState(() {
                                              _rolSeleccionadoId = null;
                                            }),
                                          ),
                                        const Icon(Icons.lock_open, size: 20, color: Color(0xFF24389C)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Permisos para: ${_rolSeleccionado?['nombre'] ?? 'Perfil'}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Color(0xFF1E293B),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (_rolSeleccionado?['descripcion'] != null &&
                                                  _rolSeleccionado!['descripcion'].toString().isNotEmpty)
                                                Text(
                                                  _rolSeleccionado!['descripcion'],
                                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.save, size: 16),
                                          label: Text(esMovil ? 'Guardar' : 'Guardar Permisos'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF24389C),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          ),
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
              Checkbox(
                tristate: true,
                value: estado == EstadoSeleccion.marcado
                    ? true
                    : estado == EstadoSeleccion.desmarcado
                        ? false
                        : null,
                onChanged: (bool? valor) {
                  nodo.seleccionarEnCascada(valor ?? false);
                  onRefrescar();
                },
              ),
              Icon(
                nodo.tipoRecurso == 'MODULO'
                    ? Icons.folder_open
                    : Icons.description_outlined,
                size: 18,
                color: Colors.blueGrey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nodo.nombre,
                  style: TextStyle(
                    fontWeight: nodo.tipoRecurso == 'MODULO'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          if (nodo.permisos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 32.0, bottom: 8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: nodo.permisos.map((p) {
                  return FilterChip(
                    label: Text(p.nombre, style: const TextStyle(fontSize: 12)),
                    selected: p.estaOtorgado,
                    onSelected: (bool valor) {
                      p.estaOtorgado = valor;
                      onRefrescar();
                    },
                  );
                }).toList(),
              ),
            ),
          if (nodo.hijos.isNotEmpty)
            Column(
              children: nodo.hijos
                  .map(
                    (hijo) => _WidgetNodoArbol(
                      nodo: hijo,
                      onRefrescar: onRefrescar,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
