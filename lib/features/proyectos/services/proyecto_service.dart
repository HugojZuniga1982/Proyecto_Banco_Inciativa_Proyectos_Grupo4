import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/proyecto.dart';

class ProyectoService {
  SupabaseClient get _supabase => Supabase.instance.client;

  // 1. Obtener lista de proyectos activos con joins y relaciones secundarias
  Future<List<Proyecto>> obtenerProyectos() async {
    final res = await _supabase
        .from('proyectos')
        .select('''
          *,
          instituciones!institucion_id(nombre),
          instituciones_coejecutoras:instituciones!institucion_coejecutora_id(nombre),
          subsectores(nombre, sector_id),
          departamentos(nombre),
          municipios(nombre),
          niveles_preinversion(nombre),
          fuentes_financiamiento(nombre),
          componentes_proyecto(*),
          estudios_proyecto(*)
        ''')
        .eq('estado', 'ACTIVO')
        .order('fecha_creacion', ascending: false);

    return (res as List).map((json) => Proyecto.fromJson(json)).toList();
  }

  // 2. Registrar o actualizar un proyecto junto con sus componentes y estudios
  Future<void> guardarProyecto(Proyecto proyecto) async {
    final Map<String, dynamic> data = proyecto.toJson();

    // Asignar el creador del proyecto
    final usuario = _supabase.auth.currentUser;
    if (usuario != null) {
      data['creado_por'] = usuario.id;
    }

    dynamic resProyecto;
    if (proyecto.id == null) {
      resProyecto = await _supabase
          .from('proyectos')
          .insert(data)
          .select('id')
          .single();
    } else {
      resProyecto = await _supabase
          .from('proyectos')
          .update(data)
          .eq('id', proyecto.id!)
          .select('id')
          .single();
    }

    final String proyectoId = resProyecto['id'];

    // En caso de actualización, limpiamos e insertamos de nuevo los componentes y estudios
    if (proyecto.id != null) {
      await _supabase
          .from('componentes_proyecto')
          .delete()
          .eq('proyecto_id', proyectoId);
      await _supabase
          .from('estudios_proyecto')
          .delete()
          .eq('proyecto_id', proyectoId);
    }

    // Insertar componentes
    if (proyecto.componentes.isNotEmpty) {
      final List<Map<String, dynamic>> comps = proyecto.componentes.map((c) {
        final cJson = c.toJson();
        cJson['proyecto_id'] = proyectoId;
        cJson.remove('id');
        return cJson;
      }).toList();
      await _supabase.from('componentes_proyecto').insert(comps);
    }

    // Insertar estudios
    if (proyecto.estudios.isNotEmpty) {
      final List<Map<String, dynamic>> ests = proyecto.estudios.map((e) {
        final eJson = e.toJson();
        eJson['proyecto_id'] = proyectoId;
        eJson.remove('id');
        return eJson;
      }).toList();
      await _supabase.from('estudios_proyecto').insert(ests);
    }
  }

  // 3. Eliminar (lógico) un proyecto cambiándole el estado a INACTIVO
  Future<void> desactivarProyecto(String id) async {
    await _supabase
        .from('proyectos')
        .update({'estado': 'INACTIVO'})
        .eq('id', id);
  }

  // 4. Obtener las métricas e indicadores de inversión para el dashboard gerencial
Future<Map<String, dynamic>> obtenerMetricasDashboard({String? institucionId}) async {
  var query = _supabase
      .from('proyectos')
      .select('''
        id,
        costo_total,
        subsector_id,
        estado_proceso,
        subsectores(
          nombre,
          sectores(id, nombre)
        )
      ''')
      .eq('estado', 'ACTIVO');

  if (institucionId != null) {
    query = query.eq('institucion_id', institucionId);
  }

  final res = await query;

  double costoAcumulado = 0.0;
  int totalProyectos = res.length;
  int totalAprobados = 0;
  Map<String, int> proyectosPorSector = {};
  Map<String, double> costoPorSector = {};
  Map<String, int> proyectosPorEstado = {};

  for (var row in res) {
    double costo = (row['costo_total'] as num?)?.toDouble() ?? 0.0;
    costoAcumulado += costo;

    final estado = row['estado_proceso'] ?? 'INGRESADO';
    proyectosPorEstado[estado] = (proyectosPorEstado[estado] ?? 0) + 1;

    if (estado == 'APROBADO') {
      totalAprobados++;
    }

    final sector = row['subsectores']?['sectores'];
    if (sector != null) {
      String sectorNombre = sector['nombre'] ?? 'Otros';
      proyectosPorSector[sectorNombre] = (proyectosPorSector[sectorNombre] ?? 0) + 1;
      costoPorSector[sectorNombre] = (costoPorSector[sectorNombre] ?? 0.0) + costo;
    }
  }

  final tasaAprobacion = totalProyectos > 0 ? (totalAprobados / totalProyectos) : 0.0;

  return {
    'totalProyectos': totalProyectos,
    'costoAcumulado': costoAcumulado,
    'tasaAprobacion': tasaAprobacion,
    'proyectosPorSector': proyectosPorSector,
    'costoPorSector': costoPorSector,
    'proyectosPorEstado': proyectosPorEstado,
  };
}

  // 5. Actualizar el estado de proceso de una ficha BIP
  Future<void> actualizarEstadoProceso(String id, String nuevoEstado) async {
    await _supabase
        .from('proyectos')
        .update({'estado_proceso': nuevoEstado})
        .eq('id', id);
  }
}
