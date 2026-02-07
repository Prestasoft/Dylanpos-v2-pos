/// Modelo de respuesta de la API del Padrón Electoral Dominicano
/// Endpoint: /api/padron-electoral/:cedula (proxy interno)
class PadronElectoralResponse {
  final bool success;
  final PadronData? data;
  final String? message;

  PadronElectoralResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory PadronElectoralResponse.fromJson(Map<String, dynamic> json) {
    return PadronElectoralResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? PadronData.fromJson(json['data']) : null,
      message: json['message'],
    );
  }
}

/// Datos del ciudadano del Padrón Electoral
class PadronData {
  final String cedula;
  final String nombres;
  final String apellido1;
  final String apellido2;
  final String? fechaNacimiento;
  final String? sexo;
  final String? estadoCivil;
  final String? municipio;
  final String? provincia;
  final String? direccion;
  final String? nacionalidad;
  final String? foto; // Base64 sin prefijo

  PadronData({
    required this.cedula,
    required this.nombres,
    required this.apellido1,
    required this.apellido2,
    this.fechaNacimiento,
    this.sexo,
    this.estadoCivil,
    this.municipio,
    this.provincia,
    this.direccion,
    this.nacionalidad,
    this.foto,
  });

  factory PadronData.fromJson(Map<String, dynamic> json) {
    return PadronData(
      cedula: json['cedula'] ?? '',
      nombres: json['nombres'] ?? '',
      apellido1: json['apellido1'] ?? '',
      apellido2: json['apellido2'] ?? '',
      fechaNacimiento: json['fechaNacimiento'],
      sexo: json['sexo'],
      estadoCivil: json['estadoCivil'],
      municipio: json['municipio'],
      provincia: json['provincia'],
      direccion: json['direccion'],
      nacionalidad: json['nacionalidad'],
      foto: json['foto'],
    );
  }

  /// Nombre completo con ambos apellidos
  String get nombreCompleto {
    final parts = <String>[];
    if (nombres.isNotEmpty) parts.add(nombres);
    if (apellido1.isNotEmpty) parts.add(apellido1);
    if (apellido2.isNotEmpty) parts.add(apellido2);
    return parts.join(' ');
  }

  /// Solo primer nombre
  String get primerNombre {
    if (nombres.isEmpty) return '';
    final parts = nombres.split(' ');
    return parts.first;
  }

  /// Todos los nombres (sin apellidos)
  String get nombresCompletos => nombres;

  /// Apellidos combinados
  String get apellidosCompletos {
    final parts = <String>[];
    if (apellido1.isNotEmpty) parts.add(apellido1);
    if (apellido2.isNotEmpty) parts.add(apellido2);
    return parts.join(' ');
  }

  /// Mapea sexo de API (MASCULINO/FEMENINO/M/F) a género del sistema
  String get generoMapeado {
    if (sexo == null) return 'Otro';
    final s = sexo!.toUpperCase();
    if (s == 'M' || s == 'MASCULINO') return 'Masculino';
    if (s == 'F' || s == 'FEMENINO') return 'Femenino';
    return 'Otro';
  }

  /// Mapea estado civil de API al formato del sistema
  String get estadoCivilMapeado {
    if (estadoCivil == null) return 'Soltero/a';
    final ec = estadoCivil!.toUpperCase();

    if (ec == 'S' || ec == 'SOLTERO' || ec == 'SOLTERO/A') return 'Soltero/a';
    if (ec == 'C' || ec == 'CASADO' || ec == 'CASADO/A') return 'Casado/a';
    if (ec == 'D' || ec == 'DIVORCIADO' || ec == 'DIVORCIADO/A') return 'Divorciado/a';
    if (ec == 'V' || ec == 'VIUDO' || ec == 'VIUDO/A') return 'Viudo/a';
    if (ec == 'U' || ec == 'UNION LIBRE' || ec == 'UNIÓN LIBRE') return 'Unión Libre';

    return 'Soltero/a';
  }

  /// Parsea fecha de nacimiento (formato: YYYY-MM-DD)
  DateTime? get fechaNacimientoParsed {
    if (fechaNacimiento == null || fechaNacimiento!.isEmpty) return null;
    try {
      return DateTime.parse(fechaNacimiento!);
    } catch (e) {
      return null;
    }
  }

  /// URL de imagen para mostrar (agrega prefijo data:image si hay foto)
  String? get fotoDataUrl {
    if (foto == null || foto!.isEmpty) return null;
    // Si ya tiene el prefijo data:, devolverlo tal cual
    if (foto!.startsWith('data:')) return foto;
    // Sino, agregar el prefijo para JPEG (formato estándar del padrón)
    return 'data:image/jpeg;base64,$foto';
  }

  /// Indica si tiene foto disponible
  bool get tieneFoto => foto != null && foto!.isNotEmpty;

  /// Dirección completa incluyendo municipio y provincia
  String get direccionCompleta {
    final parts = <String>[];
    if (direccion != null && direccion!.isNotEmpty) parts.add(direccion!);
    if (municipio != null && municipio!.isNotEmpty) parts.add(municipio!);
    if (provincia != null && provincia!.isNotEmpty) parts.add(provincia!);
    return parts.join(', ');
  }
}
