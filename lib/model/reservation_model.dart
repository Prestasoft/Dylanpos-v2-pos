import 'dart:convert';

class ReservationModel {
  final String id;
  final String serviceId;
  final String clientId;
  final String dressId;
  final String branchId;
  final String reservationDate;
  final String reservationTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool estadoFactura;
  final String? estado;
  final String? nota;
  final String? place;
  final List<Map<String, String>> multipleDress;
  final String reservation_associated;
  final String package_price;
  final String sellerName;
  final String? fiestaDate;
  final String? fiestaTime;
  final bool isFiestaDate;
  // Campos adicionales para mostrar nombres
  final String? customerName;
  final String? customerPhone;
  final String? serviceName;
  final String? vestido;
  final List<Map<String, dynamic>> dressesData;
  final int rescheduleCount;
  final String? sessionType;

  ReservationAssignments get assignments {
    if (nota == null || !nota!.contains('|||')) {
      return ReservationAssignments.empty();
    }
    try {
      final parts = nota!.split('|||');
      if (parts.length < 2) return ReservationAssignments.empty();
      final jsonStr = parts[1].trim();
      if (jsonStr.isEmpty || !jsonStr.startsWith('{')) return ReservationAssignments.empty();
      final map = jsonDecode(jsonStr);
      return ReservationAssignments.fromJson(map);
    } catch (_) {
      return ReservationAssignments.empty();
    }
  }

  String get cleanNota => cleanNotaText(nota);

  /// Limpia cualquier texto de nota eliminando la parte JSON de asignaciones.
  /// Uso: ReservationModel.cleanNotaText(notaString)
  static String cleanNotaText(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    if (raw.contains('|||')) {
      final clean = raw.split('|||')[0].trim();
      return clean;
    }
    // Si no tiene ||| pero parece ser JSON puro, retornar vacío
    final trimmed = raw.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) return '';
    return trimmed;
  }

  ReservationModel({
    String? id,
    required this.serviceId,
    required this.clientId,
    required this.dressId,
    required this.branchId,
    required this.reservationDate,
    required this.reservationTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.multipleDress,
    required this.estadoFactura,
    this.estado = "pendiente",
    required this.reservation_associated,
    required this.package_price,
    this.nota = '',
    this.place = '',
    this.sellerName = '',
    this.fiestaDate,
    this.fiestaTime,
    this.isFiestaDate = false,
    this.customerName,
    this.customerPhone,
    this.serviceName,
    this.vestido,
    this.rescheduleCount = 0,
    this.sessionType,
    List<Map<String, dynamic>>? dressesData,
  })  : id = id ?? '',
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        dressesData = dressesData ?? [];

  factory ReservationModel.fromMap(Map<String, dynamic> map, String id) {
    // Procesar dress_ids de forma segura
    List<Map<String, String>> parsedDressIds = [];
    final dressIdsRaw = map['dress_ids'];
    if (dressIdsRaw != null && dressIdsRaw is List) {
      for (final item in dressIdsRaw) {
        if (item is Map) {
          parsedDressIds.add({
            'dress_id': item['dress_id']?.toString() ?? '',
            'branch_id': item['branch_id']?.toString() ?? '',
          });
        } else if (item is String) {
          // Si es solo un string (dress_id), usarlo directamente
          parsedDressIds.add({
            'dress_id': item,
            'branch_id': '',
          });
        }
      }
    }

    // Parsear dresses_data si existe
    List<Map<String, dynamic>> parsedDressesData = [];
    final dressesDataRaw = map['dresses_data'];
    if (dressesDataRaw != null && dressesDataRaw is List) {
      for (final item in dressesDataRaw) {
        if (item is Map) {
          parsedDressesData.add(Map<String, dynamic>.from(item));
        }
      }
    }

    return ReservationModel(
      id: id,
      serviceId: map['service_id']?.toString() ?? '',
      clientId: map['client_id']?.toString() ?? '',
      dressId: map['dress_id']?.toString() ?? '',
      branchId: map['branch_id']?.toString() ?? '',
      reservationDate: map['reservation_date']?.toString() ?? '',
      reservationTime: map['reservation_time']?.toString() ?? '',
      createdAt: _parseTimestamp(map['created_at']),
      updatedAt: _parseTimestamp(map['updated_at']),
      estadoFactura: map['estado_factura'] == true || map['estado_factura'] == 'true',
      estado: map['estado']?.toString(),
      nota: map['nota']?.toString() ?? '',
      place: map['place']?.toString() ?? '',
      multipleDress: parsedDressIds,
      reservation_associated: map['reservation_associated']?.toString() ?? '',
      package_price: map['package_price']?.toString() ?? '',
      sellerName: map['seller_name']?.toString() ?? '',
      fiestaDate: map['fiesta_date']?.toString() ?? '',
      fiestaTime: map['fiesta_time']?.toString() ?? '',
      customerName: map['customer_name']?.toString(),
      customerPhone: map['customer_phone']?.toString(),
      serviceName: map['service_name']?.toString(),
      vestido: map['vestido']?.toString(),
      dressesData: parsedDressesData,
      rescheduleCount: map['reschedule_count'] is int 
          ? map['reschedule_count'] 
          : int.tryParse(map['reschedule_count']?.toString() ?? '0') ?? 0,
      sessionType: map['session_type']?.toString(),
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null || timestamp == '') {
      return DateTime.now();
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      } catch (_) {
        try {
          return DateTime.parse(timestamp);
        } catch (_) {
          return DateTime.now();
        }
      }
    }
    return DateTime.now();
  }

  ReservationModel copyWith({
    String? reservationDate,
    String? reservationTime,
    bool? isFiestaDate,
    String? fiestaDate,
    String? fiestaTime,
    int? rescheduleCount,
    String? sessionType,
  }) {
    return ReservationModel(
      id: id,
      serviceId: serviceId,
      clientId: clientId,
      dressId: dressId,
      branchId: branchId,
      reservationDate: reservationDate ?? this.reservationDate,
      reservationTime: reservationTime ?? this.reservationTime,
      createdAt: createdAt,
      updatedAt: updatedAt,
      multipleDress: multipleDress,
      estadoFactura: estadoFactura,
      estado: estado,
      reservation_associated: reservation_associated,
      package_price: package_price,
      nota: nota,
      place: place,
      sellerName: sellerName,
      fiestaDate: fiestaDate ?? this.fiestaDate,
      fiestaTime: fiestaTime ?? this.fiestaTime,
      isFiestaDate: isFiestaDate ?? this.isFiestaDate,
      rescheduleCount: rescheduleCount ?? this.rescheduleCount,
      sessionType: sessionType ?? this.sessionType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'service_id': serviceId,
      'client_id': clientId,
      'dress_id': dressId,
      'branch_id': branchId,
      'reservation_date': reservationDate,
      'reservation_time': reservationTime,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'estado_factura': estadoFactura,
      'estado': estado,
      'nota': nota,
      'place': place,
      'dress_ids': multipleDress.map((dress) {
        return {
          'dress_id': dress['dress_id'],
          'branch_id': dress['branch_id'],
        };
      }).toList(),
      'reservation_associated': reservation_associated,
      'package_price': package_price,
      'seller_name': sellerName,
      'fiesta_date': fiestaDate,
      'fiesta_time': fiestaTime,
      'reschedule_count': rescheduleCount,
    };
  }
}

