#!/bin/bash

# Script para generar un informe HTML de los métodos de pago
# Creado el: 5 de julio de 2025

echo "==================================="
echo "GENERADOR DE INFORME DE MÉTODOS DE PAGO"
echo "==================================="
echo ""

# Directorio actual del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
cd ../..

# Obtener fecha actual para el nombre del archivo
FECHA_ACTUAL=$(date +"%Y-%m-%d_%H-%M-%S")
ARCHIVO_SALIDA="/tmp/informe_metodos_pago_${FECHA_ACTUAL}.html"

# Usar la Firebase CLI para consultar la base de datos
echo "Consultando Firebase... (puede tardar unos segundos)"
echo ""

# Crear un script temporal para procesar los datos
TMP_SCRIPT="/tmp/generar_informe_metodos_pago.js"

cat > "$TMP_SCRIPT" << 'EOL'
const fs = require('fs');
const data = JSON.parse(fs.readFileSync(0, 'utf-8'));

// Obtener fecha actual formateada
const fechaActual = new Date().toLocaleString('es-ES');

// Verificar si hay datos
if (!data || !data.Sales || !data.Sales.Transition) {
  console.error('No se encontraron datos de ventas');
  process.exit(1);
}

// Preparar el HTML
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
        .filters {
            background: #f9f9f9;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            border: 1px solid #ddd;
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
        .resumen {
            background: #e8f4fd;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            border: 1px solid #bce8f1;
        }
        .metodo-pago {
            font-weight: bold;
        }
        .error {
            color: #d9534f;
        }
        .success {
            color: #5cb85c;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            font-size: 0.8em;
            color: #777;
        }
        .badge {
            display: inline-block;
            padding: 3px 7px;
            border-radius: 10px;
            font-size: 12px;
            font-weight: bold;
            color: white;
        }
        .badge-error {
            background-color: #d9534f;
        }
        .badge-success {
            background-color: #5cb85c;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Informe de Métodos de Pago - DylanPOS</h1>
            <p>Generado el: ${fechaActual}</p>
        </div>
        
        <div class="resumen" id="resumen">
            <h2>Resumen</h2>
            <div id="resumen-contenido">
                <!-- Se llenará dinámicamente -->
            </div>
        </div>
        
        <div class="filters">
            <h3>Filtros</h3>
            <div style="display: flex; gap: 10px; flex-wrap: wrap;">
                <div>
                    <label for="fecha-inicio">Fecha Inicio:</label>
                    <input type="date" id="fecha-inicio">
                </div>
                <div>
                    <label for="fecha-fin">Fecha Fin:</label>
                    <input type="date" id="fecha-fin">
                </div>
                <div>
                    <label for="metodo-pago">Método de Pago:</label>
                    <select id="metodo-pago">
                        <option value="">Todos</option>
                        <option value="Efectivo">Efectivo</option>
                        <option value="Tarjeta">Tarjeta</option>
                        <option value="Transferencia">Transferencia</option>
                        <option value="Mixto">Mixto</option>
                        <option value="Unknown">Unknown</option>
                        <option value="problematico">Problemáticos</option>
                    </select>
                </div>
                <div>
                    <label for="buscar-factura">Buscar Factura:</label>
                    <input type="text" id="buscar-factura" placeholder="Número de factura">
                </div>
                <div>
                    <button onclick="aplicarFiltros()" style="margin-top: 20px; padding: 5px 10px;">Aplicar Filtros</button>
                    <button onclick="resetearFiltros()" style="margin-top: 20px; padding: 5px 10px;">Resetear</button>
                </div>
            </div>
        </div>
        
        <h2>Listado de Transacciones</h2>
        <div style="overflow-x: auto;">
            <table id="tabla-ventas">
                <thead>
                    <tr>
                        <th>Factura</th>
                        <th>Fecha</th>
                        <th>Cliente</th>
                        <th>Monto</th>
                        <th>Método de Pago</th>
                        <th>Estado</th>
                    </tr>
                </thead>
                <tbody>
                    <!-- Se llenará dinámicamente -->
                </tbody>
            </table>
        </div>
        
        <div class="footer">
            <p>DylanPOS - Sistema de Verificación de Métodos de Pago</p>
        </div>
    </div>
    
    <script>
        // Datos de ventas
        const ventas = [];
        
        // Procesar los datos
        function procesarDatos() {
            let total = 0;
            let problematicas = 0;
            
            // Convertir datos de Firebase a array
            ${procesarDatosFirebase()}
            
            // Actualizar resumen
            actualizarResumen(total, problematicas);
            
            // Mostrar datos en la tabla
            mostrarDatos(ventas);
        }
        
        // Actualizar el resumen
        function actualizarResumen(total, problematicas) {
            const porcentajeProblematicas = ((problematicas / total) * 100).toFixed(2);
            
            document.getElementById('resumen-contenido').innerHTML = `
                <p><strong>Total de ventas:</strong> ${total}</p>
                <p><strong>Ventas con método de pago problemático:</strong> 
                   ${problematicas} (${porcentajeProblematicas}%)
                   <span class="badge ${problematicas > 0 ? 'badge-error' : 'badge-success'}">
                       ${problematicas > 0 ? 'Atención requerida' : 'Todo en orden'}
                   </span>
                </p>
            `;
        }
        
        // Mostrar datos en la tabla
        function mostrarDatos(datos) {
            const tbody = document.querySelector('#tabla-ventas tbody');
            tbody.innerHTML = '';
            
            if (datos.length === 0) {
                tbody.innerHTML = '<tr><td colspan="6" style="text-align: center;">No se encontraron ventas con los filtros aplicados</td></tr>';
                return;
            }
            
            datos.forEach(venta => {
                const esProblematica = !venta.metodoPago || venta.metodoPago === 'Unknown' || venta.metodoPago === '';
                
                const row = document.createElement('tr');
                if (esProblematica) {
                    row.classList.add('problematica');
                }
                
                row.innerHTML = `
                    <td>${venta.factura}</td>
                    <td>${venta.fecha}</td>
                    <td>${venta.cliente}</td>
                    <td>RD$ ${venta.monto.toFixed(2)}</td>
                    <td class="metodo-pago ${esProblematica ? 'error' : 'success'}">${venta.metodoPago || 'NO DEFINIDO'}</td>
                    <td>${venta.estado}</td>
                `;
                
                tbody.appendChild(row);
            });
        }
        
        // Aplicar filtros
        function aplicarFiltros() {
            const fechaInicio = document.getElementById('fecha-inicio').value ? new Date(document.getElementById('fecha-inicio').value) : null;
            const fechaFin = document.getElementById('fecha-fin').value ? new Date(document.getElementById('fecha-fin').value + 'T23:59:59') : null;
            const metodoPago = document.getElementById('metodo-pago').value;
            const buscarFactura = document.getElementById('buscar-factura').value.trim();
            
            let datosFiltrados = [...ventas];
            
            // Filtrar por fecha
            if (fechaInicio) {
                datosFiltrados = datosFiltrados.filter(venta => new Date(venta.fechaRaw) >= fechaInicio);
            }
            
            if (fechaFin) {
                datosFiltrados = datosFiltrados.filter(venta => new Date(venta.fechaRaw) <= fechaFin);
            }
            
            // Filtrar por método de pago
            if (metodoPago) {
                if (metodoPago === 'problematico') {
                    datosFiltrados = datosFiltrados.filter(venta => 
                        !venta.metodoPago || venta.metodoPago === 'Unknown' || venta.metodoPago === '');
                } else {
                    datosFiltrados = datosFiltrados.filter(venta => venta.metodoPago === metodoPago);
                }
            }
            
            // Filtrar por número de factura
            if (buscarFactura) {
                datosFiltrados = datosFiltrados.filter(venta => 
                    venta.factura.toString().includes(buscarFactura));
            }
            
            // Actualizar tabla
            mostrarDatos(datosFiltrados);
            
            // Actualizar resumen con datos filtrados
            const problematicas = datosFiltrados.filter(venta => 
                !venta.metodoPago || venta.metodoPago === 'Unknown' || venta.metodoPago === '').length;
                
            actualizarResumen(datosFiltrados.length, problematicas);
        }
        
        // Resetear filtros
        function resetearFiltros() {
            document.getElementById('fecha-inicio').value = '';
            document.getElementById('fecha-fin').value = '';
            document.getElementById('metodo-pago').value = '';
            document.getElementById('buscar-factura').value = '';
            
            // Mostrar todos los datos nuevamente
            mostrarDatos(ventas);
            
            // Actualizar resumen con todos los datos
            const problematicas = ventas.filter(venta => 
                !venta.metodoPago || venta.metodoPago === 'Unknown' || venta.metodoPago === '').length;
                
            actualizarResumen(ventas.length, problematicas);
        }
        
        // Inicializar
        document.addEventListener('DOMContentLoaded', procesarDatos);
    </script>
</body>
</html>
`;

// Función para procesar los datos de Firebase
function procesarDatosFirebase() {
  let code = 'try {\n';
  code += '  const ventasFirebase = data.Sales.Transition;\n';
  code += '  let total = 0;\n';
  code += '  let problematicas = 0;\n\n';
  
  code += '  Object.entries(ventasFirebase).forEach(([key, venta]) => {\n';
  code += '    total++;\n';
  code += '    const fechaVenta = new Date(venta.purchaseDate);\n';
  code += '    const metodoPago = venta.paymentType || "";\n\n';
  
  code += '    // Verificar si el método de pago es problemático\n';
  code += '    if (!metodoPago || metodoPago === "Unknown" || metodoPago === "") {\n';
  code += '      problematicas++;\n';
  code += '    }\n\n';
  
  code += '    // Agregar a la lista de ventas\n';
  code += '    ventas.push({\n';
  code += '      id: key,\n';
  code += '      factura: venta.invoiceNumber,\n';
  code += '      fechaRaw: venta.purchaseDate,\n';
  code += '      fecha: fechaVenta.toLocaleString("es-ES"),\n';
  code += '      cliente: venta.customerName,\n';
  code += '      telefono: venta.customerPhone,\n';
  code += '      monto: venta.totalAmount || 0,\n';
  code += '      metodoPago: metodoPago,\n';
  code += '      estado: venta.isPaid ? "PAGADO" : "PENDIENTE"\n';
  code += '    });\n';
  code += '  });\n\n';
  
  code += '  // Ordenar por fecha (más recientes primero)\n';
  code += '  ventas.sort((a, b) => new Date(b.fechaRaw) - new Date(a.fechaRaw));\n\n';
  
  code += '  return total + "; " + problematicas;\n';
  code += '} catch (error) {\n';
  code += '  console.error("Error al procesar datos:", error);\n';
  code += '  return "0; 0";\n';
  code += '}';
  
  return code;
}

fs.writeFileSync(process.env.ARCHIVO_SALIDA, html);
console.log(`Informe generado correctamente en: ${process.env.ARCHIVO_SALIDA}`);
EOL

# Ejecutar el comando y procesar los resultados
firebase database:get / --pretty > /tmp/firebase_data_temp.json
ARCHIVO_SALIDA="$ARCHIVO_SALIDA" node "$TMP_SCRIPT" < /tmp/firebase_data_temp.json

# Abrir el archivo en el navegador predeterminado
echo ""
echo "Abriendo informe en el navegador..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  open "$ARCHIVO_SALIDA"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Linux
  xdg-open "$ARCHIVO_SALIDA"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  # Windows
  start "$ARCHIVO_SALIDA"
else
  echo "No se pudo abrir automáticamente. El informe está disponible en:"
  echo "$ARCHIVO_SALIDA"
fi

# Limpiar archivos temporales
rm "$TMP_SCRIPT"
rm /tmp/firebase_data_temp.json

echo ""
echo "==================================="
echo "PROCESO COMPLETADO"
echo "==================================="
echo ""
echo "El informe ha sido generado en: $ARCHIVO_SALIDA"
echo ""
