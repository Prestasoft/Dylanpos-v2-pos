class DesignationModel {
  late num id;
  late String designation;
  late String designationDescription;

  // Sistema de tareas: encargado del cargo + SLA + color del departamento
  String? managerUserId;
  int slaDays;
  int slaHours;
  int slaMinutes;
  String colorHex;

  DesignationModel({
    required this.id,
    required this.designation,
    required this.designationDescription,
    this.managerUserId,
    this.slaDays = 1,
    this.slaHours = 0,
    this.slaMinutes = 0,
    this.colorHex = '#EC4899',
  });

  DesignationModel.fromJson(Map<dynamic, dynamic> json)
      : slaDays = _parseInt(json['sla_days'] ?? json['slaDays'], fallback: 1),
        slaHours = _parseInt(json['sla_hours'] ?? json['slaHours'], fallback: 0),
        slaMinutes = _parseInt(json['sla_minutes'] ?? json['slaMinutes'], fallback: 0),
        colorHex = (json['color_hex'] ?? json['colorHex'] ?? '#EC4899') as String {
    // El servidor PostgreSQL devuelve:
    // - 'id' = UUID (string)
    // - 'designation_id' = ID numérico (string o num, puede ser null)
    // Usamos designation_id como identificador principal
    var designationId = json['designation_id'];
    if (designationId != null) {
      if (designationId is num) {
        id = designationId;
      } else if (designationId is String) {
        id = num.tryParse(designationId) ?? DateTime.now().millisecondsSinceEpoch;
      } else {
        id = DateTime.now().millisecondsSinceEpoch;
      }
    } else {
      // Fallback: usar timestamp actual si no hay designation_id
      id = DateTime.now().millisecondsSinceEpoch;
    }

    designation = (json['designation'] ?? '') as String;
    designationDescription = (json['designation_description'] ?? json['designationDescription'] ?? '') as String;

    final rawManager = json['manager_user_id'] ?? json['managerUserId'];
    managerUserId = rawManager == null || rawManager.toString().isEmpty ? null : rawManager.toString();
  }

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'designation_id': id,
        'designation': designation,
        'designation_description': designationDescription,
        'manager_user_id': managerUserId,
        'sla_days': slaDays,
        'sla_hours': slaHours,
        'sla_minutes': slaMinutes,
        'color_hex': colorHex,
      };

  /// Duración total del SLA como Duration
  Duration get slaDuration => Duration(
        days: slaDays,
        hours: slaHours,
        minutes: slaMinutes,
      );

  /// Representación legible del SLA (ej: "2d 3h", "45min")
  String get slaLabel {
    final parts = <String>[];
    if (slaDays > 0) parts.add('${slaDays}d');
    if (slaHours > 0) parts.add('${slaHours}h');
    if (slaMinutes > 0) parts.add('${slaMinutes}min');
    return parts.isEmpty ? 'Sin SLA' : parts.join(' ');
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
