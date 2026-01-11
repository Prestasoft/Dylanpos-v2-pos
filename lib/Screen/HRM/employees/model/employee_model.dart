/// Modelo de Empleado completo para República Dominicana
/// Incluye campos para cumplimiento con TSS, AFP, SFS y leyes laborales RD
class EmployeeModel {
  final dynamic id; // Puede ser num (legacy) o String (UUID del servidor)
  late final String name;
  late final String lastName;
  late final String cedula; // Cédula dominicana (###-#######-#)
  late final String phoneNumber;
  late final String? phoneNumber2; // Teléfono secundario
  late final String email;
  late final String address;
  late final String? city;
  late final String? province; // Provincia RD
  late final String gender;
  late final String maritalStatus; // Estado civil
  late final int dependents; // Número de dependientes para ISR
  late final String employmentType; // Fijo, Temporal, Por hora
  late final String contractType; // Indefinido, Temporal, Por obra
  late final num designationId;
  late final String designation;
  late final String department; // Departamento
  late final DateTime birthDate;
  late final DateTime joiningDate;
  late final DateTime? contractEndDate; // Para contratos temporales
  late final double salary; // Salario bruto mensual
  late final String salaryType; // Mensual, Quincenal, Semanal
  late final String paymentMethod; // Transferencia, Cheque, Efectivo
  late final String? bankName; // Banco para transferencias
  late final String? bankAccountNumber; // Número de cuenta
  late final String? bankAccountType; // Ahorros, Corriente

  // Información de Seguridad Social RD
  late final String? afpNumber; // Número de cuenta AFP
  late final String afpProvider; // AFP Popular, Reservas, Siembra, etc.
  late final String? sfsNumber; // Número ARS/SFS
  late final String sfsProvider; // ARS: Humano, Universal, Senasa, etc.
  late final String? nss; // Número de Seguridad Social (si aplica)

  // Contacto de emergencia
  late final String? emergencyContactName;
  late final String? emergencyContactPhone;
  late final String? emergencyContactRelation;

  // Estado del empleado
  late final String status; // Activo, Inactivo, Suspendido, Licencia
  late final DateTime? terminationDate;
  late final String? terminationReason;

  // Información adicional
  late final String? photoUrl;
  late final String? notes;

  // Campos para vacaciones
  late final int vacationDaysAccrued; // Días de vacaciones acumulados
  late final int vacationDaysTaken; // Días de vacaciones tomados

  EmployeeModel({
    required this.id,
    required this.name,
    required this.lastName,
    required this.cedula,
    required this.phoneNumber,
    this.phoneNumber2,
    required this.email,
    required this.address,
    this.city,
    this.province,
    required this.gender,
    required this.maritalStatus,
    required this.dependents,
    required this.employmentType,
    required this.contractType,
    required this.designationId,
    required this.designation,
    required this.department,
    required this.birthDate,
    required this.joiningDate,
    this.contractEndDate,
    required this.salary,
    required this.salaryType,
    required this.paymentMethod,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountType,
    this.afpNumber,
    required this.afpProvider,
    this.sfsNumber,
    required this.sfsProvider,
    this.nss,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    required this.status,
    this.terminationDate,
    this.terminationReason,
    this.photoUrl,
    this.notes,
    this.vacationDaysAccrued = 0,
    this.vacationDaysTaken = 0,
  });

  /// Nombre completo del empleado
  String get fullName => '$name $lastName';

  /// Años de servicio
  int get yearsOfService {
    final endDate = terminationDate ?? DateTime.now();
    return endDate.difference(joiningDate).inDays ~/ 365;
  }

  /// Meses de servicio
  int get monthsOfService {
    final endDate = terminationDate ?? DateTime.now();
    return endDate.difference(joiningDate).inDays ~/ 30;
  }

  /// Días de vacaciones disponibles (14 días después de 1 año según Ley 16-92)
  int get vacationDaysAvailable => vacationDaysAccrued - vacationDaysTaken;

  /// Validar cédula dominicana (formato: ###-#######-#)
  static bool isValidCedula(String cedula) {
    final cleanCedula = cedula.replaceAll('-', '');
    if (cleanCedula.length != 11) return false;
    if (!RegExp(r'^\d{11}$').hasMatch(cleanCedula)) return false;

    // Algoritmo de validación de cédula dominicana (Luhn modificado)
    final weights = [1, 2, 1, 2, 1, 2, 1, 2, 1, 2];
    int sum = 0;
    for (int i = 0; i < 10; i++) {
      int digit = int.parse(cleanCedula[i]) * weights[i];
      if (digit > 9) digit -= 9;
      sum += digit;
    }
    final checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit == int.parse(cleanCedula[10]);
  }

