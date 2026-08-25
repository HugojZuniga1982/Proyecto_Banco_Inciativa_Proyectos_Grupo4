import 'package:flutter/material.dart';
import 'servicio_permisos.dart';

class WidgetAutorizado extends StatelessWidget {
  final String? permiso;
  final List<String>? permisos;
  final bool requiereTodos;
  final Widget child;
  final Widget fallback;

  const WidgetAutorizado({
    super.key,
    this.permiso,
    this.permisos,
    this.requiereTodos = false,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    final servicio = ServicioPermisos();

    if (permiso != null) {
      if (!servicio.tiene(permiso!)) {
        return fallback;
      }
    }

    if (permisos != null && permisos!.isNotEmpty) {
      final cumple = requiereTodos
          ? servicio.tieneTodos(permisos!)
          : servicio.tieneAlguno(permisos!);
      if (!cumple) {
        return fallback;
      }
    }

    return child;
  }
}
