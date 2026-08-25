import 'package:supabase_flutter/supabase_flutter.dart';

class ServicioPermisos {
  static final ServicioPermisos _instancia = ServicioPermisos._interno();
  factory ServicioPermisos() => _instancia;
  ServicioPermisos._interno();

  final SupabaseClient _supabase = Supabase.instance.client;
  Set<String> _permisosUsuario = {};

  Future<void> cargarPermisosUsuario() async {
    try {
      final List<dynamic> respuesta = await _supabase.rpc('obtener_mis_permisos');
      _permisosUsuario = respuesta
          .map((fila) => fila['codigo_permiso'] as String)
          .toSet();
    } catch (e) {
      _permisosUsuario = {};
    }
  }

  bool tiene(String codigoPermiso) => _permisosUsuario.contains(codigoPermiso);
  bool tieneAlguno(Iterable<String> codigos) => codigos.any(tiene);
  bool tieneTodos(Iterable<String> codigos) => codigos.every(tiene);
  void limpiar() => _permisosUsuario.clear();
}
