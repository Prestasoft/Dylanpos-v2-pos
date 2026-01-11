import 'package:flutter/foundation.dart';
import 'base_repository.dart';
import '../supabase_auth_service.dart';

/// Modelo de Reservación para Supabase
class ReservationModel {
  final String? id;
  final String branchId;
  final String? customerId;
  final String? serviceId;
  final DateTime date;
  final String? time;
  final String status;
  final String? notes;
  final double total;
  final double deposit;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Datos relacionados (para joins)
  final String? customerName;
  final String? serviceName;

  ReservationModel({
    this.id,
    required this.branchId,
    this.customerId,
    this.serviceId,
    required this.date,
    this.time,
    this.status = 'pending',
    this.notes,
    this.total = 0,
    this.deposit = 0,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.customerName,
    this.serviceName,
  });

  factory ReservationModel.fromMap(Map<String, dynamic> map) {
    return ReservationModel(
      id: map['id']?.toString(),
      branchId: map['branch_id'] ?? '',
      customerId: map['customer_id']?.toString(),
      serviceId: map['service_id']?.toString(),
      date: map['date'] != null
          ? DateTime.parse(map['date'])
          : DateTime.now(),
      time: map['time'],
      status: map['status'] ?? 'pending',
      notes: map['notes'],
      total: (map['total'] ?? 0).toDouble(),
      deposit: (map['deposit'] ?? 0).toDouble(),
      createdBy: map['created_by']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      // Datos de joins
      customerName: map['customers']?['name'],
      serviceName: map['services']?['name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'branch_id': branchId,
      'customer_id': customerId,
      'service_id': serviceId,
      'date': date.toIso8601String().split('T')[0], // Solo fecha
      'time': time,
      'status': status,
      'notes': notes,
      'total': total,
      'deposit': deposit,
      'created_by': createdBy,
    };
  }

  ReservationModel copyWith({
    String? id,
    String? branchId,
    String? customerId,
    String? serviceId,
    DateTime? date,
    String? time,
    String? status,
    String? notes,
    double? total,
    double? deposit,
    String? customerName,
    String? serviceName,
  }) {
    return ReservationModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      customerId: customerId ?? this.customerId,
      serviceId: serviceId ?? this.serviceId,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      total: total ?? this.total,
      deposit: deposit ?? this.deposit,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      customerName: customerName ?? this.customerName,
      serviceName: serviceName ?? this.serviceName,
    );
  }

  /// Balance pendiente
  double get balance => total - deposit;

  /// ¿Está confirmada?
  bool get isConfirmed => status == 'confirmed';

  /// ¿Está completada?
  bool get isCompleted => status == 'completed';

  /// ¿Está cancelada?
  bool get isCancelled => status == 'cancelled';
}

/// Estados posibles de una reservación
class ReservationStatus {
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String noShow = 'no_show';

  static List<String> get all => [
    pending,
    confirmed,
    inProgress,
    completed,
    cancelled,
    noShow,
  ];
}

/// Repositorio de Reservaciones
class ReservationRepository extends BaseRepository<ReservationModel> {
  @override
  final String tableName = 'reservations';

  @override
  ReservationModel fromMap(Map<String, dynamic> map) => ReservationModel.fromMap(map);

  @override
  Map<String, dynamic> toMap(ReservationModel model) => model.toMap();

