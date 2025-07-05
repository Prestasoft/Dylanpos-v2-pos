import 'dart:io';

// Script para verificar la contraseña estática en el sistema
void main() {
  print("=== Verificación de Protección por Contraseña en Cancelación de Reservaciones ===");
  print("");
  
  // Contraseña actual configurada en el sistema
  const String passwordActual = "22400600452";
  
  print("Contraseña actual del sistema: $passwordActual");
  print("");
  
  print("Por favor, ingrese la contraseña para simular la cancelación de una reservación:");
  String? passwordIngresada = stdin.readLineSync();
  
  if (passwordIngresada == passwordActual) {
    print("");
    print("✅ Contraseña correcta. La reservación sería cancelada.");
  } else {
    print("");
    print("❌ Contraseña incorrecta. La reservación NO sería cancelada.");
  }
  
  print("");
  print("=== Verificación Completada ===");
}