  /// Formatear cédula con guiones
  static String formatCedula(String cedula) {
    final clean = cedula.replaceAll('-', '');
    if (clean.length != 11) return cedula;
    return '${clean.substring(0, 3)}-${clean.substring(3, 10)}-${clean.substring(10)}';
  }

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    // El servidor PostgreSQL usa snake_case, Flutter usa camelCase
    // Soportamos ambos formatos para compatibilidad

    // Parsear ID - usar el UUID del servidor directamente (campo 'id')
    // El campo 'id' del servidor PostgreSQL es el UUID real para operaciones CRUD
    dynamic employeeId = json['id'] ?? json['employee_id'] ?? DateTime.now().millisecondsSinceEpoch;

    // Parsear fechas con manejo de null
    DateTime? parseBirthDate() {
      final bd = json['birth_date'] ?? json['birthDate'];
      if (bd == null) return DateTime.now().subtract(const Duration(days: 365 * 25));
      return DateTime.tryParse(bd.toString()) ?? DateTime.now().subtract(const Duration(days: 365 * 25));
    }

    DateTime? parseHireDate() {
      final hd = json['hire_date'] ?? json['joiningDate'];
      if (hd == null) return DateTime.now();
      return DateTime.tryParse(hd.toString()) ?? DateTime.now();
    }

    DateTime? parseContractEndDate() {
      final ced = json['contract_end_date'] ?? json['contractEndDate'];
      if (ced == null) return null;
      return DateTime.tryParse(ced.toString());
    }

    DateTime? parseTerminationDate() {
      final td = json['termination_date'] ?? json['terminationDate'];
      if (td == null) return null;
      return DateTime.tryParse(td.toString());
    }

    // Parsear salary
    double parseSalary() {
      final sal = json['salary'];
      if (sal == null) return 0.0;
      if (sal is num) return sal.toDouble();
      if (sal is String) return double.tryParse(sal) ?? 0.0;
      return 0.0;
    }

