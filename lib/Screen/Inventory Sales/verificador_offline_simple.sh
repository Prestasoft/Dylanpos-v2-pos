#!/bin/bash

# Script para generar un verificador de métodos de pago HTML estático
# Versión ultra simple - No requiere autenticación de Firebase
# Creado el: 5 de julio de 2025

echo "==================================="
echo "GENERADOR DE VERIFICADOR HTML ESTÁTICO"
echo "==================================="
echo ""

# Directorio actual del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
cd ../..

# Definir la ruta del archivo HTML
ARCHIVO_HTML="verificador_metodos_pago.html"

# Crear el archivo HTML
cat > "$ARCHIVO_HTML" << 'EOL'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verificador de Método de Pago - DylanPOS</title>
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
        .input-container {
            margin-bottom: 20px;
        }
        #cargar-datos {
            display: block;
            margin: 0 auto;
            padding: 10px 20px;
            background-color: #4CAF50;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
        }
        #cargar-datos:hover {
            background-color: #45a049;
        }
        textarea {
            width: 100%;
            height: 200px;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-family: monospace;
            font-size: 14px;
        }
        .tab {
            overflow: hidden;
            border: 1px solid #ccc;
            background-color: #f1f1f1;
            border-radius: 5px 5px 0 0;
        }
        .tab button {
            background-color: inherit;
            float: left;
            border: none;
            outline: none;
            cursor: pointer;
            padding: 14px 16px;
            transition: 0.3s;
            font-size: 16px;
        }
        .tab button:hover {
            background-color: #ddd;
        }
        .tab button.active {
            background-color: #3498db;
            color: white;
        }
        .tabcontent {
            display: none;
            padding: 20px;
            border: 1px solid #ccc;
            border-top: none;
            border-radius: 0 0 5px 5px;
        }
        #buscar-factura-especifica {
            padding: 10px 20px;
            background-color: #3498db;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
            margin-left: 10px;
        }
        #buscar-factura-especifica:hover {
            background-color: #2980b9;
        }
        .card {
            background: white;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            padding: 20px;
            margin-bottom: 20px;
        }
        .text-center {
            text-align: center;
        }
        .detail-section {
            background: #fff;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            border: 1px solid #ddd;
        }
        .detail-row {
            display: flex;
            margin-bottom: 8px;
            border-bottom: 1px solid #eee;
            padding-bottom: 8px;
        }
        .detail-label {
            font-weight: bold;
            width: 200px;
            color: #555;
        }
        .detail-value {
            flex: 1;
        }
        .instrucciones {
            background: #fff3cd;
            color: #856404;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            border: 1px solid #ffeeba;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Verificador de Método de Pago - DylanPOS</h1>
            <p id="fecha-generacion">Generado el: <span id="fecha-actual"></span></p>
        </div>
        
        <div class="instrucciones">
            <h3>Instrucciones</h3>
            <p>Esta herramienta te permite verificar los métodos de pago en las transacciones de venta. Para usarla:</p>
            <ol>
                <li>En Firebase, ve a la sección "Realtime Database"</li>
                <li>Navega a la ruta <code>tuUsuarioID/Sales Transition</code></li>
                <li>Haz clic en los tres puntos y selecciona "Exportar JSON"</li>
                <li>Descarga el archivo JSON</li>
                <li>Abre el archivo con un editor de texto y copia todo su contenido</li>
                <li>Pega el contenido en el área de texto a continuación</li>
                <li>Haz clic en "Cargar Datos"</li>
            </ol>
        </div>
        
        <div class="tab">
            <button class="tablinks active" onclick="openTab(event, 'tab-cargar')">Cargar Datos</button>
            <button class="tablinks" onclick="openTab(event, 'tab-informe')" disabled id="btn-tab-informe">Informe General</button>
            <button class="tablinks" onclick="openTab(event, 'tab-factura')" disabled id="btn-tab-factura">Factura Específica</button>
        </div>
        
        <div id="tab-cargar" class="tabcontent" style="display: block;">
            <h2>Cargar Datos de Ventas</h2>
            <div class="input-container">
                <textarea id="json-input" placeholder="Pega aquí el JSON exportado de Firebase..."></textarea>
            </div>
            <button id="cargar-datos" onclick="cargarDatos()">Cargar Datos</button>
        </div>
        
        <div id="tab-informe" class="tabcontent">
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
                            <th>Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <!-- Se llenará dinámicamente -->
                    </tbody>
                </table>
            </div>
        </div>
        
        <div id="tab-factura" class="tabcontent">
            <h2>Buscar Factura Específica</h2>
            <div style="display: flex; margin-bottom: 20px;">
                <input type="text" id="numero-factura" placeholder="Ingrese número de factura" style="flex: 1; padding: 10px;">
                <button id="buscar-factura-especifica" onclick="buscarFacturaEspecifica()">Buscar</button>
            </div>
            
            <div id="detalle-factura">
                <!-- Se llenará dinámicamente -->
            </div>
        </div>
        
        <div class="footer">
            <p>DylanPOS - Sistema de Verificación de Métodos de Pago</p>
        </div>
    </div>
    
    <script>
        // Variables globales
        let ventas = [];
        let datosOriginales = null;
        
        // Establecer la fecha actual
        document.getElementById('fecha-actual').textContent = new Date().toLocaleString('es-ES');
        
        // Función para abrir pestañas
        function openTab(evt, tabName) {
            var i, tabcontent, tablinks;
            
            tabcontent = document.getElementsByClassName("tabcontent");
            for (i = 0; i < tabcontent.length; i++) {
                tabcontent[i].style.display = "none";
            }
            
            tablinks = document.getElementsByClassName("tablinks");
            for (i = 0; i < tablinks.length; i++) {
                tablinks[i].className = tablinks[i].className.replace(" active", "");
            }
            
            document.getElementById(tabName).style.display = "block";
            evt.currentTarget.className += " active";
        }
        
        // Función para cargar datos desde JSON
        function cargarDatos() {
            const jsonInput = document.getElementById('json-input').value.trim();
            
            if (!jsonInput) {
                alert('Por favor, ingresa los datos JSON de ventas');
                return;
            }
            
            try {
                datosOriginales = JSON.parse(jsonInput);
                procesarDatos();
                
                // Habilitar pestañas
                document.getElementById('btn-tab-informe').disabled = false;
                document.getElementById('btn-tab-factura').disabled = false;
                
                // Cambiar a la pestaña de informe
                document.querySelector('button[onclick="openTab(event, \'tab-informe\')"]').click();
                
            } catch (error) {
                alert('Error al procesar los datos JSON: ' + error.message);
            }
        }
        
        // Función para procesar los datos
        function procesarDatos() {
            ventas = [];
            let total = 0;
            let problematicas = 0;
            
            // Convertir datos de Firebase a array
            Object.entries(datosOriginales).forEach(([key, venta]) => {
                total++;
                const fechaVenta = new Date(venta.purchaseDate);
                const metodoPago = venta.paymentType || "";
                
                // Verificar si el método de pago es problemático
                const esProblematica = !metodoPago || metodoPago === "Unknown" || metodoPago === "";
                if (esProblematica) {
                    problematicas++;
                }
                
                // Agregar a la lista de ventas
                ventas.push({
                    id: key,
                    factura: venta.invoiceNumber,
                    fechaRaw: venta.purchaseDate,
                    fecha: fechaVenta.toLocaleString("es-ES"),
                    cliente: venta.customerName,
                    telefono: venta.customerPhone,
                    monto: venta.totalAmount || 0,
                    metodoPago: metodoPago,
                    estado: venta.isPaid ? "PAGADO" : "PENDIENTE",
                    esProblematica: esProblematica,
                    datosCompletos: venta
                });
            });
            
            // Ordenar por fecha (más recientes primero)
            ventas.sort((a, b) => new Date(b.fechaRaw) - new Date(a.fechaRaw));
            
            // Actualizar resumen
            actualizarResumen(ventas.length, problematicas);
            
            // Mostrar datos en la tabla
            mostrarDatos(ventas);
        }
        
        // Actualizar el resumen
        function actualizarResumen(total, problematicas) {
            const porcentajeProblematicas = total > 0 ? ((problematicas / total) * 100).toFixed(2) : "0.00";
            
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
                tbody.innerHTML = '<tr><td colspan="7" style="text-align: center;">No se encontraron ventas con los filtros aplicados</td></tr>';
                return;
            }
            
            datos.forEach(venta => {
                const row = document.createElement('tr');
                if (venta.esProblematica) {
                    row.classList.add('problematica');
                }
                
                row.innerHTML = `
                    <td>${venta.factura}</td>
                    <td>${venta.fecha}</td>
                    <td>${venta.cliente}</td>
                    <td>RD$ ${venta.monto.toFixed(2)}</td>
                    <td class="metodo-pago ${venta.esProblematica ? 'error' : 'success'}">${venta.metodoPago || 'NO DEFINIDO'}</td>
                    <td>${venta.estado}</td>
                    <td>
                        <button onclick="verDetalles('${venta.id}')" style="padding: 2px 5px;">Ver Detalles</button>
                    </td>
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
        
        // Buscar factura específica
        function buscarFacturaEspecifica() {
            const numeroFactura = document.getElementById('numero-factura').value.trim();
            
            if (!numeroFactura) {
                alert('Por favor, ingrese un número de factura');
                return;
            }
            
            const factura = ventas.find(v => v.factura === numeroFactura);
            
            if (factura) {
                mostrarDetalleFactura(factura);
            } else {
                document.getElementById('detalle-factura').innerHTML = `
                    <div class="card">
                        <h3 class="text-center error">No se encontró la factura</h3>
                        <p class="text-center">No existe ninguna factura con el número ${numeroFactura}</p>
                    </div>
                `;
            }
        }
        
        // Ver detalles de una venta
        function verDetalles(id) {
            const venta = ventas.find(v => v.id === id);
            
            if (venta) {
                // Cambiar a la pestaña de factura
                document.querySelector('button[onclick="openTab(event, \'tab-factura\')"]').click();
                
                // Mostrar detalles
                document.getElementById('numero-factura').value = venta.factura;
                mostrarDetalleFactura(venta);
            }
        }
        
        // Mostrar detalle de factura
        function mostrarDetalleFactura(venta) {
            const esProblematica = venta.esProblematica;
            const datos = venta.datosCompletos;
            
            let html = `
                <div class="card">
                    <h2 class="text-center">Información de la Factura #${venta.factura}</h2>
                    
                    <div class="detail-section">
                        <div class="detail-row">
                            <div class="detail-label">ID:</div>
                            <div class="detail-value">${venta.id}</div>
                        </div>
                        <div class="detail-row">
                            <div class="detail-label">Cliente:</div>
                            <div class="detail-value">${venta.cliente}</div>
                        </div>
                        <div class="detail-row">
                            <div class="detail-label">Teléfono:</div>
                            <div class="detail-value">${venta.telefono}</div>
                        </div>
                        <div class="detail-row">
                            <div class="detail-label">Fecha:</div>
                            <div class="detail-value">${venta.fecha}</div>
                        </div>
                        <div class="detail-row">
                            <div class="detail-label">Monto total:</div>
                            <div class="detail-value">RD$ ${venta.monto.toFixed(2)}</div>
                        </div>
                        <div class="detail-row">
                            <div class="detail-label">Método de pago:</div>
                            <div class="detail-value metodo-pago ${esProblematica ? 'error' : 'success'}">
                                ${venta.metodoPago || 'NO DEFINIDO'}
                            </div>
                        </div>
                        <div class="detail-row">
                            <div class="detail-label">Estado de pago:</div>
                            <div class="detail-value">${venta.estado}</div>
                        </div>
                        ${datos.dueAmount > 0 ? `
                        <div class="detail-row">
                            <div class="detail-label">Monto pendiente:</div>
                            <div class="detail-value">RD$ ${datos.dueAmount.toFixed(2)}</div>
                        </div>` : ''}
                    </div>
                    
                    <div class="resumen">
                        ${esProblematica 
                            ? '<p class="error">⚠️ ADVERTENCIA: Esta factura no tiene un método de pago definido correctamente</p>' 
                            : '<p class="success">✅ Método de pago correctamente registrado</p>'}
                    </div>
                </div>
            `;
            
            document.getElementById('detalle-factura').innerHTML = html;
        }
    </script>
</body>
</html>
EOL

echo "Archivo HTML generado: $ARCHIVO_HTML"
echo ""
echo "Abriendo archivo en el navegador..."

# Abrir en el navegador
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  open "$ARCHIVO_HTML"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Linux
  xdg-open "$ARCHIVO_HTML"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  # Windows
  start "$ARCHIVO_HTML"
else
  echo "No se pudo abrir automáticamente. El archivo está disponible en:"
  echo "$ARCHIVO_HTML"
fi

echo ""
echo "==================================="
echo "INSTRUCCIONES"
echo "==================================="
echo "1. Se ha abierto una página web en tu navegador"
echo "2. Sigue las instrucciones en la página para exportar tus datos de Firebase"
echo "3. Pega los datos JSON en el área de texto y haz clic en 'Cargar Datos'"
echo ""
echo "NOTA: Esta versión es 100% offline y no requiere autenticación"
echo "==================================="
