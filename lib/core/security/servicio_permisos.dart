import 'package:supabase_flutter/supabase_flutter.dart';

class ServicioPermisos {
  static final ServicioPermisos _instancia = ServicioPermisos._interno();
  factory ServicioPermisos() => _instancia;
  ServicioPermisos._interno();

  SupabaseClient get _supabase => Supabase.instance.client;
  Set<String> _permisosUsuario = {};

  String? userNombre;
  String? userInstitucionNombre;
  String? userInstitucionId;
  bool esAdministradorGlobal = false;
  bool esFormuladorODirectorUpeg = false;
  bool esAprobadorUpeg = false;

  Future<void> cargarPermisosUsuario() async {
    try {
      // 1. Cargar permisos efectivos
      final List<dynamic> respuesta = await _supabase.rpc('obtener_mis_permisos');
      _permisosUsuario = respuesta
          .map((fila) => fila['codigo_permiso'] as String)
          .toSet();

      // 2. Cargar perfil e institución
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final perfil = await _supabase
            .from('perfiles')
            .select('''
              nombres, 
              apellidos, 
              instituciones(id, nombre), 
              usuarios_roles(roles(codigo))
            ''')
            .eq('id', userId)
            .maybeSingle();

        if (perfil != null) {
          userNombre = '${perfil['nombres']} ${perfil['apellidos']}';
          final inst = perfil['instituciones'];
          if (inst != null) {
            userInstitucionNombre = inst['nombre'];
            userInstitucionId = inst['id']?.toString();
          }

          final roles = perfil['usuarios_roles'] as List<dynamic>? ?? [];
          esAdministradorGlobal = roles.any((r) => r['roles']?['codigo'] == 'ADMINISTRADOR_SISTEMA');
          
          esFormuladorODirectorUpeg = roles.any((r) {
            final codigo = r['roles']?['codigo'] as String? ?? '';
            return codigo == 'FORMULADOR_UPEG' || codigo == 'DIRECTOR_UPEG' || codigo == 'APROBADOR_UPEG';
          });

          esAprobadorUpeg = roles.any((r) => r['roles']?['codigo'] == 'APROBADOR_UPEG');
        }
      }
    } catch (e) {
      _permisosUsuario = {};
      userNombre = null;
      userInstitucionNombre = null;
      userInstitucionId = null;
      esAdministradorGlobal = false;
      esFormuladorODirectorUpeg = false;
      esAprobadorUpeg = false;
    }
  }

  bool tiene(String codigoPermiso) => _permisosUsuario.contains(codigoPermiso);
  bool tieneAlguno(Iterable<String> codigos) => codigos.any(tiene);
  bool tieneTodos(Iterable<String> codigos) => codigos.every(tiene);
  
  void limpiar() {
    _permisosUsuario.clear();
    userNombre = null;
    userInstitucionNombre = null;
    userInstitucionId = null;
    esAdministradorGlobal = false;
    esFormuladorODirectorUpeg = false;
    esAprobadorUpeg = false;
  }
}
