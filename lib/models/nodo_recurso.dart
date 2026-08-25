enum EstadoSeleccion { marcado, desmarcado, indeterminado }

class ItemPermiso {
  final String id;
  final String codigo;
  final String nombre;
  bool estaOtorgado;

  ItemPermiso({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.estaOtorgado,
  });
}

class NodoRecurso {
  final String id;
  final String? recursoPadreId;
  final String codigo;
  final String nombre;
  final String tipoRecurso;
  final List<ItemPermiso> permisos;
  final List<NodoRecurso> hijos;
  bool estaExpandido;

  NodoRecurso({
    required this.id,
    this.recursoPadreId,
    required this.codigo,
    required this.nombre,
    required this.tipoRecurso,
    required this.permisos,
    List<NodoRecurso>? hijos,
    this.estaExpandido = true,
  }) : hijos = hijos ?? [];

  EstadoSeleccion get estadoSeleccion {
    final todosLosPermisos = _obtenerTodosPermisosHojas();
    if (todosLosPermisos.isEmpty) return EstadoSeleccion.desmarcado;

    final totalOtorgados = todosLosPermisos.where((p) => p.estaOtorgado).length;
    if (totalOtorgados == todosLosPermisos.length) return EstadoSeleccion.marcado;
    if (totalOtorgados > 0) return EstadoSeleccion.indeterminado;
    return EstadoSeleccion.desmarcado;
  }

  List<ItemPermiso> _obtenerTodosPermisosHojas() {
    final lista = <ItemPermiso>[...permisos];
    for (final hijo in hijos) {
      lista.addAll(hijo._obtenerTodosPermisosHojas());
    }
    return lista;
  }

  void seleccionarEnCascada(bool valor) {
    for (final p in permisos) {
      p.estaOtorgado = valor;
    }
    for (final hijo in hijos) {
      hijo.seleccionarEnCascada(valor);
    }
  }
}
