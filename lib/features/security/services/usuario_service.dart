import 'package:supabase_flutter/supabase_flutter.dart';

class UsuarioService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. Obtener lista de usuarios con su institución y roles asignados
  Future<List<Map<String, dynamic>>> obtenerUsuariosConRoles() async {
    final respuesta = await _supabase.from('perfiles').select('''
      id, nombres, apellidos, identidad, celular, cargo, estado,
      instituciones (id, codigo, nombre),
      usuarios_roles (
        rol_id,
        roles (id, codigo, nombre)
      )
    ''').order('fecha_creacion', ascending: false);

    return List<Map<String, dynamic>>.from(respuesta);
  }

  // 2. Obtener lista de instituciones activas para el selector
  Future<List<Map<String, dynamic>>> obtenerInstituciones() async {
    final respuesta = await _supabase
        .from('instituciones')
        .select('id, codigo, nombre')
        .eq('estado', 'ACTIVO')
        .order('nombre');
    return List<Map<String, dynamic>>.from(respuesta);
  }

  // 3. Registrar nuevo usuario institucional en Supabase Auth
  Future<void> registrarUsuario({
    required String email,
    required String password,
    required String institucionId,
    required String nombres,
    required String apellidos,
    required String identidad,
    required String celular,
    required String cargo,
  }) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'institucion_id': institucionId,
        'nombres': nombres,
        'apellidos': apellidos,
        'identidad': identidad,
        'celular': celular,
        'cargo': cargo,
      },
    );
  }

  // 4. Guardar los roles asignados a un usuario específico
  Future<void> guardarRolesUsuario(String usuarioId, List<String> rolesIds) async {
    await _supabase.rpc('guardar_roles_usuario', params: {
      'id_usuario': usuarioId,
      'ids_roles': rolesIds,
    });
  }
}
