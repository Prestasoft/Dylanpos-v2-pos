#!/bin/bash

# Script simplificado para verificar el método de pago
# Versión que no requiere Firebase CLI
# Creado el: 5 de julio de 2025

echo "==================================="
echo "VERIFICADOR DIRECTO DE MÉTODO DE PAGO"
echo "==================================="
echo ""

# Verificar si se proporcionó un número de factura o parámetro
if [ -z "$1" ]; then
  echo "Uso: $0 <número_de_factura> o 'informe' para generar un informe completo"
  echo ""
  echo "Ejemplos:"
  echo "  $0 365          # Verifica la factura número 365"
  echo "  $0 informe      # Genera un informe HTML de todas las ventas"
  exit 1
fi

# Establecer directorio actual
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
cd ../..

# Función para crear un script web básico
crear_script_web() {
  TIPO="$1"  # puede ser 'factura' o 'informe'
  FACTURA="$2"  # número de factura (solo para tipo 'factura')
  
  FECHA_ACTUAL=$(date +"%Y-%m-%d_%H-%M-%S")
  ARCHIVO_HTML="/tmp/dylanpos_verificador_${TIPO}_${FECHA_ACTUAL}.html"
  
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
        #loading {
            text-align: center;
            margin: 50px 0;
        }
        .spinner {
            border: 6px solid #f3f3f3;
            border-top: 6px solid #3498db;
            border-radius: 50%;
            width: 50px;
            height: 50px;
            animation: spin 2s linear infinite;
            margin: 0 auto 20px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        .auth-panel {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
            text-align: center;
        }
        .auth-panel button {
            background: #4CAF50;
            color: white;
            border: none;
            padding: 10px 15px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
        }
        .auth-panel button:hover {
            background: #45a049;
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
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Verificador de Método de Pago - DylanPOS</h1>
            <p id="fecha-generacion">Cargando...</p>
        </div>
        
        <div class="auth-panel" id="auth-panel">
            <h2>Autenticación</h2>
            <p>Necesitas iniciar sesión con tu cuenta de Firebase para acceder a los datos.</p>
            <button id="login-button">Iniciar Sesión</button>
        </div>

        <div id="loading">
            <div class="spinner"></div>
            <p>Conectando con Firebase y cargando datos...</p>
        </div>
        
        <div id="main-content" style="display: none;">
            <!-- El contenido principal se mostrará aquí -->
        </div>
        
        <div class="footer">
            <p>DylanPOS - Sistema de Verificación de Métodos de Pago</p>
        </div>
    </div>

    <!-- Firebase -->
    <script src="https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js"></script>
    <script src="https://www.gstatic.com/firebasejs/8.10.1/firebase-auth.js"></script>
    <script src="https://www.gstatic.com/firebasejs/8.10.1/firebase-database.js"></script>

    <script>
        // Configuración de Firebase
        const firebaseConfig = {
          apiKey: "AIzaSyC-tsScYuvKuNwGFpFEBQhBft-FZBhzRww",
          authDomain: "dylanpos-v2.firebaseapp.com",
          databaseURL: "https://dylanpos-v2-default-rtdb.firebaseio.com",
          projectId: "dylanpos-v2",
          storageBucket: "dylanpos-v2.appspot.com",
          messagingSenderId: "160073445726",
          appId: "1:160073445726:web:c327914c0478a4e10d2ed3",
          measurementId: "G-X5VHKGQFP6"
        };
        
        // Inicializar Firebase
        firebase.initializeApp(firebaseConfig);
        
        // Variables globales
        let currentUser = null;
        let ventas = [];
        const facturaEspecifica = 'FACTURA_NUM_PLACEHOLDER';
        const tipoVerificacion = 'TIPO_VERIFICACION_PLACEHOLDER';
        
        // Establecer la fecha actual
        document.getElementById('fecha-generacion').textContent = 'Generado el: ' + new Date().toLocaleString('es-ES');
        
        // Evento de carga de página
        document.addEventListener('DOMContentLoaded', function() {
            // Ocultar sección de carga inicialmente
            document.getElementById('loading').style.display = 'none';
            
            // Configurar botón de inicio de sesión
            document.getElementById('login-button').addEventListener('click', function() {
                iniciarSesion();
            });
            
            // Verificar estado de autenticación
            firebase.auth().onAuthStateChanged(function(user) {
                if (user) {
                    currentUser = user;
                    document.getElementById('auth-panel').style.display = 'none';
                    document.getElementById('loading').style.display = 'block';
                    
                    // Cargar los datos
                    if (tipoVerificacion === 'factura') {
                        cargarFacturaEspecifica(facturaEspecifica);
                    } else {
                        cargarTodasLasVentas();
                    }
                } else {
                    document.getElementById('auth-panel').style.display = 'block';
                    document.getElementById('loading').style.display = 'none';
                    document.getElementById('main-content').style.display = 'none';
                }
            });
        });
        
        // Función para iniciar sesión
        function iniciarSesion() {
            const provider = new firebase.auth.GoogleAuthProvider();
            firebase.auth().signInWithPopup(provider).catch(function(error) {
                console.error('Error de autenticación:', error);
                alert('Error al iniciar sesión: ' + error.message);
            });
        }
        
        // Función para cargar una factura específica
        function cargarFacturaEspecifica(numeroFactura) {
            const userId = currentUser.uid;
            const dbRef = firebase.database().ref(`${userId}/Sales Transition`);
            
            dbRef.once('value')
                .then(function(snapshot) {
                    if (!snapshot.exists()) {
                        mostrarError('No se encontraron transacciones de venta.');
                        return;
                    }
                    
                    let facturaEncontrada = false;
                    
                    snapshot.forEach(function(childSnapshot) {
                        const venta = childSnapshot.val();
                        
                        if (venta.invoiceNumber === numeroFactura) {
                            facturaEncontrada = true;
                            mostrarDetalleFactura(childSnapshot.key, venta);
                        }
                    });
                    
                    if (!facturaEncontrada) {
                        mostrarError(`No se encontró ninguna factura con el número ${numeroFactura}`);
                    }
                })
                .catch(function(error) {
                    console.error('Error al cargar la factura:', error);
                    mostrarError('Error al cargar la factura: ' + error.message);
                })
                .finally(function() {
                    document.getElementById('loading').style.display = 'none';
                });
        }
        
        // Función para mostrar el detalle de una factura
        function mostrarDetalleFactura(id, venta) {
            const fechaVenta = new Date(venta.purchaseDate);
            const metodoPago = venta.paymentType || '';
            const esProblematica = !metodoPago || metodoPago === 'Unknown' || metodoPago === '';
            
            let html = `
                <div class="card">
                    <h2 class="text-center">Información de la Factura #${venta.invoiceNumber}</h2>
                    
                    <div class="detail-section">
                        <div class="detail-row">
                            <div class="detail-label">ID:</div>
                            <div class="detail-value">${id}</div>
                        </div>
                        <div class="detail-row">
                            <div class="detail-label">Cliente:</div>
                            <div class="detail-value">${venta.customerName}</div>
                        </div>
                        <div class="detail-row">
                            <div class="detail-label">Teléfono:</div>
                            <div class="detail-value">${venta.customerPhone}</div>
                        </div>
                        <div class="detail-row">
                            <div class="detail-label">Fecha:</div>
                            <div class="detail-value">${fechaVenta.toLocaleString('es-ES')}</div>
                        </div>
                        <div class="detail-row">
                            <div class="detail-label">Monto total:</div>
                            <div class="detail-value">RD$ ${venta.totalAmount ? venta.totalAmount.toFixed(2) : '0.00'}</div>
                        </div>
                        <div class="detail-row">
                            <div class="detail-label">Método de pago:</div>
                            <div class="detail-value metodo-pago ${esProblematica ? 'error' : 'success'}">
                                ${metodoPago || 'NO DEFINIDO'}
                            </div>
                        </div>
                        <div class="detail-row">
                            <div class="detail-label">Estado de pago:</div>
                            <div class="detail-value">${venta.isPaid ? 'PAGADO' : 'PENDIENTE'}</div>
                        </div>
                        ${venta.dueAmount > 0 ? `
                        <div class="detail-row">
                            <div class="detail-label">Monto pendiente:</div>
                            <div class="detail-value">RD$ ${venta.dueAmount.toFixed(2)}</div>
                        </div>` : ''}
                    </div>
                    
                    <div class="resumen">
                        ${esProblematica 
                            ? '<p class="error">⚠️ ADVERTENCIA: Esta factura no tiene un método de pago definido correctamente</p>' 
                            : '<p class="success">✅ Método de pago correctamente registrado</p>'}
                    </div>
                </div>
            `;
            
            document.getElementById('main-content').innerHTML = html;
            document.getElementById('main-content').style.display = 'block';
        }
        
        // Función para cargar todas las ventas (para el informe)
        function cargarTodasLasVentas() {
            const userId = currentUser.uid;
            const dbRef = firebase.database().ref(`${userId}/Sales Transition`);
            
            dbRef.once('value')
                .then(function(snapshot) {
                    if (!snapshot.exists()) {
                        mostrarError('No se encontraron transacciones de venta.');
                        return;
                    }
                    
                    ventas = [];
                    let total = 0;
                    let problematicas = 0;
                    
                    snapshot.forEach(function(childSnapshot) {
                        const venta = childSnapshot.val();
                        total++;
                        
                        const fechaVenta = new Date(venta.purchaseDate);
                        const metodoPago = venta.paymentType || '';
                        
                        // Verificar si el método de pago es problemático
                        if (!metodoPago || metodoPago === 'Unknown' || metodoPago === '') {
                            problematicas++;
                        }
                        
                        // Agregar a la lista de ventas
                        ventas.push({
                            id: childSnapshot.key,
                            factura: venta.invoiceNumber,
                            fechaRaw: venta.purchaseDate,
                            fecha: fechaVenta.toLocaleString('es-ES'),
                            cliente: venta.customerName,
                            telefono: venta.customerPhone,
                            monto: venta.totalAmount || 0,
                            metodoPago: metodoPago,
                            estado: venta.isPaid ? 'PAGADO' : 'PENDIENTE',
                            esProblematica: !metodoPago || metodoPago === 'Unknown' || metodoPago === ''
                        });
                    });
                    
                    // Ordenar por fecha (más recientes primero)
                    ventas.sort((a, b) => new Date(b.fechaRaw) - new Date(a.fechaRaw));
                    
                    // Mostrar el informe
                    mostrarInforme(ventas, total, problematicas);
                })
                .catch(function(error) {
                    console.error('Error al cargar las ventas:', error);
                    mostrarError('Error al cargar las ventas: ' + error.message);
                })
                .finally(function() {
                    document.getElementById('loading').style.display = 'none';
                });
        }
        
        // Función para mostrar el informe completo
        function mostrarInforme(ventas, total, problematicas) {
            const porcentajeProblematicas = ((problematicas / total) * 100).toFixed(2);
            
            let html = `
                <div class="resumen" id="resumen">
                    <h2>Resumen</h2>
                    <p><strong>Total de ventas:</strong> ${total}</p>
                    <p><strong>Ventas con método de pago problemático:</strong> 
                       ${problematicas} (${porcentajeProblematicas}%)
                       <span class="badge ${problematicas > 0 ? 'badge-error' : 'badge-success'}">
                           ${problematicas > 0 ? 'Atención requerida' : 'Todo en orden'}
                       </span>
                    </p>
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
            `;
            
            if (ventas.length === 0) {
                html += '<tr><td colspan="6" style="text-align: center;">No se encontraron ventas</td></tr>';
            } else {
                ventas.forEach(venta => {
                    html += `
                        <tr class="${venta.esProblematica ? 'problematica' : ''}">
                            <td>${venta.factura}</td>
                            <td>${venta.fecha}</td>
                            <td>${venta.cliente}</td>
                            <td>RD$ ${venta.monto.toFixed(2)}</td>
                            <td class="metodo-pago ${venta.esProblematica ? 'error' : 'success'}">${venta.metodoPago || 'NO DEFINIDO'}</td>
                            <td>${venta.estado}</td>
                        </tr>
                    `;
                });
            }
            
            html += `
                        </tbody>
                    </table>
                </div>
                
                <script>
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
                                datosFiltrados = datosFiltrados.filter(venta => venta.esProblematica);
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
                        actualizarTabla(datosFiltrados);
                        
                        // Actualizar resumen con datos filtrados
                        const problematicas = datosFiltrados.filter(venta => venta.esProblematica).length;
                        actualizarResumen(datosFiltrados.length, problematicas);
                    }
                    
                    // Resetear filtros
                    function resetearFiltros() {
                        document.getElementById('fecha-inicio').value = '';
                        document.getElementById('fecha-fin').value = '';
                        document.getElementById('metodo-pago').value = '';
                        document.getElementById('buscar-factura').value = '';
                        
                        // Mostrar todos los datos nuevamente
                        actualizarTabla(ventas);
                        
                        // Actualizar resumen con todos los datos
                        const problematicas = ventas.filter(venta => venta.esProblematica).length;
                        actualizarResumen(ventas.length, problematicas);
                    }
                    
                    // Actualizar tabla con datos filtrados
                    function actualizarTabla(datos) {
                        const tbody = document.querySelector('#tabla-ventas tbody');
                        tbody.innerHTML = '';
                        
                        if (datos.length === 0) {
                            tbody.innerHTML = '<tr><td colspan="6" style="text-align: center;">No se encontraron ventas con los filtros aplicados</td></tr>';
                            return;
                        }
                        
                        datos.forEach(venta => {
                            const row = document.createElement('tr');
                            if (venta.esProblematica) {
                                row.classList.add('problematica');
                            }
                            
                            row.innerHTML = \`
                                <td>\${venta.factura}</td>
                                <td>\${venta.fecha}</td>
                                <td>\${venta.cliente}</td>
                                <td>RD$ \${venta.monto.toFixed(2)}</td>
                                <td class="metodo-pago \${venta.esProblematica ? 'error' : 'success'}">\${venta.metodoPago || 'NO DEFINIDO'}</td>
                                <td>\${venta.estado}</td>
                            \`;
                            
                            tbody.appendChild(row);
                        });
                    }
                    
                    // Actualizar el resumen
                    function actualizarResumen(total, problematicas) {
                        const porcentajeProblematicas = ((problematicas / total) * 100).toFixed(2);
                        
                        const resumen = document.getElementById('resumen');
                        resumen.innerHTML = \`
                            <h2>Resumen</h2>
                            <p><strong>Total de ventas:</strong> \${total}</p>
                            <p><strong>Ventas con método de pago problemático:</strong> 
                               \${problematicas} (\${porcentajeProblematicas}%)
                               <span class="badge \${problematicas > 0 ? 'badge-error' : 'badge-success'}">
                                   \${problematicas > 0 ? 'Atención requerida' : 'Todo en orden'}
                               </span>
                            </p>
                        \`;
                    }
                </script>
            `;
            
            document.getElementById('main-content').innerHTML = html;
            document.getElementById('main-content').style.display = 'block';
        }
        
        // Función para mostrar errores
        function mostrarError(mensaje) {
            document.getElementById('main-content').innerHTML = `
                <div class="card">
                    <h2 class="text-center error">Error</h2>
                    <p class="text-center">${mensaje}</p>
                </div>
            `;
            document.getElementById('main-content').style.display = 'block';
        }
    </script>
</body>
</html>
EOL

  # Reemplazar los marcadores de posición con valores reales
  sed -i '' "s/FACTURA_NUM_PLACEHOLDER/$FACTURA/g" "$ARCHIVO_HTML"
  sed -i '' "s/TIPO_VERIFICACION_PLACEHOLDER/$TIPO/g" "$ARCHIVO_HTML"

  echo "$ARCHIVO_HTML"
}

# Determinar el tipo de operación
if [ "$1" == "informe" ]; then
  # Generar informe completo
  echo "Generando informe completo de métodos de pago..."
  ARCHIVO_HTML=$(crear_script_web "informe" "")
else
  # Verificar factura específica
  FACTURA="$1"
  echo "Verificando factura número: $FACTURA"
  ARCHIVO_HTML=$(crear_script_web "factura" "$FACTURA")
fi

# Abrir el archivo en el navegador predeterminado
echo ""
echo "Abriendo verificador en el navegador..."
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
  echo "No se pudo abrir automáticamente. El verificador está disponible en:"
  echo "$ARCHIVO_HTML"
fi

echo ""
echo "==================================="
echo "INSTRUCCIONES"
echo "==================================="
echo "1. Se abrirá una página web en tu navegador"
echo "2. Inicia sesión con tu cuenta de Google asociada a Firebase"
echo "3. El verificador mostrará automáticamente la información solicitada"
echo ""
echo "NOTA: Esta versión no requiere Firebase CLI ni Node.js"
echo "==================================="
