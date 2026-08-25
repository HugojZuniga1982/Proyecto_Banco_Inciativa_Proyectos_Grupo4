import 'package:flutter/material.dart';
import 'package:proyecto_programacion_movil_grupo_4/core/security/security.dart';

class PaginaPruebaPermisos extends StatelessWidget {
  const PaginaPruebaPermisos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laboratorio de Pruebas: WidgetAutorizado'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar Permisos',
            onPressed: () async {
              await ServicioPermisos().cargarPermisosUsuario();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Permisos recargados desde Supabase.')),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pruebas de Visibilidad y Permisos Reactivos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // CASO 1: Permiso que el usuario SÍ tiene (seguridad.roles.crear)
            const Text('1. Permiso concedido (Debe mostrar el botón):', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            WidgetAutorizado(
              permiso: 'seguridad.roles.crear',
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Crear Nuevo Rol (Visible)'),
                onPressed: () {},
              ),
            ),
            const Divider(height: 32),

            // CASO 2: Permiso que NO tiene con Fallback activo (reportes.ver)
            const Text('2. Permiso denegado con mensaje alternativo:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            WidgetAutorizado(
              permiso: 'reportes.ver',
              fallback: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('No tienes permisos para ver reportes ejecutivos.', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Descargar Reporte General'),
              ),
            ),
            const Divider(height: 32),

            // CASO 3: Múltiples permisos (al menos uno debe coincidir)
            const Text('3. Múltiples permisos (Requiere al menos uno):', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            WidgetAutorizado(
              permisos: const ['seguridad.roles.modificar', 'seguridad.roles.eliminar'],
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white),
                    child: const Text('Modificar Rol'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    child: const Text('Eliminar Rol'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
