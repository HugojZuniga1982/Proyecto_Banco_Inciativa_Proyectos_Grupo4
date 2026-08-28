import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/proyecto.dart';
import '../../../../core/security/servicio_permisos.dart';
import '../../../security/services/usuario_service.dart';
import '../../../catalogs/services/catalogos_service.dart';
import '../../services/proyecto_service.dart';
import '../../../../core/utils/formatters.dart';

class FichaProyectoPage extends StatefulWidget {
  final Proyecto? proyectoAEditar;
  final bool isEmbedded;
  final void Function(String ruta, Proyecto? proyecto)? onNavigate;

  const FichaProyectoPage({
    super.key,
    this.proyectoAEditar,
    this.isEmbedded = false,
    this.onNavigate,
  });

  @override
  State<FichaProyectoPage> createState() => _FichaProyectoPageState();
}

class _FichaProyectoPageState extends State<FichaProyectoPage> {
  final _proyectoService = ProyectoService();
  final _catalogosService = CatalogosService();
  final _usuarioService = UsuarioService();

  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Controllers Step 1 & 2
  final _nombreCtrl = TextEditingController();
  final _objetivoGeneralCtrl = TextEditingController();
  final _descripcionProblemaCtrl = TextEditingController();
  String? _institucionSeleccionadaId;
  String? _institucionSeleccionadaNombre;
  String? _coejecutoraSeleccionadaId;
  String? _sectorSeleccionadoId;
  String? _subsectorSeleccionadoId;

  // Controllers Step 2
  final _costoTotalCtrl = TextEditingController();
  String? _periodoEjecucionSeleccionado = '12 meses';
  final _coordenadasUtmCtrl = TextEditingController();
  final _aspectosTecnicosCtrl = TextEditingController();
  final _entregablePrincipalCtrl = TextEditingController();
  final _finalidadIntervencionCtrl = TextEditingController();
  final _porcentajeInversionRealCtrl = TextEditingController();
  final _porcentajeDesarrolloHumanoCtrl = TextEditingController();
  final _costoAnualOperacionCtrl = TextEditingController();
  final _entidadResponsableOperacionCtrl = TextEditingController();
  String? _departamentoSeleccionadoId;
  String? _municipioSeleccionadoId;
  String? _nivelPreinversionSeleccionadoId;
  String? _posibleFuenteFinanciamientoSeleccionadoId;

  // Tipología y Estado (Stitch specification)
  String _tipoIniciativa = 'Proyecto';
  final _vidaUtilCtrl = TextEditingController(text: '20');

  // Controllers Step 3 (Componentes y Estudios dinámicos)
  final List<ComponenteProyecto> _componentes = [];
  final List<EstudioProyecto> _estudios = [];

  final _compNombreCtrl = TextEditingController();
  final _compCostoCtrl = TextEditingController();

  final _estNombreCtrl = TextEditingController();
  final _estFechaCtrl = TextEditingController();
  final _estObsCtrl = TextEditingController();

  // Controllers Step 4
  final _evalCaeCtrl = TextEditingController();
  final _evalCostoEficienciaCtrl = TextEditingController();
  final _evalVpnCtrl = TextEditingController();
  final _evalBeneficioCostoCtrl = TextEditingController();
  final _evalTirCtrl = TextEditingController();
  final _beneficiariosDirectosCtrl = TextEditingController();
  final _beneficiariosIndirectosCtrl = TextEditingController();
  final _empleosDirectosCtrl = TextEditingController();
  final _empleosIndirectosCtrl = TextEditingController();

  // Catalog Lists
  List<Map<String, dynamic>> _instituciones = [];
  List<Map<String, dynamic>> _sectores = [];
  List<Map<String, dynamic>> _subsectores = [];
  List<Map<String, dynamic>> _departamentos = [];
  List<Map<String, dynamic>> _municipios = [];
  List<Map<String, dynamic>> _nivelesPreinversion = [];
  List<Map<String, dynamic>> _fuentesFinanciamiento = [];

  bool _cargandoCatalogos = true;

  final List<String> _periodosMeses = [
    '1 mes', '2 meses', '3 meses', '4 meses', '5 meses', '6 meses',
    '8 meses', '10 meses', '12 meses', '18 meses', '24 meses',
    '36 meses', '48 meses', '60 meses'
  ];

  @override
  void initState() {
    super.initState();
    _inicializarCatalogos();
    _setupFieldListeners();
  }

  void _setupFieldListeners() {
    final controllers = [
      _nombreCtrl, _objetivoGeneralCtrl, _descripcionProblemaCtrl,
      _costoTotalCtrl, _coordenadasUtmCtrl, _aspectosTecnicosCtrl,
      _entregablePrincipalCtrl, _finalidadIntervencionCtrl,
      _porcentajeInversionRealCtrl, _porcentajeDesarrolloHumanoCtrl,
      _costoAnualOperacionCtrl, _entidadResponsableOperacionCtrl,
      _vidaUtilCtrl, _evalCaeCtrl, _evalCostoEficienciaCtrl,
      _evalVpnCtrl, _evalBeneficioCostoCtrl, _evalTirCtrl,
      _beneficiariosDirectosCtrl, _beneficiariosIndirectosCtrl,
      _empleosDirectosCtrl, _empleosIndirectosCtrl
    ];
    for (var ctrl in controllers) {
      ctrl.addListener(() => setState(() {}));
    }
  }