class ReservationAssignments {
  final String? fotografoId;
  final List<String> fotografoIdsPre; // Fotógrafos para Pre-Quince
  final List<String> fotografoIdsFiesta; // Fotógrafos para Fiesta
  final String? maquillistaId; // Primer maquillista (compatibilidad)
  final List<String> maquillistaIds; // Múltiples maquillistas (plan simple)
  final List<String> maquillistaIdsPre; // Maquillistas para Pre-Quince
  final List<String> maquillistaIdsFiesta; // Maquillistas para Fiesta
  final String? filmmakerId; // Filmmaker/Video
  final List<String> filmmakerIdsPre; // Filmmaker para Pre-Quince
  final List<String> filmmakerIdsFiesta; // Filmmaker para Fiesta
  final String? editorId;
  final String? bookedById;
  final String? contactChannel;
  final String? socialNetwork;
  final Map<String, bool> declined;

  ReservationAssignments({
    this.fotografoId,
    List<String>? fotografoIdsPre,
    List<String>? fotografoIdsFiesta,
    this.maquillistaId,
    List<String>? maquillistaIds,
    List<String>? maquillistaIdsPre,
    List<String>? maquillistaIdsFiesta,
    this.filmmakerId,
    List<String>? filmmakerIdsPre,
    List<String>? filmmakerIdsFiesta,
    this.editorId,
    this.bookedById,
    this.contactChannel,
    this.socialNetwork,
    Map<String, bool>? declined,
  }) : fotografoIdsPre = fotografoIdsPre ?? [],
       fotografoIdsFiesta = fotografoIdsFiesta ?? [],
       filmmakerIdsPre = filmmakerIdsPre ?? [],
       filmmakerIdsFiesta = filmmakerIdsFiesta ?? [],
       maquillistaIds = maquillistaIds ?? [],
       maquillistaIdsPre = maquillistaIdsPre ?? [],
       maquillistaIdsFiesta = maquillistaIdsFiesta ?? [],
       declined = declined ?? {};

  /// True si el slot fue marcado como "No aplica"
  bool isDeclined(String slot) => declined[slot] == true;

