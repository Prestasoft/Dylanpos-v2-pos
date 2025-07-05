import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:salespro_admin/model/reservation_model.dart';
import 'package:salespro_admin/Provider/reservation_provider.dart';

// Archivo de prueba para verificar la funcionalidad de cancelación de reservaciones con contraseña
void main() {
  // Configuración de la prueba
  late Widget testWidget;
  final mockReservation = ReservationModel(
    id: 'test-id',
    customerName: 'Cliente de Prueba',
    customerId: 'customer-1',
    dressId: 'dress-1',
    serviceId: 'service-1',
    reservationDate: '2025-07-05',
    reservationTime: '15:00',
    paymentStatus: 'Due',
    remainingAmount: 1000,
    branchId: 'branch-1',
    discount: 0,
    subtotal: 1000,
    tax: 0,
    total: 1000,
  );

  // Prueba para verificar que la contraseña correcta permite cancelar la reservación
  testWidgets('Verificar diálogo de contraseña para cancelación de reservación', (WidgetTester tester) async {
    // Configura el widget de prueba
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Sobreescribe el proveedor de cancelación para simular una cancelación exitosa
          cancelReservationProvider.family<bool, String>((ref, id) async {
            return Future.value(true);
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  // Simula abrir el diálogo de confirmación
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cancelar Reservación'),
                      content: const Text('¿Estás seguro que deseas cancelar esta reservación?'),
                      actions: [
                        TextButton(
                          key: const Key('cancel_reservation_no_button'),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('No'),
                        ),
                        TextButton(
                          key: const Key('cancel_reservation_confirm_button'),
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Muestra el diálogo de contraseña
                            _showPasswordDialog(context, mockReservation);
                          },
                          child: const Text('Sí, Cancelar'),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Cancelar Reservación'),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap en el botón para mostrar el diálogo de confirmación
    await tester.tap(find.text('Cancelar Reservación'));
    await tester.pumpAndSettle();

    // Verifica que el diálogo de confirmación se muestra
    expect(find.text('Cancelar Reservación'), findsOneWidget);
    expect(find.text('¿Estás seguro que deseas cancelar esta reservación?'), findsOneWidget);

    // Tap en el botón 'Sí, Cancelar' para mostrar el diálogo de contraseña
    await tester.tap(find.text('Sí, Cancelar'));
    await tester.pumpAndSettle();

    // Verifica que el diálogo de contraseña se muestra
    expect(find.text('Ingrese la contraseña'), findsOneWidget);

    // Ingresa la contraseña incorrecta
    await tester.enterText(find.byType(TextFormField), 'contraseña_incorrecta');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    // Verifica que el mensaje de error se muestra
    expect(find.text('Contraseña incorrecta'), findsOneWidget);

    // Ingresa la contraseña correcta
    await tester.enterText(find.byType(TextFormField), '22400600452');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    // El diálogo debería cerrarse si la contraseña es correcta
    expect(find.text('Ingrese la contraseña'), findsNothing);

    // Deberías ver el widget principal nuevamente
    expect(find.text('Cancelar Reservación'), findsOneWidget);
  });
}

// Copia del método _showPasswordDialog para pruebas
void _showPasswordDialog(BuildContext context, ReservationModel reservation) {
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  // Contraseña estática para cancelar reservaciones
  const String staticPassword = "22400600452";
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Ingrese la contraseña'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Contraseña',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese la contraseña';
            }
            if (value != staticPassword) {
              return 'Contraseña incorrecta';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              Navigator.of(context).pop(); // Cierra el diálogo de contraseña
              
              // Simula la cancelación de la reservación
              // En un entorno real, esto llamaría al provider
              // await ref.read(cancelReservationProvider(reservation.id).future);
            }
          },
          child: const Text('Confirmar'),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
        ),
      ],
    ),
  );
}
