import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// Firebase Auth deshabilitado - Usar ApiService para autenticación
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../version.dart';

class VersionCheckService {
  static final VersionCheckService _instance = VersionCheckService._internal();
  factory VersionCheckService() => _instance;
  VersionCheckService._internal();

  // Timer para verificación periódica
  Timer? _versionCheckTimer;
  
  // Callback para notificar cuando hay una actualización
  Function(VersionInfo)? onUpdateAvailable;
  
  // Versión actual almacenada localmente
  String? _currentVersion;
  
  // Última versión disponible en el servidor
  String? _latestVersion;
  
  // URL base de la aplicación
  String get _baseUrl {
    if (kIsWeb) {
      // En web, usar la URL actual
      final uri = Uri.base;
      return '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
    }
    return '';
  }

  /// Iniciar verificación periódica de versión
  void startVersionCheck({Duration interval = const Duration(minutes: 5)}) {
    // Detener timer anterior si existe
    stopVersionCheck();

    // Esperar 3 segundos antes de la primera verificación
    // para dar tiempo a que la app se inicialice completamente
    Future.delayed(const Duration(seconds: 3), () {
      checkForUpdates();
    });

    // Configurar verificación periódica
    _versionCheckTimer = Timer.periodic(interval, (_) {
      checkForUpdates();
    });
  }

  /// Detener verificación periódica
  void stopVersionCheck() {
    _versionCheckTimer?.cancel();
    _versionCheckTimer = null;
  }

  /// Verificar si hay actualizaciones disponibles
  Future<void> checkForUpdates() async {
    try {
      // Obtener versión del servidor
      final serverVersion = await _fetchServerVersion();
      if (serverVersion == null) return;
      
      // Guardar la última versión disponible
      _latestVersion = serverVersion.version;
      
      // Obtener versión actual desde el archivo compilado
      final prefs = await SharedPreferences.getInstance();
      _currentVersion = appVersion;
      
      // Verificar si el usuario ya hizo clic en actualizar para esta versión
      // Primero verificar en SharedPreferences
      bool updateClicked = prefs.getBool('update_clicked') ?? false;
      String updateClickedVersion = prefs.getString('update_clicked_version') ?? '';
      
      // Si es web, también verificar en localStorage
      if (kIsWeb && !updateClicked) {
        final localUpdateClicked = html.window.localStorage['update_clicked'];
        final localUpdateClickedVersion = html.window.localStorage['update_clicked_version'] ?? '';
        final localUpdateTimestamp = html.window.localStorage['update_timestamp'];
        
        debugPrint('checkForUpdates: localStorage - clicked: $localUpdateClicked, version: $localUpdateClickedVersion');
        
        if (localUpdateClicked == 'true' && localUpdateClickedVersion == serverVersion.version) {
          updateClicked = true;
          updateClickedVersion = localUpdateClickedVersion;
          
          // Verificar si es reciente (menos de 24 horas)
          if (localUpdateTimestamp != null) {
            try {
              final timestamp = int.parse(localUpdateTimestamp);
              final updateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
              final hoursSinceUpdate = DateTime.now().difference(updateTime).inHours;
              
              debugPrint('checkForUpdates: Actualización hace $hoursSinceUpdate horas');
              
              // Si han pasado más de 24 horas, limpiar el estado
              if (hoursSinceUpdate > 24) {
                debugPrint('checkForUpdates: Limpiando estado antiguo de actualización');
                updateClicked = false;
                updateClickedVersion = '';
                html.window.localStorage.remove('update_clicked');
                html.window.localStorage.remove('update_clicked_version');
                html.window.localStorage.remove('update_timestamp');
              }
            } catch (e) {
              debugPrint('checkForUpdates: Error parseando timestamp: $e');
            }
          }
          
          // Sincronizar con SharedPreferences si es válido
          if (updateClicked) {
            await prefs.setBool('update_clicked', true);
            await prefs.setString('update_clicked_version', localUpdateClickedVersion);
          }
        }
      }
      
      // Si ya hizo clic en actualizar para esta versión, no mostrar el popup
      if (updateClicked && updateClickedVersion == serverVersion.version) {
        debugPrint('Usuario ya hizo clic en actualizar para versión ${serverVersion.version}');
        return;
      }
      
      // Comparar versiones
      if (_isNewerVersion(serverVersion.version, _currentVersion!)) {
        debugPrint('Nueva versión disponible: ${serverVersion.version}');
        
        // Guardar nueva versión detectada
        await prefs.setString('latest_version_detected', serverVersion.version);
        
        // Notificar actualización disponible
        onUpdateAvailable?.call(serverVersion);
      } else {
        debugPrint('La aplicación está actualizada: $_currentVersion');
        // Limpiar flag de actualización si la versión está actualizada
        if (updateClicked) {
          await prefs.remove('update_clicked');
          await prefs.remove('update_clicked_version');
        }
      }
    } catch (e) {
      debugPrint('Error verificando actualizaciones: $e');
    }
  }

