import 'package:flutter/material.dart';
import '../../../../models/proyecto.dart';
import '../../services/proyecto_service.dart';
import 'ficha_proyecto_page.dart';
import 'detalle_proyecto_page.dart';
import '../../../security/presentation/paginas/menu_lateral_bip.dart';
import '../../../../core/security/servicio_permisos.dart';
import '../../../security/presentation/paginas/acceso_denegado_widget.dart';
import '../../../../core/utils/formatters.dart';

class BandejaProyectosPage extends StatefulWidget {
  final bool isEmbedded;
  final void Function(String tab, Proyecto? proyecto)? onNavigate;

  const BandejaProyectosPage({
    super.key,
    this.isEmbedded = false,
    this.onNavigate,
  });

  @override
  State<BandejaProyectosPage> createState() => _BandejaProyectosPageState();
}

class _BandejaProyectosPageState extends State<BandejaProyectosPage> {
  final _proyectoService = ProyectoService();
  List<Proyecto> _proyectos = [];
  List<Proyecto> _filtrados = [];
  bool _cargando = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarProyectos();
  }

  Future<void> _cargarProyectos() async {
    setState(() => _cargando = true);
    try {
      final proys = await _proyectoService.obtenerProyectos();
      
      final userSp = ServicioPermisos();
      List<Proyecto> filteredProys = proys;
      if (userSp.esFormuladorODirectorUpeg && userSp.userInstitucionId != null) {
        filteredProys = proys.where((p) => p.institucionId == userSp.userInstitucionId).toList();
      }

      setState(() {
        _proyectos = filteredProys;
        _filtrados = filteredProys;
        _cargando = false;
      });
      _filtrar(_searchCtrl.text);
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarMensaje('Error al cargar proyectos: $e', esError: true);
    }
  }

  void _filtrar(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtrados = _proyectos;
      } else {
        final q = query.toLowerCase();
        _filtrados = _proyectos.where((p) {
          final nombre = p.nombre.toLowerCase();
          final inst = p.institucionNombre?.toLowerCase() ?? '';
          final sub = p.subsectorNombre?.toLowerCase() ?? '';
          return nombre.contains(q) || inst.contains(q) || sub.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _eliminarProyecto(Proyecto p) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Proyecto'),
        content: Text('¿Está seguro de eliminar de forma lógica la ficha de proyecto: "${p.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && p.id != null) {
      try {
        await _proyectoService.desactivarProyecto(p.id!);
        _mostrarMensaje('Proyecto eliminado correctamente.');
        _cargarProyectos();
      } catch (e) {
        _mostrarMensaje('Error al eliminar el proyecto: $e', esError: true);
      }
    }
  }

  void _mostrarMensaje(String texto, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: esError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!ServicioPermisos().tiene('preinversion.proyectos.consultar')) {
      return const AccesoDenegadoWidget(
        permisoRequerido: 'preinversion.proyectos.consultar',
        tituloSeccion: 'Bandeja de Proyectos',
      );
    }

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    if (widget.isEmbedded) {
      return _buildBody(context, isDesktop);
    }

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      drawer: const MenuLateralBip(rutaActiva: 'proyectos'),
      appBar: AppBar(
        title: const Text('Bandeja de Proyectos (BIP)'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context, isDesktop),
    );
  }

  Widget _buildBody(BuildContext context, bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isEmbedded) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bandeja de Proyectos',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF191C1E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestión y monitoreo de iniciativas de inversión pública (BIP)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Search Box Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre, institución o subsector...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                ),
                onChanged: _filtrar,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Main data list/table
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _filtrados.isEmpty
                    ? const Center(child: Text('No se encontraron fichas de proyectos registradas.'))
                    : isDesktop
                        ? _buildDesktopTable()
                        : _buildMobileCardsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable() {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 1,
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFECEEF1)),
              columns: const [
                DataColumn(label: Text('Código / Sector', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Nombre de Proyecto', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Institución Ejecutora', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Costo Total (Lps)', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Periodo', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Estado Proceso', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _filtrados.map((p) {
                return DataRow(
                  cells: [
                    DataCell(Text(p.subsectorNombre ?? 'N/A')),
                    DataCell(
                      SizedBox(
                        width: 250,
                        child: Text(
                          p.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: Text(
                          p.institucionNombre ?? 'N/A',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text('Lps ${Formatters.formatearLempiras(p.costoTotal)}')),
                    DataCell(Text(p.periodoEjecucion)),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.estadoProceso == 'APROBADO_INSTITUCION'
                              ? Colors.green.withValues(alpha: 0.05)
                              : p.estadoProceso == 'VERIFICADO_INSTITUCION'
                                  ? Colors.blue.withValues(alpha: 0.05)
                                  : Colors.orange.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: p.estadoProceso == 'APROBADO_INSTITUCION'
                                ? Colors.green
                                : p.estadoProceso == 'VERIFICADO_INSTITUCION'
                                    ? Colors.blue
                                    : Colors.orange,
                          ),
                        ),
                        child: Text(
                          p.estadoProceso == 'VERIFICADO_INSTITUCION'
                              ? 'VERIFICADO INST.'
                              : p.estadoProceso == 'APROBADO_INSTITUCION'
                                  ? 'APROBADO INST.'
                                  : p.estadoProceso,
                          style: TextStyle(
                            color: p.estadoProceso == 'APROBADO_INSTITUCION'
                                ? Colors.green.shade800
                                : p.estadoProceso == 'VERIFICADO_INSTITUCION'
                                    ? Colors.blue.shade800
                                    : Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility, color: Colors.blue),
                            tooltip: 'Visualizar Ficha',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DetalleProyectoPage(proyecto: p)),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            tooltip: 'Editar Ficha',
                            onPressed: () async {
                              if (widget.isEmbedded) {
                                widget.onNavigate?.call('registro', p);
                              } else {
                                final editado = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => FichaProyectoPage(proyectoAEditar: p)),
                                );
                                if (editado == true) _cargarProyectos();
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Eliminar Ficha',
                            onPressed: () => _eliminarProyecto(p),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCardsList() {
    return ListView.builder(
      itemCount: _filtrados.length,
      itemBuilder: (context, i) {
        final p = _filtrados[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      p.subsectorNombre ?? 'N/A',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF24389C), fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: p.estadoProceso == 'APROBADO_INSTITUCION'
                            ? Colors.green.withValues(alpha: 0.05)
                            : p.estadoProceso == 'VERIFICADO_INSTITUCION'
                                ? Colors.blue.withValues(alpha: 0.05)
                                : Colors.orange.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: p.estadoProceso == 'APROBADO_INSTITUCION'
                              ? Colors.green
                              : p.estadoProceso == 'VERIFICADO_INSTITUCION'
                                  ? Colors.blue
                                  : Colors.orange,
                        ),
                      ),
                      child: Text(
                        p.estadoProceso == 'VERIFICADO_INSTITUCION'
                            ? 'VERIFICADO INST.'
                            : p.estadoProceso == 'APROBADO_INSTITUCION'
                                ? 'APROBADO INST.'
                                : p.estadoProceso,
                        style: TextStyle(
                          color: p.estadoProceso == 'APROBADO_INSTITUCION'
                              ? Colors.green.shade800
                              : p.estadoProceso == 'VERIFICADO_INSTITUCION'
                                  ? Colors.blue.shade800
                                  : Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  p.nombre,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Institución: ${p.institucionNombre ?? "N/A"}'),
                const SizedBox(height: 4),
                Text('Costo: Lps ${Formatters.formatearLempiras(p.costoTotal)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Periodo: ${p.periodoEjecucion}'),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Ver'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DetalleProyectoPage(proyecto: p)),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 18, color: Colors.orange),
                      label: const Text('Editar', style: TextStyle(color: Colors.orange)),
                      onPressed: () async {
                        if (widget.isEmbedded) {
                          widget.onNavigate?.call('registro', p);
                        } else {
                          final editado = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => FichaProyectoPage(proyectoAEditar: p)),
                          );
                          if (editado == true) _cargarProyectos();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                      onPressed: () => _eliminarProyecto(p),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
