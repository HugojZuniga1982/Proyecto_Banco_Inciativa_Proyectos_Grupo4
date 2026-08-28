class Proyecto {
  final String? id;
  final String nombre;
  final String institucionId;
  final String? institucionCoejecutoraId;
  final int? vidaUtil;
  final String tipoIniciativa;
  final String subsectorId;
  final String objetivoGeneral;
  final String descripcionProblema;
  final double costoTotal;
  final String periodoEjecucion;
  final String departamentoId;
  final String municipioId;
  final String? coordenadasUtm;
  final String? aspectosTecnicos;
  final String? entregablePrincipal;
  final String? finalidadIntervencion;
  final double? porcentajeInversionReal;
  final double? porcentajeDesarrolloHumano;
  final double? costoAnualOperacion;
  final String? nivelPreinversionId;
  final String? posibleFuenteFinanciamientoId;
  final String? entidadResponsableOperacion;
  final double? evalCostoAnualEquivalente;
  final double? evalRelacionCostoEficiencia;
  final double? evalVpn;
  final double? evalBeneficioCosto;
  final double? evalTir;
  final int? beneficiariosDirectos;
  final int? beneficiariosIndirectos;
  final int? empleosDirectos;
  final int? empleosIndirectos;
  final String? estado;
  final String estadoProceso;
  final String? creadoPor;
  final DateTime? fechaCreacion;

  // Joined information (for displaying in lists and details)
  final String? institucionNombre;
  final String? institucionCoejecutoraNombre;
  final String? subsectorNombre;
  final String? departamentoNombre;
  final String? municipioNombre;
  final String? nivelPreinversionNombre;
  final String? posibleFuenteFinanciamientoNombre;

  // Nested collections
  final List<ComponenteProyecto> componentes;
  final List<EstudioProyecto> estudios;

  Proyecto({
    this.id,
    required this.nombre,
    required this.institucionId,
    this.institucionCoejecutoraId,
    this.vidaUtil = 20,
    this.tipoIniciativa = 'Proyecto',
    required this.subsectorId,
    required this.objetivoGeneral,
    required this.descripcionProblema,
    required this.costoTotal,
    required this.periodoEjecucion,
    required this.departamentoId,
    required this.municipioId,
    this.coordenadasUtm,
    this.aspectosTecnicos,
    this.entregablePrincipal,
    this.finalidadIntervencion,
    this.porcentajeInversionReal,
    this.porcentajeDesarrolloHumano,
    this.costoAnualOperacion,
    this.nivelPreinversionId,
    this.posibleFuenteFinanciamientoId,
    this.entidadResponsableOperacion,
    this.evalCostoAnualEquivalente,
    this.evalRelacionCostoEficiencia,
    this.evalVpn,
    this.evalBeneficioCosto,
    this.evalTir,
    this.beneficiariosDirectos,
    this.beneficiariosIndirectos,
    this.empleosDirectos,
    this.empleosIndirectos,
    this.estado,
    this.estadoProceso = 'INGRESADO',
    this.creadoPor,
    this.fechaCreacion,
    this.institucionNombre,
    this.institucionCoejecutoraNombre,
    this.subsectorNombre,
    this.departamentoNombre,
    this.municipioNombre,
    this.nivelPreinversionNombre,
    this.posibleFuenteFinanciamientoNombre,
    this.componentes = const [],
    this.estudios = const [],
  });

  factory Proyecto.fromJson(Map<String, dynamic> json) {
    // Parse nested components
    var listComp = json['componentes_proyecto'] as List?;
    List<ComponenteProyecto> comps = listComp != null
        ? listComp.map((i) => ComponenteProyecto.fromJson(i)).toList()
        : [];

    // Parse nested studies
    var listEst = json['estudios_proyecto'] as List?;
    List<EstudioProyecto> ests = listEst != null
        ? listEst.map((i) => EstudioProyecto.fromJson(i)).toList()
        : [];

    return Proyecto(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      institucionId: json['institucion_id'] ?? '',
      institucionCoejecutoraId: json['institucion_coejecutora_id'],
      vidaUtil: json['vida_util'] as int?,
      tipoIniciativa: json['tipo_iniciativa'] ?? 'Proyecto',
      subsectorId: json['subsector_id'] ?? '',
      objetivoGeneral: json['objetivo_general'] ?? '',
      descripcionProblema: json['descripcion_problema'] ?? '',
      costoTotal: (json['costo_total'] as num?)?.toDouble() ?? 0.0,
      periodoEjecucion: json['periodo_ejecucion'] ?? '',
      departamentoId: json['departamento_id'] ?? '',
      municipioId: json['municipio_id'] ?? '',
      coordenadasUtm: json['coordenadas_utm'],
      aspectosTecnicos: json['aspectos_tecnicos'],
      entregablePrincipal: json['entregable_principal'],
      finalidadIntervencion: json['finalidad_intervencion'],
      porcentajeInversionReal: (json['porcentaje_inversion_real'] as num?)?.toDouble(),
      porcentajeDesarrolloHumano: (json['porcentaje_desarrollo_humano'] as num?)?.toDouble(),
      costoAnualOperacion: (json['costo_anual_operacion'] as num?)?.toDouble(),
      nivelPreinversionId: json['nivel_preinversion_id'],
      posibleFuenteFinanciamientoId: json['posible_fuente_financiamiento_id'],
      entidadResponsableOperacion: json['entidad_responsable_operacion'],
      evalCostoAnualEquivalente: (json['eval_costo_anual_equivalente'] as num?)?.toDouble(),
      evalRelacionCostoEficiencia: (json['eval_relacion_costo_eficiencia'] as num?)?.toDouble(),
      evalVpn: (json['eval_vpn'] as num?)?.toDouble(),
      evalBeneficioCosto: (json['eval_beneficio_costo'] as num?)?.toDouble(),
      evalTir: (json['eval_tir'] as num?)?.toDouble(),
      beneficiariosDirectos: json['beneficiarios_directos'] as int?,
      beneficiariosIndirectos: json['beneficiarios_indirectos'] as int?,
      empleosDirectos: json['empleos_directos'] as int?,
      empleosIndirectos: json['empleos_indirectos'] as int?,
      estado: json['estado'],
      estadoProceso: json['estado_proceso'] ?? 'INGRESADO',
      creadoPor: json['creado_por'],
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : null,
      // Extracted from Joins
      institucionNombre: json['instituciones']?['nombre'],
      institucionCoejecutoraNombre: json['instituciones_coejecutoras']?['nombre'],
      subsectorNombre: json['subsectores']?['nombre'],
      departamentoNombre: json['departamentos']?['nombre'],
      municipioNombre: json['municipios']?['nombre'],
      nivelPreinversionNombre: json['niveles_preinversion']?['nombre'],
      posibleFuenteFinanciamientoNombre: json['fuentes_financiamiento']?['nombre'],
      componentes: comps,
      estudios: ests,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'institucion_id': institucionId,
      'institucion_coejecutora_id': institucionCoejecutoraId,
      'vida_util': vidaUtil,
      'tipo_iniciativa': tipoIniciativa,
      'subsector_id': subsectorId,
      'objetivo_general': objetivoGeneral,
      'descripcion_problema': descripcionProblema,
      'costo_total': costoTotal,
      'periodo_ejecucion': periodoEjecucion,
      'departamento_id': departamentoId,
      'municipio_id': municipioId,
      'coordenadas_utm': coordenadasUtm,
      'aspectos_tecnicos': aspectosTecnicos,
      'entregable_principal': entregablePrincipal,
      'finalidad_intervencion': finalidadIntervencion,
      'porcentaje_inversion_real': porcentajeInversionReal,
      'porcentaje_desarrollo_humano': porcentajeDesarrolloHumano,
      'costo_anual_operacion': costoAnualOperacion,
      'nivel_preinversion_id': nivelPreinversionId,
      'posible_fuente_financiamiento_id': posibleFuenteFinanciamientoId,
      'entidad_responsable_operacion': entidadResponsableOperacion,
      'eval_costo_anual_equivalente': evalCostoAnualEquivalente,
      'eval_relacion_costo_eficiencia': evalRelacionCostoEficiencia,
      'eval_vpn': evalVpn,
      'eval_beneficio_costo': evalBeneficioCosto,
      'eval_tir': evalTir,
      'beneficiarios_directos': beneficiariosDirectos,
      'beneficiarios_indirectos': beneficiariosIndirectos,
      'empleos_directos': empleosDirectos,
      'empleos_indirectos': empleosIndirectos,
      'estado': estado ?? 'ACTIVO',
      'estado_proceso': estadoProceso,
      if (creadoPor != null) 'creado_por': creadoPor,
    };
  }
}

