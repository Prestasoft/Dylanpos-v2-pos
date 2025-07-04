# Implementación de Reservas con Doble Fecha para Planes PRE-QUINCE FIESTA

## Resumen
Se implementó la funcionalidad para crear automáticamente **una reserva única** con **dos fechas** (pre-quince y fiesta) cuando se selecciona un plan que contenga "PRE-QUINCE FIESTA" en su nombre, y mostrar ambas fechas en la factura.

## Cambios Implementados

### 1. Modificación del Screen de Confirmación (`lib/Screen/Reservation/confirmation_screen.dart`)

#### Funcionalidades agregadas:
- **Detección automática de planes PRE-QUINCE FIESTA**: Se normaliza el nombre del plan ignorando mayúsculas, tildes, espacios extra y prefijos como "Plan A", "Plan B", etc.
- **Validación de disponibilidad doble**: Se verifica la disponibilidad de vestidos tanto para la fecha de pre-quince como para la fecha de fiesta.
- **Creación de UNA SOLA reserva**:
  - Reserva única con `session_type: 'pre-quince-fiesta'`
  - Precio completo del paquete (sin dividir)
  - Campos adicionales: `fiesta_date` y `fiesta_time` para la segunda fecha
- **Mensajes mejorados**: Se muestra confirmación específica cuando se crea la reserva con ambas fechas

### 2. Actualización del Provider de Reservas (`lib/Provider/reservation_provider.dart`)

#### Nuevos campos agregados en la base de datos:
- `session_type`: Identifica el tipo de sesión ('normal' o 'pre-quince-fiesta')
- `fiesta_date`: Campo para la fecha de la fiesta (solo para planes PRE-QUINCE FIESTA)
- `fiesta_time`: Campo para la hora de la fiesta (solo para planes PRE-QUINCE FIESTA)

#### Estructura de datos:
```dart
{
  'service_id': 'xxx',
  'client_id': 'xxx', 
  'dress_id': 'xxx',
  'reservation_date': '2025-07-10', // Fecha pre-quince
  'reservation_time': '15:00',      // Hora pre-quince
  'fiesta_date': '2025-07-15',      // Fecha fiesta
  'fiesta_time': '19:00',           // Hora fiesta
  'session_type': 'pre-quince-fiesta',
  'package_price': 5000.0,         // Precio completo
  // ... otros campos
}
```

### 3. Actualización del PDF de Factura (`lib/PDF/sales_invoice_pdf.dart`)

#### Funcionalidades agregadas:
- **Detección de reservas PRE-QUINCE FIESTA**: El sistema identifica automáticamente si `session_type` es 'pre-quince-fiesta'
- **Visualización mejorada de fechas**:
  - Si es una reserva PRE-QUINCE FIESTA, se muestra "Fecha Pre-Quince" y "Fecha Fiesta" (en negritas)
  - Si es una reserva normal, se muestra "Fecha de reservación"
- **Uso de campos adicionales**: Lee `fiesta_date` y `fiesta_time` de la misma reserva

## Flujo de Funcionamiento

### Para Planes Normales:
1. El usuario selecciona fecha y hora
2. Se crea una reserva normal con `session_type: 'normal'`
3. Se muestra en la factura como "Fecha de reservación"

### Para Planes PRE-QUINCE FIESTA:
1. El usuario selecciona fecha/hora de pre-quince
2. El usuario selecciona fecha/hora de fiesta (campos adicionales aparecen automáticamente)
3. Se valida disponibilidad para ambas fechas
4. Se crea UNA SOLA reserva con:
   - `reservation_date` y `reservation_time` para pre-quince
   - `fiesta_date` y `fiesta_time` para fiesta
   - `session_type: 'pre-quince-fiesta'`
   - Precio completo del paquete
5. Se muestra confirmación de la reserva con ambas fechas
6. En la factura se muestran ambas fechas claramente diferenciadas

