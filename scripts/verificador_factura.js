#!/usr/bin/env node

/**
 * Verificador de Método de Pago por Número de Factura
 * 
 * Este script permite buscar una factura específica por su número
 * y mostrar información detallada, incluyendo el método de pago utilizado.
 * 
 * Uso:
 *   node verificador_factura.js [número de factura]
 * 
 * Ejemplo:
 *   node verificador_factura.js 12345
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const readline = require('readline');

// Configuración
const CONFIG = {
  projectId: 'dylanpos-victorfoto-stodgo',
  userId: '1sNp9iHiGKRxpmqgNsr2S5712uw2', // El ID que usamos anteriormente
  dataPath: 'Sales Transition', // Ruta en Firebase donde están las transacciones
  outputDir: path.join(__dirname, 'output')
};

// Crear directorio de salida si no existe
if (!fs.existsSync(CONFIG.outputDir)) {
  fs.mkdirSync(CONFIG.outputDir, { recursive: true });
}

// Función para mostrar texto con colores
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  white: '\x1b[37m'
};

function colorText(text, color) {
  return `${colors[color]}${text}${colors.reset}`;
}

// Interfaz de línea de comandos
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// Función para verificar que Firebase CLI está instalado
function checkFirebaseCLI() {
  try {
    const version = execSync('firebase --version').toString().trim();
    console.log(colorText(`✓ Firebase CLI detectado: ${version}`, 'green'));
    return true;
  } catch (error) {
    console.error(colorText('✗ Firebase CLI no encontrado. Por favor instálelo con: npm install -g firebase-tools', 'red'));
    return false;
  }
}

// Función para verificar que estamos autenticados en Firebase
function checkFirebaseAuth() {
  try {
    const account = execSync('firebase login:list').toString();
    if (account.includes('miguelcastillo@prestasoft.do')) {
      console.log(colorText('✓ Autenticado en Firebase', 'green'));
      return true;
    } else {
      console.log(colorText('! No autenticado con la cuenta esperada', 'yellow'));
      return false;
    }
  } catch (error) {
    console.error(colorText('✗ No autenticado en Firebase', 'red'));
    return false;
  }
}

// Función para buscar una factura por número
async function buscarFactura(numeroFactura) {
  console.log(colorText(`\nBuscando factura número: ${numeroFactura}...`, 'blue'));
  
  // Primero exportamos todas las ventas
  const outputPath = path.join(CONFIG.outputDir, 'firebase_sales_data.json');
  
  try {
    // Exportar datos de Firebase
    const exportCommand = `firebase database:get "/${CONFIG.userId}/${CONFIG.dataPath}" -o "${outputPath}"`;
    console.log(colorText(`Exportando datos: ${exportCommand}`, 'yellow'));
    
    execSync(exportCommand, { stdio: 'inherit' });
    
    if (!fs.existsSync(outputPath)) {
      throw new Error('No se pudo exportar los datos de Firebase');
    }
    
    // Leer el archivo JSON exportado
    const rawData = fs.readFileSync(outputPath, 'utf8');
    const salesData = JSON.parse(rawData);
    
    if (!salesData || Object.keys(salesData).length === 0) {
      console.log(colorText('! No se encontraron datos de ventas', 'yellow'));
      return;
    }
    
    // Buscar la factura por número
    let facturaEncontrada = null;
    let facturaId = null;
    
    Object.keys(salesData).forEach(saleId => {
      const sale = salesData[saleId];
      if (sale.invoiceNumber === numeroFactura || sale.invoiceNumber === parseInt(numeroFactura)) {
        facturaEncontrada = sale;
        facturaId = saleId;
      }
    });
    
    if (facturaEncontrada) {
      console.log(colorText('\n=== FACTURA ENCONTRADA ===', 'green'));
      console.log(colorText(`ID en Firebase: ${facturaId}`, 'white'));
      console.log(colorText(`Número de Factura: ${facturaEncontrada.invoiceNumber}`, 'white'));
      console.log(colorText(`Fecha: ${new Date(facturaEncontrada.purchaseDate || 0).toLocaleString()}`, 'white'));
      console.log(colorText(`Cliente: ${facturaEncontrada.customerName || 'No especificado'}`, 'white'));
      console.log(colorText(`Total: RD$ ${facturaEncontrada.totalAmount?.toLocaleString('es-DO', { minimumFractionDigits: 2 }) || '0.00'}`, 'white'));
      console.log(colorText(`Método de Pago: ${facturaEncontrada.paymentType || 'NO DEFINIDO'}`, 'cyan'));
      
      // Guardar detalles de la factura en un archivo
      const detallesPath = path.join(CONFIG.outputDir, `factura_${numeroFactura}_detalles.json`);
      fs.writeFileSync(detallesPath, JSON.stringify(facturaEncontrada, null, 2));
      console.log(colorText(`\nDetalles completos guardados en: ${detallesPath}`, 'green'));
      
    } else {
      console.log(colorText(`\n✗ No se encontró ninguna factura con el número: ${numeroFactura}`, 'red'));
    }
    
  } catch (error) {
    console.error(colorText('✗ Error al buscar la factura:', 'red'), error.message);
  }
}

// Función principal
async function main() {
  console.log(colorText('\n===============================================', 'blue'));
  console.log(colorText('     VERIFICADOR DE FACTURA - MÉTODO DE PAGO    ', 'blue'));
  console.log(colorText('===============================================\n', 'blue'));
  
  // Verificar requisitos
  if (!checkFirebaseCLI() || !checkFirebaseAuth()) {
    console.error(colorText('✗ No se cumplen los requisitos para continuar', 'red'));
    process.exit(1);
  }
  
  // Obtener número de factura desde argumentos o pedir al usuario
  let numeroFactura = process.argv[2];
  
  if (!numeroFactura) {
    // Si no se proporcionó como argumento, preguntar al usuario
    rl.question(colorText('\nIngrese el número de factura a buscar: ', 'cyan'), async (answer) => {
      if (answer.trim()) {
        await buscarFactura(answer.trim());
      } else {
        console.log(colorText('✗ Debe proporcionar un número de factura válido', 'red'));
      }
      rl.close();
    });
  } else {
    // Si se proporcionó como argumento, usarlo directamente
    await buscarFactura(numeroFactura);
    rl.close();
  }
}

// Ejecutar el programa
main().catch(error => {
  console.error(colorText('Error en la ejecución:', 'red'), error);
  process.exit(1);
});
