#!/bin/bash

# =============================================================
# VERIFICADOR UNIVERSAL DE MÉTODOS DE PAGO (VERSIÓN MEJORADA)
# =============================================================
# Este script unifica todas las herramientas de verificación
# y proporciona una interfaz más amigable con mejor manejo de errores
# Creado: 8 de agosto de 2025
# =============================================================

# Definir colores para mejor visualización
ROJO='\033[0;31m'
VERDE='\033[0;32m'
AMARILLO='\033[0;33m'
AZUL='\033[0;34m'
RESET='\033[0m'

# Obtener el directorio actual del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
cd ../..

# Directorio temporal para los archivos HTML
TEMP_DIR="/tmp/dylanpos_verificador_$(date +"%Y%m%d_%H%M%S")"
mkdir -p "$TEMP_DIR"

# Archivo HTML de salida
ARCHIVO_HTML="$TEMP_DIR/verificador_metodos_pago.html"

echo -e "${AZUL}===========================================================${RESET}"
echo -e "${AZUL}   VERIFICADOR UNIVERSAL DE MÉTODOS DE PAGO - DYLANPOS${RESET}"
echo -e "${AZUL}===========================================================${RESET}"
echo ""

# Mostrar menú de opciones
mostrar_menu() {
    echo -e "${VERDE}Seleccione una opción:${RESET}"
    echo ""
    echo -e "  ${AMARILLO}1.${RESET} Verificador Offline (No requiere autenticación)"
    echo -e "  ${AMARILLO}2.${RESET} Verificador Web Directo (Autenticación con Google)"
    echo -e "  ${AMARILLO}3.${RESET} Verificar factura específica"
    echo -e "  ${AMARILLO}4.${RESET} Generar informe completo"
    echo -e "  ${AMARILLO}5.${RESET} Salir"
    echo ""
    echo -n -e "${VERDE}Opción:${RESET} "
    read opcion
    echo ""
    
    case $opcion in
        1) ejecutar_verificador_offline ;;
        2) ejecutar_verificador_web_directo ;;
        3) solicitar_numero_factura ;;
        4) generar_informe_completo ;;
        5) salir ;;
        *) echo -e "${ROJO}Opción inválida. Por favor, intente de nuevo.${RESET}"; mostrar_menu ;;
    esac
}

# Función para el verificador offline
ejecutar_verificador_offline() {
    echo -e "${AZUL}Iniciando el verificador offline...${RESET}"
    echo ""
    
    # Verificar si el archivo de script original existe
    if [ -f "$SCRIPT_DIR/verificador_offline_simple.sh" ]; then
        # Dar permisos de ejecución si no los tiene
        chmod +x "$SCRIPT_DIR/verificador_offline_simple.sh"
        # Ejecutar el script original
        "$SCRIPT_DIR/verificador_offline_simple.sh"
    else
        # Si no existe, creamos uno integrado aquí mismo
        crear_verificador_offline
    fi
}

