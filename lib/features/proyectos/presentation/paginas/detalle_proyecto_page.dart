import 'package:flutter/material.dart';
import '../../../../models/proyecto.dart';
import '../../../../core/security/servicio_permisos.dart';
import '../../services/proyecto_service.dart';
import '../../../../core/utils/formatters.dart';

class DetalleProyectoPage extends StatefulWidget {
  final Proyecto proyecto;
  const DetalleProyectoPage({super.key, required this.proyecto});

  @override
  State<DetalleProyectoPage> createState() => _DetalleProyectoPageState();
}

class _DetalleProyectoPageState extends State<DetalleProyectoPage> {
  late String _estadoProceso;
  bool _actualizando = false;
  final _proyectoService = ProyectoService();

  @override
  void initState() {
    super.initState();
    _estadoProceso = widget.proyecto.estadoProceso;
  }

  Future<void> _actualizarEstado(String nuevoEstado) async {
    if (widget.proyecto.id == null) return;
    setState(() => _actualizando = true);
    try {
      await _proyectoService.actualizarEstadoProceso(widget.proyecto.id!, nuevoEstado);
      setState(() {
        _estadoProceso = nuevoEstado;
        _actualizando = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado de la ficha BIP actualizado a: $nuevoEstado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _actualizando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar estado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text('Ficha Técnica de Proyecto (BIP)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Workflow Status and Action Buttons Bar
            _buildWorkflowBar(),
            const SizedBox(height: 16),

            // Header Card
            _buildHeaderCard(),
            const SizedBox(height: 16),

            // Responsive Layout for Main Content
            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildInfoGeneralCard(),
                            const SizedBox(height: 16),
                            _buildComponentesCard(),
                            const SizedBox(height: 16),
                            _buildEstudiosCard(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildAspectosTecnicosCard(),
                            const SizedBox(height: 16),
                            _buildEvaluacionBeneficiariosCard(),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildInfoGeneralCard(),
                      const SizedBox(height: 16),
                      _buildAspectosTecnicosCard(),
                      const SizedBox(height: 16),
                      _buildComponentesCard(),
                      const SizedBox(height: 16),
                      _buildEstudiosCard(),
                      const SizedBox(height: 16),
                      _buildEvaluacionBeneficiariosCard(),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowBar() {
    final userSp = ServicioPermisos();
    Color statusColor;
    String displayState = _estadoProceso;

    switch (_estadoProceso) {
      case 'VERIFICADO_INSTITUCION':
        statusColor = Colors.blue;
        displayState = 'VERIFICADO INST.';
        break;
      case 'APROBADO_INSTITUCION':
        statusColor = Colors.teal;
        displayState = 'APROBADO INST.';
        break;
      case 'VERIFICADO':
        statusColor = Colors.indigo;
        displayState = 'VERIFICADO DGIP';
        break;
      case 'APROBADO':
        statusColor = Colors.green;
        displayState = 'APROBADO';
        break;
      case 'RECHAZADO':
        statusColor = Colors.red;
        displayState = 'RECHAZADO';
        break;
      default:
        statusColor = Colors.orange;
        displayState = _estadoProceso;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side: current status badge
            Row(
              children: [
                const Text(
                  'Estado del Proceso: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    displayState,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            // Right side: transition actions depending on user role
            if (_actualizando)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Row(
                children: [
                  // 1. From INGRESADO -> VERIFICADO_INSTITUCION (for older projects)
                  if (_estadoProceso == 'INGRESADO' &&
                      (userSp.esFormuladorODirectorUpeg || userSp.esAdministradorGlobal)) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text('Enviar a Verificación'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _actualizarEstado('VERIFICADO_INSTITUCION'),
                    ),
                  ],

                  // 2. From VERIFICADO_INSTITUCION -> APROBADO_INSTITUCION (UPEG Approver role)
                  if (_estadoProceso == 'VERIFICADO_INSTITUCION' &&
                      (userSp.esAprobadorUpeg || userSp.esAdministradorGlobal)) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.verified_user, size: 16),
                      label: const Text('Aprobar Institución'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _actualizarEstado('APROBADO_INSTITUCION'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Rechazar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () => _actualizarEstado('RECHAZADO'),
                    ),
                  ],

                  // 3. From APROBADO_INSTITUCION -> VERIFICADO (DGIP Analista/Coordinador)
                  if (_estadoProceso == 'APROBADO_INSTITUCION' &&
                      (userSp.tiene('preinversion.proyectos.verificar') || userSp.esAdministradorGlobal)) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Verificar Ficha (DGIP)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _actualizarEstado('VERIFICADO'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Rechazar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () => _actualizarEstado('RECHAZADO'),
                    ),
                  ],

                  // 4. From VERIFICADO -> APROBADO (DGIP Director)
                  if (_estadoProceso == 'VERIFICADO' &&
                      (userSp.tiene('preinversion.proyectos.aprobar') || userSp.esAdministradorGlobal)) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.stars, size: 16),
                      label: const Text('Aprobar Ficha Global'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _actualizarEstado('APROBADO'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Rechazar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () => _actualizarEstado('RECHAZADO'),
                    ),
                  ],

                  // 5. Reset process if rejected
                  if (_estadoProceso == 'RECHAZADO' &&
                      (userSp.esAdministradorGlobal ||
                          userSp.esFormuladorODirectorUpeg ||
                          userSp.tiene('preinversion.proyectos.verificar'))) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.settings_backup_restore, size: 16),
                      label: const Text('Reiniciar Proceso'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _actualizarEstado('VERIFICADO_INSTITUCION'),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      color: Colors.indigo,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance, color: Colors.white, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.proyecto.institucionNombre ?? 'Institución Desconocida',
                    style: TextStyle(color: Colors.indigo[100], fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.proyecto.periodoEjecucion,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.proyecto.nombre,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Subsector: ${widget.proyecto.subsectorNombre ?? "N/A"}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGeneralCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('1. Identificación e Información General'),
            _buildDetailRow('Objetivo General', widget.proyecto.objetivoGeneral, isMultiline: true),
            _buildDetailRow('Problema / Necesidad', widget.proyecto.descripcionProblema, isMultiline: true),
            const Divider(),
            Row(
              children: [
                Expanded(child: _buildDetailRow('Departamento', widget.proyecto.departamentoNombre ?? 'N/A')),
                Expanded(child: _buildDetailRow('Municipio', widget.proyecto.municipioNombre ?? 'N/A')),
              ],
            ),
            _buildDetailRow('Localización UTM', widget.proyecto.coordenadasUtm ?? 'No proporcionada'),
          ],
        ),
      ),
    );
  }

  Widget _buildAspectosTecnicosCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('2. Aspectos Técnicos e Inversión'),
            _buildDetailRow('Entregable Principal', widget.proyecto.entregablePrincipal ?? 'N/A'),
            _buildDetailRow('Finalidad de Intervención', widget.proyecto.finalidadIntervencion ?? 'N/A'),
            const Divider(),
            Row(
              children: [
                Expanded(child: _buildDetailRow('% Inv. Real', '${widget.proyecto.porcentajeInversionReal ?? 0}%')),
                Expanded(child: _buildDetailRow('% Des. Humano', '${widget.proyecto.porcentajeDesarrolloHumano ?? 0}%')),
              ],
            ),
            const Divider(),
            _buildDetailRow('Costo Total Ficha', 'Lps ${Formatters.formatearLempiras(widget.proyecto.costoTotal)}', isBold: true),
            _buildDetailRow('Costo Anual Operación y Manto.', widget.proyecto.costoAnualOperacion != null ? 'Lps ${Formatters.formatearLempiras(widget.proyecto.costoAnualOperacion!)}' : 'Lps 0.00'),
            _buildDetailRow('Entidad Responsable de O&M', widget.proyecto.entidadResponsableOperacion ?? 'N/A'),
            const Divider(),
            _buildDetailRow('Nivel Preinversión', widget.proyecto.nivelPreinversionNombre ?? 'N/A'),
            _buildDetailRow('Fuente de Financiamiento', widget.proyecto.posibleFuenteFinanciamientoNombre ?? 'N/A'),
            _buildDetailRow('Aspectos Técnicos Generales', widget.proyecto.aspectosTecnicos ?? 'No descritos', isMultiline: true),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('3. Componentes del Proyecto'),
            if (widget.proyecto.componentes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('No hay componentes registrados.', style: TextStyle(color: Colors.grey))),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.proyecto.componentes.length,
                itemBuilder: (context, i) {
                  final c = widget.proyecto.componentes[i];
                  final pct = (c.costo / (widget.proyecto.costoTotal > 0 ? widget.proyecto.costoTotal : 1)) * 100;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Representa el ${pct.toStringAsFixed(1)}% del costo total'),
                    trailing: Text(
                      'Lps ${Formatters.formatearLempiras(c.costo)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstudiosCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('4. Historial de Estudios y Diseños'),
            if (widget.proyecto.estudios.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('No se registran estudios asociados.', style: TextStyle(color: Colors.grey))),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.proyecto.estudios.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, i) {
                  final e = widget.proyecto.estudios[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.nombreEstudio, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('Elaboración: ${e.fechaElaboracion ?? "N/A"} | Nivel: ${e.nivelEstudio ?? "N/A"}'),
                        Text('Custodio: ${e.custodioEstudios ?? "N/A"}'),
                        if (e.observaciones != null) ...[
                          const SizedBox(height: 4),
                          Text('Obs: ${e.observaciones}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ]
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluacionBeneficiariosCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('5. Evaluación y Beneficiarios'),
            const Text('EVALUACIÓN SOCIOECONÓMICA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo)),
            const SizedBox(height: 6),
            _buildDetailRow('Costo Anual Equivalente (CAE)', widget.proyecto.evalCostoAnualEquivalente != null ? 'Lps ${Formatters.formatearLempiras(widget.proyecto.evalCostoAnualEquivalente!)}' : 'N/A'),
            _buildDetailRow('Relación Costo - Eficiencia', widget.proyecto.evalRelacionCostoEficiencia?.toStringAsFixed(2) ?? 'N/A'),
            _buildDetailRow('Valor Presente Neto (VPN)', widget.proyecto.evalVpn != null ? 'Lps ${Formatters.formatearLempiras(widget.proyecto.evalVpn!)}' : 'N/A'),
            _buildDetailRow('Relación Beneficio / Costo (B/C)', widget.proyecto.evalBeneficioCosto?.toStringAsFixed(2) ?? 'N/A'),
            _buildDetailRow('Tasa Interna de Retorno (TIR)', '${widget.proyecto.evalTir ?? "N/A"}%'),
            const Divider(),
            const Text('BENEFICIARIOS Y EMPLEO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _buildDetailRow('Directos', widget.proyecto.beneficiariosDirectos?.toString() ?? '0')),
                Expanded(child: _buildDetailRow('Indirectos', widget.proyecto.beneficiariosIndirectos?.toString() ?? '0')),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildDetailRow('Empleos Dir.', widget.proyecto.empleosDirectos?.toString() ?? '0')),
                Expanded(child: _buildDetailRow('Empleos Indir.', widget.proyecto.empleosIndirectos?.toString() ?? '0')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMultiline = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isMultiline) const SizedBox(height: 6),
        ],
      ),
    );
  }
}