class ComponenteProyecto {
  final String? id;
  final String? proyectoId;
  final String nombre;
  final double costo;

  ComponenteProyecto({
    this.id,
    this.proyectoId,
    required this.nombre,
    required this.costo,
  });

  factory ComponenteProyecto.fromJson(Map<String, dynamic> json) {
    return ComponenteProyecto(
      id: json['id'],
      proyectoId: json['proyecto_id'],
      nombre: json['nombre'] ?? '',
      costo: (json['costo'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (proyectoId != null) 'proyecto_id': proyectoId,
      'nombre': nombre,
      'costo': costo,
    };
  }
}

class EstudioProyecto {
  final String? id;
  final String? proyectoId;
  final String nombreEstudio;
  final String? fechaElaboracion;
  final String? nivelEstudio;
  final String? custodioEstudios;
  final String? observaciones;

  EstudioProyecto({
    this.id,
    this.proyectoId,
    required this.nombreEstudio,
    this.fechaElaboracion,
    this.nivelEstudio,
    this.custodioEstudios,
    this.observaciones,
  });

  factory EstudioProyecto.fromJson(Map<String, dynamic> json) {
    return EstudioProyecto(
      id: json['id'],
      proyectoId: json['proyecto_id'],
      nombreEstudio: json['nombre_estudio'] ?? '',
      fechaElaboracion: json['fecha_elaboracion'],
      nivelEstudio: json['nivel_estudio'],
      custodioEstudios: json['custodio_estudios'],
      observaciones: json['observaciones'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (proyectoId != null) 'proyecto_id': proyectoId,
      'nombre_estudio': nombreEstudio,
      'fecha_elaboracion': fechaElaboracion,
      'nivel_estudio': nivelEstudio,
      'custodio_estudios': custodioEstudios,
      'observaciones': observaciones,
    };
  }
}
