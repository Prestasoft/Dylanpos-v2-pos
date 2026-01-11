import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/ncf_model.dart';
import '../Repository/dgii_repo.dart';

/// Provider para tipos de NCF
final ncfTypesProvider = FutureProvider.autoDispose<List<NcfTypeModel>>((ref) async {
  return dgiiRepository.getNcfTypes();
});

/// Provider para secuencias NCF de la sucursal
final ncfSequencesProvider = FutureProvider.autoDispose<List<NcfSequenceModel>>((ref) async {
  return dgiiRepository.getNcfSequences();
});

/// Provider para el tipo de NCF seleccionado en filtros
final selectedNcfTypeProvider = StateProvider<String>((ref) => 'all');

/// Provider para rango de fechas del reporte
final reportDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

/// Clase para rango de fechas
class DateTimeRange {
  final DateTime start;
  final DateTime end;

  DateTimeRange({required this.start, required this.end});
}

/// Provider para resumen de ventas por NCF
final ncfSalesSummaryProvider = FutureProvider.autoDispose<List<NcfSalesSummaryModel>>((ref) async {
  final dateRange = ref.watch(reportDateRangeProvider);
  return dgiiRepository.getSummaryByNcf(
    startDate: dateRange?.start.toIso8601String(),
    endDate: dateRange?.end.toIso8601String(),
  );
});

/// Provider para ventas filtradas por NCF
final ncfSalesProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  return dgiiRepository.getSalesByNcf(
    ncfType: params['ncfType'] as String?,
    startDate: params['startDate'] as String?,
    endDate: params['endDate'] as String?,
    limit: params['limit'] as int? ?? 100,
    offset: params['offset'] as int? ?? 0,
  );
});

/// Provider para reporte 607
final report607Provider = FutureProvider.autoDispose.family<Map<String, dynamic>, Map<String, int>>((ref, params) async {
  final year = params['year'] ?? DateTime.now().year;
  final month = params['month'] ?? DateTime.now().month;
  return dgiiRepository.getReport607(year, month);
});

/// Notifier para gestión de NCF en facturación
class NcfSelectionNotifier extends StateNotifier<NcfSelectionState> {
  NcfSelectionNotifier() : super(NcfSelectionState());

  void selectNcfType(NcfTypeModel? type) {
    state = state.copyWith(selectedType: type);
  }

  void setCustomerRnc(String? rnc) {
    state = state.copyWith(customerRnc: rnc);
  }

  void setGeneratedNcf(String? ncf) {
    state = state.copyWith(generatedNcf: ncf);
  }

  void reset() {
    state = NcfSelectionState();
  }

  /// Genera un NCF si es necesario
  Future<String?> generateNcfIfNeeded() async {
    if (state.selectedType == null || state.selectedType!.code == 'SIN') {
      return null;
    }

    // Validar RNC para tipos que lo requieren
    if (state.selectedType!.requiresRnc && (state.customerRnc == null || state.customerRnc!.isEmpty)) {
      throw Exception('Se requiere RNC/Cédula para este tipo de comprobante');
    }

    final ncf = await dgiiRepository.generateNcf(state.selectedType!.code);
    if (ncf != null) {
      state = state.copyWith(generatedNcf: ncf);
    }
    return ncf;
  }

  /// Calcula el ITBIS basado en el subtotal
  double calculateItbis(double subtotal) {
    if (state.selectedType == null || !state.selectedType!.appliesItbis) {
      return 0.0;
    }
    return subtotal * (state.selectedType!.itbisRate / 100);
  }
}

/// Estado para selección de NCF en facturación
class NcfSelectionState {
  final NcfTypeModel? selectedType;
  final String? customerRnc;
  final String? generatedNcf;

  NcfSelectionState({
    this.selectedType,
    this.customerRnc,
    this.generatedNcf,
  });

  NcfSelectionState copyWith({
    NcfTypeModel? selectedType,
    String? customerRnc,
    String? generatedNcf,
  }) {
    return NcfSelectionState(
      selectedType: selectedType ?? this.selectedType,
      customerRnc: customerRnc ?? this.customerRnc,
      generatedNcf: generatedNcf ?? this.generatedNcf,
    );
  }

  /// Verifica si se puede proceder con la facturación
  bool get canProceed {
    if (selectedType == null) return true; // Sin tipo = SIN
    if (selectedType!.code == 'SIN') return true;
    if (selectedType!.requiresRnc) {
      return customerRnc != null && customerRnc!.isNotEmpty;
    }
    return true;
  }

  /// Mensaje de error si no se puede proceder
  String? get errorMessage {
    if (selectedType != null && selectedType!.requiresRnc) {
      if (customerRnc == null || customerRnc!.isEmpty) {
        return 'Se requiere RNC/Cédula para ${selectedType!.name}';
      }
    }
    return null;
  }
}

/// Provider para el notifier de selección NCF
final ncfSelectionProvider = StateNotifierProvider<NcfSelectionNotifier, NcfSelectionState>((ref) {
  return NcfSelectionNotifier();
});

/// Provider para mes/año seleccionado en reportes
final reportMonthProvider = StateProvider<int>((ref) => DateTime.now().month);
final reportYearProvider = StateProvider<int>((ref) => DateTime.now().year);
