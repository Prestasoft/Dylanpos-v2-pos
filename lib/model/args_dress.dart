// Opción 1: Clase inmutable manual
class DressFilterParams {
  final String search;
  final String status;

  const DressFilterParams({
    this.search = '',
    this.status = 'Todos',
  });

  // Importante: Override de == y hashCode para que Riverpod
  // detecte correctamente cuando los parámetros cambian
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DressFilterParams &&
          runtimeType == other.runtimeType &&
          search == other.search &&
          status == other.status;

  @override
  int get hashCode => search.hashCode ^ status.hashCode;

  @override
  String toString() => 'DressFilterParams(search: $search, status: $status)';

  // Método copyWith para crear nuevas instancias con cambios
  DressFilterParams copyWith({
    String? search,
    String? status,
  }) {
    return DressFilterParams(
      search: search ?? this.search,
      status: status ?? this.status,
    );
  }
}
