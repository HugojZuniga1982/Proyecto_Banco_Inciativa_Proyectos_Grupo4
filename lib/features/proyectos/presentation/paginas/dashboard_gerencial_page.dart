import 'package:flutter/material.dart';
import '../../../../models/proyecto.dart';
import '../../services/proyecto_service.dart';
import '../../../../core/security/servicio_permisos.dart';
import '../../../security/presentation/paginas/acceso_denegado_widget.dart';
import '../../../security/presentation/paginas/menu_lateral_bip.dart';
import '../../../../core/utils/formatters.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardGerencialPage extends StatefulWidget {
  final bool isEmbedded;
  final void Function(String tab, Proyecto? proyecto)? onNavigate;

  const DashboardGerencialPage({
    super.key,
    this.isEmbedded = false,
    this.onNavigate,
  });

  @override
  State<DashboardGerencialPage> createState() => _DashboardGerencialPageState();
}

class _DashboardGerencialPageState extends State<DashboardGerencialPage> {
  final _proyectoService = ProyectoService();
  bool _cargando = true;

  int _totalProyectos = 0;
  double _costoAcumulado = 0.0;
  double _tasaAprobacion = 0.0;
  Map<String, int> _proyectosPorSector = {};
  Map<String, double> _costoPorSector = {};
  Map<String, int> _proyectosPorEstado = {};

  @override
  void initState() {
    super.initState();
    _cargarMetricas();
  }

  Future<void> _cargarMetricas() async {
    setState(() => _cargando = true);
    try {
      final userSp = ServicioPermisos();
      String? filterInstId;
      if (userSp.esFormuladorODirectorUpeg) {
        filterInstId = userSp.userInstitucionId;
      }
      final data = await _proyectoService.obtenerMetricasDashboard(institucionId: filterInstId);
      setState(() {
  _totalProyectos = data['totalProyectos'] ?? 0;
  _costoAcumulado = data['costoAcumulado'] ?? 0.0;
  _tasaAprobacion = data['tasaAprobacion'] ?? 0.0;
  _proyectosPorSector = Map<String, int>.from(data['proyectosPorSector'] ?? {});
  _costoPorSector = Map<String, double>.from(data['costoPorSector'] ?? {});
  _proyectosPorEstado = Map<String, int>.from(data['proyectosPorEstado'] ?? {});
  _cargando = false;
});
    } catch (e) {
      setState(() => _cargando = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar métricas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ServicioPermisos().tiene('preinversion.dashboard.consultar')) {
      return const AccesoDenegadoWidget(
        permisoRequerido: 'preinversion.dashboard.consultar',
        tituloSeccion: 'Dashboard Gerencial',
      );
    }

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    if (widget.isEmbedded) {
      return _cargando
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(isDesktop);
    }

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      drawer: const MenuLateralBip(rutaActiva: 'dashboard'),
      appBar: AppBar(
        title: const Text('Dashboard Gerencial BIP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarMetricas,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(isDesktop),
    );
  }

  Widget _buildBody(bool isDesktop) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Embedded header title matching Stitch specs
          if (widget.isEmbedded) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard Gerencial',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF191C1E),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Indicadores ejecutivos y resumen de inversiones',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF24389C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _cargarMetricas,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // KPI Cards
          _buildKpiSection(isDesktop),
          const SizedBox(height: 24),

          // Charts/Distributions
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildProyectosPorSectorCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildInversionPorSectorCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildEstadoGeneralCard()),
                  ],
                )
              : Column(
                  children: [
                    _buildProyectosPorSectorCard(),
                    const SizedBox(height: 16),
                    _buildInversionPorSectorCard(),
                    const SizedBox(height: 16),
                    _buildEstadoGeneralCard(),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildKpiSection(bool isDesktop) {
    final children = [
    _buildKpiCard(
      title: 'Total Proyectos Registrados',
      value: '$_totalProyectos',
      subtitle: 'Fichas BIP activas en el sistema',
      icon: Icons.assignment_outlined,
      color: Colors.indigo,
    ),
    _buildKpiCard(
      title: 'Inversión Acumulada Planeada',
      value: 'Lps ${Formatters.formatearLempiras(_costoAcumulado)}',
      subtitle: 'Presupuesto total estimado',
      icon: Icons.monetization_on_outlined,
      color: Colors.teal,
    ),
    _buildKpiCard(
      title: 'Tasa de Aprobación',
      value: '${(_tasaAprobacion * 100).toStringAsFixed(0)}%',
      subtitle: 'Proyectos aprobados sobre el total',
      icon: Icons.check_circle_outline,
      color: Colors.green,
    ),
  ];

    if (isDesktop) {
      return Row(
        children: children
            .map((card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: card,
                  ),
                ))
            .toList(),
      );
    } else {
      return Column(
        children: children
            .map((card) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: card,
                ))
            .toList(),
      );
    }
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProyectosPorSectorCard() {
  final sectores = _proyectosPorSector.keys.toList();
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribución de Proyectos por Sector',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF24389C)),
          ),
          const SizedBox(height: 16),
          if (_proyectosPorSector.isEmpty)
            const Center(child: Text('No hay proyectos registrados aún.', style: TextStyle(color: Colors.grey)))
          else
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _proyectosPorSector.values.reduce((a, b) => a > b ? a : b).toDouble() + 1,
                  barGroups: List.generate(sectores.length, (index) {
                    final valor = _proyectosPorSector[sectores[index]]!;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: valor.toDouble(),
                          color: const Color(0xFF24389C),
                          width: 22,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= sectores.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              sectores[index],
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

  Widget _buildInversionPorSectorCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inversión Financiera por Sector',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF24389C)),
            ),
            const SizedBox(height: 16),
            if (_costoPorSector.isEmpty)
              const Center(child: Text('No hay costos de inversión registrados.', style: TextStyle(color: Colors.grey)))
            else
              ..._costoPorSector.entries.map((entry) {
                final pct = _costoAcumulado > 0 ? (entry.value / _costoAcumulado) : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500))),
                          Text('Lps ${Formatters.formatearLempiras(entry.value)} (${(pct * 100).toStringAsFixed(1)}%)', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
    Widget _buildEstadoGeneralCard() {
    final estados = _proyectosPorEstado.keys.toList();
    final coloresPorEstado = {
      'INGRESADO': Colors.blueGrey,
      'VERIFICADO': Colors.blue,
      'VERIFICADO_INSTITUCION': Colors.orange,
      'APROBADO': Colors.green,
      'RECHAZADO': Colors.red,
    };

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estado General',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF24389C)),
            ),
            const Text(
              'Fases del proceso de verificación',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (_proyectosPorEstado.isEmpty)
              const Center(child: Text('No hay datos de estado disponibles.', style: TextStyle(color: Colors.grey)))
            else
              Row(
                children: [
                  SizedBox(
                    height: 160,
                    width: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 45,
                            sections: estados.map((estado) {
                              final valor = _proyectosPorEstado[estado]!;
                              return PieChartSectionData(
                                value: valor.toDouble(),
                                color: coloresPorEstado[estado] ?? Colors.grey,
                                radius: 30,
                                showTitle: false,
                              );
                            }).toList(),
                          ),
                        ),
                        Text(
                          '$_totalProyectos\nTotal',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: estados.map((estado) {
                        final valor = _proyectosPorEstado[estado]!;
                        final pct = _totalProyectos > 0 ? (valor / _totalProyectos * 100) : 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              CircleAvatar(radius: 5, backgroundColor: coloresPorEstado[estado] ?? Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(estado, style: const TextStyle(fontSize: 11)),
                              ),
                              Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
