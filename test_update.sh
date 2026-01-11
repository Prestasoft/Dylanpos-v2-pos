#!/bin/bash

# Script para probar el sistema de actualización automática

echo "🚀 Sistema de prueba de actualización automática"
echo "=============================================="
echo ""

# Función para mostrar el menú
show_menu() {
    echo "Selecciona una opción:"
    echo "1) Ver versión actual"
    echo "2) Simular actualización (cambiar a v1.0.1)"
    echo "3) Simular actualización forzada (cambiar a v2.0.0)"
    echo "4) Restaurar versión original (v1.0.0)"
    echo "5) Ejecutar aplicación Flutter"
    echo "6) Salir"
    echo ""
}

# Función para ver versión actual
view_version() {
    echo "📦 Versión actual en version.json:"
    cat web/version.json | python3 -m json.tool
    echo ""
}

# Función para actualizar versión
update_version() {
    local version=$1
    local force=$2
    local desc=$3
    
    cat > web/version.json << EOF
{
  "version": "$version",
  "releaseDate": "$(date +%Y-%m-%d)",
  "description": "$desc",
  "forceUpdate": $force
}
EOF
    
    echo "✅ Actualizado a versión $version"
    view_version
}

# Loop principal
while true; do
    show_menu
    read -p "Opción: " choice
    
    case $choice in
        1)
            view_version
            ;;
        2)
            update_version "1.0.1" "false" "Nueva actualización con mejoras de rendimiento y corrección de errores"
            echo "💡 La aplicación detectará el cambio en máximo 5 minutos"
            ;;
        3)
            update_version "2.0.0" "true" "Actualización mayor obligatoria con nuevas funcionalidades"
            echo "⚠️  Esta es una actualización forzada - el usuario no podrá cerrar el popup"
            ;;
        4)
            update_version "1.0.0" "false" "Versión inicial"
            echo "🔄 Restaurado a versión original"
            ;;
        5)
            echo "🌐 Iniciando aplicación Flutter..."
            echo "Presiona Ctrl+C para detener"
            flutter run -d chrome --web-renderer html
            ;;
        6)
            echo "👋 ¡Hasta luego!"
            exit 0
            ;;
        *)
            echo "❌ Opción inválida"
            ;;
    esac
    
    echo ""
    read -p "Presiona Enter para continuar..."
    clear
done