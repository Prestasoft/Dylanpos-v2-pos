import 'package:firebase_core/firebase_core.dart';

/// Configuración de WhatsApp API para una sucursal
class WhatsAppConfig {
  final String token;
  final String instanceId;
  final bool isEnabled;

  const WhatsAppConfig({
    this.token = '',
    this.instanceId = '',
    this.isEnabled = false,
  });

  /// Verifica si la configuración está completa
  bool get isConfigured => token.isNotEmpty && instanceId.isNotEmpty;

  /// Obtiene la URL del API para un endpoint específico
  String getApiUrl(String endpoint) {
    return 'https://api.ultramsg.com/$instanceId/$endpoint';
  }

  /// URL para enviar mensajes de chat
  String get chatUrl => getApiUrl('messages/chat');

  /// URL para enviar documentos
  String get documentUrl => getApiUrl('messages/document');
}

/// Modelo que representa una sucursal/tenant del sistema
class TenantModel {
  final String id;
  final String name;
  final String shortName;
  final String city;
  final String? address;
  final String? phone;
  final String? logo;
  final FirebaseOptions firebaseOptions;
  final bool isActive;
  /// Configuración de WhatsApp API para esta sucursal (puede estar vacía)
  final WhatsAppConfig whatsAppConfig;

  const TenantModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.city,
    this.address,
    this.phone,
    this.logo,
    required this.firebaseOptions,
    this.isActive = true,
    this.whatsAppConfig = const WhatsAppConfig(),
  });

  /// Indica si esta sucursal tiene WhatsApp configurado
  bool get hasWhatsApp => whatsAppConfig.isConfigured;

  /// Nombre completo para mostrar
  String get displayName => '$name - $city';

  /// Iniciales para avatar
  String get initials {
    final words = shortName.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return shortName.substring(0, 2).toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TenantModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Configuración de todas las sucursales disponibles
class TenantConfig {
  // Santo Domingo Este - Sin WhatsApp configurado
  static const TenantModel santoDomingoEste = TenantModel(
    id: 'sde',
    name: 'Victor Guzman Fotografía',
    shortName: 'SDE',
    city: 'Santo Domingo Este',
    address: 'Av. San Vicente de Paul',
    phone: '809-000-0000',
    firebaseOptions: FirebaseOptions(
      apiKey: "AIzaSyDfcwhEq_JuUg23OonfQtYtDGzlXQEXI9c",
      authDomain: "sistema-victor-sde.firebaseapp.com",
      databaseURL: "https://sistema-victor-sde-default-rtdb.firebaseio.com",
      projectId: "sistema-victor-sde",
      storageBucket: "sistema-victor-sde.firebasestorage.app",
      messagingSenderId: "180650620806",
      appId: "1:180650620806:web:5daf2c0d43927db6a61e07",
      measurementId: "G-231GYNFL54",
    ),
    // Sin WhatsApp API configurado
    whatsAppConfig: WhatsAppConfig(),
  );

  // Santiago - Con WhatsApp configurado
  static const TenantModel santiago = TenantModel(
    id: 'stg',
    name: 'Victor Guzman Fotografía',
    shortName: 'Santiago',
    city: 'Santiago',
    address: '',
    phone: '809-000-0000',
    firebaseOptions: FirebaseOptions(
      apiKey: "AIzaSyBP1pN3CBRNcUROMYinjTjKCzisLN7RjA0",
      authDomain: "dylanpos-v2.firebaseapp.com",
      databaseURL: "https://dylanpos-v2-default-rtdb.firebaseio.com",
      projectId: "dylanpos-v2",
      storageBucket: "dylanpos-v2.firebasestorage.app",
      messagingSenderId: "917502791038",
      appId: "1:917502791038:web:478334d1eb2748c1c6772f",
      measurementId: "G-XN9YDWN22N",
    ),
    // WhatsApp API de Santiago - REEMPLAZAR CON CREDENCIALES REALES
    whatsAppConfig: WhatsAppConfig(
      token: '', // TODO: Agregar token real de Santiago
      instanceId: '', // TODO: Agregar instanceId real de Santiago
      isEnabled: false,
    ),
  );

  // Santo Domingo Oeste - Sin WhatsApp configurado
  static const TenantModel santoDomingo = TenantModel(
    id: 'sdo',
    name: 'Victor Guzman Fotografía',
    shortName: 'Sto Dgo Oeste',
    city: 'Santo Domingo Oeste',
    address: '',
    phone: '809-000-0000',
    firebaseOptions: FirebaseOptions(
      apiKey: "AIzaSyCm5cqfIUlV3wll49QA36IRwUrbnww__lo",
      authDomain: "dylanpos-victorfoto-stodgo.firebaseapp.com",
      databaseURL: "https://dylanpos-victorfoto-stodgo-default-rtdb.firebaseio.com",
      projectId: "dylanpos-victorfoto-stodgo",
      storageBucket: "dylanpos-victorfoto-stodgo.firebasestorage.app",
      messagingSenderId: "892139987413",
      appId: "1:892139987413:web:e93a15d7a74313c78e1d5c",
      measurementId: "G-B6GB7L2RCM",
    ),
    // Sin WhatsApp API configurado
    whatsAppConfig: WhatsAppConfig(),
  );

  // La Romana - Sin WhatsApp configurado
  static const TenantModel laRomana = TenantModel(
    id: 'rom',
    name: 'Victor Guzman Fotografía',
    shortName: 'La Romana',
    city: 'La Romana',
    address: '',
    phone: '809-000-0000',
    firebaseOptions: FirebaseOptions(
      apiKey: "AIzaSyBkEcFoUDjFXH8IcH-oxlWHNZ_H15WfEE0",
      authDomain: "sistema-victor-romana.firebaseapp.com",
      databaseURL: "https://sistema-victor-romana-default-rtdb.firebaseio.com",
      projectId: "sistema-victor-romana",
      storageBucket: "sistema-victor-romana.firebasestorage.app",
      messagingSenderId: "609430938517",
      appId: "1:609430938517:web:fbc73dda27c7fee4974c9c",
      measurementId: "G-KHTR23Q0FM",
    ),
    // Sin WhatsApp API configurado
    whatsAppConfig: WhatsAppConfig(),
  );

  /// Lista de todas las sucursales disponibles
  static List<TenantModel> get allTenants => [
        santoDomingoEste,
        santiago,
        santoDomingo,
        laRomana,
      ];

  /// Obtener sucursal por ID
  static TenantModel? getTenantById(String id) {
    try {
      return allTenants.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Sucursal por defecto
  static TenantModel get defaultTenant => santoDomingoEste;
}