    // Parsear enteros que pueden venir como String
    int parseIntValue(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    // Parsear números que pueden venir como String
    num parseNumValue(dynamic value, [num defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return EmployeeModel(
      id: employeeId,
      name: (json['first_name'] ?? json['name'] ?? '') as String,
      lastName: (json['last_name'] ?? json['lastName'] ?? '') as String,
      cedula: (json['cedula'] ?? '') as String,
      phoneNumber: (json['phone'] ?? json['phoneNumber'] ?? '') as String,
      phoneNumber2: json['phone2'] ?? json['phoneNumber2'],
      email: (json['email'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      city: json['city'] as String?,
      province: json['province'] as String?,
      gender: (json['gender'] ?? 'Otro') as String,
      maritalStatus: (json['marital_status'] ?? json['maritalStatus'] ?? 'Soltero/a') as String,
      dependents: parseIntValue(json['dependents'], 0),
      employmentType: (json['employment_type'] ?? json['employmentType'] ?? 'Tiempo Completo') as String,
      contractType: (json['contract_type'] ?? json['contractType'] ?? 'Indefinido') as String,
      designation: (json['designation'] ?? 'Sin Cargo') as String,
      designationId: parseNumValue(json['designation_id'] ?? json['designationId'], 0),
      department: (json['department'] ?? 'General') as String,
      birthDate: parseBirthDate()!,
      joiningDate: parseHireDate()!,
      contractEndDate: parseContractEndDate(),
      salary: parseSalary(),
      salaryType: (json['salary_type'] ?? json['salaryType'] ?? 'Mensual') as String,
      paymentMethod: (json['payment_method'] ?? json['paymentMethod'] ?? 'Transferencia') as String,
      bankName: json['bank_name'] ?? json['bankName'],
      bankAccountNumber: json['bank_account'] ?? json['bankAccountNumber'],
      bankAccountType: json['bank_account_type'] ?? json['bankAccountType'],
      afpNumber: json['afp_number'] ?? json['afpNumber'],
      afpProvider: (json['afp_provider'] ?? json['afpProvider'] ?? 'AFP Popular') as String,
      sfsNumber: json['sfs_number'] ?? json['sfsNumber'],
      sfsProvider: (json['sfs_provider'] ?? json['sfsProvider'] ?? 'Senasa') as String,
      nss: json['nss'] as String?,
      emergencyContactName: json['emergency_contact_name'] ?? json['emergencyContactName'],
      emergencyContactPhone: json['emergency_contact_phone'] ?? json['emergencyContactPhone'],
      emergencyContactRelation: json['emergency_contact_relation'] ?? json['emergencyContactRelation'],
      status: (json['status'] ?? 'Activo') as String,
      terminationDate: parseTerminationDate(),
      terminationReason: json['termination_reason'] ?? json['terminationReason'],
      photoUrl: json['image_url'] ?? json['photoUrl'],
      notes: json['notes'] as String?,
      vacationDaysAccrued: parseIntValue(json['vacation_days_accrued'] ?? json['vacationDaysAccrued'], 0),
      vacationDaysTaken: parseIntValue(json['vacation_days_taken'] ?? json['vacationDaysTaken'], 0),
    );
  }

  Map<String, dynamic> toJson() {
    // Enviamos con snake_case que es lo que espera el servidor PostgreSQL
    return {
      'employee_id': id,
      'first_name': name,
      'last_name': lastName,
      'full_name': '$name $lastName',
      'cedula': cedula,
      'phone': phoneNumber,
      'phone2': phoneNumber2,
      'email': email,
      'address': address,
      'city': city,
      'province': province,
      'gender': gender,
      'marital_status': maritalStatus,
      'dependents': dependents,
      'employment_type': employmentType,
      'contract_type': contractType,
      'designation_id': designationId,
      'designation': designation,
      'department': department,
      'birth_date': birthDate.toIso8601String(),
      'hire_date': joiningDate.toIso8601String(),
      'contract_start_date': joiningDate.toIso8601String(),
      'contract_end_date': contractEndDate?.toIso8601String(),
      'salary': salary,
      'salary_type': salaryType,
      'payment_method': paymentMethod,
      'bank_name': bankName,
      'bank_account': bankAccountNumber,
      'bank_account_type': bankAccountType,
      'afp_number': afpNumber,
      'afp_provider': afpProvider,
      'sfs_number': sfsNumber,
      'sfs_provider': sfsProvider,
      'nss': nss,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'emergency_contact_relation': emergencyContactRelation,
      'status': status,
      'termination_date': terminationDate?.toIso8601String(),
      'termination_reason': terminationReason,
      'image_url': photoUrl,
      'notes': notes,
      'vacation_days_accrued': vacationDaysAccrued,
      'vacation_days_taken': vacationDaysTaken,
    };
  }
}

/// Provincias de República Dominicana
class ProvincesRD {
  static const List<String> all = [
    'Azua',
    'Bahoruco',
    'Barahona',
    'Dajabón',
    'Distrito Nacional',
    'Duarte',
    'El Seibo',
    'Elías Piña',
    'Espaillat',
    'Hato Mayor',
    'Hermanas Mirabal',
    'Independencia',
    'La Altagracia',
    'La Romana',
    'La Vega',
    'María Trinidad Sánchez',
    'Monseñor Nouel',
    'Monte Cristi',
    'Monte Plata',
    'Pedernales',
    'Peravia',
    'Puerto Plata',
    'Samaná',
    'San Cristóbal',
    'San José de Ocoa',
    'San Juan',
    'San Pedro de Macorís',
    'Sánchez Ramírez',
    'Santiago',
    'Santiago Rodríguez',
    'Santo Domingo',
    'Valverde',
  ];
}

/// Proveedores de AFP en República Dominicana
class AFPProviders {
  static const List<String> all = [
    'AFP Popular',
    'AFP Reservas',
    'AFP Siembra',
    'AFP Crecer',
    'AFP Romana',
  ];
}

/// Proveedores de ARS/SFS en República Dominicana
class ARSProviders {
  static const List<String> all = [
    'Senasa',
    'ARS Humano',
    'ARS Universal',
    'ARS Palic',
    'ARS Semma',
    'ARS APS',
    'ARS Monumental',
    'ARS Renacer',
    'ARS Mapfre',
    'ARS Futuro',
    'ARS Colonial',
    'ARS Meta Salud',
    'ARS CMD',
    'ARS Primera',
    'ARS Yunen',
  ];
}

/// Bancos en República Dominicana
class BanksRD {
  static const List<String> all = [
    'Banco Popular Dominicano',
    'Banco de Reservas',
    'Banco BHD León',
    'Scotiabank',
    'Banco Santa Cruz',
    'Banco Promerica',
    'Banco Caribe',
    'Banco López de Haro',
    'Banco Vimenca',
    'Banco Ademi',
    'Banco Múltiple Lafise',
    'Banco Activo',
    'Asociación Popular',
    'Asociación La Nacional',
    'Asociación Cibao',
    'Banesco',
  ];
}