  Future<void> _inicializarCatalogos() async {
    try {
      final inst = await _usuarioService.obtenerInstituciones();
      final sec = await _catalogosService.obtenerSectoresPrincipales();
      final dep = await _catalogosService.obtenerDepartamentos();
      final niv = await _catalogosService.obtenerNivelesPreinversion();
      final fte = await _catalogosService.obtenerFuentesFinanciamiento();

      // Sort Preinvestment Levels according to requested order:
      // 1. Perfil de proyecto (PERFIL)
      // 2. Prefactibilidad (PREFACTIBILIDAD)
      // 3. Factibilidad (FACTIBILIDAD)
      // 4. Diseño Final / Ingeniería Detalle (DISENO_FINAL)
      final orderMap = {
        'PERFIL': 1,
        'PREFACTIBILIDAD': 2,
        'FACTIBILIDAD': 3,
        'DISENO_FINAL': 4
      };
      niv.sort((a, b) {
        final codeA = a['codigo']?.toString() ?? '';
        final codeB = b['codigo']?.toString() ?? '';
        final oA = orderMap[codeA] ?? 99;
        final oB = orderMap[codeB] ?? 99;
        return oA.compareTo(oB);
      });

      setState(() {
        _instituciones = inst;
        _sectores = sec;
        _departamentos = dep;
        _nivelesPreinversion = niv;
        _fuentesFinanciamiento = fte;
        _cargandoCatalogos = false;
      });

      // Default institutional auto-fill for Formulador/Director Upeg
      final userSp = ServicioPermisos();
      if (widget.proyectoAEditar == null) {
        if (userSp.esFormuladorODirectorUpeg && userSp.userInstitucionId != null) {
          _institucionSeleccionadaId = userSp.userInstitucionId;
          final matched = inst.firstWhere(
            (i) => i['id'] == userSp.userInstitucionId,
            orElse: () => {},
          );
          if (matched.isNotEmpty) {
            _institucionSeleccionadaNombre = '${matched['codigo']} - ${matched['nombre']}';
          }
        }
      } else {
        _cargarDatosEdicion();
      }
    } catch (e) {
      _mostrarMensaje('Error al inicializar catálogos: $e', esError: true);
    }
  }

  void _cargarDatosEdicion() async {
    final p = widget.proyectoAEditar!;
    _nombreCtrl.text = p.nombre;
    _objetivoGeneralCtrl.text = p.objetivoGeneral;
    _descripcionProblemaCtrl.text = p.descripcionProblema;
    _institucionSeleccionadaId = p.institucionId;
    _coejecutoraSeleccionadaId = p.institucionCoejecutoraId;
    _tipoIniciativa = p.tipoIniciativa;
    _vidaUtilCtrl.text = p.vidaUtil?.toString() ?? '20';

    if (p.institucionId.isNotEmpty) {
      final matched = _instituciones.firstWhere(
        (i) => i['id'] == p.institucionId,
        orElse: () => {},
      );
      if (matched.isNotEmpty) {
        _institucionSeleccionadaNombre = '${matched['codigo']} - ${matched['nombre']}';
      }
    }

    _subsectorSeleccionadoId = p.subsectorId;
    final SupabaseClient supabase = Supabase.instance.client;
    final subRes = await supabase
        .from('subsectores')
        .select('sector_id')
        .eq('id', p.subsectorId)
        .maybeSingle();

    if (subRes != null) {
      final sectorId = subRes['sector_id'];
      _sectorSeleccionadoId = sectorId;
      final subs = await _catalogosService.obtenerSubsectores(sectorId);
      setState(() {
        _subsectores = subs;
      });
    }

    _costoTotalCtrl.text = p.costoTotal.toString();
    _periodoEjecucionSeleccionado = _periodosMeses.contains(p.periodoEjecucion)
        ? p.periodoEjecucion
        : '12 meses';
    _coordenadasUtmCtrl.text = p.coordenadasUtm ?? '';
    _aspectosTecnicosCtrl.text = p.aspectosTecnicos ?? '';
    _entregablePrincipalCtrl.text = p.entregablePrincipal ?? '';
    _finalidadIntervencionCtrl.text = p.finalidadIntervencion ?? '';
    _porcentajeInversionRealCtrl.text = p.porcentajeInversionReal?.toString() ?? '';
    _porcentajeDesarrolloHumanoCtrl.text = p.porcentajeDesarrolloHumano?.toString() ?? '';
    _costoAnualOperacionCtrl.text = p.costoAnualOperacion?.toString() ?? '';
    _entidadResponsableOperacionCtrl.text = p.entidadResponsableOperacion ?? '';
    
    _departamentoSeleccionadoId = p.departamentoId;
    if (_departamentoSeleccionadoId != null) {
      final muns = await _catalogosService.obtenerMunicipios(_departamentoSeleccionadoId!);
      setState(() {
        _municipios = muns;
        _municipioSeleccionadoId = p.municipioId;
      });
    }

    _nivelPreinversionSeleccionadoId = p.nivelPreinversionId;
    _posibleFuenteFinanciamientoSeleccionadoId = p.posibleFuenteFinanciamientoId;

    _evalCaeCtrl.text = p.evalCostoAnualEquivalente?.toString() ?? '';
    _evalCostoEficienciaCtrl.text = p.evalRelacionCostoEficiencia?.toString() ?? '';
    _evalVpnCtrl.text = p.evalVpn?.toString() ?? '';
    _evalBeneficioCostoCtrl.text = p.evalBeneficioCosto?.toString() ?? '';
    _evalTirCtrl.text = p.evalTir?.toString() ?? '';
    _beneficiariosDirectosCtrl.text = p.beneficiariosDirectos?.toString() ?? '';
    _beneficiariosIndirectosCtrl.text = p.beneficiariosIndirectos?.toString() ?? '';
    _empleosDirectosCtrl.text = p.empleosDirectos?.toString() ?? '';
    _empleosIndirectosCtrl.text = p.empleosIndirectos?.toString() ?? '';

    setState(() {
      _componentes.addAll(p.componentes);
      _estudios.addAll(p.estudios);
    });
  }

