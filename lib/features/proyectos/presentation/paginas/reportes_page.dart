import 'package:flutter/material.dart';
import 'package:proyecto_programacion_movil_grupo_4/models/proyecto.dart';
import 'package:proyecto_programacion_movil_grupo_4/features/proyectos/services/proyecto_service.dart';
import 'package:proyecto_programacion_movil_grupo_4/features/security/services/usuario_service.dart';
import 'package:proyecto_programacion_movil_grupo_4/features/catalogs/services/catalogos_service.dart';
import 'package:proyecto_programacion_movil_grupo_4/core/utils/formatters.dart';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});

  @override
  State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  final _proyectoService = ProyectoService();
  final _usuarioService = UsuarioService();
  final _catalogosService = CatalogosService();

  bool _cargando = true;
  List<Proyecto> _proyectosOriginales = [];
  List<Proyecto> _proyectosFiltrados = [];

  List<Map<String, dynamic>> _instituciones = [];
  List<Map<String, dynamic>> _fuentesFinanciamiento = [];

  String? _institucionSeleccionada;
  String? _fuenteSeleccionada;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  int _paginaActual = 0;
  static const int _filasPorPagina = 10;

  Proyecto? _proyectoSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final resultados = await Future.wait([
        _proyectoService.obtenerProyectos(),
        _usuarioService.obtenerInstituciones(),
        _catalogosService.obtenerFuentesFinanciamiento(),
      ]);

      setState(() {
        _proyectosOriginales = resultados[0] as List<Proyecto>;
        _proyectosFiltrados = resultados[0] as List<Proyecto>;
        _instituciones = resultados[1] as List<Map<String, dynamic>>;
        _fuentesFinanciamiento = resultados[2] as List<Map<String, dynamic>>;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _aplicarFiltros() {
    setState(() {
      _paginaActual = 0;
      _proyectosFiltrados = _proyectosOriginales.where((proyecto) {
        final pasaInstitucion = _institucionSeleccionada == null ||
            proyecto.institucionId == _institucionSeleccionada;

        final pasaFuente = _fuenteSeleccionada == null ||
            proyecto.posibleFuenteFinanciamientoId == _fuenteSeleccionada;

        final pasaFechaInicio = _fechaInicio == null ||
            (proyecto.fechaCreacion != null &&
                !proyecto.fechaCreacion!.isBefore(_fechaInicio!));

        final pasaFechaFin = _fechaFin == null ||
            (proyecto.fechaCreacion != null &&
                !proyecto.fechaCreacion!.isAfter(_fechaFin!));

        return pasaInstitucion && pasaFuente && pasaFechaInicio && pasaFechaFin;
      }).toList();

      if (_proyectoSeleccionado != null &&
          !_proyectosFiltrados.any((p) => p.id == _proyectoSeleccionado!.id)) {
        _proyectoSeleccionado = null;
      }
    });
  }

  void _limpiarFiltros() {
    setState(() {
      _institucionSeleccionada = null;
      _fuenteSeleccionada = null;
      _fechaInicio = null;
      _fechaFin = null;
      _paginaActual = 0;
      _proyectosFiltrados = _proyectosOriginales;
      _proyectoSeleccionado = null;
    });
  }

  List<Proyecto> get _proyectosPaginaActual {
    final inicio = _paginaActual * _filasPorPagina;
    final fin = (inicio + _filasPorPagina) > _proyectosFiltrados.length
        ? _proyectosFiltrados.length
        : inicio + _filasPorPagina;
    if (inicio >= _proyectosFiltrados.length) return [];
    return _proyectosFiltrados.sublist(inicio, fin);
  }

  int get _totalPaginas => (_proyectosFiltrados.length / _filasPorPagina).ceil();

  Widget _buildBadgeEstado(String estado) {
    Color color;
    switch (estado) {
      case 'APROBADO':
        color = Colors.green;
        break;
      case 'RECHAZADO':
        color = Colors.red;
        break;
      case 'VERIFICADO':
      case 'VERIFICADO_INSTITUCION':
        color = Colors.blue;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        estado,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  void _exportarCSV() {
    List<List<dynamic>> filas = [
      ['Institución', 'Nombre del Proyecto', 'Fuente de Financiamiento', 'Inversión (Lps)', 'Estado'],
    ];

    for (var p in _proyectosFiltrados) {
      filas.add([
        p.institucionNombre ?? 'N/A',
        p.nombre,
        p.posibleFuenteFinanciamientoNombre ?? 'N/A',
        p.costoTotal.toStringAsFixed(2),
        p.estadoProceso,
      ]);
    }

    String csvData = csv.encode(filas);
    final bytes = utf8.encode(csvData);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'reporte_proyectos.csv')
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reporte CSV descargado correctamente.')),
    );
  }

  // 1. Reporte Listado Tabular
  Future<void> _exportarPDF() async {
    final documento = pw.Document();

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('REPÚBLICA DE HONDURAS - SECRETARÍA DE FINANZAS (SEFIN)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                  pw.Text('DIRECCIÓN GENERAL DE INVERSIONES PÚBLICAS (DGIP)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                  pw.Text('LISTADO DE PROYECTOS DE PREINVERSIÓN REGISTRADOS (BIP)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700)),
                ],
              ),
              pw.Text('Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.indigo900, thickness: 1.5),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['No.', 'Institución', 'Nombre del Proyecto', 'Fuente Financ.', 'Inversión (Lps)', 'Estado'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(color: PdfColors.grey300),
            data: List.generate(_proyectosFiltrados.length, (i) {
              final p = _proyectosFiltrados[i];
              return [
                '${i + 1}',
                p.institucionNombre ?? 'N/A',
                p.nombre,
                p.posibleFuenteFinanciamientoNombre ?? 'N/A',
                Formatters.formatearLempiras(p.costoTotal),
                p.estadoProceso,
              ];
            }),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => documento.save(),
      name: 'reporte_listado_proyectos.pdf',
    );
  }

  // 2. Ficha Técnica Oficial de un Proyecto Seleccionado
  Future<void> _imprimirFichaTecnica(Proyecto p) async {
    final documento = pw.Document();

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Encabezado institucional
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.indigo900, width: 2)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('REPÚBLICA DE HONDURAS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.Text('SECRETARÍA DE FINANZAS (SEFIN)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                    pw.Text('Dirección General de Inversiones Públicas (DGIP) - Banco Integrado de Proyectos (BIP)', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.indigo50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: PdfColors.indigo900),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('ESTADO BIP', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                      pw.Text(p.estadoProceso, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Título de la Ficha
          pw.Center(
            child: pw.Text('FICHA TÉCNICA OFICIAL DE PREINVERSIÓN', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(p.nombre, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 12),

          // Sección 1: Identificación y Localización
          _buildPdfSectionHeader('1. IDENTIFICACIÓN Y LOCALIZACIÓN'),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            cellStyle: const pw.TextStyle(fontSize: 8),
            data: [
              ['Institución Formuladora:', p.institucionNombre ?? 'N/A', 'Institución Coejecutora:', p.institucionCoejecutoraNombre ?? 'No aplica'],
              ['Sector de Inversión:', p.subsectorNombre ?? 'N/A', 'Etapa a Financiar:', p.nivelPreinversionNombre ?? 'N/A'],
              ['Departamento:', p.departamentoNombre ?? 'N/A', 'Municipio:', p.municipioNombre ?? 'N/A'],
              ['Coordenadas UTM:', p.coordenadasUtm ?? 'Sin georreferenciación', 'Periodo Ejecución:', p.periodoEjecucion],
              ['Vida Útil (Años):', '${p.vidaUtil ?? 20} años', 'Tipo Iniciativa:', p.tipoIniciativa],
            ],
          ),
          pw.SizedBox(height: 10),

          // Sección 2: Objetivos y Justificación
          _buildPdfSectionHeader('2. OBJETIVOS Y JUSTIFICACIÓN'),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Objetivo General:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                pw.Text(p.objetivoGeneral.isNotEmpty ? p.objetivoGeneral : 'No especificado', style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 4),
                pw.Text('Descripción del Problema / Necesidad:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                pw.Text(p.descripcionProblema.isNotEmpty ? p.descripcionProblema : 'No especificado', style: const pw.TextStyle(fontSize: 8)),
                if (p.entregablePrincipal != null && p.entregablePrincipal!.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text('Entregable Principal: ${p.entregablePrincipal}', style: const pw.TextStyle(fontSize: 8)),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // Sección 3: Presupuesto y Componentes
          _buildPdfSectionHeader('3. PRESUPUESTO Y COMPONENTES'),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Costo Total Estimado: Lps ${Formatters.formatearLempiras(p.costoTotal)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.indigo900)),
              pw.Text('Fuente Posible: ${p.posibleFuenteFinanciamientoNombre ?? "Fondos Nacionales"}', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
          pw.SizedBox(height: 4),
          if (p.componentes.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: ['No.', 'Nombre del Componente', 'Costo Estimado (Lps)'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
              border: pw.TableBorder.all(color: PdfColors.grey300),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              cellStyle: const pw.TextStyle(fontSize: 8),
              data: List.generate(p.componentes.length, (i) {
                final c = p.componentes[i];
                return ['${i + 1}', c.nombre, 'Lps ${Formatters.formatearLempiras(c.costo)}'];
              }),
            )
          else
            pw.Text('Sin desglose de componentes registrado.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.SizedBox(height: 10),

          // Sección 4: Evaluación e Impacto
          _buildPdfSectionHeader('4. EVALUACIÓN SOCIOECONÓMICA E IMPACTO'),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            cellStyle: const pw.TextStyle(fontSize: 8),
            data: [
              ['Costo Anual Equivalente (CAE):', p.evalCostoAnualEquivalente != null ? 'Lps ${Formatters.formatearLempiras(p.evalCostoAnualEquivalente!)}' : 'N/A', 'Relación Costo - Eficiencia:', p.evalRelacionCostoEficiencia?.toString() ?? 'N/A'],
              ['Valor Presente Neto (VPN):', p.evalVpn != null ? 'Lps ${Formatters.formatearLempiras(p.evalVpn!)}' : 'N/A', 'Tasa Interna Retorno (TIR):', p.evalTir != null ? '${p.evalTir}%' : 'N/A'],
              ['Relación Beneficio / Costo:', p.evalBeneficioCosto?.toString() ?? 'N/A', 'Inversión Real / Desarrollo Humano:', '${p.porcentajeInversionReal ?? 0}% / ${p.porcentajeDesarrolloHumano ?? 0}%'],
              ['Beneficiarios Directos:', '${p.beneficiariosDirectos ?? 0} hab.', 'Beneficiarios Indirectos:', '${p.beneficiariosIndirectos ?? 0} hab.'],
              ['Empleos Directos:', '${p.empleosDirectos ?? 0} empleos', 'Empleos Indirectos:', '${p.empleosIndirectos ?? 0} empleos'],
            ],
          ),
          pw.SizedBox(height: 20),

          // Firmas de Responsabilidad
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Container(width: 140, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey800)))),
                  pw.SizedBox(height: 3),
                  pw.Text('Formulador UPEG', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Firma y Sello Institucional', style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 140, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey800)))),
                  pw.SizedBox(height: 3),
                  pw.Text('Aprobador / Director UPEG', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Firma y Sello de Autorización', style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 140, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey800)))),
                  pw.SizedBox(height: 3),
                  pw.Text('Analista / Coordinador DGIP', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Dictamen de Calidad Preinversión', style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text('Documento oficial generado por el Sistema BIP Web (SEFIN / DGIP) - Fecha de emisión: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
          ),
        ],
      ),
    );

    final cleanName = p.nombre.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    await Printing.layoutPdf(
      onLayout: (format) async => documento.save(),
      name: 'Ficha_Tecnica_$cleanName.pdf',
    );
  }

  // 3. Reporte General Consolidado por Institución
  Future<void> _exportarReportePorInstitucion() async {
    final documento = pw.Document();

    Map<String, List<Proyecto>> proyectosPorInst = {};
    for (var p in _proyectosFiltrados) {
      final inst = p.institucionNombre ?? 'Sin Institución Asignada';
      proyectosPorInst.putIfAbsent(inst, () => []).add(p);
    }

    final String ambitoFiltro = _institucionSeleccionada != null
        ? (_instituciones.firstWhere((i) => i['id'] == _institucionSeleccionada, orElse: () => {})['nombre'] ?? 'Institución Seleccionada')
        : 'Consolidado Institucional (Todas las Entidades)';

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          final List<pw.Widget> content = [];

          // Encabezado
          content.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('REPÚBLICA DE HONDURAS - SECRETARÍA DE FINANZAS (SEFIN)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.Text('DIRECCIÓN GENERAL DE INVERSIONES PÚBLICAS (DGIP)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                    pw.Text('SISTEMA BIP - REPORTE GENERAL CONSOLIDADO POR INSTITUCIÓN', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Fecha de Emisión: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Ámbito: $ambitoFiltro', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                  ],
                ),
              ],
            ),
          );
          content.add(pw.SizedBox(height: 10));
          content.add(pw.Divider(color: PdfColors.indigo900, thickness: 1.5));
          content.add(pw.SizedBox(height: 8));

          // Resumen global
          double totalInversionGlobal = 0.0;
          int totalProyectosGlobal = _proyectosFiltrados.length;
          int totalAprobadosGlobal = 0;
          for (var p in _proyectosFiltrados) {
            totalInversionGlobal += p.costoTotal;
            if (p.estadoProceso == 'APROBADO') totalAprobadosGlobal++;
          }

          content.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.indigo50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.indigo200),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Total de Proyectos', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.Text('$totalProyectosGlobal', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Inversión Total Acumulada', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.Text('Lps ${Formatters.formatearLempiras(totalInversionGlobal)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Instituciones Registradas', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.Text('${proyectosPorInst.keys.length}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Tasa de Aprobación', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.Text(
                        totalProyectosGlobal > 0 ? '${((totalAprobadosGlobal / totalProyectosGlobal) * 100).toStringAsFixed(0)}%' : '0%',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
          content.add(pw.SizedBox(height: 12));

          // Desglose por Institución
          proyectosPorInst.forEach((institucionNombre, listaProyectos) {
            double totalInst = listaProyectos.fold(0.0, (sum, p) => sum + p.costoTotal);

            content.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 8, bottom: 4),
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Entidad: $institucionNombre (${listaProyectos.length} iniciativas)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.indigo900)),
                    pw.Text('Inversión Institucional: Lps ${Formatters.formatearLempiras(totalInst)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.indigo900)),
                  ],
                ),
              ),
            );

            content.add(
              pw.TableHelper.fromTextArray(
                headers: ['No.', 'Nombre de la Iniciativa de Inversión', 'Sector / Subsector', 'Fuente Financ.', 'Inversión (Lps)', 'Estado Proceso'],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
                border: pw.TableBorder.all(color: PdfColors.grey300),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                cellStyle: const pw.TextStyle(fontSize: 7),
                cellAlignment: pw.Alignment.centerLeft,
                data: List.generate(listaProyectos.length, (idx) {
                  final p = listaProyectos[idx];
                  return [
                    '${idx + 1}',
                    p.nombre,
                    p.subsectorNombre ?? 'N/A',
                    p.posibleFuenteFinanciamientoNombre ?? 'Fondos Nacionales',
                    Formatters.formatearLempiras(p.costoTotal),
                    p.estadoProceso,
                  ];
                }),
              ),
            );
            content.add(pw.SizedBox(height: 6));
          });

          return content;
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => documento.save(),
      name: 'Reporte_General_Institucional.pdf',
    );
  }

  static pw.Widget _buildPdfSectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      decoration: const pw.BoxDecoration(
        color: PdfColors.indigo900,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes y Exportación')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Filtros
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Generador de Reportes y Filtros',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              SizedBox(
                                width: 260,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _institucionSeleccionada,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Institución',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text('Todas las instituciones')),
                                    ..._instituciones.map((inst) => DropdownMenuItem(
                                          value: inst['id'] as String,
                                          child: Text(
                                            inst['nombre'] ?? '',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )),
                                  ],
                                  onChanged: (valor) => setState(() => _institucionSeleccionada = valor),
                                ),
                              ),
                              SizedBox(
                                width: 240,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _fuenteSeleccionada,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Fuente de Financiamiento',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text('Todas las fuentes')),
                                    ..._fuentesFinanciamiento.map((f) => DropdownMenuItem(
                                          value: f['id'] as String,
                                          child: Text(
                                            f['nombre'] ?? '',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )),
                                  ],
                                  onChanged: (valor) => setState(() => _fuenteSeleccionada = valor),
                                ),
                              ),
                              SizedBox(
                                width: 160,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.date_range),
                                  label: Text(_fechaInicio == null
                                      ? 'Fecha inicio'
                                      : '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}'),
                                  onPressed: () async {
                                    final seleccionada = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2015),
                                      lastDate: DateTime(2035),
                                    );
                                    if (seleccionada != null) {
                                      setState(() => _fechaInicio = seleccionada);
                                    }
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 160,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.date_range),
                                  label: Text(_fechaFin == null
                                      ? 'Fecha fin'
                                      : '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}'),
                                  onPressed: () async {
                                    final seleccionada = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2015),
                                      lastDate: DateTime(2035),
                                    );
                                    if (seleccionada != null) {
                                      setState(() => _fechaFin = seleccionada);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.filter_alt),
                                label: const Text('Aplicar Filtros'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF24389C),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _aplicarFiltros,
                              ),
                              const SizedBox(width: 12),
                              TextButton(
                                onPressed: _limpiarFiltros,
                                child: const Text('Limpiar Filtros'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Card Resultados
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Resultados y Exportación',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Mostrando ${_proyectosFiltrados.length} de ${_proyectosOriginales.length} iniciativas',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    if (_proyectoSeleccionado != null) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF24389C).withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFF24389C).withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.check_circle, size: 14, color: Color(0xFF24389C)),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Seleccionado: ${_proyectoSeleccionado!.nombre}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF24389C)),
                                            ),
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () => setState(() => _proyectoSeleccionado = null),
                                              child: const Icon(Icons.close, size: 14, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.end,
                                children: [
                                  // Botón 1: Reporte General por Institución
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.account_balance, size: 16),
                                    label: Text(_institucionSeleccionada != null
                                        ? 'Reporte Institucional (PDF)'
                                        : 'Reporte por Institución (PDF)'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF134074),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: _proyectosFiltrados.isEmpty ? null : _exportarReportePorInstitucion,
                                  ),
                                  // Botón 2: Ficha Técnica Individual (si hay seleccionado)
                                  if (_proyectoSeleccionado != null)
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.print, size: 16),
                                      label: const Text('Imprimir Ficha Seleccionada'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF24389C),
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => _imprimirFichaTecnica(_proyectoSeleccionado!),
                                    ),
                                  // Botón 3: Exportar Listado PDF
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                                    label: const Text('Listado (PDF)'),
                                    onPressed: _proyectosFiltrados.isEmpty ? null : _exportarPDF,
                                  ),
                                  // Botón 4: Exportar CSV
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.table_chart, size: 16),
                                    label: const Text('Exportar Excel'),
                                    onPressed: _proyectosFiltrados.isEmpty ? null : _exportarCSV,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_proyectosFiltrados.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: Text('No se encontraron proyectos con los filtros seleccionados.')),
                            )
                          else ...[
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFECEEF1)),
                                columns: const [
                                  DataColumn(label: Text('Institución', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Nombre del Proyecto', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Inversión (Lps)', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Ficha Técnica', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: _proyectosPaginaActual.map((p) {
                                  final bool isSelected = _proyectoSeleccionado?.id == p.id;
                                  return DataRow(
                                    selected: isSelected,
                                    onSelectChanged: (val) {
                                      setState(() {
                                        _proyectoSeleccionado = val == true ? p : null;
                                      });
                                    },
                                    cells: [
                                      DataCell(
                                        SizedBox(
                                          width: 170,
                                          child: Text(p.institucionNombre ?? 'N/A', overflow: TextOverflow.ellipsis),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 220,
                                          child: Text(
                                            p.nombre,
                                            style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(Text('Lps ${Formatters.formatearLempiras(p.costoTotal)}')),
                                      DataCell(_buildBadgeEstado(p.estadoProceso)),
                                      DataCell(
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.print, size: 14),
                                          label: const Text('Ficha PDF', style: TextStyle(fontSize: 11)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF24389C),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            minimumSize: const Size(90, 30),
                                          ),
                                          onPressed: () => _imprimirFichaTecnica(p),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _paginaActual > 0
                                      ? () => setState(() => _paginaActual--)
                                      : null,
                                ),
                                Text('Página ${_paginaActual + 1} de $_totalPaginas'),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: (_paginaActual + 1) < _totalPaginas
                                      ? () => setState(() => _paginaActual++)
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}