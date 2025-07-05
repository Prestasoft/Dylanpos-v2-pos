#!/bin/bash

# Script para validar que el método de pago se guarda correctamente
# en las transacciones de ventas de inventario

echo "=== Validador de Método de Pago ==="
echo "Este script ejecutará una aplicación Flutter para verificar que el método de pago"
echo "seleccionado durante una venta se guarda correctamente en Firebase."
echo ""

# Verificar si el Flutter está disponible
if ! command -v flutter &> /dev/null; then
    echo "Flutter no está instalado o no está en el PATH. Por favor, instale Flutter primero."
    exit 1
fi

echo "Ejecutando validador de método de pago..."
echo "Por favor, asegúrese de haber realizado una venta con un método de pago específico"
echo "antes de ejecutar esta verificación."
echo ""

# Ejecutar la aplicación de validación
flutter run -d chrome --web-renderer html --target=lib/Screen/Inventory\ Sales/validacion_metodo_pago.dart

# Nota: También puedes ejecutarlo en dispositivos móviles cambiando -d chrome por el ID del dispositivo
# flutter devices # Para ver los dispositivos disponibles