  void _onSectorChanged(String? val) async {
    if (val == null) return;
    setState(() {
      _sectorSeleccionadoId = val;
      _subsectorSeleccionadoId = null;
      _subsectores = [];
    });
    try {
      final sub = await _catalogosService.obtenerSubsectores(val);
      setState(() => _subsectores = sub);
    } catch (e) {
      _mostrarMensaje('Error al obtener subsectores: $e', esError: true);
    }
  }

  void _onDepartamentoChanged(String? val) async {
    if (val == null) return;
    setState(() {
      _departamentoSeleccionadoId = val;
      _municipioSeleccionadoId = null;
      _municipios = [];
    });
    try {
      final mun = await _catalogosService.obtenerMunicipios(val);
      setState(() => _municipios = mun);
    } catch (e) {
      _mostrarMensaje('Error al obtener municipios: $e', esError: true);
    }
  }

  void _agregarComponente() {
    final nombre = _compNombreCtrl.text.trim();
    final costo = double.tryParse(_compCostoCtrl.text.trim()) ?? 0.0;
    if (nombre.isEmpty || costo <= 0.0) {
      _mostrarMensaje('Ingrese un nombre y un costo válido mayor a cero.', esError: true);
      return;
    }
    setState(() {
      _componentes.add(ComponenteProyecto(nombre: nombre, costo: costo));
      _compNombreCtrl.clear();
      _compCostoCtrl.clear();
    });
  }

