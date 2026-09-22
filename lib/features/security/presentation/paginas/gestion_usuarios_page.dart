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
  List<Map<String, dynamic>> _institucionesDisponibles = [];
  bool _cargando = true;

  String _busqueda = '';
  String _filtroEstado = 'TODOS'; // 'TODOS', 'ACTIVO', 'INACTIVO'

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
      final insts = await _usuarioService.obtenerInstituciones();
      if (!mounted) return;
      setState(() {
        _usuarios = usuarios;
        _rolesDisponibles = roles;
        _institucionesDisponibles = insts;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      _mostrarMensaje('Error al cargar datos: $e', esError: true);
    }
  }

  List<Map<String, dynamic>> get _usuariosFiltrados {
    return _usuarios.where((u) {
      final estado = (u['estado'] ?? 'ACTIVO').toString().toUpperCase();
      if (_filtroEstado != 'TODOS' && estado != _filtroEstado) {
        return false;
      }
      if (_busqueda.trim().isNotEmpty) {
        final q = _busqueda.toLowerCase().trim();
        final nombres = (u['nombres'] ?? '').toString().toLowerCase();
        final apellidos = (u['apellidos'] ?? '').toString().toLowerCase();
        final identidad = (u['identidad'] ?? '').toString().toLowerCase();
        final celular = (u['celular'] ?? '').toString().toLowerCase();
        final cargo = (u['cargo'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        final instCodigo = (u['instituciones']?['codigo'] ?? '').toString().toLowerCase();
        final instNombre = (u['instituciones']?['nombre'] ?? '').toString().toLowerCase();

        return nombres.contains(q) ||
            apellidos.contains(q) ||
            email.contains(q) ||
            identidad.contains(q) ||
            celular.contains(q) ||
            cargo.contains(q) ||
            instCodigo.contains(q) ||
            instNombre.contains(q);
      }
      return true;
    }).toList();
  }

  int get _totalActivos => _usuarios.where((u) => (u['estado'] ?? 'ACTIVO') == 'ACTIVO').length;
  int get _totalInactivos => _usuarios.where((u) => (u['estado'] ?? 'ACTIVO') == 'INACTIVO').length;

  void _abrirModalAsignarRoles(Map<String, dynamic> usuario) {
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF24389C),
                    foregroundColor: Colors.white,
                  ),
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
    final instituciones = _institucionesDisponibles.isNotEmpty
        ? _institucionesDisponibles
        : await _usuarioService.obtenerInstituciones();

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
              title: const Row(
                children: [
                  Icon(Icons.person_add, color: Color(0xFF24389C)),
                  SizedBox(width: 8),
                  Text('Registrar Nuevo Colaborador'),
                ],
              ),
              content: SizedBox(
                width: 520,
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
                            labelText: 'Institución / UPEG *',
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
                      Row(
                        children: [
                          Expanded(child: TextField(controller: nombresCtrl, decoration: const InputDecoration(labelText: 'Nombres *', border: OutlineInputBorder()))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: apellidosCtrl, decoration: const InputDecoration(labelText: 'Apellidos *', border: OutlineInputBorder()))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: identidadCtrl, decoration: const InputDecoration(labelText: 'DNI / Identidad *', border: OutlineInputBorder()))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: celularCtrl, decoration: const InputDecoration(labelText: 'Celular *', border: OutlineInputBorder()))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: cargoCtrl, decoration: const InputDecoration(labelText: 'Cargo Funcional *', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Correo Institucional *', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña Inicial *', border: OutlineInputBorder())),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Registrar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF24389C),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (institucionSeleccionadaId == null ||
                        emailCtrl.text.trim().isEmpty ||
                        passCtrl.text.trim().isEmpty ||
                        nombresCtrl.text.trim().isEmpty ||
                        apellidosCtrl.text.trim().isEmpty) {
                      _mostrarMensaje('Por favor complete los campos obligatorios (*).', esError: true);
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
                      _mostrarMensaje('Usuario registrado correctamente con estado ACTIVO.');
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

  void _abrirModalEditarUsuario(Map<String, dynamic> usuario) async {
    final instituciones = _institucionesDisponibles.isNotEmpty
        ? _institucionesDisponibles
        : await _usuarioService.obtenerInstituciones();

    final nombresCtrl = TextEditingController(text: usuario['nombres'] ?? '');
    final apellidosCtrl = TextEditingController(text: usuario['apellidos'] ?? '');
    final identidadCtrl = TextEditingController(text: usuario['identidad'] ?? '');
    final celularCtrl = TextEditingController(text: usuario['celular'] ?? '');
    final cargoCtrl = TextEditingController(text: usuario['cargo'] ?? '');
    final emailCtrl = TextEditingController(text: usuario['email'] ?? '');

    String? institucionSeleccionadaId = usuario['institucion_id'] ?? usuario['instituciones']?['id'];
    String? institucionSeleccionadaNombre;
    if (usuario['instituciones'] != null) {
      final codigo = usuario['instituciones']['codigo'] ?? '';
      final nombre = usuario['instituciones']['nombre'] ?? '';
      institucionSeleccionadaNombre = '$codigo - $nombre';
    }

    String estadoSeleccionado = (usuario['estado'] ?? 'ACTIVO').toString().toUpperCase();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final esActivo = estadoSeleccionado == 'ACTIVO';

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.edit, color: Color(0xFF24389C)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Modificar Usuario: ${usuario['nombres']} ${usuario['apellidos']}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Selector de Institución
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
                            labelText: 'Institución / UPEG *',
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
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nombresCtrl,
                              decoration: const InputDecoration(labelText: 'Nombres *', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: apellidosCtrl,
                              decoration: const InputDecoration(labelText: 'Apellidos *', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: identidadCtrl,
                              decoration: const InputDecoration(labelText: 'DNI / Identidad *', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: celularCtrl,
                              decoration: const InputDecoration(labelText: 'Celular *', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: cargoCtrl,
                        decoration: const InputDecoration(labelText: 'Cargo Funcional *', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Correo Institucional / Acceso *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Estado Activo / Inactivo con Switch
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: esActivo ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: esActivo ? Colors.green.shade300 : Colors.red.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      esActivo ? Icons.check_circle : Icons.block,
                                      size: 18,
                                      color: esActivo ? Colors.green.shade800 : Colors.red.shade800,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Estado: $estadoSeleccionado',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: esActivo ? Colors.green.shade900 : Colors.red.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  esActivo
                                      ? 'El usuario puede iniciar sesión y operar en el BIP.'
                                      : 'El usuario NO podrá acceder al sistema (acceso revocado).',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: esActivo ? Colors.green.shade800 : Colors.red.shade800,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: esActivo,
                              activeThumbColor: Colors.green,
                              inactiveThumbColor: Colors.red,
                              onChanged: (val) {
                                setModalState(() {
                                  estadoSeleccionado = val ? 'ACTIVO' : 'INACTIVO';
                                });
                              },
                            ),
                          ],
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
                  label: const Text('Guardar Cambios'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF24389C),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (institucionSeleccionadaId == null ||
                        nombresCtrl.text.trim().isEmpty ||
                        apellidosCtrl.text.trim().isEmpty ||
                        identidadCtrl.text.trim().isEmpty ||
                        cargoCtrl.text.trim().isEmpty) {
                      _mostrarMensaje('Por favor complete todos los campos obligatorios (*).', esError: true);
                      return;
                    }
                    Navigator.pop(context);
                    try {
                      await _usuarioService.actualizarUsuario(
                        id: usuario['id'],
                        nombres: nombresCtrl.text.trim(),
                        apellidos: apellidosCtrl.text.trim(),
                        identidad: identidadCtrl.text.trim(),
                        celular: celularCtrl.text.trim(),
                        cargo: cargoCtrl.text.trim(),
                        institucionId: institucionSeleccionadaId!,
                        estado: estadoSeleccionado,
                        email: emailCtrl.text.trim(),
                      );
                      _mostrarMensaje('Usuario actualizado correctamente.');
                      _cargarDatos();
                    } catch (e) {
                      _mostrarMensaje('Error al actualizar usuario: $e', esError: true);
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

  void _confirmarCambioEstado(Map<String, dynamic> usuario) {
    final estadoActual = (usuario['estado'] ?? 'ACTIVO').toString().toUpperCase();
    final esActivo = estadoActual == 'ACTIVO';
    final nuevoEstado = esActivo ? 'INACTIVO' : 'ACTIVO';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                esActivo ? Icons.person_off : Icons.check_circle_outline,
                color: esActivo ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(esActivo ? 'Desactivar Colaborador' : 'Reactivar Colaborador'),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esActivo
                      ? '¿Está seguro de dejar INACTIVO a ${usuario['nombres']} ${usuario['apellidos']}?'
                      : '¿Desea reactivar a ${usuario['nombres']} ${usuario['apellidos']}?',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 20, color: Color(0xFF24389C)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          esActivo
                              ? 'Por políticas de auditoría y trazabilidad gubernamental (SEFIN / DGIP), los usuarios no son eliminados del sistema. Al inactivarlo, su cuenta no podrá iniciar sesión pero se preservará todo su historial de formulación y dictámenes.'
                              : 'Al reactivar al colaborador, podrá volver a iniciar sesión en la plataforma conservando sus roles y datos previamente asignados.',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF374151), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              icon: Icon(esActivo ? Icons.block : Icons.check),
              label: Text(esActivo ? 'Sí, Dejar Inactivo' : 'Sí, Reactivar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: esActivo ? Colors.red.shade700 : Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _usuarioService.cambiarEstadoUsuario(usuario['id'], nuevoEstado);
                  _mostrarMensaje(
                    esActivo
                        ? 'Usuario dejado como INACTIVO correctamente.'
                        : 'Usuario reactivado con éxito.',
                  );
                  _cargarDatos();
                } catch (e) {
                  _mostrarMensaje('Error al cambiar estado: $e', esError: true);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _mostrarMensaje(String texto, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: esError ? Colors.red.shade700 : Colors.green.shade700,
      ),
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
        title: const Text('Gestión de Usuarios y Colaboradores'),
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

    final esMovil = MediaQuery.of(context).size.width < 700;
    final lista = _usuariosFiltrados;

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
                        'Administración de cuentas institucionales, roles y vigencia de usuarios',
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

        // Barra de búsqueda, KPIs y Filtro de Estado
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de búsqueda y selector de filtro
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre, apellidos, DNI, cargo o institución...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _busqueda.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _busqueda = ''),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (val) => setState(() => _busqueda = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Filtros Rápidos de Estado
                  Wrap(
                    spacing: 6,
                    children: [
                      ChoiceChip(
                        label: Text('Todos (${_usuarios.length})'),
                        selected: _filtroEstado == 'TODOS',
                        onSelected: (_) => setState(() => _filtroEstado = 'TODOS'),
                      ),
                      ChoiceChip(
                        avatar: const Icon(Icons.check_circle, size: 14, color: Colors.green),
                        label: Text('Activos ($_totalActivos)'),
                        selected: _filtroEstado == 'ACTIVO',
                        selectedColor: Colors.green.shade100,
                        onSelected: (_) => setState(() => _filtroEstado = 'ACTIVO'),
                      ),
                      ChoiceChip(
                        avatar: const Icon(Icons.block, size: 14, color: Colors.red),
                        label: Text('Inactivos ($_totalInactivos)'),
                        selected: _filtroEstado == 'INACTIVO',
                        selectedColor: Colors.red.shade100,
                        onSelected: (_) => setState(() => _filtroEstado = 'INACTIVO'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Mensaje aclaratorio de trazabilidad gubernamental
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: Color(0xFF24389C)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Auditoría BIP: Los usuarios no se eliminan para garantizar la trazabilidad legal de proyectos; utilice "Inactivar" para suspender accesos.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Lista de Usuarios
        Expanded(
          child: lista.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_search, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'No se encontraron colaboradores con los criterios seleccionados.',
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: lista.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final u = lista[i];
                    final institucionCodigo = u['instituciones']?['codigo'] ?? '';
                    final institucionNombre = u['instituciones']?['nombre'] ?? 'Sin Entidad Asignada';
                    final List<dynamic> rolesAsignados = u['usuarios_roles'] ?? [];
                    final estado = (u['estado'] ?? 'ACTIVO').toString().toUpperCase();
                    final esActivo = estado == 'ACTIVO';

                    return Card(
                      elevation: esActivo ? 2 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: esActivo ? Colors.transparent : Colors.grey.shade300,
                        ),
                      ),
                      color: esActivo ? Colors.white : const Color(0xFFFAFAFA),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Avatar
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: esActivo
                                      ? const Color(0xFF24389C).withValues(alpha: 0.12)
                                      : Colors.grey.shade300,
                                  child: Icon(
                                    Icons.person,
                                    color: esActivo ? const Color(0xFF24389C) : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Datos de identificación
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${u['nombres']} ${u['apellidos']}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: esActivo ? const Color(0xFF1E293B) : Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                          // Badge de Estado ACTIVO / INACTIVO
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: esActivo ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: esActivo ? Colors.green.shade300 : Colors.red.shade300,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  esActivo ? Icons.check_circle : Icons.block,
                                                  size: 12,
                                                  color: esActivo ? Colors.green.shade700 : Colors.red.shade700,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  estado,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: esActivo ? Colors.green.shade800 : Colors.red.shade800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Cargo: ${u['cargo'] ?? 'Sin Cargo'}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blueGrey.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Institución: $institucionCodigo - $institucionNombre',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                      ),
                                      Text(
                                        'DNI: ${u['identidad'] ?? 'N/A'}  |  Celular: ${u['celular'] ?? 'N/A'}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(Icons.email_outlined, size: 13, color: Color(0xFF24389C)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Correo: ',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                                          ),
                                          Expanded(
                                            child: Text(
                                              u['email'] != null && u['email'].toString().trim().isNotEmpty
                                                  ? u['email']
                                                  : 'Sin correo registrado',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF24389C),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Roles Chips
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text('Roles: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                if (rolesAsignados.isEmpty)
                                  const Chip(
                                    visualDensity: VisualDensity.compact,
                                    label: Text('Sin Roles Asignados', style: TextStyle(color: Colors.red, fontSize: 10)),
                                  )
                                else
                                  ...rolesAsignados.map((ur) {
                                    final nombreRol = ur['roles']?['nombre'] ?? '';
                                    return Chip(
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: const Color(0xFFEEF2FF),
                                      side: BorderSide(color: Colors.indigo.shade200),
                                      label: Text(
                                        nombreRol,
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF24389C), fontWeight: FontWeight.w500),
                                      ),
                                    );
                                  }),
                              ],
                            ),
                            const Divider(height: 18),
                            // Botones de Acción (Modificar, Roles, Inactivar/Activar)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Botón Modificar / Editar
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: Text(esMovil ? 'Editar' : 'Modificar Datos'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF24389C),
                                    side: const BorderSide(color: Color(0xFF24389C)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: () => _abrirModalEditarUsuario(u),
                                ),
                                const SizedBox(width: 8),
                                // Botón Asignar Roles
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.security, size: 16),
                                  label: Text(esMovil ? 'Roles' : 'Asignar Roles'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF24389C),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: () => _abrirModalAsignarRoles(u),
                                ),
                                const SizedBox(width: 8),
                                // Botón Inactivar / Activar (No eliminación física)
                                if (esActivo)
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.person_off, size: 16),
                                    label: Text(esMovil ? 'Inactivar' : 'Dejar Inactivo'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red.shade700,
                                      side: BorderSide(color: Colors.red.shade300),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onPressed: () => _confirmarCambioEstado(u),
                                  )
                                else
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.check_circle_outline, size: 16),
                                    label: Text(esMovil ? 'Activar' : 'Reactivar Usuario'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.green.shade700,
                                      side: BorderSide(color: Colors.green.shade300),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onPressed: () => _confirmarCambioEstado(u),
                                  ),
                              ],
                            ),
                          ],
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
