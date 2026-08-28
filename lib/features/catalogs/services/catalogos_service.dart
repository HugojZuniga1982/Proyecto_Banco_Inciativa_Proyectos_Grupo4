import 'package:supabase_flutter/supabase_flutter.dart';

class CatalogosService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. Sectores Principales (donde sector_padre_id es nulo)
  Future<List<Map<String, dynamic>>> obtenerSectoresPrincipales() async {
    final res = await _supabase
        .from('sectores')
        .select('id, codigo, nombre')
        .isFilter('sector_padre_id', null)
        .eq('estado', 'ACTIVO')
        .order('nombre');
    return List<Map<String, dynamic>>.from(res);
  }

  // 2. Subsectores según el Sector Seleccionado (En Cascada)
  Future<List<Map<String, dynamic>>> obtenerSubsectores(
    String sectorId,
  ) async {
    final res = await _supabase
        .from('subsectores')
        .select('id, codigo, nombre')
        .eq('sector_id', sectorId)
        .eq('estado', 'ACTIVO')
        .order('nombre');
    return List<Map<String, dynamic>>.from(res);
  }

  // 3. Niveles de Preinversión
  Future<List<Map<String, dynamic>>> obtenerNivelesPreinversion() async {
    final res = await _supabase
        .from('niveles_preinversion')
        .select('id, codigo, nombre, orden')
        .eq('estado', 'ACTIVO')
        .order('orden');
    return List<Map<String, dynamic>>.from(res);
  }

  // 4. Metodologías de Evaluación Socioeconómica
  Future<List<Map<String, dynamic>>> obtenerMetodologiasEvaluacion() async {
    final res = await _supabase
        .from('metodologias_evaluacion')
        .select('id, codigo, nombre, sigla')
        .eq('estado', 'ACTIVO')
        .order('nombre');
    return List<Map<String, dynamic>>.from(res);
  }

  // 5. Fuentes de Financiamiento
  Future<List<Map<String, dynamic>>> obtenerFuentesFinanciamiento() async {
    final res = await _supabase
        .from('fuentes_financiamiento')
        .select('id, codigo, nombre, tipo')
        .eq('estado', 'ACTIVO')
        .order('nombre');
    return List<Map<String, dynamic>>.from(res);
  }

  // 6. Departamentos
  Future<List<Map<String, dynamic>>> obtenerDepartamentos() async {
    final res = await _supabase
        .from('departamentos')
        .select('id, codigo, nombre')
        .order('nombre');
    return List<Map<String, dynamic>>.from(res);
  }

  // 7. Municipios según Departamento (En Cascada)
  Future<List<Map<String, dynamic>>> obtenerMunicipios(
    String departamentoId,
  ) async {
    final res = await _supabase
        .from('municipios')
        .select('id, codigo, nombre')
        .eq('departamento_id', departamentoId)
        .order('nombre');
    return List<Map<String, dynamic>>.from(res);
  }
}
