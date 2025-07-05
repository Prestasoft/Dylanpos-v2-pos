# Implementación de Leyenda de Colores en Calendario de Reservaciones

## Descripción
Se ha agregado una leyenda visual que muestra el significado de cada color utilizado en el calendario de reservaciones. Esta mejora permite a los usuarios identificar rápidamente qué tipo de evento está programado en cada fecha sin necesidad de abrir el detalle de la reservación.

## Cambios Realizados
1. Se agregó un contenedor con la leyenda de colores justo debajo de los botones de formato del calendario (Día, Semana, Mes).
2. La leyenda incluye los siguientes colores y sus significados:
   - **Verde**: Renta
   - **Ámbar**: Fiesta
   - **Azul**: Estudio
   - **Púrpura**: Exterior
3. Se mejoró la visualización con un fondo gris claro y espaciado adecuado para una mejor legibilidad.
4. Se implementó un método auxiliar `_buildLegendItem` que construye cada elemento de la leyenda con un círculo de color y su etiqueta correspondiente.

## Beneficios
- Mayor claridad visual para los usuarios al interpretar los eventos del calendario.
- Reducción de la necesidad de abrir detalles para identificar tipos de eventos.
- Mejora en la experiencia general del usuario al navegar por el calendario de reservaciones.

## Archivo Modificado
- `/lib/Screen/Reservation/ReservationCalendarScreen.dart`

## Notas Técnicas
Los colores utilizados en la leyenda coinciden exactamente con los colores asignados a los eventos en el método `markerBuilder` del calendario, asegurando consistencia visual en toda la aplicación.
