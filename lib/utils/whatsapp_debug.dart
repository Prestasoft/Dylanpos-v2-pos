// lib/utils/whatsapp_debug.dart

import 'package:firebase_database/firebase_database.dart';
import 'firebase_key_util.dart';

// Clase para depurar problemas con WhatsApp y Firebase
class WhatsAppDebug {
  // Esta función sanitiza una fecha específica que está causando problemas
  static String sanitizeProblemDate(String problemDate) {
    // La fecha específica que está causando problemas
    const String knownProblemDate = "2025-05-24 16:58:51.524";
    
    // Si coincide con la fecha problemática, sanitizarla
    if (problemDate == knownProblemDate) {
      return "2025_05_24_16_58_51_524";
    }
    
    // Para otras fechas, usar el sanitizador normal
    return FirebaseKeyUtil.sanitizeKey(problemDate);
  }
  
  // Función segura para crear una referencia de Firebase evitando problemas con fechas
  static DatabaseReference safeReference(String path) {
    // Sanitizar la ruta completa
    String sanitizedPath = path;
    
    // Verificar y sanitizar la fecha problemática específicamente
    if (sanitizedPath.contains("2025-05-24 16:58:51.524")) {
      sanitizedPath = sanitizedPath.replaceAll("2025-05-24 16:58:51.524", "2025_05_24_16_58_51_524");
    }
    
    // Sanitizar cualquier otro carácter problemático
    sanitizedPath = FirebaseKeyUtil.sanitizeKey(sanitizedPath);
    
    // Devolver la referencia con la ruta sanitizada
    return FirebaseDatabase.instance.ref(sanitizedPath);
  }
}