  Future<void> _seleccionarFechaElaboracion(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _estFechaCtrl.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _agregarEstudio() {
    final nombre = _estNombreCtrl.text.trim();
    if (nombre.isEmpty) {
      _mostrarMensaje('Ingrese el nombre del estudio y/o diseño.', esError: true);
      return;
    }
    setState(() {
      _estudios.add(EstudioProyecto(
        nombreEstudio: nombre,
        fechaElaboracion: _estFechaCtrl.text.trim().isEmpty ? null : _estFechaCtrl.text.trim(),
        nivelEstudio: null,
        custodioEstudios: null,
        observaciones: _estObsCtrl.text.trim().isEmpty ? null : _estObsCtrl.text.trim(),
      ));
      _estNombreCtrl.clear();
      _estFechaCtrl.clear();
      _estObsCtrl.clear();
    });
  }

  double _calcularCompletitud() {
    int totalCampos = 32;
    int camposLlenos = 0;

    if (_nombreCtrl.text.trim().isNotEmpty) camposLlenos++;
    if (_institucionSeleccionadaId != null) camposLlenos++;
    camposLlenos++; // Coejecutora is always counted (either specific institution selected or defaults to "No aplica")
    if (_sectorSeleccionadoId != null) camposLlenos++;
    if (_subsectorSeleccionadoId != null) camposLlenos++;
    if (_objetivoGeneralCtrl.text.trim().isNotEmpty) camposLlenos++;
    if (_descripcionProblemaCtrl.text.trim().isNotEmpty) camposLlenos++;
    if (_costoTotalCtrl.text.trim().isNotEmpty) camposLlenos++;
    if (_periodoEjecucionSeleccionado != null) camposLlenos++;
    if (_departamentoSeleccionadoId != null) camposLlenos++;
    if (_municipioSeleccionadoId != null) camposLlenos++;
    if (_coordenadasUtmCtrl.text.trim().isNotEmpty) camposLlenos++;
    if (_entregablePrincipalCtrl.text.trim().isNotEmpty) camposLlenos++;
    if (_finalidadIntervencionCtrl.text.trim().isNotEmpty) camposLlenos++;
    if (_porcentajeInversionRealCtrl.text.trim().isNotEmpty) camposLlenos++;
    if (_porcentajeDesarrolloHumanoCtrl.text.trim().isNotEmpty) camposLlenos++;
    if (_costoAnualOperacionCtrl.text.trim().isNotEmpty) camposLlenos++;
    if (_entidadResponsableOperacionCtrl.text.trim().isNotEmpty) camposLlenos++;
    if (_nivelPreinversionSeleccionadoId != null) camposLlenos++;
    if (_posibleFuenteFinanciamientoSeleccionadoId != null) camposLlenos++;
    if (_aspectosTecnicosCtrl.text.trim().isNotEmpty) camposLlenos++;
    if (_vidaUtilCtrl.text.trim().isNotEmpty) camposLlenos++;
    if (_componentes.isNotEmpty) camposLlenos++;
    if (_estudios.isNotEmpty) camposLlenos++;
    if (_evalCaeCtrl.text.trim().isNotEmpty) camposLlenos++;
    if (_evalCostoEficienciaCtrl.text.trim().isNotEmpty) camposLlenos++;
    if (_evalVpnCtrl.text.trim().isNotEmpty) camposLlenos++;
    if (_evalBeneficioCostoCtrl.text.trim().isNotEmpty) camposLlenos++;
    if (_evalTirCtrl.text.trim().isNotEmpty) camposLlenos++;
    if (_beneficiariosDirectosCtrl.text.trim().isNotEmpty) camposLlenos++;
    if (_beneficiariosIndirectosCtrl.text.trim().isNotEmpty) camposLlenos++;
    if (_empleosDirectosCtrl.text.trim().isNotEmpty) camposLlenos++;
    if (_empleosIndirectosCtrl.text.trim().isNotEmpty) camposLlenos++;

    final double pct = (camposLlenos / totalCampos) * 100;
    return pct > 100.0 ? 100.0 : pct;
  }

  Future<void> _guardarProyecto() async {
    if (!_formKey.currentState!.validate() ||
        _institucionSeleccionadaId == null ||
        _subsectorSeleccionadoId == null ||
        _departamentoSeleccionadoId == null ||
        _municipioSeleccionadoId == null) {
      _mostrarMensaje('Por favor complete todos los campos obligatorios.', esError: true);
      return;
    }

    // Cost sum validation for components
    if (_componentes.isEmpty) {
      _mostrarMensaje('Debe agregar al menos un componente al proyecto.', esError: true);
      return;
    }
    final totalProyecto = double.tryParse(_costoTotalCtrl.text.trim()) ?? 0.0;
    final totalComponentes = _componentes.fold(0.0, (sum, c) => sum + c.costo);
    if ((totalComponentes - totalProyecto).abs() > 0.01) {
      _mostrarMensaje(
        'La suma del costo de los componentes (Lps ${Formatters.formatearLempiras(totalComponentes)}) debe ser exactamente igual al Costo Total del Proyecto (Lps ${Formatters.formatearLempiras(totalProyecto)}).',
        esError: true,
      );
      return;
    }

    // Inversión Real & Desarrollo Humano Validation
    final invReal = double.tryParse(_porcentajeInversionRealCtrl.text.trim()) ?? 0.0;
    final desHumano = double.tryParse(_porcentajeDesarrolloHumanoCtrl.text.trim()) ?? 0.0;
    if (invReal > 0 && desHumano > 0) {
      if ((invReal + desHumano - 100.0).abs() > 0.01) {
        _mostrarMensaje(
          'La suma de % Inversión Real y % Desarrollo Humano debe ser exactamente 100%.',
          esError: true,
        );
        return;
      }
    }

    final p = Proyecto(
      id: widget.proyectoAEditar?.id,
      nombre: _nombreCtrl.text.trim(),
      institucionId: _institucionSeleccionadaId!,
      institucionCoejecutoraId: _coejecutoraSeleccionadaId,
      tipoIniciativa: _tipoIniciativa,
      vidaUtil: int.tryParse(_vidaUtilCtrl.text.trim()) ?? 20,
      subsectorId: _subsectorSeleccionadoId!,
      objetivoGeneral: _objetivoGeneralCtrl.text.trim(),
      descripcionProblema: _descripcionProblemaCtrl.text.trim(),
      costoTotal: totalProyecto,
      periodoEjecucion: _periodoEjecucionSeleccionado ?? '12 meses',
      departamentoId: _departamentoSeleccionadoId!,
      municipioId: _municipioSeleccionadoId!,
      coordenadasUtm: _coordenadasUtmCtrl.text.trim().isEmpty ? null : _coordenadasUtmCtrl.text.trim(),
      aspectosTecnicos: _aspectosTecnicosCtrl.text.trim().isEmpty ? null : _aspectosTecnicosCtrl.text.trim(),
      entregablePrincipal: _entregablePrincipalCtrl.text.trim().isEmpty ? null : _entregablePrincipalCtrl.text.trim(),
      finalidadIntervencion: _finalidadIntervencionCtrl.text.trim().isEmpty ? null : _finalidadIntervencionCtrl.text.trim(),
      porcentajeInversionReal: invReal > 0 ? invReal : null,
      porcentajeDesarrolloHumano: desHumano > 0 ? desHumano : null,
      costoAnualOperacion: double.tryParse(_costoAnualOperacionCtrl.text.trim()),
      nivelPreinversionId: _nivelPreinversionSeleccionadoId,
      posibleFuenteFinanciamientoId: _posibleFuenteFinanciamientoSeleccionadoId,
      entidadResponsableOperacion: _entidadResponsableOperacionCtrl.text.trim().isEmpty ? null : _entidadResponsableOperacionCtrl.text.trim(),
      evalCostoAnualEquivalente: double.tryParse(_evalCaeCtrl.text.trim()),
      evalRelacionCostoEficiencia: double.tryParse(_evalCostoEficienciaCtrl.text.trim()),
      evalVpn: double.tryParse(_evalVpnCtrl.text.trim()),
      evalBeneficioCosto: double.tryParse(_evalBeneficioCostoCtrl.text.trim()),
      evalTir: double.tryParse(_evalTirCtrl.text.trim()),
      beneficiariosDirectos: int.tryParse(_beneficiariosDirectosCtrl.text.trim()),
      beneficiariosIndirectos: int.tryParse(_beneficiariosIndirectosCtrl.text.trim()),
      empleosDirectos: int.tryParse(_empleosDirectosCtrl.text.trim()),
      empleosIndirectos: int.tryParse(_empleosIndirectosCtrl.text.trim()),
      estadoProceso: 'VERIFICADO_INSTITUCION',
      componentes: _componentes,
      estudios: _estudios,
    );

    try {
      await _proyectoService.guardarProyecto(p);
      _mostrarMensaje('Ficha de Proyecto guardada exitosamente.');
      if (widget.isEmbedded) {
        widget.onNavigate?.call('proyectos', null);
      } else {
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      _mostrarMensaje('Error al guardar el proyecto: $e', esError: true);
    }
  }

  void _mostrarMensaje(String msg, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: esError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoCatalogos) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    final stepperWidget = Form(
      key: _formKey,
      child: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepTapped: (step) {
          if (step < _currentStep) {
            setState(() => _currentStep = step);
          }
        },
        onStepContinue: () {
          if (_currentStep == 0) {
            // Validate step 1 fields
            if (_nombreCtrl.text.isEmpty ||
                _institucionSeleccionadaId == null ||
                _sectorSeleccionadoId == null ||
                _subsectorSeleccionadoId == null ||
                _objetivoGeneralCtrl.text.isEmpty ||
                _descripcionProblemaCtrl.text.isEmpty) {
              _mostrarMensaje('Complete todos los campos de Identificación del Proyecto.', esError: true);
              return;
            }
            setState(() => _currentStep += 1);
          } else if (_currentStep == 1) {
            // Validate step 2: Cost & Percentages
            if (_costoTotalCtrl.text.isEmpty ||
                _departamentoSeleccionadoId == null ||
                _municipioSeleccionadoId == null) {
              _mostrarMensaje('Complete los campos obligatorios de Financiamiento.', esError: true);
              return;
            }
            final invReal = double.tryParse(_porcentajeInversionRealCtrl.text.trim()) ?? 0.0;
            final desHumano = double.tryParse(_porcentajeDesarrolloHumanoCtrl.text.trim()) ?? 0.0;
            if (invReal > 0 && desHumano > 0) {
              if ((invReal + desHumano - 100.0).abs() > 0.01) {
                _mostrarMensaje('La suma del % de inversión real y el % de desarrollo humano debe ser exactamente 100%.', esError: true);
                return;
              }
            }
            setState(() => _currentStep += 1);
          } else if (_currentStep == 2) {
            // Validate step 3: Components & Cost Sum
            if (_componentes.isEmpty) {
              _mostrarMensaje('Debe agregar al menos un componente al proyecto.', esError: true);
              return;
            }
            final totalProyecto = double.tryParse(_costoTotalCtrl.text.trim()) ?? 0.0;
            final totalComponentes = _componentes.fold(0.0, (sum, c) => sum + c.costo);
            if ((totalComponentes - totalProyecto).abs() > 0.01) {
              _mostrarMensaje(
                'La suma del costo de los componentes (Lps ${Formatters.formatearLempiras(totalComponentes)}) debe ser exactamente igual al Costo Total del Proyecto (Lps ${Formatters.formatearLempiras(totalProyecto)}).',
                esError: true,
              );
              return;
            }
            setState(() => _currentStep += 1);
          } else if (_currentStep == 3) {
            _guardarProyecto();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF24389C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(_currentStep == 3 ? 'Guardar Ficha' : 'Siguiente Paso'),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Atrás'),
                  ),
                ] else if (widget.isEmbedded) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      widget.onNavigate?.call('proyectos', null);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ]
              ],
            ),
          );
        },
        steps: [
          // STEP 1: IDENTIFICACION
          Step(
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
            title: Text(size.width > 1150 ? 'Identificación' : 'Identif.'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Container 1: Identificación del Proyecto (matching Stitch visual card specs)
                _buildVisualContainer(
                  title: 'Identificación del Proyecto',
                  icon: Icons.info_outline,
                  child: _buildResponsiveGrid([
                    _buildTextField(
                      label: 'Nombre del Proyecto *',
                      controller: _nombreCtrl,
                      maxLines: 2,
                      maxLength: 150,
                      validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                    ),
                    _buildSearchableInstitucionField(),
                    _buildCoejecutoraDropdown(),
                    _buildDropdown(
                      label: 'Sector de Inversión *',
                      value: _sectorSeleccionadoId,
                      items: _sectores,
                      onChanged: _onSectorChanged,
                    ),
                    _buildDropdown(
                      label: 'Sub-Sector de Inversión *',
                      value: _subsectorSeleccionadoId,
                      items: _subsectores,
                      onChanged: (v) => setState(() => _subsectorSeleccionadoId = v),
                    ),
                  ], isDesktop: isDesktop),
                ),
                const SizedBox(height: 20),

                // Container 2: Tipología y Estado (matching Stitch visual card specs)
                _buildVisualContainer(
                  title: 'Tipología y Estado',
                  icon: Icons.category_outlined,
                  child: _buildResponsiveGrid([
                    _buildRadioTipoIniciativa(),
                    _buildDropdown(
                      label: 'Etapa a Financiar *',
                      value: _nivelPreinversionSeleccionadoId,
                      items: _nivelesPreinversion,
                      onChanged: (v) => setState(() => _nivelPreinversionSeleccionadoId = v),
                    ),
                    _buildTextField(
                      label: 'Vida Útil (Años) *',
                      controller: _vidaUtilCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                    ),
                    _buildPeriodoEjecucionDropdown(),
                  ], isDesktop: isDesktop),
                ),
                const SizedBox(height: 20),

                // Container 3: Objetivos e Impacto
                _buildVisualContainer(
                  title: 'Objetivos del Proyecto',
                  icon: Icons.lightbulb_outline,
                  child: _buildResponsiveGrid([
                    _buildTextField(
                      label: 'Objetivo General *',
                      controller: _objetivoGeneralCtrl,
                      maxLines: 2,
                      maxLength: 500,
                      validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                    ),
                    _buildTextField(
                      label: 'Descripción del Problema / Necesidad *',
                      controller: _descripcionProblemaCtrl,
                      maxLines: 2,
                      maxLength: 500,
                      validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                    ),
                  ], isDesktop: isDesktop),
                ),
              ],
            ),
          ),

          // STEP 2: FINANCIAMIENTO Y LOCALIZACION
          Step(
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.editing,
            title: Text(size.width > 1150 ? 'Financiamiento' : 'Financ.'),
            content: _buildVisualContainer(
              title: 'Detalles de Financiamiento y Localización',
              icon: Icons.monetization_on_outlined,
              child: _buildResponsiveGrid([
                _buildTextField(
                  label: 'Costo Total (Lps) *',
                  controller: _costoTotalCtrl,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v!.isEmpty) return 'Campo obligatorio';
                    if (double.tryParse(v) == null) return 'Ingrese un valor numérico';
                    return null;
                  },
                ),
                _buildDropdown(
                  label: 'Departamento *',
                  value: _departamentoSeleccionadoId,
                  items: _departamentos,
                  onChanged: _onDepartamentoChanged,
                ),
                _buildDropdown(
                  label: 'Municipio *',
                  value: _municipioSeleccionadoId,
                  items: _municipios,
                  onChanged: (v) => setState(() => _municipioSeleccionadoId = v),
                ),
                _buildTextField(
                  label: 'Coordenadas Georreferenciadas (UTM WGS84)',
                  controller: _coordenadasUtmCtrl,
                  maxLength: 50,
                ),
                _buildTextField(
                  label: 'Entregable Principal',
                  controller: _entregablePrincipalCtrl,
                  maxLength: 100,
                ),
                _buildTextField(
                  label: 'Finalidad de la Intervención',
                  controller: _finalidadIntervencionCtrl,
                  maxLength: 250,
                ),
                _buildTextField(
                  label: '% Inversión Real',
                  controller: _porcentajeInversionRealCtrl,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final val = double.tryParse(v);
                    if (val == null || val < 1 || val > 100) return 'Entre 1 y 100';
                    return null;
                  },
                ),
                _buildTextField(
                  label: '% Desarrollo Humano',
                  controller: _porcentajeDesarrolloHumanoCtrl,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final val = double.tryParse(v);
                    if (val == null || val < 1 || val > 100) return 'Entre 1 y 100';
                    return null;
                  },
                ),
                _buildTextField(
                  label: 'Costo Estimado Anual de O&M',
                  controller: _costoAnualOperacionCtrl,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  label: 'Entidad Responsable de O&M',
                  controller: _entidadResponsableOperacionCtrl,
                  maxLength: 100,
                ),
                _buildDropdown(
                  label: 'Posibles Fuentes de Financiamiento',
                  value: _posibleFuenteFinanciamientoSeleccionadoId,
                  items: _fuentesFinanciamiento,
                  onChanged: (v) => setState(() => _posibleFuenteFinanciamientoSeleccionadoId = v),
                ),
                _buildTextField(
                  label: 'Aspectos Técnicos',
                  controller: _aspectosTecnicosCtrl,
                  maxLines: 2,
                  maxLength: 500,
                ),
              ], isDesktop: isDesktop),
            ),
          ),

          // STEP 3: COMPONENTES Y ESTUDIOS
          Step(
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.editing,
            title: Text(size.width > 1150 ? 'Componentes' : 'Comp.'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // COMPONENTES SECTION
                _buildVisualContainer(
                  title: 'Componentes del Proyecto',
                  icon: Icons.playlist_add_check,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _compNombreCtrl,
                              decoration: const InputDecoration(labelText: 'Nombre Componente', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 150,
                            child: TextField(
                              controller: _compCostoCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Costo (Lps)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _agregarComponente,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF24389C),
                              foregroundColor: Colors.white,
                            ),
                            child: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      if (_componentes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _componentes.length,
                          itemBuilder: (context, i) {
                            final c = _componentes[i];
                            return ListTile(
                              title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Lps ${Formatters.formatearLempiras(c.costo)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => setState(() => _componentes.removeAt(i)),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ESTUDIOS SECTION
                _buildVisualContainer(
                  title: 'Estudios y Diseños (Historial)',
                  icon: Icons.history_edu,
                  child: Column(
                    children: [
                      _buildResponsiveGrid([
                        TextField(
                          controller: _estNombreCtrl,
                          decoration: const InputDecoration(labelText: 'Nombre del Estudio', border: OutlineInputBorder()),
                        ),
                        TextField(
                          controller: _estFechaCtrl,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Fecha de Elaboración',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () => _seleccionarFechaElaboracion(context),
                        ),
                        TextField(
                          controller: _estObsCtrl,
                          decoration: const InputDecoration(labelText: 'Observaciones', border: OutlineInputBorder()),
                        ),
                      ], isDesktop: isDesktop),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar Estudio'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF24389C),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _agregarEstudio,
                        ),
                      ),
                      if (_estudios.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _estudios.length,
                          itemBuilder: (context, i) {
                            final e = _estudios[i];
                            return ListTile(
                              title: Text(e.nombreEstudio),
                              subtitle: Text('Elaboración: ${e.fechaElaboracion ?? "N/A"} | Obs: ${e.observaciones ?? "Ninguna"}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => setState(() => _estudios.removeAt(i)),
                              ),
                            );
                          },
                        )
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),

          // STEP 4: EVALUACION Y BENEFICIARIOS
          Step(
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.editing,
            title: Text(size.width > 1150 ? 'Beneficiarios' : 'Benef.'),
            content: _buildVisualContainer(
              title: 'Evaluación Socioeconómica e Impacto de Empleos',
              icon: Icons.analytics_outlined,
              child: _buildResponsiveGrid([
                _buildTextField(
                  label: 'Costo Anual Equivalente (CAE)',
                  controller: _evalCaeCtrl,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  label: 'Relación Costo - Eficiencia',
                  controller: _evalCostoEficienciaCtrl,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  label: 'Valor Presente Neto (VPN)',
                  controller: _evalVpnCtrl,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  label: 'Relación Beneficio / Costo (B/C)',
                  controller: _evalBeneficioCostoCtrl,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  label: 'Tasa Interna de Retorno (TIR %)',
                  controller: _evalTirCtrl,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  label: 'Beneficiarios Directos',
                  controller: _beneficiariosDirectosCtrl,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  label: 'Beneficiarios Indirectos',
                  controller: _beneficiariosIndirectosCtrl,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  label: 'Empleos Directos Generados',
                  controller: _empleosDirectosCtrl,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  label: 'Empleos Indirectos Generados',
                  controller: _empleosIndirectosCtrl,
                  keyboardType: TextInputType.number,
                ),
              ], isDesktop: isDesktop),
            ),
          ),
        ],
      ),
    );

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 8,
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: stepperWidget,
                ),
              ),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRecommendationsCard(),
                  const SizedBox(height: 24),
                  _buildSummaryCard(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return stepperWidget;
  }

  Widget _buildVisualContainer({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF24389C)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF191C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildRadioTipoIniciativa() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Iniciativa *',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        RadioGroup<String>(
          groupValue: _tipoIniciativa,
          onChanged: (v) => setState(() => _tipoIniciativa = v!),
          child: Row(
            children: [
              Radio<String>(
                value: 'Proyecto',
              ),
              const Text('Proyecto'),
              Radio<String>(
                value: 'Programa',
              ),
              const Text('Programa'),
              Radio<String>(
                value: 'Estudio',
              ),
              const Text('Estudio'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodoEjecucionDropdown() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _periodoEjecucionSeleccionado,
      decoration: const InputDecoration(
        labelText: 'Meses de Ejecución *',
        border: OutlineInputBorder(),
      ),
      items: _periodosMeses.map((p) {
        return DropdownMenuItem<String>(
          value: p,
          child: Text(p),
        );
      }).toList(),
      onChanged: (v) => setState(() => _periodoEjecucionSeleccionado = v),
    );
  }

  Widget _buildCoejecutoraDropdown() {
    List<DropdownMenuItem<String>> items = [
      const DropdownMenuItem<String>(
        value: null,
        child: Text('No aplica'),
      )
    ];
    items.addAll(_instituciones.map((i) {
      return DropdownMenuItem<String>(
        value: i['id'],
        child: Text(
          i['nombre'] ?? '',
          overflow: TextOverflow.ellipsis,
        ),
      );
    }));

    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _coejecutoraSeleccionadaId,
      decoration: const InputDecoration(
        labelText: 'Institución Coejecutora',
        border: OutlineInputBorder(),
      ),
      items: items,
      onChanged: (v) => setState(() => _coejecutoraSeleccionadaId = v),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    if (maxLength == null) {
      return TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: const SizedBox.shrink()),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                final currentLength = value.text.length;
                final remaining = maxLength - currentLength;
                final displayRemaining = remaining < 0 ? 0 : remaining;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4, right: 4),
                  child: Text(
                    '$displayRemaining caracteres restantes',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: remaining <= 10 ? Colors.red.shade700 : Colors.grey.shade600,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          maxLength: maxLength,
          buildCounter: (context, {required currentLength, required isFocused, required maxLength}) => null,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<Map<String, dynamic>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items.map((i) {
        return DropdownMenuItem<String>(
          value: i['id'],
          child: Text(
            i['nombre'] ?? '',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSearchableInstitucionField() {
    final userSp = ServicioPermisos();
    final isRestricted = userSp.esFormuladorODirectorUpeg && userSp.userInstitucionId != null;

    return InkWell(
      onTap: isRestricted ? null : () async {
        final seleccion = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => _BuscarInstitucionDialog(instituciones: _instituciones),
        );
        if (seleccion != null) {
          setState(() {
            _institucionSeleccionadaId = seleccion['id'];
            _institucionSeleccionadaNombre = '${seleccion['codigo']} - ${seleccion['nombre']}';
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Institución Ejecutora *',
          border: const OutlineInputBorder(),
          suffixIcon: isRestricted ? null : const Icon(Icons.arrow_drop_down),
          fillColor: isRestricted ? Colors.grey.shade100 : null,
          filled: isRestricted,
        ),
        child: Text(
          _institucionSeleccionadaNombre ?? 'Seleccione una institución...',
          style: TextStyle(
            color: _institucionSeleccionadaNombre == null
                ? Colors.grey[600]
                : Colors.black,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    return Card(
      color: const Color(0xFF24389C).withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFDEE0FF)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Color(0xFF24389C)),
                SizedBox(width: 8),
                Text(
                  'Recomendaciones',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF24389C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'El nombre del proyecto debe seguir la estructura estándar: [Acción] + [Objeto] + [Ubicación].',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF454652),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Correcto',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '"Construcción Escuela Básica Los Pinos, Valdivia"',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cancel_outlined, size: 16, color: Colors.red.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Incorrecto',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '"Proyecto para hacer una escuela nueva"',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final double completitud = _calcularCompletitud();
    final isNew = widget.proyectoAEditar == null;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RESUMEN DE FORMULACIÓN',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estado', style: TextStyle(color: Colors.grey, fontSize: 13)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isNew ? 'Borrador' : 'Edición',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Última mod.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                Text(
                  isNew ? 'Nueva ficha' : 'Hace 5 min',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Completitud', style: TextStyle(color: Colors.grey, fontSize: 13)),
                Text(
                  '${completitud.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF24389C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: completitud / 100,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF24389C)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid(List<Widget> children, {required bool isDesktop}) {
    if (isDesktop) {
      final List<Widget> rows = [];
      for (int i = 0; i < children.length; i += 2) {
        final left = children[i];
        final right = (i + 1 < children.length) ? children[i + 1] : const Spacer();
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: left),
                const SizedBox(width: 16),
                Expanded(child: right),
              ],
            ),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: c,
                ))
            .toList(),
      );
    }
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
      title: const Text('Buscar Institución Ejecutora'),
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