  factory ReservationAssignments.empty() {
    return ReservationAssignments();
  }

  factory ReservationAssignments.fromJson(Map<String, dynamic> json) {
    final mRaw = json['m'];
    String? firstMaq;
    List<String> maqIds = [];
    if (json['mIds'] is List) {
      maqIds = (json['mIds'] as List).map((e) => e.toString()).toList();
      firstMaq = maqIds.isNotEmpty ? maqIds.first : null;
    } else if (mRaw is String) {
      firstMaq = mRaw;
      maqIds = [mRaw];
    }

    List<String> parseMaqList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return [];
    }

    return ReservationAssignments(
      fotografoId: json['f'],
      fotografoIdsPre: parseMaqList(json['fPre']),
      fotografoIdsFiesta: parseMaqList(json['fFiesta']),
      maquillistaId: firstMaq,
      maquillistaIds: maqIds,
      maquillistaIdsPre: parseMaqList(json['mPre']),
      maquillistaIdsFiesta: parseMaqList(json['mFiesta']),
      filmmakerId: json['fm']?.toString(),
      filmmakerIdsPre: parseMaqList(json['fmPre']),
      filmmakerIdsFiesta: parseMaqList(json['fmFiesta']),
      editorId: json['e'],
      bookedById: json['b'],
      contactChannel: json['c'],
      socialNetwork: json['s'],
      declined: json['declined'] is Map
          ? (json['declined'] as Map).map((k, v) => MapEntry(k.toString(), v == true))
          : null,
    );
  }

  /// Obtiene el fotógrafo en la posición [index] para un evento específico
  String? getFotografoAt(int index, [String? event]) {
    final list = _getFotoListForEvent(event);
    if (index < list.length && list[index].isNotEmpty) return list[index];
    return null;
  }

  /// Crea una copia con el fotógrafo en [index] actualizado para un evento
  ReservationAssignments withFotografoAt(int index, String employeeId, [String? event]) {
    final oldPre = List<String>.from(fotografoIdsPre);
    final oldFiesta = List<String>.from(fotografoIdsFiesta);

    void setInList(List<String> list, int idx, String val) {
      while (list.length <= idx) list.add('');
      list[idx] = val;
      while (list.isNotEmpty && list.last.isEmpty) list.removeLast();
    }

    String? newFotoId = fotografoId;
    if (event == 'pre') {
      setInList(oldPre, index, employeeId);
    } else if (event == 'fiesta') {
      setInList(oldFiesta, index, employeeId);
    } else {
      newFotoId = employeeId;
    }

    return ReservationAssignments(
      fotografoId: newFotoId,
      fotografoIdsPre: oldPre,
      fotografoIdsFiesta: oldFiesta,
      maquillistaId: maquillistaId,
      maquillistaIds: maquillistaIds,
      maquillistaIdsPre: maquillistaIdsPre,
      maquillistaIdsFiesta: maquillistaIdsFiesta,
      filmmakerId: filmmakerId,
      filmmakerIdsPre: filmmakerIdsPre,
      filmmakerIdsFiesta: filmmakerIdsFiesta,
      editorId: editorId,
      bookedById: bookedById,
      contactChannel: contactChannel,
      socialNetwork: socialNetwork,
      declined: declined,
    );
  }

  List<String> _getFotoListForEvent(String? event) {
    if (event == 'pre') return fotografoIdsPre;
    if (event == 'fiesta') return fotografoIdsFiesta;
    return fotografoId != null ? [fotografoId!] : [];
  }

  /// Verifica si todos los slots de fotografía están asignados para un evento
  bool allFotoAssigned(int needed, [String? event]) {
    final list = _getFotoListForEvent(event);
    if (list.length < needed) return false;
    return list.take(needed).every((id) => id.isNotEmpty);
  }

  // ── Filmmaker/Video helpers ──

  String? getFilmmakerAt(int index, [String? event]) {
    final list = _getFilmListForEvent(event);
    if (index < list.length && list[index].isNotEmpty) return list[index];
    return null;
  }

  ReservationAssignments withFilmmakerAt(int index, String employeeId, [String? event]) {
    final oldPre = List<String>.from(filmmakerIdsPre);
    final oldFiesta = List<String>.from(filmmakerIdsFiesta);

    void setInList(List<String> list, int idx, String val) {
      while (list.length <= idx) list.add('');
      list[idx] = val;
      while (list.isNotEmpty && list.last.isEmpty) list.removeLast();
    }

    String? newFmId = filmmakerId;
    if (event == 'pre') {
      setInList(oldPre, index, employeeId);
    } else if (event == 'fiesta') {
      setInList(oldFiesta, index, employeeId);
    } else {
      newFmId = employeeId;
    }

    return ReservationAssignments(
      fotografoId: fotografoId,
      fotografoIdsPre: fotografoIdsPre,
      fotografoIdsFiesta: fotografoIdsFiesta,
      maquillistaId: maquillistaId,
      maquillistaIds: maquillistaIds,
      maquillistaIdsPre: maquillistaIdsPre,
      maquillistaIdsFiesta: maquillistaIdsFiesta,
      filmmakerId: newFmId,
      filmmakerIdsPre: oldPre,
      filmmakerIdsFiesta: oldFiesta,
      editorId: editorId,
      bookedById: bookedById,
      contactChannel: contactChannel,
      socialNetwork: socialNetwork,
      declined: declined,
    );
  }

  List<String> _getFilmListForEvent(String? event) {
    if (event == 'pre') return filmmakerIdsPre;
    if (event == 'fiesta') return filmmakerIdsFiesta;
    return filmmakerId != null ? [filmmakerId!] : [];
  }

  bool allFilmmakerAssigned(int needed, [String? event]) {
    final list = _getFilmListForEvent(event);
    if (list.length < needed) return false;
    return list.take(needed).every((id) => id.isNotEmpty);
  }

  /// Obtiene el maquillista en la posición [index] para un evento específico
  String? getMaquillistaAt(int index, [String? event]) {
    final list = _getMaqListForEvent(event);
    if (index < list.length && list[index].isNotEmpty) return list[index];
    return null;
  }

  /// Crea una copia con el maquillista en [index] actualizado para un evento
  ReservationAssignments withMaquillistaAt(int index, String employeeId, [String? event]) {
    final oldPre = List<String>.from(maquillistaIdsPre);
    final oldFiesta = List<String>.from(maquillistaIdsFiesta);
    final oldIds = List<String>.from(maquillistaIds);

    void setInList(List<String> list, int idx, String val) {
      while (list.length <= idx) list.add('');
      list[idx] = val;
      while (list.isNotEmpty && list.last.isEmpty) list.removeLast();
    }

    if (event == 'pre') {
      setInList(oldPre, index, employeeId);
    } else if (event == 'fiesta') {
      setInList(oldFiesta, index, employeeId);
    } else {
      setInList(oldIds, index, employeeId);
    }

    return ReservationAssignments(
      fotografoId: fotografoId,
      fotografoIdsPre: fotografoIdsPre,
      fotografoIdsFiesta: fotografoIdsFiesta,
      maquillistaId: oldIds.isNotEmpty ? oldIds.first : (oldPre.isNotEmpty ? oldPre.first : maquillistaId),
      maquillistaIds: oldIds,
      maquillistaIdsPre: oldPre,
      maquillistaIdsFiesta: oldFiesta,
      filmmakerId: filmmakerId,
      filmmakerIdsPre: filmmakerIdsPre,
      filmmakerIdsFiesta: filmmakerIdsFiesta,
      editorId: editorId,
      bookedById: bookedById,
      contactChannel: contactChannel,
      socialNetwork: socialNetwork,
      declined: declined,
    );
  }

  List<String> _getMaqListForEvent(String? event) {
    if (event == 'pre') return maquillistaIdsPre;
    if (event == 'fiesta') return maquillistaIdsFiesta;
    return maquillistaIds;
  }

  /// Verifica si todos los slots de maquillaje están asignados para un evento
  bool allMaqAssigned(int needed, [String? event]) {
    final list = _getMaqListForEvent(event);
    if (list.length < needed) return false;
    return list.take(needed).every((id) => id.isNotEmpty);
  }

  Map<String, dynamic> toJson() {
    return {
      if (fotografoId != null) 'f': fotografoId,
      if (fotografoIdsPre.isNotEmpty) 'fPre': fotografoIdsPre,
      if (fotografoIdsFiesta.isNotEmpty) 'fFiesta': fotografoIdsFiesta,
      if (maquillistaId != null) 'm': maquillistaId,
      if (maquillistaIds.length > 1) 'mIds': maquillistaIds,
      if (maquillistaIdsPre.isNotEmpty) 'mPre': maquillistaIdsPre,
      if (maquillistaIdsFiesta.isNotEmpty) 'mFiesta': maquillistaIdsFiesta,
      if (filmmakerId != null) 'fm': filmmakerId,
      if (filmmakerIdsPre.isNotEmpty) 'fmPre': filmmakerIdsPre,
      if (filmmakerIdsFiesta.isNotEmpty) 'fmFiesta': filmmakerIdsFiesta,
      if (editorId != null) 'e': editorId,
      if (bookedById != null) 'b': bookedById,
      if (contactChannel != null) 'c': contactChannel,
      if (socialNetwork != null) 's': socialNetwork,
      if (declined.isNotEmpty) 'declined': declined,
    };
  }
}