  /// Obtener información de versión del servidor
  Future<VersionInfo?> _fetchServerVersion() async {
    try {
      // Usar app-version.json para evitar conflictos con el version.json de Flutter
      final url = '$_baseUrl/app-version.json?t=${DateTime.now().millisecondsSinceEpoch}';
      
      if (kDebugMode) {
        debugPrint('Verificando actualización en: $url');
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          debugPrint('Datos de versión recibidos: $data');
        }
        return VersionInfo.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error obteniendo versión del servidor: $e');
    }
    return null;
  }

  /// Comparar versiones (formato: x.y.z)
  bool _isNewerVersion(String serverVersion, String currentVersion) {
    try {
      final serverParts = serverVersion.split('.').map(int.parse).toList();
      final currentParts = currentVersion.split('.').map(int.parse).toList();
      
      // Asegurar que ambas versiones tengan 3 partes
      while (serverParts.length < 3) {
        serverParts.add(0);
      }
      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      
      // Comparar mayor, menor y parche
      for (int i = 0; i < 3; i++) {
        if (serverParts[i] > currentParts[i]) return true;
        if (serverParts[i] < currentParts[i]) return false;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error comparando versiones: $e');
      return false;
    }
  }

  /// Limpiar caché y cerrar sesión
  Future<void> performUpdate() async {
    try {
      debugPrint('performUpdate: Iniciando proceso de actualización');
      
      // Obtener info de la versión del servidor ANTES de limpiar
      final serverVersion = await _fetchServerVersion();
      final latestVer = _latestVersion ?? serverVersion?.version ?? '';
      
      // Detener el timer de verificación
      stopVersionCheck();
      
      if (kIsWeb) {
        // 1. Limpiar caches del service worker (NO localStorage todavía)
        debugPrint('performUpdate: Limpiando caché del navegador');
        _clearBrowserCache();
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        // 2. Ahora RE-ESCRIBIR las claves que index.html necesita
        //    para que checkServerVersion() no piense que hay una nueva versión
        //    La clave CACHE_KEY en index.html es: version + '_' + build
        //    Necesitamos reconstruir exactamente eso
        if (serverVersion != null) {
          final build = serverVersion.releaseDate.replaceAll('-', ''); // fallback
          // Fetch the actual build string from app-version.json
          try {
            final url = '$_baseUrl/app-version.json?t=${DateTime.now().millisecondsSinceEpoch}';
            final response = await http.get(Uri.parse(url), headers: {
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
            }).timeout(const Duration(seconds: 5));
            
            if (response.statusCode == 200) {
              final data = json.decode(response.body);
              final serverBuild = data['build'] ?? build;
              final cacheKey = '${data['version']}_$serverBuild';
              
              html.window.localStorage['app_cache_version'] = cacheKey;
              html.window.localStorage['app_version'] = data['version'].toString();
              debugPrint('performUpdate: Re-wrote CACHE_KEY=$cacheKey app_version=${data['version']}');
            }
          } catch (e) {
            // Fallback: just set the version
            html.window.localStorage['app_version'] = latestVer;
            debugPrint('performUpdate: Fallback - set app_version=$latestVer');
          }
        }
        
        // 3. Marcar la actualización como completada para el VersionCheckService
        html.window.localStorage['update_clicked'] = 'true';
        html.window.localStorage['update_clicked_version'] = latestVer;
        html.window.localStorage['update_timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        // 4. Recargar la página para obtener la nueva versión
        debugPrint('performUpdate: Recargando página');
        _reloadPage();
      }
    } catch (e) {
      debugPrint('Error durante actualización: $e');
    }
  }

  /// Limpiar caché del navegador
  void _clearBrowserCache() {
    if (kIsWeb) {
      try {
        // Limpiar caché del service worker usando JavaScript
        final script = html.ScriptElement()
          ..text = '''
            // Limpiar caché del service worker
            if ('caches' in window) {
              caches.keys().then(function(names) {
                names.forEach(function(name) {
                  caches.delete(name);
                  console.log('Cache cleared:', name);
                });
              });
            }
            
            // Desregistrar service workers
            if ('serviceWorker' in navigator) {
              navigator.serviceWorker.getRegistrations().then(function(registrations) {
                registrations.forEach(function(registration) {
                  registration.unregister();
                  console.log('Service worker unregistered');
                });
              });
            }
          ''';
        
        html.document.head!.append(script);
        
        // Remover el script después de ejecutarlo
        Future.delayed(const Duration(milliseconds: 100), () {
          script.remove();
        });
        
        debugPrint('Caché del navegador limpiado exitosamente');
      } catch (e) {
        debugPrint('Error limpiando caché del navegador: $e');
      }
    }
  }

  /// Recargar página
  void _reloadPage() {
    if (kIsWeb) {
      try {
        // Forzar recarga completa de la página
        html.window.location.reload();
      } catch (e) {
        debugPrint('Error recargando página: $e');
      }
    }
  }
  
  /// Guardar versión actual después de actualización exitosa
  Future<void> saveCurrentVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_version', version);
    _currentVersion = version;
    
    // Limpiar los flags de actualización si la versión coincide
    if (_latestVersion == version) {
      await prefs.remove('update_clicked');
      await prefs.remove('update_clicked_version');
      
      if (kIsWeb) {
        html.window.localStorage.remove('update_clicked');
        html.window.localStorage.remove('update_clicked_version');
      }
    }
  }
  
  /// Limpiar el estado de actualización (útil para pruebas)
  Future<void> clearUpdateState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('update_clicked');
    await prefs.remove('update_clicked_version');
    
    if (kIsWeb) {
      html.window.localStorage.remove('update_clicked');
      html.window.localStorage.remove('update_clicked_version');
      html.window.localStorage.remove('update_timestamp');
    }
    
    debugPrint('Estado de actualización limpiado');
  }
  
  /// Verificar si el usuario viene de una actualización
  Future<bool> isComingFromUpdate() async {
    if (!kIsWeb) return false;
    
    final updateClicked = html.window.localStorage['update_clicked'];
    final updateTimestamp = html.window.localStorage['update_timestamp'];
    
    if (updateClicked == 'true' && updateTimestamp != null) {
      try {
        final timestamp = int.parse(updateTimestamp);
        final updateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final minutesSinceUpdate = DateTime.now().difference(updateTime).inMinutes;
        
        // Si han pasado menos de 5 minutos desde que hizo clic en actualizar
        return minutesSinceUpdate < 5;
      } catch (e) {
        debugPrint('isComingFromUpdate: Error verificando timestamp: $e');
      }
    }
    
    return false;
  }
}

/// Modelo de información de versión
class VersionInfo {
  final String version;
  final String releaseDate;
  final String description;
  final bool forceUpdate;

  VersionInfo({
    required this.version,
    required this.releaseDate,
    required this.description,
    required this.forceUpdate,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      version: json['version'] ?? '0.0.0',
      releaseDate: json['releaseDate'] ?? '',
      description: json['description'] ?? '',
      forceUpdate: json['forceUpdate'] ?? false,
    );
  }
}