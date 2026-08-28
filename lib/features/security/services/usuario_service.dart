import 'package:supabase_flutter/supabase_flutter.dart';

class UsuarioService {
  SupabaseClient get _supabase => Supabase.instance.client;

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

  // 2. Obtener lista de instituciones activas para el selector, ordenadas por código de menor a mayor
  Future<List<Map<String, dynamic>>> obtenerInstituciones() async {
    final respuesta = await _supabase
        .from('instituciones')
        .select('id, codigo, nombre')
        .eq('estado', 'ACTIVO');

    final lista = List<Map<String, dynamic>>.from(respuesta);

    // Ordenamiento natural por código (ej. 1, 2, 1.101, 10, 100, 411)
    lista.sort((a, b) {
      final String codA = a['codigo']?.toString() ?? '';
      final String codB = b['codigo']?.toString() ?? '';

      final partsA = codA.split('.');
      final partsB = codB.split('.');

      for (int i = 0; i < partsA.length && i < partsB.length; i++) {
        final int? valA = int.tryParse(partsA[i]);
        final int? valB = int.tryParse(partsB[i]);

        if (valA != null && valB != null) {
          if (valA != valB) {
            return valA.compareTo(valB);
          }
        } else {
          final comp = partsA[i].compareTo(partsB[i]);
          if (comp != 0) return comp;
        }
      }
      return partsA.length.compareTo(partsB.length);
    });

    return lista;
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
