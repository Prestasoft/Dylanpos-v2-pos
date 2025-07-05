#!/usr/bin/env node

/**
 * Script para validar métodos de pago en Firebase Realtime Database
 * 
 * Este script se conecta directamente a Firebase y extrae información
 * sobre los métodos de pago utilizados en las transacciones.
 * 
 * Uso:
 *   node validador_metodo_pago_console.js
 *
 * Creado: 8 de agosto de 2025
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const readline = require('readline');

// Configuración
const CONFIG = {
  projectId: 'dylanpos-victorfoto-stodgo',
  userId: null, // Se llenará durante la ejecución
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
      console.log(colorText('✓ Autenticado en Firebase como miguelcastillo@prestasoft.do', 'green'));
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

// Función para iniciar sesión en Firebase
function firebaseLogin() {
  console.log(colorText('\nIniciando sesión en Firebase...', 'blue'));
  try {
    execSync('firebase login', { stdio: 'inherit' });
    return checkFirebaseAuth();
  } catch (error) {
    console.error(colorText('Error al iniciar sesión:', 'red'), error.message);
    return false;
  }
}

// Función para seleccionar el proyecto de Firebase
function selectFirebaseProject() {
  console.log(colorText('\nSeleccionando proyecto Firebase...', 'blue'));
  try {
    execSync(`firebase use ${CONFIG.projectId}`, { stdio: 'inherit' });
    console.log(colorText(`✓ Proyecto seleccionado: ${CONFIG.projectId}`, 'green'));
    return true;
  } catch (error) {
    console.error(colorText(`✗ Error al seleccionar proyecto ${CONFIG.projectId}:`, 'red'), error.message);
    return false;
  }
}

// Función para consultar el ID de usuario
function getUserId() {
  return new Promise((resolve) => {
    rl.question(colorText('\nPor favor, ingrese el ID de usuario de Firebase (probablemente es el UID del usuario autenticado):\n> ', 'cyan'), (answer) => {
      if (answer.trim()) {
        CONFIG.userId = answer.trim();
        console.log(colorText(`✓ ID de usuario establecido: ${CONFIG.userId}`, 'green'));
        resolve(true);
      } else {
        console.log(colorText('⚠️ El ID de usuario es obligatorio para consultar las transacciones correctamente.', 'yellow'));
        console.log(colorText('Para encontrar el ID de usuario, puede revisar:', 'yellow'));
        console.log(colorText('1. En la aplicación, revise las preferencias compartidas donde se guarda "userId"', 'yellow'));
        console.log(colorText('2. Si es un usuario normal, el ID es el UID de Firebase Auth', 'yellow'));
        console.log(colorText('3. Si es un sub-usuario, el ID está en Admin Panel/User Role', 'yellow'));
        getUserId(); // Preguntar de nuevo
      }
    });
  });
}

// Función para exportar datos de Firebase
async function exportFirebaseData() {
  console.log(colorText('\nExportando datos de Firebase...', 'blue'));
  const outputPath = path.join(CONFIG.outputDir, 'firebase_sales_data.json');
  
  try {
    // Preparar el comando para exportar solo la sección de ventas del usuario específico
    const exportCommand = `firebase database:get "/${CONFIG.userId}/${CONFIG.dataPath}" -o "${outputPath}"`;
    console.log(colorText(`Ejecutando: ${exportCommand}`, 'yellow'));
    
    execSync(exportCommand, { stdio: 'inherit' });
    
    if (fs.existsSync(outputPath)) {
      console.log(colorText(`✓ Datos exportados correctamente a: ${outputPath}`, 'green'));
      return outputPath;
    } else {
      throw new Error('Archivo de salida no encontrado después de la exportación');
    }
  } catch (error) {
    console.error(colorText('✗ Error al exportar datos:', 'red'), error.message);
    return null;
  }
}

// Función para analizar los datos exportados
function analyzePaymentMethods(dataPath) {
  console.log(colorText('\nAnalizando métodos de pago...', 'blue'));
  
  try {
    // Leer el archivo JSON exportado
    const rawData = fs.readFileSync(dataPath, 'utf8');
    const salesData = JSON.parse(rawData);
    
    if (!salesData || Object.keys(salesData).length === 0) {
      console.log(colorText('! No se encontraron datos de ventas', 'yellow'));
      return;
    }
    
    // Contadores y estadísticas
    const stats = {
      totalSales: 0,
      paymentMethods: {},
      missingPaymentMethod: 0,
      salesByDate: {}
    };
    
    // Procesar cada transacción
    Object.keys(salesData).forEach(saleId => {
      const sale = salesData[saleId];
      stats.totalSales++;
      
      // Registrar método de pago
      const paymentType = sale.paymentType || 'NO DEFINIDO';
      stats.paymentMethods[paymentType] = (stats.paymentMethods[paymentType] || 0) + 1;
      
      if (!sale.paymentType) {
        stats.missingPaymentMethod++;
      }
      
      // Agrupar por fecha
      const saleDate = new Date(sale.purchaseDate || '').toISOString().split('T')[0];
      if (!stats.salesByDate[saleDate]) {
        stats.salesByDate[saleDate] = {
          total: 0,
          methods: {}
        };
      }
      stats.salesByDate[saleDate].total++;
      stats.salesByDate[saleDate].methods[paymentType] = (stats.salesByDate[saleDate].methods[paymentType] || 0) + 1;
    });
    
    // Mostrar resultados
    console.log(colorText('\n=== RESULTADOS DEL ANÁLISIS ===', 'cyan'));
    console.log(colorText(`Total de ventas analizadas: ${stats.totalSales}`, 'white'));
    
    console.log(colorText('\nMétodos de pago utilizados:', 'cyan'));
    Object.keys(stats.paymentMethods).sort().forEach(method => {
      const count = stats.paymentMethods[method];
      const percentage = ((count / stats.totalSales) * 100).toFixed(2);
      
      if (method === 'NO DEFINIDO') {
        console.log(colorText(`  - ${method}: ${count} (${percentage}%)`, 'red'));
      } else {
        console.log(colorText(`  - ${method}: ${count} (${percentage}%)`, 'white'));
      }
    });
    
    if (stats.missingPaymentMethod > 0) {
      const missingPercentage = ((stats.missingPaymentMethod / stats.totalSales) * 100).toFixed(2);
      console.log(colorText(`\nATENCIÓN: Se encontraron ${stats.missingPaymentMethod} ventas (${missingPercentage}%) sin método de pago definido`, 'red'));
      console.log(colorText('Esto podría indicar un problema en el proceso de guardado del método de pago', 'yellow'));
    } else {
      console.log(colorText('\n✓ Todas las ventas tienen un método de pago correctamente definido', 'green'));
    }
    
    // Guardar informe detallado
    const reportPath = path.join(CONFIG.outputDir, 'informe_metodos_pago.json');
    fs.writeFileSync(reportPath, JSON.stringify(stats, null, 2));
    console.log(colorText(`\nInforme detallado guardado en: ${reportPath}`, 'green'));
    
    // Crear informe HTML para mejor visualización
    createHtmlReport(stats, salesData);
    
  } catch (error) {
    console.error(colorText('✗ Error al analizar los datos:', 'red'), error.message);
  }
}

// Función para crear un informe HTML
function createHtmlReport(stats, salesData) {
  const reportPath = path.join(CONFIG.outputDir, 'informe_metodos_pago.html');
  
  // Generar contenido HTML
  let html = `
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Informe de Métodos de Pago - DylanPOS</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 20px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
            border-radius: 5px;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .header {
            background: #3498db;
            color: white;
            padding: 20px;
            border-radius: 5px 5px 0 0;
            margin-bottom: 20px;
        }
        .resumen {
            background: #e8f4fd;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            border: 1px solid #bce8f1;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 10px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
            font-weight: bold;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        tr:hover {
            background-color: #f1f1f1;
        }
        .problematica {
            background-color: #ffebee !important;
        }
        .problematica:hover {
            background-color: #ffcdd2 !important;
        }
        .chart-container {
            margin: 20px 0;
            height: 300px;
        }
        .footer {
            margin-top: 40px;
            text-align: center;
            color: #777;
            font-size: 12px;
        }
        .error {
            color: #d9534f;
        }
        .success {
            color: #5cb85c;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Informe de Métodos de Pago - DylanPOS</h1>
            <p>Proyecto: ${CONFIG.projectId} | Usuario: ${CONFIG.userId}</p>
        </div>
        
        <div class="resumen">
            <h2>Resumen</h2>
            <p><strong>Total de ventas analizadas:</strong> ${stats.totalSales}</p>
            <p><strong>Ventas sin método de pago:</strong> 
                ${stats.missingPaymentMethod > 0 
                  ? `<span class="error">${stats.missingPaymentMethod} (${((stats.missingPaymentMethod / stats.totalSales) * 100).toFixed(2)}%)</span>` 
                  : `<span class="success">0 (0.00%)</span>`}
            </p>
            <p><strong>Estado del sistema:</strong> 
                ${stats.missingPaymentMethod > 0 
                  ? '<span class="error">⚠️ Hay transacciones sin método de pago definido</span>' 
                  : '<span class="success">✅ Todos los métodos de pago están correctamente definidos</span>'}
            </p>
        </div>
        
        <h2>Métodos de Pago Utilizados</h2>
        <table>
            <thead>
                <tr>
                    <th>Método de Pago</th>
                    <th>Cantidad</th>
                    <th>Porcentaje</th>
                </tr>
            </thead>
            <tbody>
  `;
  
  // Agregar filas para cada método de pago
  Object.keys(stats.paymentMethods).sort().forEach(method => {
    const count = stats.paymentMethods[method];
    const percentage = ((count / stats.totalSales) * 100).toFixed(2);
    const isProblematic = method === 'NO DEFINIDO';
    
    html += `
                <tr${isProblematic ? ' class="problematica"' : ''}>
                    <td>${method}</td>
                    <td>${count}</td>
                    <td>${percentage}%</td>
                </tr>
    `;
  });
  
  // Continuar con el resto del HTML
  html += `
            </tbody>
        </table>
        
        <h2>Transacciones Recientes</h2>
        <table>
            <thead>
                <tr>
                    <th>Fecha</th>
                    <th>Factura #</th>
                    <th>Cliente</th>
                    <th>Total</th>
                    <th>Método de Pago</th>
                </tr>
            </thead>
            <tbody>
  `;
  
  // Agregar las 20 transacciones más recientes
  const recentSales = Object.keys(salesData)
    .map(key => ({ id: key, ...salesData[key] }))
    .sort((a, b) => new Date(b.purchaseDate || 0) - new Date(a.purchaseDate || 0))
    .slice(0, 20);
  
  recentSales.forEach(sale => {
    const isProblematic = !sale.paymentType;
    const date = new Date(sale.purchaseDate || '').toLocaleString();
    
    html += `
                <tr${isProblematic ? ' class="problematica"' : ''}>
                    <td>${date}</td>
                    <td>${sale.invoiceNumber || 'N/A'}</td>
                    <td>${sale.customerName || 'N/A'}</td>
                    <td>RD$ ${sale.totalAmount?.toLocaleString('es-DO', { minimumFractionDigits: 2 }) || '0.00'}</td>
                    <td>${sale.paymentType || '<span class="error">NO DEFINIDO</span>'}</td>
                </tr>
    `;
  });
  
  // Finalizar el HTML
  html += `
            </tbody>
        </table>
        
        <div class="footer">
            <p>Informe generado el: ${new Date().toLocaleString()}</p>
            <p>Validador de Métodos de Pago v2.0 - DylanPOS</p>
        </div>
    </div>
</body>
</html>
  `;
  
  // Guardar el archivo HTML
  fs.writeFileSync(reportPath, html);
  console.log(colorText(`\nInforme HTML generado en: ${reportPath}`, 'green'));
  console.log(colorText('Puede abrir este archivo en su navegador para una mejor visualización', 'cyan'));
}

// Función principal
async function main() {
  console.log(colorText('\n===============================================', 'blue'));
  console.log(colorText('  VALIDADOR DE MÉTODOS DE PAGO - MODO CONSOLA  ', 'blue'));
  console.log(colorText('===============================================\n', 'blue'));
  
  // Verificar requisitos
  if (!checkFirebaseCLI()) {
    console.log(colorText('\nInstalando Firebase CLI...', 'yellow'));
    try {
      execSync('npm install -g firebase-tools', { stdio: 'inherit' });
      console.log(colorText('✓ Firebase CLI instalado correctamente', 'green'));
    } catch (error) {
      console.error(colorText('✗ No se pudo instalar Firebase CLI. Por favor, instálelo manualmente.', 'red'));
      process.exit(1);
    }
  }
  
  // Verificar autenticación
  if (!checkFirebaseAuth()) {
    if (!firebaseLogin()) {
      console.error(colorText('✗ No se pudo iniciar sesión en Firebase. Abortando.', 'red'));
      process.exit(1);
    }
  }
  
  // Seleccionar proyecto
  if (!selectFirebaseProject()) {
    console.error(colorText('✗ No se pudo seleccionar el proyecto Firebase. Abortando.', 'red'));
    process.exit(1);
  }
  
  // Obtener ID de usuario
  await getUserId();
  
  // Exportar datos
  const dataPath = await exportFirebaseData();
  if (!dataPath) {
    console.error(colorText('✗ No se pudieron exportar los datos. Abortando.', 'red'));
    process.exit(1);
  }
  
  // Analizar datos
  analyzePaymentMethods(dataPath);
  
  // Finalizar
  console.log(colorText('\n✓ Análisis completado con éxito', 'green'));
  rl.close();
}

// Ejecutar el programa
main().catch(error => {
  console.error(colorText('Error en la ejecución:', 'red'), error);
  process.exit(1);
});
