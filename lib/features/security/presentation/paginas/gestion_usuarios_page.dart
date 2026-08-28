import 'package:flutter/material.dart';
import '../../services/services.dart';
import 'menu_lateral_bip.dart';
import '../../../../core/security/servicio_permisos.dart';
import 'acceso_denegado_widget.dart';
import '../../../../models/proyecto.dart';

class GestionUsuariosPage extends StatefulWidget {
  final bool isEmbedded;
  final void Function(String tab, Proyecto? proyecto)? onNavigate;

  const GestionUsuariosPage({
    super.key,
    this.isEmbedded = false,
    this.onNavigate,
  });

  @override
  State<GestionUsuariosPage> createState() => _GestionUsuariosPageState();
}

class _GestionUsuariosPageState extends State<GestionUsuariosPage> {
  final _usuarioService = UsuarioService();
  final _rolService = RolService();

  List<Map<String, dynamic>> _usuarios = [];
  List<Map<String, dynamic>> _rolesDisponibles = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final usuarios = await _usuarioService.obtenerUsuariosConRoles();
      final roles = await _rolService.obtenerRoles();
      setState(() {
        _usuarios = usuarios;
        _rolesDisponibles = roles;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarMensaje('Error al cargar datos: $e', esError: true);
    }
  }

  void _abrirModalAsignarRoles(Map<String, dynamic> usuario) {
    // Extraer IDs de roles que el usuario ya tiene
    final List<dynamic> rolesActuales = usuario['usuarios_roles'] ?? [];
    final Set<String> rolesSeleccionados = rolesActuales
        .map((ur) => ur['rol_id'] as String)
        .toSet();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('Asignar Roles a: ${usuario['nombres']} ${usuario['apellidos']}'),
              content: SizedBox(
                width: 450,
                child: ListView(
                  shrinkWrap: true,
                  children: _rolesDisponibles.map((rol) {
                    final rolId = rol['id'] as String;
                    final estaSeleccionado = rolesSeleccionados.contains(rolId);
                    return CheckboxListTile(
                      title: Text(rol['nombre'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(rol['codigo'] ?? ''),
                      value: estaSeleccionado,
                      onChanged: (bool? valor) {
                        setModalState(() {
                          if (valor == true) {
                            rolesSeleccionados.add(rolId);
                          } else {
                            rolesSeleccionados.remove(rolId);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Asignación'),
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await _usuarioService.guardarRolesUsuario(
                        usuario['id'],
                        rolesSeleccionados.toList(),
                      );
                      _mostrarMensaje('Roles asignados exitosamente.');
                      _cargarDatos();
                    } catch (e) {
                      _mostrarMensaje('Error al guardar roles: $e', esError: true);
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

  void _abrirModalCrearUsuario() async {
    final instituciones = await _usuarioService.obtenerInstituciones();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nombresCtrl = TextEditingController();
    final apellidosCtrl = TextEditingController();
    final identidadCtrl = TextEditingController();
    final celularCtrl = TextEditingController();
    final cargoCtrl = TextEditingController();
    String? institucionSeleccionadaId;
    String? institucionSeleccionadaNombre;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Registrar Nuevo Colaborador'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () async {
                          final seleccion = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (context) => _BuscarInstitucionDialog(instituciones: instituciones),
                          );
                          if (seleccion != null) {
                            setModalState(() {
                              institucionSeleccionadaId = seleccion['id'];
                              institucionSeleccionadaNombre = '${seleccion['codigo']} - ${seleccion['nombre']}';
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Institución / UPEG',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                          child: Text(
                            institucionSeleccionadaNombre ?? 'Seleccione una institución...',
                            style: TextStyle(
                              color: institucionSeleccionadaNombre == null
                                  ? Colors.grey[600]
                                  : Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: nombresCtrl, decoration: const InputDecoration(labelText: 'Nombres', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(controller: apellidosCtrl, decoration: const InputDecoration(labelText: 'Apellidos', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(controller: identidadCtrl, decoration: const InputDecoration(labelText: 'DNI / Identidad', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(controller: celularCtrl, decoration: const InputDecoration(labelText: 'Celular', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(controller: cargoCtrl, decoration: const InputDecoration(labelText: 'Cargo Funcional', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Correo Institucional', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña Inicial', border: OutlineInputBorder())),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Registrar'),
                  onPressed: () async {
                    if (institucionSeleccionadaId == null || emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                      _mostrarMensaje('Complete los campos obligatorios.', esError: true);
                      return;
                    }
                    Navigator.pop(context);
                    try {
                      await _usuarioService.registrarUsuario(
                        email: emailCtrl.text.trim(),
                        password: passCtrl.text.trim(),
                        institucionId: institucionSeleccionadaId!,
                        nombres: nombresCtrl.text.trim(),
                        apellidos: apellidosCtrl.text.trim(),
                        identidad: identidadCtrl.text.trim(),
                        celular: celularCtrl.text.trim(),
                        cargo: cargoCtrl.text.trim(),
                      );
                      _mostrarMensaje('Usuario registrado correctamente.');
                      _cargarDatos();
                    } catch (e) {
                      _mostrarMensaje('Error al crear usuario: $e', esError: true);
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
      SnackBar(content: Text(texto), backgroundColor: esError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!ServicioPermisos().tiene('seguridad.usuarios.consultar')) {
      return const AccesoDenegadoWidget(
        permisoRequerido: 'seguridad.usuarios.consultar',
        tituloSeccion: 'Gestión de Usuarios',
      );
    }

    if (widget.isEmbedded) {
      return _buildBody(context);
    }

    return Scaffold(
      drawer: const MenuLateralBip(rutaActiva: 'usuarios'),
      appBar: AppBar(
        title: const Text('Gestión de Usuarios y Asignación de Roles'),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Nuevo Usuario'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF24389C), foregroundColor: Colors.white),
            onPressed: _abrirModalCrearUsuario,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_usuarios.isEmpty) {
      return const Center(child: Text('No hay usuarios registrados.'));
    }

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
                      'Gestión de Usuarios',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF191C1E),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Administración de cuentas institucionales y personal',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Usuario'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF24389C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _abrirModalCrearUsuario,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _usuarios.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, i) {
              final u = _usuarios[i];
              final institucion = u['instituciones']?['codigo'] ?? 'Sin Entidad';
              final List<dynamic> rolesAsignados = u['usuarios_roles'] ?? [];

                    return Card(
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: const Icon(Icons.person, color: Colors.indigo),
                        ),
                        title: Text(
                          '${u['nombres']} ${u['apellidos']} (${u['cargo']})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Institución: $institucion | DNI: ${u['identidad']} | Celular: ${u['celular']}'),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: rolesAsignados.isEmpty
                                  ? [const Chip(label: Text('Sin Roles', style: TextStyle(color: Colors.red, fontSize: 11)))]
                                  : rolesAsignados.map((ur) {
                                      final nombreRol = ur['roles']?['nombre'] ?? '';
                                      return Chip(
                                        backgroundColor: Colors.indigo.shade50,
                                        label: Text(nombreRol, style: const TextStyle(fontSize: 11, color: Colors.indigo)),
                                      );
                                    }).toList(),
                            ),
                          ],
                        ),
                        trailing: ElevatedButton.icon(
                          icon: const Icon(Icons.security, size: 18),
                          label: const Text('Asignar Roles'),
                          onPressed: () => _abrirModalAsignarRoles(u),
                        ),
                      ),
                    );
            },
          ),
        ),
      ],
    );
  }
}

class _BuscarInstitucionDialog extends StatefulWidget {
  final List<Map<String, dynamic>> instituciones;
  const _BuscarInstitucionDialog({required this.instituciones});

  @override
  State<_BuscarInstitucionDialog> createState() => _BuscarInstitucionDialogState();
}

class _BuscarInstitucionDialogState extends State<_BuscarInstitucionDialog> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.instituciones;
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.instituciones;
      } else {
        final q = query.toLowerCase();
        _filtered = widget.instituciones.where((inst) {
          final codigo = inst['codigo']?.toString().toLowerCase() ?? '';
          final nombre = inst['nombre']?.toString().toLowerCase() ?? '';
          return codigo.contains(q) || nombre.contains(q);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Buscar Institución / UPEG'),
      content: SizedBox(
        width: 450,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre o código...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filter,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final inst = _filtered[index];
                  return ListTile(
                    title: Text('${inst['codigo']} - ${inst['nombre']}'),
                    onTap: () => Navigator.pop(context, inst),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
