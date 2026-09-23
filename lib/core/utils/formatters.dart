import 'package:flutter/material.dart';

class Formatters {
  static String formatearLempiras(double valor) {
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return valor.toStringAsFixed(2).replaceAllMapped(reg, (Match match) => '${match[1]},');
  }

  static String formatearEstadoProceso(String? estado) {
    if (estado == null || estado.isEmpty) return 'SIN ESTADO';
    switch (estado.toUpperCase()) {
      case 'VERIFICADO':
      case 'VERIFICADO_DGIP':
        return 'VERIFICADO DGIP';
      case 'APROBADO':
      case 'APROBADO_DGIP':
        return 'APROBADO DGIP';
      case 'VERIFICADO_INSTITUCION':
        return 'VERIFICADO INST.';
      case 'APROBADO_INSTITUCION':
        return 'APROBADO INST.';
      case 'INGRESADO':
        return 'INGRESADO';
      case 'RECHAZADO':
        return 'RECHAZADO';
      default:
        return estado.replaceAll('_', ' ');
    }
  }

  static Color colorEstadoProceso(String? estado) {
    if (estado == null) return Colors.grey;
    switch (estado.toUpperCase()) {
      case 'APROBADO':
      case 'APROBADO_DGIP':
        return Colors.green;
      case 'VERIFICADO':
      case 'VERIFICADO_DGIP':
        return Colors.indigo;
      case 'APROBADO_INSTITUCION':
        return Colors.teal;
      case 'VERIFICADO_INSTITUCION':
        return Colors.blue;
      case 'RECHAZADO':
        return Colors.red;
      case 'INGRESADO':
      default:
        return Colors.orange;
    }
  }
}
