# Implementación de Protección con Contraseña para Cancelación de Reservaciones

## Descripción
Se ha implementado un mecanismo de seguridad que requiere una contraseña estática para poder cancelar una reservación. Esta funcionalidad añade una capa adicional de seguridad para evitar cancelaciones accidentales o no autorizadas.

## Cambios Realizados
1. Se modificó el proceso de cancelación de reservaciones para que ahora requiera una contraseña.
2. Se añadió un nuevo diálogo que solicita una contraseña al usuario después de confirmar la intención de cancelar una reservación.
3. Se implementó una validación de contraseña estática (Admin123) que debe ser ingresada correctamente antes de proceder con la cancelación.
4. Se agregaron mensajes de error adecuados para guiar al usuario en caso de ingresar una contraseña incorrecta o dejar el campo vacío.

## Flujo del Proceso de Cancelación
1. El usuario hace clic en el botón "Cancelar" en la vista de detalles de reservación.
2. Se muestra un primer diálogo de confirmación que pregunta si está seguro de querer cancelar la reservación.
3. Al confirmar, se muestra un segundo diálogo que solicita la contraseña.
4. Si la contraseña ingresada es correcta, se procede con la cancelación de la reservación.
5. Si la contraseña es incorrecta, se muestra un mensaje de error y no se permite la cancelación.

## Detalles Técnicos
- Contraseña estática: "Admin123"
- Se utiliza un `TextFormField` con `obscureText: true` para ocultar la contraseña mientras se escribe.
- Se implementa validación en tiempo real para proporcionar retroalimentación inmediata al usuario.
- Se usa un `Form` con `GlobalKey<FormState>` para gestionar la validación del formulario.

## Archivo Modificado
- `/lib/Screen/Reservation/ReservationCalendarScreen.dart`

## Consideraciones de Seguridad
- La contraseña está definida como una constante en el código. En una implementación más segura, esta debería estar almacenada de forma cifrada o gestionada a través de un sistema de autenticación.
- En futuras versiones, se podría considerar la implementación de un sistema de roles para determinar quién tiene permiso para cancelar reservaciones.
