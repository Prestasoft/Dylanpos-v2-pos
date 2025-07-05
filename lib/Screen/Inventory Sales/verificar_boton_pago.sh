#!/bin/bash

# Este script ayuda a verificar y corregir problemas con el botón de pago en inventory_sales.dart

echo "=== Verificador de botón de pago ==="
echo "Este script te ayudará a encontrar y corregir problemas con el botón de pago."

INVENTORY_SALES_PATH="/Users/miguelcastillo/Desktop/Dylanpos-v2-pos/lib/Screen/Inventory Sales/inventory_sales.dart"

# Verificar si el archivo existe
if [ ! -f "$INVENTORY_SALES_PATH" ]; then
    echo "ERROR: No se encontró el archivo inventory_sales.dart"
    exit 1
fi

# Buscar líneas duplicadas de set post.toJson()
echo "Buscando líneas duplicadas de 'await ref.push().set(post.toJson())'..."
DUPLICATED_LINES=$(grep -n "await ref.push().set(post.toJson());" "$INVENTORY_SALES_PATH" | wc -l)

if [ "$DUPLICATED_LINES" -gt 1 ]; then
    echo "PROBLEMA ENCONTRADO: Hay $DUPLICATED_LINES líneas que llaman a 'await ref.push().set(post.toJson());'"
    echo "Esto puede causar errores y transacciones duplicadas."
    
    echo "Líneas donde aparece:"
    grep -n "await ref.push().set(post.toJson());" "$INVENTORY_SALES_PATH"
    
    echo ""
    echo "SOLUCIÓN: Debes eliminar la línea duplicada. Típicamente, debes mantener solo la que está dentro del bloque try-catch."
else
    echo "OK: No se encontraron líneas duplicadas de 'await ref.push().set(post.toJson())'."
fi

# Verificar si se valida que el cliente esté seleccionado
echo ""
echo "Verificando validación de cliente seleccionado..."
CLIENT_VALIDATION=$(grep -n "selectedUserId == null" "$INVENTORY_SALES_PATH" | wc -l)

if [ "$CLIENT_VALIDATION" -eq 0 ]; then
    echo "PROBLEMA ENCONTRADO: No se está validando si selectedUserId es nulo."
    echo "Esto puede causar errores cuando se intenta procesar un pago sin seleccionar un cliente."
    
    echo ""
    echo "SOLUCIÓN: Añade esta validación antes de procesar el pago:"
    echo "else if (selectedUserId == null) {"
    echo "  EasyLoading.showError('Por favor seleccione un cliente');"
    echo "}"
else
    echo "OK: Se encontró validación para selectedUserId."
fi

# Verificar variables ref y post
echo ""
echo "Verificando definición de variables ref y post..."
LOCAL_REF_DEFINITION=$(grep -n "DatabaseReference ref = FirebaseDatabase" "$INVENTORY_SALES_PATH" | wc -l)

if [ "$LOCAL_REF_DEFINITION" -gt 0 ]; then
    echo "PROBLEMA POTENCIAL: La variable 'ref' está definida con alcance local."
    echo "Esto puede causar errores cuando se intenta acceder a 'ref' fuera del bloque donde se define."
    
    echo ""
    echo "SOLUCIÓN: Declara 'ref' y 'post' fuera del bloque try-catch para que estén disponibles en todo el ámbito:"
    echo "// Declarar las variables fuera del bloque try"
    echo "DatabaseReference ref;"
    echo "SaleTransactionModel post;"
    echo ""
    echo "try {"
    echo "  ref = FirebaseDatabase.instance.ref(...);"
    echo "  ..."
    echo "  post = checkLossProfit(...);"
    echo "}"
else
    echo "No se pudo determinar cómo están definidas las variables ref y post."
fi

# Verificar manejo de múltiples clics
echo ""
echo "Verificando protección contra múltiples clics..."
CLICK_PROTECTION=$(grep -n "saleButtonClicked = true" "$INVENTORY_SALES_PATH" | wc -l)

if [ "$CLICK_PROTECTION" -gt 0 ]; then
    echo "OK: Se encontró código que establece 'saleButtonClicked = true'."
    
    INITIAL_CHECK=$(grep -n "if (saleButtonClicked)" "$INVENTORY_SALES_PATH" | wc -l)
    
    if [ "$INITIAL_CHECK" -eq 0 ]; then
        echo "PROBLEMA ENCONTRADO: No se encontró una verificación inicial de 'saleButtonClicked'."
        echo "Esto puede permitir múltiples clics en el botón de pago."
        
        echo ""
        echo "SOLUCIÓN: Añade esta verificación al inicio de la función onPressed:"
        echo "// Evitar múltiples clics"
        echo "if (saleButtonClicked) {"
        echo "  print('DEBUG: Botón ya presionado, ignorando clic');"
        echo "  return;"
        echo "}"
    else
        echo "OK: Se encontró verificación inicial de 'saleButtonClicked'."
    fi
else
    echo "PROBLEMA ENCONTRADO: No se encontró código que establezca 'saleButtonClicked = true'."
    echo "Esto puede causar problemas con el estado del botón."
fi

echo ""
echo "=== Recomendaciones finales ==="
echo "1. Asegúrate de que el botón de pago tenga la validación adecuada para 'selectedUserId'"
echo "2. Verifica que las variables 'ref' y 'post' estén definidas con el alcance correcto"
echo "3. Elimina cualquier línea duplicada de 'await ref.push().set(post.toJson());'"
echo "4. Implementa protección contra múltiples clics al inicio de la función onPressed"
echo "5. Asegúrate de que 'saleButtonClicked' se establezca a 'false' en todos los casos de error"
echo ""
echo "Estas modificaciones deberían resolver los problemas con el botón de pago."
