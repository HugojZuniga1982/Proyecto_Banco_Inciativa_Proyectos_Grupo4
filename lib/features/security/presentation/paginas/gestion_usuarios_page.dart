import 'package:flutter/material.dart';
import '../../services/services.dart';

class GestionUsuariosPage extends StatefulWidget {
  const GestionUsuariosPage({super.key});

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
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Institución / UPEG', border: OutlineInputBorder()),
                        items: instituciones.map((inst) {
                          return DropdownMenuItem<String>(
                            value: inst['id'],
                            child: Text('${inst['codigo']} - ${inst['nombre']}', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) => setModalState(() => institucionSeleccionadaId = val),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios y Asignación de Roles'),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Nuevo Usuario'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: _abrirModalCrearUsuario,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _usuarios.isEmpty
              ? const Center(child: Text('No hay usuarios registrados.'))
              : ListView.separated(
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
    );
  }
}
