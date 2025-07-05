#!/bin/bash

# Script para verificar el método de pago en la última transacción
# Usa la API REST de Firebase para consultar directamente

echo "=== Verificador de Método de Pago en Transacciones ==="

# Función para solicitar el ID de usuario y API Key si no están configurados
setup_credentials() {
  echo "Para usar este script, necesita sus credenciales de Firebase."
  echo "Estas credenciales se guardarán localmente para futuras ejecuciones."
  
  read -p "Ingrese el ID de usuario de Firebase: " FIREBASE_USER_ID
  read -p "Ingrese la API Key de Firebase (opcional, solo para bases de datos con reglas de seguridad): " FIREBASE_API_KEY
  
  # Guardar configuración
  echo "FIREBASE_USER_ID=$FIREBASE_USER_ID" > ~/.firebase_validation_config
  echo "FIREBASE_API_KEY=$FIREBASE_API_KEY" >> ~/.firebase_validation_config
  
  echo "Credenciales guardadas en ~/.firebase_validation_config"
}

# Cargar configuración si existe
if [ -f ~/.firebase_validation_config ]; then
  source ~/.firebase_validation_config
else
  setup_credentials
fi

# Verificar si tenemos la información necesaria
if [ -z "$FIREBASE_USER_ID" ]; then
  echo "Error: ID de usuario de Firebase no configurado."
  setup_credentials
fi

# URL de la base de datos Firebase
FIREBASE_URL="https://dylanpos-v2-default-rtdb.firebaseio.com/${FIREBASE_USER_ID}/Sales Transition.json"

# Añadir autenticación si se proporcionó una API key
if [ ! -z "$FIREBASE_API_KEY" ]; then
  FIREBASE_URL="${FIREBASE_URL}?auth=${FIREBASE_API_KEY}"
fi

echo "Consultando las últimas transacciones..."

# Realizar la consulta a Firebase
RESPONSE=$(curl -s "$FIREBASE_URL?orderBy=\"purchaseDate\"&limitToLast=5")

# Verificar si hubo un error
if [[ $RESPONSE == *"error"* ]]; then
  echo "Error al consultar Firebase: $RESPONSE"
  exit 1
fi

# Procesar la respuesta
echo "Últimas transacciones encontradas:"
echo "--------------------------------"

# Imprimir la información de método de pago para cada transacción
echo "$RESPONSE" | python3 -c '
import sys, json
data = json.load(sys.stdin)
if not data:
    print("No se encontraron transacciones")
    sys.exit(0)

# Ordenar por fecha de compra (de más reciente a más antigua)
sorted_keys = sorted(data.keys(), key=lambda k: data[k].get("purchaseDate", ""), reverse=True)

for i, key in enumerate(sorted_keys[:5], 1):
    transaction = data[key]
    print(f"{i}. Factura #{transaction.get(\"invoiceNumber\", \"N/A\")}")
    print(f"   Cliente: {transaction.get(\"customerName\", \"N/A\")}")
    print(f"   Fecha: {transaction.get(\"purchaseDate\", \"N/A\")}")
    print(f"   Método de pago: {transaction.get(\"paymentType\", \"No especificado\")}")
    print(f"   Monto: {transaction.get(\"totalAmount\", \"N/A\")}")
    print("--------------------------------")
'

echo ""
echo "Para validar el método de pago:"
echo "1. Verifique que el método de pago mostrado para la transacción más reciente"
echo "   coincide con el que seleccionó durante la venta."
echo "2. Si no coincide, revise el código de asignación en inventory_sales.dart"
echo ""
