#!/bin/bash

# Script para verificar el método de pago de una factura específica (versión simplificada)
# Creado el: 5 de julio de 2025

echo "==================================="
echo "VERIFICADOR DE MÉTODO DE PAGO POR FACTURA"
echo "==================================="
echo ""

# Verificar si se proporcionó un número de factura
if [ -z "$1" ]; then
  echo "Uso: $0 <número_de_factura>"
  echo ""
  echo "Ejemplo: $0 12345"
  exit 1
fi

# Establecer el número de factura
FACTURA="$1"
echo "Buscando factura número: $FACTURA"
echo ""

# Directorio actual del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
cd ../..

# Usar la Firebase CLI para consultar la base de datos
# Nota: Debes tener configurada la Firebase CLI con 'firebase login'
echo "Consultando Firebase... (puede tardar unos segundos)"
echo ""

# Crear un script temporal para procesar los datos
TMP_SCRIPT="/tmp/procesar_factura_${FACTURA}.js"

cat > "$TMP_SCRIPT" << 'EOL'
const fs = require('fs');
const data = JSON.parse(fs.readFileSync(0, 'utf-8'));

// Obtener el número de factura desde el argumento
const invoiceNumber = process.env.FACTURA_NUM;

if (!data || !data.Sales || !data.Sales.Transition) {
  console.error('No se encontraron datos de ventas');
  process.exit(1);
}

// Buscar la factura
let found = false;
let total = 0;
let problematicas = 0;

Object.entries(data.Sales.Transition).forEach(([key, venta]) => {
  total++;
  
  // Verificar el método de pago
  if (!venta.paymentType || venta.paymentType === 'Unknown' || venta.paymentType === '') {
    problematicas++;
  }
  
  // Si coincide con la factura buscada
  if (venta.invoiceNumber === invoiceNumber) {
    found = true;
    
    const fechaVenta = new Date(venta.purchaseDate);
    const formatoFecha = fechaVenta.toLocaleString('es-ES');
    
    console.log('=================================');
    console.log(`INFORMACIÓN DE LA FACTURA #${venta.invoiceNumber}`);
    console.log('=================================');
    console.log(`ID: ${key}`);
    console.log(`Cliente: ${venta.customerName}`);
    console.log(`Teléfono: ${venta.customerPhone}`);
    console.log(`Fecha: ${formatoFecha}`);
    console.log(`Monto total: RD$ ${venta.totalAmount.toFixed(2)}`);
    console.log(`Método de pago: ${venta.paymentType || "NO DEFINIDO"}`);
    console.log(`Estado de pago: ${venta.isPaid ? "PAGADO" : "PENDIENTE"}`);
    
    if (venta.dueAmount > 0) {
      console.log(`Monto pendiente: RD$ ${venta.dueAmount.toFixed(2)}`);
    }
    
    console.log('=================================');
    
    // Evaluar si hay problemas con el método de pago
    if (!venta.paymentType || venta.paymentType === 'Unknown' || venta.paymentType === '') {
      console.log('⚠️  ADVERTENCIA: Esta factura no tiene un método de pago definido correctamente');
    } else {
      console.log('✅ Método de pago correctamente registrado');
    }
  }
});

if (!found) {
  console.log(`⚠️  No se encontró ninguna factura con el número ${invoiceNumber}`);
}

console.log('\n=================================');
console.log('RESUMEN GENERAL');
console.log('=================================');
console.log(`Total de ventas en el sistema: ${total}`);
console.log(`Ventas con método de pago problemático: ${problematicas} (${((problematicas/total)*100).toFixed(2)}%)`);
console.log('=================================');
EOL

# Buscar la ruta de acceso al archivo de base de datos
echo "Exportando datos desde Firebase..."
echo ""

# Ejecutar el comando y procesar los resultados
firebase database:get / --pretty > /tmp/firebase_data_temp.json
FACTURA_NUM="$FACTURA" node "$TMP_SCRIPT" < /tmp/firebase_data_temp.json

# Limpiar archivos temporales
rm "$TMP_SCRIPT"
rm /tmp/firebase_data_temp.json