  /// Obtener reservaciones con datos de cliente y servicio
  Future<List<ReservationModel>> getAllWithRelations() async {
    try {
      final branchId = currentBranchId;
      if (branchId == null) return [];

      final response = await client
          .from(tableName)
          .select('''
            *,
            customers (name),
            services (name)
          ''')
          .eq('branch_id', branchId)
          .order('date', ascending: true)
          .order('time', ascending: true);

      return (response as List)
          .map((item) => ReservationModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      debugPrint('❌ Error al obtener reservaciones: $e');
      return [];
    }
  }

  /// Crear reservación
  Future<ReservationModel?> createReservation(ReservationModel reservation) async {
    try {
      final data = reservation.toMap();
      data['branch_id'] = currentBranchId;
      data['created_by'] = supabaseAuth.currentUserId;
      data['created_at'] = DateTime.now().toIso8601String();

      final response = await client
          .from(tableName)
          .insert(data)
          .select()
          .single();

      debugPrint('✅ Reservación creada');
      return ReservationModel.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      debugPrint('❌ Error al crear reservación: $e');
      return null;
    }
  }

  /// Obtener reservaciones por fecha
  Future<List<ReservationModel>> getByDate(DateTime date) async {
    try {
      final branchId = currentBranchId;
      if (branchId == null) return [];

      final dateStr = date.toIso8601String().split('T')[0];

      final response = await client
          .from(tableName)
          .select('''
            *,
            customers (name),
            services (name)
          ''')
          .eq('branch_id', branchId)
          .eq('date', dateStr)
          .order('time', ascending: true);

      return (response as List)
          .map((item) => ReservationModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtener reservaciones por rango de fechas
  Future<List<ReservationModel>> getByDateRange(DateTime start, DateTime end) async {
    try {
      final branchId = currentBranchId;
      if (branchId == null) return [];

      final startStr = start.toIso8601String().split('T')[0];
      final endStr = end.toIso8601String().split('T')[0];

      final response = await client
          .from(tableName)
          .select('''
            *,
            customers (name),
            services (name)
          ''')
          .eq('branch_id', branchId)
          .gte('date', startStr)
          .lte('date', endStr)
          .order('date', ascending: true)
          .order('time', ascending: true);

      return (response as List)
          .map((item) => ReservationModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtener reservaciones por estado
  Future<List<ReservationModel>> getByStatus(String status) async {
    try {
      final branchId = currentBranchId;
      if (branchId == null) return [];

      final response = await client
          .from(tableName)
          .select('''
            *,
            customers (name),
            services (name)
          ''')
          .eq('branch_id', branchId)
          .eq('status', status)
          .order('date', ascending: true);

      return (response as List)
          .map((item) => ReservationModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtener reservaciones por cliente
  Future<List<ReservationModel>> getByCustomer(String customerId) async {
    try {
      final response = await client
          .from(tableName)
          .select('''
            *,
            customers (name),
            services (name)
          ''')
          .eq('customer_id', customerId)
          .order('date', ascending: false);

      return (response as List)
          .map((item) => ReservationModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Actualizar estado de reservación
  Future<bool> updateStatus(String reservationId, String newStatus) async {
    return update(reservationId, {'status': newStatus});
  }

  /// Actualizar depósito
  Future<bool> updateDeposit(String reservationId, double newDeposit) async {
    return update(reservationId, {'deposit': newDeposit});
  }

  /// Cancelar reservación
  Future<bool> cancelReservation(String reservationId) async {
    return updateStatus(reservationId, ReservationStatus.cancelled);
  }

  /// Confirmar reservación
  Future<bool> confirmReservation(String reservationId) async {
    return updateStatus(reservationId, ReservationStatus.confirmed);
  }

  /// Completar reservación
  Future<bool> completeReservation(String reservationId) async {
    return updateStatus(reservationId, ReservationStatus.completed);
  }

  /// Obtener reservaciones pendientes de hoy
  Future<List<ReservationModel>> getTodaysPending() async {
    final today = DateTime.now();
    final reservations = await getByDate(today);
    return reservations.where((r) =>
        r.status == ReservationStatus.pending ||
        r.status == ReservationStatus.confirmed
    ).toList();
  }

  /// Verificar disponibilidad de horario
  Future<bool> isTimeSlotAvailable(DateTime date, String time) async {
    try {
      final branchId = currentBranchId;
      if (branchId == null) return false;

      final dateStr = date.toIso8601String().split('T')[0];

      final response = await client
          .from(tableName)
          .select('id')
          .eq('branch_id', branchId)
          .eq('date', dateStr)
          .eq('time', time)
          .neq('status', ReservationStatus.cancelled);

      return (response as List).isEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Obtener horarios ocupados para una fecha
  Future<List<String>> getOccupiedTimeSlots(DateTime date) async {
    try {
      final reservations = await getByDate(date);
      return reservations
          .where((r) => !r.isCancelled && r.time != null)
          .map((r) => r.time!)
          .toList();
    } catch (e) {
      return [];
    }
  }
}

/// Instancia global del repositorio
final reservationRepository = ReservationRepository();