# Función para crear el verificador offline integrado
crear_verificador_offline() {
    echo -e "${AZUL}Creando verificador offline integrado...${RESET}"
    
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
        .warning {
            color: #f0ad4e;
        }
        .highlight {
            background-color: #fffbcc;
            padding: 2px 5px;
            border-radius: 3px;
        }
        .input-area {
            margin-bottom: 20px;
        }
        textarea {
            width: 100%;
            min-height: 200px;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-family: monospace;
            margin-bottom: 10px;
        }
        button {
            background-color: #3498db;
            color: white;
            border: none;
            padding: 10px 15px;
            border-radius: 5px;
            cursor: pointer;
            font-size: 14px;
        }
        button:hover {
            background-color: #2980b9;
        }
        .instrucciones {
            background-color: #fff8e1;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            border: 1px solid #ffecb3;
        }
        .paso {
            margin-bottom: 10px;
        }
        .hidden {
            display: none;
        }
        .loading {
            margin: 20px 0;
            text-align: center;
        }
        .spinner {
            border: 4px solid rgba(0, 0, 0, 0.1);
            width: 36px;
            height: 36px;
            border-radius: 50%;
            border-left-color: #3498db;
            animation: spin 1s linear infinite;
            display: inline-block;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        .results-count {
            font-weight: bold;
            margin-bottom: 10px;
        }
        .empty-state {
            text-align: center;
            padding: 40px;
            color: #666;
        }
        .footer {
            margin-top: 40px;
            text-align: center;
            color: #777;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Verificador de Método de Pago - DylanPOS</h1>
            <p>Herramienta para validar el guardado correcto del método de pago en las transacciones</p>
        </div>
        
        <div class="instrucciones">
            <h2>Instrucciones:</h2>
            <div class="paso">
                <strong>1.</strong> Accede a la consola de Firebase: <a href="https://console.firebase.google.com" target="_blank">https://console.firebase.google.com</a>
            </div>
            <div class="paso">
                <strong>2.</strong> Selecciona tu proyecto y ve a "Firestore Database"
            </div>
            <div class="paso">
                <strong>3.</strong> En la colección <code>sale_transaction</code>, exporta los datos (3 puntos verticales > Exportar colección)
            </div>
            <div class="paso">
                <strong>4.</strong> Pega el contenido del archivo JSON exportado en el área de texto de abajo
            </div>
            <div class="paso">
                <strong>5.</strong> Haz clic en "Cargar Datos" para analizar las transacciones
            </div>
        </div>
        
        <div class="input-area">
            <h3>Pega los datos JSON exportados de Firebase:</h3>
            <textarea id="jsonInput" placeholder='Pega aquí el JSON exportado de Firebase...'></textarea>
            <button id="loadButton">Cargar Datos</button>
        </div>
        
        <div id="loading" class="loading hidden">
            <div class="spinner"></div>
            <p>Procesando datos...</p>
        </div>
        
        <div id="results" class="hidden">
            <div class="resumen" id="resumen">
                <h2>Resumen de Análisis</h2>
                <p>Cargando resumen...</p>
            </div>
            
            <div class="filters">
                <h3>Filtros:</h3>
                <div style="display: flex; flex-wrap: wrap; gap: 15px;">
                    <div>
                        <label for="fechaInicioFiltro">Fecha Inicio:</label>
                        <input type="date" id="fechaInicioFiltro">
                    </div>
                    <div>
                        <label for="fechaFinFiltro">Fecha Fin:</label>
                        <input type="date" id="fechaFinFiltro">
                    </div>
                    <div>
                        <label for="metodoPagoFiltro">Método de Pago:</label>
                        <select id="metodoPagoFiltro">
                            <option value="">Todos</option>
                        </select>
                    </div>
                    <div>
                        <label for="invoiceNoFiltro">Número de Factura:</label>
                        <input type="text" id="invoiceNoFiltro" placeholder="Ej: 365">
                    </div>
                    <div>
                        <label for="problemasCheck">Mostrar Solo Problemas:</label>
                        <input type="checkbox" id="problemasCheck">
                    </div>
                    <div>
                        <button id="aplicarFiltro">Aplicar Filtros</button>
                        <button id="limpiarFiltro">Limpiar Filtros</button>
                    </div>
                </div>
            </div>
            
            <div class="results-count" id="resultsCount"></div>
            
            <table id="ventasTable">
                <thead>
                    <tr>
                        <th>Fecha</th>
                        <th>Factura #</th>
                        <th>Cliente</th>
                        <th>Total</th>
                        <th>Método de Pago</th>
                        <th>Estado</th>
                        <th>Detalles</th>
                    </tr>
                </thead>
                <tbody id="ventasTableBody">
                    <!-- Los datos se cargarán aquí -->
                </tbody>
            </table>
            
            <div id="emptyState" class="empty-state hidden">
                <h3>No se encontraron transacciones</h3>
                <p>Intenta cambiar los filtros o cargar otros datos</p>
            </div>
        </div>
        
        <div class="footer">
            <p>DylanPOS - Verificador de Método de Pago v2.0 - Generado el: <span id="fechaGeneracion"></span></p>
        </div>
    </div>
    
    <script>
        // Establecer la fecha de generación
        document.getElementById('fechaGeneracion').textContent = new Date().toLocaleString();
        
        // Variables globales
        let todasLasVentas = [];
        let ventasFiltradas = [];
        let metodosDisponibles = new Set();
        
        // Listener para el botón de cargar datos
        document.getElementById('loadButton').addEventListener('click', function() {
            const jsonInput = document.getElementById('jsonInput').value;
            if (!jsonInput.trim()) {
                alert('Por favor, pega los datos JSON exportados de Firebase');
                return;
            }
            
            // Mostrar spinner de carga
            document.getElementById('loading').classList.remove('hidden');
            document.getElementById('results').classList.add('hidden');
            
            // Procesar de forma asíncrona para no bloquear la UI
            setTimeout(() => {
                procesarDatos(jsonInput);
            }, 100);
        });
        
        // Función para procesar los datos JSON
        function procesarDatos(jsonInput) {
            try {
                let datos;
                try {
                    datos = JSON.parse(jsonInput);
                } catch (e) {
                    // Si falla, intentar limpiar el formato que Firebase exporta
                    const contenidoLimpio = jsonInput
                        .replace(/^export default/, '')  // Remover "export default" si existe
                        .replace(/;$/, '')  // Remover punto y coma final si existe
                        .trim();
                    
                    // Evaluar el JSON con precaución
                    datos = (new Function('return ' + contenidoLimpio))();
                }
                
                // Verificar estructura básica
                if (!datos || typeof datos !== 'object') {
                    throw new Error('Formato de datos inválido');
                }
                
                // Procesar según el formato de Firebase
                todasLasVentas = [];
                
                if (Array.isArray(datos)) {
                    // Formato de array directo
                    todasLasVentas = datos.map(procesarVenta);
                } else if (datos.__collections__ && datos.__collections__.sale_transaction) {
                    // Formato de exportación completa
                    const transacciones = datos.__collections__.sale_transaction;
                    Object.keys(transacciones).forEach(key => {
                        const venta = transacciones[key];
                        const ventaProcesada = procesarVenta(venta);
                        ventaProcesada.id = key;  // Asignar ID de documento
                        todasLasVentas.push(ventaProcesada);
                    });
                } else if (Object.keys(datos).length > 0) {
                    // Intentar como objetos directos
                    Object.keys(datos).forEach(key => {
                        const venta = datos[key];
                        const ventaProcesada = procesarVenta(venta);
                        ventaProcesada.id = key;  // Asignar ID de documento
                        todasLasVentas.push(ventaProcesada);
                    });
                } else {
                    throw new Error('No se encontraron datos de ventas en el formato esperado');
                }
                
                // Ordenar por fecha (más reciente primero)
                todasLasVentas.sort((a, b) => {
                    return new Date(b.fecha) - new Date(a.fecha);
                });
                
                // Establecer métodos disponibles para el filtro
                metodosDisponibles.clear();
                todasLasVentas.forEach(venta => {
                    if (venta.metodoPago) {
                        metodosDisponibles.add(venta.metodoPago);
                    }
                });
                
                // Actualizar selector de métodos de pago
                const metodoPagoFiltro = document.getElementById('metodoPagoFiltro');
                metodoPagoFiltro.innerHTML = '<option value="">Todos</option>';
                metodosDisponibles.forEach(metodo => {
                    const option = document.createElement('option');
                    option.value = metodo;
                    option.textContent = metodo;
                    metodoPagoFiltro.appendChild(option);
                });
                
                // Aplicar filtros iniciales (sin filtros)
                aplicarFiltros();
                
                // Mostrar resultados
                document.getElementById('loading').classList.add('hidden');
                document.getElementById('results').classList.remove('hidden');
                
            } catch (error) {
                document.getElementById('loading').classList.add('hidden');
                alert(`Error al procesar los datos: ${error.message}\n\nAsegúrate de pegar el JSON correctamente exportado.`);
            }
        }
        
        // Función para procesar una venta individual
        function procesarVenta(venta) {
            let fecha = venta.saleDate || venta.date || '';
            if (fecha && typeof fecha === 'object' && fecha.seconds) {
                // Convertir timestamp de Firestore
                fecha = new Date(fecha.seconds * 1000).toISOString();
            }
            
            return {
                id: venta.id || '',
                fecha: fecha,
                factura: venta.invoiceNumber || venta.invoiceNo || '',
                cliente: venta.customerName || venta.customer?.name || 'Sin cliente',
                total: venta.totalAmount || venta.total || 0,
                metodoPago: venta.paymentType || '',
                estado: venta.status || venta.paymentStatus || '',
                problematica: !venta.paymentType || venta.paymentType === '',
                datos: venta  // Guardar los datos completos para detalles
            };
        }
        
        // Listeners para los filtros
        document.getElementById('aplicarFiltro').addEventListener('click', aplicarFiltros);
        document.getElementById('limpiarFiltro').addEventListener('click', limpiarFiltros);
        
        // Función para aplicar filtros
        function aplicarFiltros() {
            const fechaInicio = document.getElementById('fechaInicioFiltro').value;
            const fechaFin = document.getElementById('fechaFinFiltro').value;
            const metodoPago = document.getElementById('metodoPagoFiltro').value;
            const invoiceNo = document.getElementById('invoiceNoFiltro').value.trim();
            const soloProblemas = document.getElementById('problemasCheck').checked;
            
            ventasFiltradas = todasLasVentas.filter(venta => {
                // Filtro de fecha inicio
                if (fechaInicio && new Date(venta.fecha) < new Date(fechaInicio)) return false;
                
                // Filtro de fecha fin
                if (fechaFin) {
                    const fechaFinLimit = new Date(fechaFin);
                    fechaFinLimit.setHours(23, 59, 59, 999);
                    if (new Date(venta.fecha) > fechaFinLimit) return false;
                }
                
                // Filtro de método de pago
                if (metodoPago && venta.metodoPago !== metodoPago) return false;
                
                // Filtro de número de factura
                if (invoiceNo && !venta.factura.toString().includes(invoiceNo)) return false;
                
                // Filtro de solo problemas
                if (soloProblemas && !venta.problematica) return false;
                
                return true;
            });
            
            // Actualizar tabla y resumen
            actualizarTablaVentas();
            actualizarResumen();
        }
        
        // Función para limpiar filtros
        function limpiarFiltros() {
            document.getElementById('fechaInicioFiltro').value = '';
            document.getElementById('fechaFinFiltro').value = '';
            document.getElementById('metodoPagoFiltro').value = '';
            document.getElementById('invoiceNoFiltro').value = '';
            document.getElementById('problemasCheck').checked = false;
            
            aplicarFiltros();
        }
        
        // Función para actualizar la tabla de ventas
        function actualizarTablaVentas() {
            const tbody = document.getElementById('ventasTableBody');
            tbody.innerHTML = '';
            
            // Actualizar contador de resultados
            document.getElementById('resultsCount').textContent = `Mostrando ${ventasFiltradas.length} de ${todasLasVentas.length} transacciones`;
            
            // Mostrar mensaje de vacío si no hay resultados
            if (ventasFiltradas.length === 0) {
                document.getElementById('ventasTable').classList.add('hidden');
                document.getElementById('emptyState').classList.remove('hidden');
                return;
            }
            
            // Mostrar tabla si hay resultados
            document.getElementById('ventasTable').classList.remove('hidden');
            document.getElementById('emptyState').classList.add('hidden');
            
            // Agregar filas a la tabla
            ventasFiltradas.forEach(venta => {
                const tr = document.createElement('tr');
                if (venta.problematica) {
                    tr.classList.add('problematica');
                }
                
                // Formatear fecha
                let fechaFormateada = 'Sin fecha';
                if (venta.fecha) {
                    try {
                        fechaFormateada = new Date(venta.fecha).toLocaleString();
                    } catch (e) {
                        fechaFormateada = venta.fecha;
                    }
                }
                
                // Formatear método de pago
                let metodoPagoHtml = '';
                if (!venta.metodoPago) {
                    metodoPagoHtml = '<span class="error">⚠️ NO DEFINIDO</span>';
                } else {
                    metodoPagoHtml = `<span class="metodo-pago">${venta.metodoPago}</span>`;
                }
                
                // Formatear el monto total con separación de miles
                const totalFormateado = venta.total ? venta.total.toLocaleString('es-DO', {
                    minimumFractionDigits: 2,
                    maximumFractionDigits: 2
                }) : '0.00';
                
                tr.innerHTML = `
                    <td>${fechaFormateada}</td>
                    <td>${venta.factura}</td>
                    <td>${venta.cliente}</td>
                    <td>RD$ ${totalFormateado}</td>
                    <td>${metodoPagoHtml}</td>
                    <td>${venta.estado || 'N/A'}</td>
                    <td>
                        <button onclick='mostrarDetalles(${JSON.stringify(venta).replace(/'/g, "\\'")})'
                                style="padding: 5px 10px;">Ver Detalles</button>
                    </td>
                `;
                
                tbody.appendChild(tr);
            });
        }
        
        // Función para actualizar el resumen
        function actualizarResumen() {
            const totalVentas = ventasFiltradas.length;
            const ventasConProblemas = ventasFiltradas.filter(v => v.problematica).length;
            const porcentajeProblemas = totalVentas > 0 ? (ventasConProblemas / totalVentas * 100).toFixed(2) : 0;
            
            // Agrupar por método de pago
            const metodosResumen = {};
            ventasFiltradas.forEach(venta => {
                const metodo = venta.metodoPago || 'NO DEFINIDO';
                if (!metodosResumen[metodo]) {
                    metodosResumen[metodo] = 0;
                }
                metodosResumen[metodo]++;
            });
            
            let metodosHtml = '';
            Object.keys(metodosResumen).sort().forEach(metodo => {
                const porcentaje = (metodosResumen[metodo] / totalVentas * 100).toFixed(2);
                const esProblematico = metodo === 'NO DEFINIDO';
                const claseEstilo = esProblematico ? 'error' : 'success';
                
                metodosHtml += `
                    <div>
                        <span class="${claseEstilo}">
                            ${metodo}: ${metodosResumen[metodo]} ventas (${porcentaje}%)
                        </span>
                    </div>
                `;
            });
            
            // Actualizar el resumen
            document.getElementById('resumen').innerHTML = `
                <h2>Resumen de Análisis</h2>
                <div style="display: flex; flex-wrap: wrap; gap: 15px;">
                    <div>
                        <strong>Total de Ventas:</strong> 
                        <span class="success">${totalVentas}</span>
                    </div>
                    <div>
                        <strong>Ventas con Problemas:</strong> 
                        <span class="${ventasConProblemas > 0 ? 'error' : 'success'}">
                            ${ventasConProblemas} (${porcentajeProblemas}%)
                        </span>
                    </div>
                </div>
                
                <h3>Métodos de Pago:</h3>
                <div style="display: flex; flex-wrap: wrap; gap: 10px; flex-direction: column;">
                    ${metodosHtml}
                </div>
                
                <div style="margin-top: 15px;">
                    <strong>Estado del Sistema:</strong> 
                    <span class="${ventasConProblemas > 0 ? 'warning' : 'success'}">
                        ${ventasConProblemas > 0 ? 
                          '⚠️ Hay transacciones sin método de pago definido' : 
                          '✅ Todos los métodos de pago están correctamente definidos'}
                    </span>
                </div>
            `;
        }
        
        // Función para mostrar detalles de una venta
        window.mostrarDetalles = function(venta) {
            let detallesHtml = '<h2>Detalles de la Transacción</h2>';
            
            // Información general
            detallesHtml += `
                <div style="margin-bottom: 20px;">
                    <strong>Factura:</strong> ${venta.factura}<br>
                    <strong>Fecha:</strong> ${new Date(venta.fecha).toLocaleString()}<br>
                    <strong>Cliente:</strong> ${venta.cliente}<br>
                    <strong>Total:</strong> RD$ ${venta.total.toLocaleString('es-DO', {minimumFractionDigits: 2})}<br>
                    <strong>Método de Pago:</strong> ${venta.metodoPago || '<span class="error">NO DEFINIDO</span>'}<br>
                    <strong>Estado:</strong> ${venta.estado || 'N/A'}<br>
                </div>
            `;
            
            // Productos de la venta
            if (venta.datos.productList && venta.datos.productList.length > 0) {
                detallesHtml += '<h3>Productos:</h3>';
                detallesHtml += '<table style="width:100%; margin-bottom: 20px;">';
                detallesHtml += '<tr><th>Producto</th><th>Cantidad</th><th>Precio</th><th>Total</th></tr>';
                
                venta.datos.productList.forEach(producto => {
                    detallesHtml += `
                        <tr>
                            <td>${producto.productName || producto.name || 'Producto sin nombre'}</td>
                            <td>${producto.quantity || 1}</td>
                            <td>RD$ ${(producto.sellingPrice || 0).toLocaleString('es-DO', {minimumFractionDigits: 2})}</td>
                            <td>RD$ ${((producto.sellingPrice || 0) * (producto.quantity || 1)).toLocaleString('es-DO', {minimumFractionDigits: 2})}</td>
                        </tr>
                    `;
                });
                
                detallesHtml += '</table>';
            }
            
            // Datos completos (para debugging)
            detallesHtml += `
                <details>
                    <summary>Ver datos completos (JSON)</summary>
                    <pre style="background: #f5f5f5; padding: 10px; overflow: auto; max-height: 300px;">${JSON.stringify(venta.datos, null, 2)}</pre>
                </details>
            `;
            
            // Mostrar en un modal o alerta
            const modal = document.createElement('div');
            modal.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0,0,0,0.7);
                display: flex;
                align-items: center;
                justify-content: center;
                z-index: 1000;
            `;
            
            const modalContent = document.createElement('div');
            modalContent.style.cssText = `
                background: white;
                padding: 20px;
                border-radius: 5px;
                max-width: 80%;
                max-height: 80%;
                overflow: auto;
                position: relative;
            `;
            
            const closeButton = document.createElement('button');
            closeButton.textContent = 'X';
            closeButton.style.cssText = `
                position: absolute;
                top: 10px;
                right: 10px;
                background: #f44336;
                color: white;
                border: none;
                border-radius: 50%;
                width: 30px;
                height: 30px;
                font-weight: bold;
                cursor: pointer;
            `;
            closeButton.onclick = function() {
                document.body.removeChild(modal);
            };
            
            modalContent.innerHTML = detallesHtml;
            modalContent.appendChild(closeButton);
            modal.appendChild(modalContent);
            document.body.appendChild(modal);
            
            // Cerrar al hacer clic fuera
            modal.addEventListener('click', function(event) {
                if (event.target === modal) {
                    document.body.removeChild(modal);
                }
            });
        };
    </script>
</body>
</html>
EOL

    echo -e "${VERDE}Archivo HTML generado: $ARCHIVO_HTML${RESET}"
    echo ""
    echo -e "${AZUL}Abriendo archivo en el navegador...${RESET}"

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
        echo -e "${AMARILLO}No se pudo abrir automáticamente. El archivo está disponible en:${RESET}"
        echo -e "${VERDE}$ARCHIVO_HTML${RESET}"
    fi

    echo ""
    echo -e "${AZUL}===========================================================${RESET}"
    echo -e "${VERDE}INSTRUCCIONES${RESET}"
    echo -e "${AZUL}===========================================================${RESET}"
    echo -e "1. Se ha abierto una página web en tu navegador"
    echo -e "2. Sigue las instrucciones en la página para exportar tus datos de Firebase"
    echo -e "3. Pega los datos JSON en el área de texto y haz clic en 'Cargar Datos'"
    echo ""
    echo -e "${AMARILLO}NOTA: Esta versión es 100% offline y no requiere autenticación${RESET}"
    echo -e "${AZUL}===========================================================${RESET}"
    
    read -p "Presiona Enter para volver al menú principal..."
    mostrar_menu
}

# Función para el verificador web directo
ejecutar_verificador_web_directo() {
    echo -e "${AZUL}Iniciando el verificador web directo...${RESET}"
    echo ""
    
    # Verificar si el archivo de script original existe
    if [ -f "$SCRIPT_DIR/verificador_web_directo.sh" ]; then
        # Dar permisos de ejecución si no los tiene
        chmod +x "$SCRIPT_DIR/verificador_web_directo.sh"
        # Ejecutar el script original
        "$SCRIPT_DIR/verificador_web_directo.sh" "informe"
    else
        echo -e "${ROJO}El script verificador_web_directo.sh no existe.${RESET}"
        echo -e "${AMARILLO}Usando el verificador offline como alternativa...${RESET}"
        ejecutar_verificador_offline
    fi
    
    read -p "Presiona Enter para volver al menú principal..."
    mostrar_menu
}

# Función para solicitar número de factura
solicitar_numero_factura() {
    echo -n -e "${VERDE}Ingrese el número de factura a verificar:${RESET} "
    read numero_factura
    
    if [[ -z "$numero_factura" ]]; then
        echo -e "${ROJO}Número de factura inválido.${RESET}"
        mostrar_menu
        return
    fi
    
    echo -e "${AZUL}Verificando factura #$numero_factura...${RESET}"
    
    # Verificar si el archivo de script original existe
    if [ -f "$SCRIPT_DIR/verificador_web_directo.sh" ]; then
        # Dar permisos de ejecución si no los tiene
        chmod +x "$SCRIPT_DIR/verificador_web_directo.sh"
        # Ejecutar el script original con el número de factura
        "$SCRIPT_DIR/verificador_web_directo.sh" "$numero_factura"
    else
        echo -e "${ROJO}El script verificador_web_directo.sh no existe.${RESET}"
        echo -e "${AMARILLO}Usando el verificador offline como alternativa...${RESET}"
        ejecutar_verificador_offline
    fi
    
    read -p "Presiona Enter para volver al menú principal..."
    mostrar_menu
}

# Función para generar informe completo
generar_informe_completo() {
    echo -e "${AZUL}Generando informe completo...${RESET}"
    echo ""
    
    # Verificar si el archivo de script original existe
    if [ -f "$SCRIPT_DIR/generar_informe_metodos_pago.sh" ]; then
        # Dar permisos de ejecución si no los tiene
        chmod +x "$SCRIPT_DIR/generar_informe_metodos_pago.sh"
        # Ejecutar el script original
        "$SCRIPT_DIR/generar_informe_metodos_pago.sh"
    else
        echo -e "${ROJO}El script generar_informe_metodos_pago.sh no existe.${RESET}"
        echo -e "${AMARILLO}Usando el verificador offline como alternativa...${RESET}"
        ejecutar_verificador_offline
    fi
    
    read -p "Presiona Enter para volver al menú principal..."
    mostrar_menu
}

# Función para salir
salir() {
    echo -e "${VERDE}¡Gracias por usar el Verificador Universal de Métodos de Pago!${RESET}"
    exit 0
}

# Iniciar el programa
mostrar_menu
