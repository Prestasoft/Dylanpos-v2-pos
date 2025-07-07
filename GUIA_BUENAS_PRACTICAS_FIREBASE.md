# Guía de Buenas Prácticas para Firebase

## Problema de Rutas Inválidas en Firebase

Firebase tiene restricciones sobre los caracteres que pueden usarse en las rutas de base de datos y almacenamiento. Específicamente, los siguientes caracteres están prohibidos en las claves de Firebase Realtime Database:
- `.` (punto)
- `#` (numeral)
- `$` (signo de dólar)
- `[` y `]` (corchetes)
- `/` (barra diagonal, solo para rutas)

Estos caracteres pueden aparecer en cadenas como `DateTime.now().toString()` que produce un formato como `2025-05-24 16:58:51.524` que contiene caracteres prohibidos.

## Soluciones Implementadas

Hemos implementado las siguientes soluciones:

1. **Uso de ISO8601 para fechas**: 
   ```dart
   DateTime.now().toIso8601String() // "2025-05-24T16:58:51.524Z"
   ```
   Este formato aún contiene puntos pero se usa principalmente como valor, no como clave.

2. **Sanitización de cadenas usadas como claves**:
   ```dart
   String safeKey = unsafeKey.replaceAll(RegExp(r'[.#$\[\]]'), '_');
   ```

3. **Conversión a formatos seguros para claves**:
   ```dart
   // Usar milliseconds desde epoch es completamente seguro
   String safeKey = DateTime.now().millisecondsSinceEpoch.toString();
   ```

## Mejores Prácticas para Firebase

### 1. Para Rutas y Claves de Firebase

```dart
// ❌ EVITAR
ref.child(DateTime.now().toString());
ref.child("path/with.dots/or#hashes");

// ✅ CORRECTO
ref.child(DateTime.now().millisecondsSinceEpoch.toString());
ref.child(unsafePath.replaceAll(RegExp(r'[.#$\[\]/]'), '_'));
```

### 2. Para Valores en Firebase

```dart
// ❌ EVITAR (si se usará como clave más adelante)
Map<String, dynamic> data = {
  'id': DateTime.now().toString(),
  // ...
};

// ✅ CORRECTO
Map<String, dynamic> data = {
  'id': DateTime.now().millisecondsSinceEpoch.toString(),
  'createdAt': DateTime.now().toIso8601String(), // Como valor está bien
  // ...
};
```

### 3. Para Nombres de Archivos en Storage

```dart
// ❌ EVITAR
Reference ref = storage.ref().child('invoices/invoice-${DateTime.now().toString()}.pdf');

// ✅ CORRECTO
String safeFileName = 'invoice-${DateTime.now().millisecondsSinceEpoch}.pdf';
// O sanitizar:
String safeFileName = 'invoice-${DateTime.now().toString().replaceAll(RegExp(r'[.#$\[\]/]'), '_')}.pdf';
Reference ref = storage.ref().child('invoices/$safeFileName');
```

### 4. Para WhatsApp y Archivos Temporales

```dart
// ❌ EVITAR
String fileName = 'Factura ${DateTime.now().toString()}.pdf';

// ✅ CORRECTO
String fileName = 'Factura_${DateTime.now().millisecondsSinceEpoch}.pdf';
```

## Función Utilitaria Recomendada

```dart
// Añadir esta función a un archivo de utilidades
String sanitizeForFirebase(String input) {
  return input.replaceAll(RegExp(r'[.#$\[\]/]'), '_');
}

// Para fechas específicamente
String getFirebaseSafeDateKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

// Para valores de fecha (no usados como claves)
String getFormattedDateValue() {
  return DateTime.now().toIso8601String();
}
```

## Comprobación de Errores

Si aún se producen errores de Firebase relacionados con rutas inválidas, revise:

1. Todos los lugares donde se usa `DateTime.now().toString()` como parte de una ruta o clave
2. Nombres de archivos generados dinámicamente
3. IDs generados a partir de fechas u otras cadenas que puedan contener caracteres prohibidos
4. Consultas o actualizaciones que usen valores dinámicos como parte de la ruta

Recuerde que una fecha bien formateada para mostrar al usuario no siempre es adecuada para usar como clave en Firebase.
