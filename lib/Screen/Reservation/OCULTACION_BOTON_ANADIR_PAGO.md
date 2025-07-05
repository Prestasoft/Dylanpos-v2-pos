# Ocultación del Botón "Añadir Pago" en Detalles de Reservación

## Descripción
Se ha ocultado el botón "Añadir Pago" en la vista de detalles de reservación. Este botón anteriormente aparecía cuando un cliente tenía un balance pendiente, permitiéndole al usuario registrar un pago para dicho cliente directamente desde la vista de detalles de la reservación.

## Cambios Realizados
1. Eliminación del botón `ElevatedButton.icon` con la etiqueta "Añadir Pago" del archivo `ReservationCalendarScreen.dart`.
2. Se mantiene el mensaje de alerta que indica que el cliente tiene un balance pendiente.
3. Eliminación del import no utilizado `../Due List/due_popUp.dart` que se usaba para el modal de pago.

## Razón del Cambio
La funcionalidad de añadir pagos ahora solo debe estar disponible desde la sección de Cuentas por Cobrar, para mantener una separación clara de responsabilidades en la aplicación y evitar posibles inconsistencias en el registro de pagos.

## Archivo Modificado
- `/lib/Screen/Reservation/ReservationCalendarScreen.dart`

## Impacto
- Los usuarios ya no podrán añadir pagos directamente desde la vista de detalles de reservación.
- Los clientes con balance pendiente seguirán siendo identificados con un mensaje de alerta en esta pantalla.
- Para registrar pagos, los usuarios deberán dirigirse a la sección de Cuentas por Cobrar.
