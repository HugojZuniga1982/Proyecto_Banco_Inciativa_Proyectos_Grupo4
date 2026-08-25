import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:proyecto_programacion_movil_grupo_4/models/models.dart';

class RolService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> obtenerRoles() async {
    final respuesta = await _supabase
        .from('roles')
        .select('id, codigo, nombre, descripcion')
        .eq('esta_activo', true)
        .order('nombre');
    return List<Map<String, dynamic>>.from(respuesta);
  }

  Future<List<NodoRecurso>> obtenerArbolPermisos(String idRol) async {
    final respuesta =
        await _supabase.rpc(
              'obtener_arbol_permisos_rol',
              params: {'id_rol': idRol},
            )
            as List<dynamic>;

    final Map<String, NodoRecurso> mapaNodos = {};
    final List<NodoRecurso> raices = [];

    for (var raw in respuesta) {
      final listaPermisos = (raw['permisos'] as List<dynamic>)
          .map(
            (p) => ItemPermiso(
              id: p['permiso_id'],
              codigo: p['codigo'],
              nombre: p['nombre'],
              estaOtorgado: p['esta_otorgado'] ?? false,
            ),
          )
          .toList();

      mapaNodos[raw['recurso_id']] = NodoRecurso(
        id: raw['recurso_id'],
        recursoPadreId: raw['recurso_padre_id'],
        codigo: raw['codigo'],
        nombre: raw['nombre'],
        tipoRecurso: raw['tipo_recurso'],
        permisos: listaPermisos,
      );
    }

    for (var nodo in mapaNodos.values) {
      if (nodo.recursoPadreId == null) {
        raices.add(nodo);
      } else if (mapaNodos.containsKey(nodo.recursoPadreId)) {
        mapaNodos[nodo.recursoPadreId]!.hijos.add(nodo);
      }
    }
    return raices;
  }

  Future<void> guardarPermisos(String idRol, List<String> idsPermisos) async {
    await _supabase.rpc(
      'guardar_permisos_rol',
      params: {'id_rol': idRol, 'ids_permisos': idsPermisos},
    );
  }
}
