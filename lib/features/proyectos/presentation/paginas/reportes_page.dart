import 'package:flutter/material.dart';
import 'package:proyecto_programacion_movil_grupo_4/models/proyecto.dart';
import 'package:proyecto_programacion_movil_grupo_4/features/proyectos/services/proyecto_service.dart';
import 'package:proyecto_programacion_movil_grupo_4/features/security/services/usuario_service.dart';
import 'package:proyecto_programacion_movil_grupo_4/features/catalogs/services/catalogos_service.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:csv/csv.dart';
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
      // Filtro por institución: si no hay ninguna seleccionada, pasa cualquiera.
      final pasaInstitucion = _institucionSeleccionada == null ||
          proyecto.institucionId == _institucionSeleccionada;

      // Filtro por fuente de financiamiento.
      final pasaFuente = _fuenteSeleccionada == null ||
          proyecto.posibleFuenteFinanciamientoId == _fuenteSeleccionada;

      // Filtro por rango de fechas (solo si el proyecto tiene fecha de creación).
      final pasaFechaInicio = _fechaInicio == null ||
          (proyecto.fechaCreacion != null &&
              !proyecto.fechaCreacion!.isBefore(_fechaInicio!));

      final pasaFechaFin = _fechaFin == null ||
          (proyecto.fechaCreacion != null &&
              !proyecto.fechaCreacion!.isAfter(_fechaFin!));

      // El proyecto solo se muestra si pasa TODOS los filtros activos.
      return pasaInstitucion && pasaFuente && pasaFechaInicio && pasaFechaFin;
    }).toList();
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
  // Encabezados de las columnas
  List<List<dynamic>> filas = [
    ['Institución', 'Nombre del Proyecto', 'Fuente de Financiamiento', 'Inversión (Lps)', 'Estado'],
  ];

  // Una fila por cada proyecto FILTRADO (no solo los de la página actual)
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
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', 'reporte_proyectos.csv')
    ..click();
  html.Url.revokeObjectUrl(url);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Reporte CSV descargado correctamente.')),
  );
}
Future<void> _exportarPDF() async {
  final documento = pw.Document();

  documento.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Header(level: 0, child: pw.Text('Reporte de Proyectos - BIP Web')),
        pw.SizedBox(height: 12),
        pw.Table.fromTextArray(
          headers: ['Institución', 'Nombre del Proyecto', 'Fuente Financ.', 'Inversión (Lps)', 'Estado'],
          data: _proyectosFiltrados.map((p) {
            return [
              p.institucionNombre ?? 'N/A',
              p.nombre,
              p.posibleFuenteFinanciamientoNombre ?? 'N/A',
              p.costoTotal.toStringAsFixed(2),
              p.estadoProceso,
            ];
          }).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignment: pw.Alignment.centerLeft,
        ),
      ],
    ),
  );

  await Printing.sharePdf(
    bytes: await documento.save(),
    filename: 'reporte_proyectos.pdf',
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
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Generador de Reportes',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: 220,
                              child: DropdownButtonFormField<String>(
                              value: _institucionSeleccionada,
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
                              width: 220,
                              child: DropdownButtonFormField<String>(
                                value: _fuenteSeleccionada,
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
                              onPressed: _aplicarFiltros,
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: _limpiarFiltros,
                              child: const Text('Limpiar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text(
      'Resultados del Reporte',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
    Row(
  children: [
    Text(
      'Mostrando ${_proyectosFiltrados.length} de ${_proyectosOriginales.length} registros encontrados',
      style: const TextStyle(color: Colors.grey, fontSize: 12),
    ),
    const SizedBox(width: 16),
    OutlinedButton.icon(
      icon: const Icon(Icons.picture_as_pdf, size: 18),
      label: const Text('Exportar PDF'),
      onPressed: _proyectosFiltrados.isEmpty ? null : _exportarPDF,
    ),
    const SizedBox(width: 8),
    OutlinedButton.icon(
      icon: const Icon(Icons.table_chart, size: 18),
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
              ],
              rows: _proyectosPaginaActual.map((p) {
                return DataRow(cells: [
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(p.institucionNombre ?? 'N/A', overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 220,
                      child: Text(p.nombre, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  DataCell(Text(p.costoTotal.toStringAsFixed(2))),
                  DataCell(_buildBadgeEstado(p.estadoProceso)),
                ]);
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