## Detección de Planes PRE-QUINCE FIESTA

La detección se realiza mediante normalización del nombre del plan:
- Se eliminan tildes (á→a, é→e, etc.)
- Se convierten a minúsculas
- Se eliminan espacios extra
- Se remueven prefijos como "Plan A", "Plan B", etc.
- Se busca la cadena "pre-quince y fiesta"

Ejemplos de nombres que se detectan:
- "Plan A PRE-QUINCE Y FIESTA"
- "pre-quince y fiesta básico"
- "PLAN B Pre-Quinceañera y Fiesta"
- "pré-quince y fiesta premium"
- "PRE-QUINCE FIESTA DELUXE"

La detección incluye variantes como:
- "pre-quince y fiesta"
- "pre-quince fiesta"
- "pre quince y fiesta"  
- "pre quince fiesta"
- "quinceañera y fiesta"

## Campos de Base de Datos

### Estructura para reservas PRE-QUINCE FIESTA:
```json
{
  "reservation_date": "2025-07-10",     // Fecha pre-quince
  "reservation_time": "15:00",          // Hora pre-quince
  "fiesta_date": "2025-07-15",          // Fecha fiesta
  "fiesta_time": "19:00",               // Hora fiesta
  "session_type": "pre-quince-fiesta",  // Tipo de sesión
  "package_price": 5000,                // Precio completo
  "service_id": "xxx",
  "client_id": "xxx",
  "dress_id": "xxx"
}
```

### Estructura para reservas normales:
```json
{
  "reservation_date": "2025-07-10",
  "reservation_time": "15:00",
  "session_type": "normal",
  "package_price": 3000,
  "fiesta_date": "",                    // Vacío
  "fiesta_time": ""                     // Vacío
}
```

## Ventajas de la Nueva Implementación

1. **Una sola factura**: No se duplica el monto, aparece como un solo servicio
2. **Gestión simplificada**: Una sola reserva en lugar de dos separadas
3. **Calendario claro**: Una reserva que ocupa dos fechas diferentes
4. **Facturación clara**: El cliente ve ambas fechas en una sola factura
5. **Trazabilidad mejorada**: No hay problemas de vinculación entre reservas
6. **Inventario correcto**: Los vestidos se marcan como no disponibles en ambas fechas

## Archivos Modificados

1. `/lib/Screen/Reservation/confirmation_screen.dart` - Creación de reserva única con campos adicionales
2. `/lib/Provider/reservation_provider.dart` - Soporte para campos fiesta_date y fiesta_time + visualización en calendario
3. `/lib/PDF/sales_invoice_pdf.dart` - Visualización de ambas fechas desde una sola reserva

### Cambios en `reservation_provider.dart`:
- **`reservationsByDateProvider`**: Modificado para mostrar reservas tanto en `reservation_date` como en `fiesta_date`
- **`isDressAvailableProvider`**: Actualizado para verificar conflictos en ambas fechas
- **`crearReservaProvider`**: Soporte para campos `fiesta_date` y `fiesta_time`

## Testing

Para probar la funcionalidad:
1. Crear un plan de servicio con nombre que contenga "pre-quince y fiesta"
2. Hacer una reserva seleccionando ese plan
3. Verificar que aparecen los campos de fecha/hora de fiesta
4. Completar ambas fechas y confirmar
5. Verificar que se crea UNA reserva en el sistema
6. Verificar que en inventory sales aparece como una sola entrada
7. Generar factura y verificar que se muestran ambas fechas

## Diferencias con la Implementación Anterior

- **Antes**: 2 reservas separadas con precio dividido (50% cada una)
- **Ahora**: 1 reserva con precio completo y campos adicionales para la segunda fecha
- **Antes**: Problemas de duplicación en inventory sales
- **Ahora**: Aparece como una sola entrada para facturar
- **Antes**: Reservas vinculadas con `reservation_associated`
- **Ahora**: Una sola reserva con ambas fechas integradas
