class Formatters {
  static String formatearLempiras(double valor) {
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return valor.toStringAsFixed(2).replaceAllMapped(reg, (Match match) => '${match[1]},');
  }
}
