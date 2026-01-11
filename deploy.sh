#!/bin/bash
# ============================================
# SCRIPT DE DESPLIEGUE - VICTOR GUZMAN POS
# ============================================
# Uso: ./deploy.sh [version]
# Ejemplo: ./deploy.sh 2.1.0
# Si no se especifica versión, incrementa el patch automáticamente

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuración del servidor
SERVER_IP="72.62.163.74"
SERVER_USER="root"
SERVER_PASS="Elary16081991@"
REMOTE_PATH="/var/www/victorpos-app"
PROJECT_PATH="/Users/miguelcastillo/Desktop/Dylanpos-v2-pos"

# Archivos de versión
PUBSPEC_FILE="$PROJECT_PATH/pubspec.yaml"
INDEX_FILE="$PROJECT_PATH/web/index.html"
TOP_BAR_FILE="$PROJECT_PATH/lib/top_bar/top_bar.dart"
APP_VERSION_FILE="$PROJECT_PATH/web/app-version.json"

echo -e "${PURPLE}"
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║       DESPLIEGUE - VICTOR GUZMAN POS                               ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Función para obtener versión actual
get_current_version() {
    grep -E "^version:" "$PUBSPEC_FILE" | sed 's/version: //' | cut -d'+' -f1
}

# Función para incrementar versión
increment_version() {
    local version=$1
    local major minor patch
    IFS='.' read -r major minor patch <<< "$version"
    patch=$((patch + 1))
    echo "$major.$minor.$patch"
}

# Obtener versión actual
CURRENT_VERSION=$(get_current_version)
echo -e "${CYAN}📦 Versión actual: ${YELLOW}$CURRENT_VERSION${NC}"

# Determinar nueva versión
if [ -n "$1" ]; then
    NEW_VERSION="$1"
    echo -e "${CYAN}📌 Nueva versión especificada: ${YELLOW}$NEW_VERSION${NC}"
else
    NEW_VERSION=$(increment_version "$CURRENT_VERSION")
    echo -e "${CYAN}🔄 Auto-incrementando a: ${YELLOW}$NEW_VERSION${NC}"
fi

# Confirmar
echo ""
read -p "¿Continuar con la versión $NEW_VERSION? (s/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}❌ Despliegue cancelado${NC}"
    exit 1
fi

# Obtener descripción del cambio
echo ""
read -p "Descripción del cambio (Enter para usar default): " DESCRIPTION
if [ -z "$DESCRIPTION" ]; then
    DESCRIPTION="Actualización a versión $NEW_VERSION"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"

# PASO 1: Actualizar versiones en todos los archivos
echo -e "${YELLOW}📝 Paso 1: Actualizando versiones en archivos...${NC}"

# pubspec.yaml
BUILD_NUMBER=$(grep -E "^version:" "$PUBSPEC_FILE" | cut -d'+' -f2)
sed -i '' "s/version: $CURRENT_VERSION+$BUILD_NUMBER/version: $NEW_VERSION+$((BUILD_NUMBER + 1))/" "$PUBSPEC_FILE"
echo -e "   ${GREEN}✓${NC} pubspec.yaml: $NEW_VERSION+$((BUILD_NUMBER + 1))"

# web/index.html - REQUIRED_VERSION, title, version-text y comentario de versión
sed -i '' "s/const REQUIRED_VERSION = '.*'/const REQUIRED_VERSION = '$NEW_VERSION'/" "$INDEX_FILE"
sed -i '' "s/<title>Victor Guzman POS v.*<\/title>/<title>Victor Guzman POS v$NEW_VERSION<\/title>/" "$INDEX_FILE"
sed -i '' "s/<span id=\"version-text\">v.*<\/span>/<span id=\"version-text\">v$NEW_VERSION<\/span>/" "$INDEX_FILE"
sed -i '' "s/SISTEMA DE CONTROL DE VERSIONES v.*/SISTEMA DE CONTROL DE VERSIONES v$NEW_VERSION/" "$INDEX_FILE"
echo -e "   ${GREEN}✓${NC} index.html: $NEW_VERSION"

# top_bar.dart - version badge
sed -i '' "s/'v[0-9]*\.[0-9]*\.[0-9]*'/'v$NEW_VERSION'/" "$TOP_BAR_FILE"
echo -e "   ${GREEN}✓${NC} top_bar.dart: v$NEW_VERSION"

# log_in.dart - version badge in login screen
LOGIN_FILE="$PROJECT_PATH/lib/Screen/Authentication/log_in.dart"
sed -i '' "s/'v[0-9]*\.[0-9]*\.[0-9]*'/'v$NEW_VERSION'/" "$LOGIN_FILE"
echo -e "   ${GREEN}✓${NC} log_in.dart: v$NEW_VERSION"

# web/app-version.json
BUILD_DATE=$(date "+%Y%m%d-%H%M")
RELEASE_DATE=$(date "+%Y-%m-%d")
cat > "$APP_VERSION_FILE" << EOF
{
  "version": "$NEW_VERSION",
  "build": "$BUILD_DATE",
  "releaseDate": "$RELEASE_DATE",
  "environment": "production",
  "description": "$DESCRIPTION",
  "changelog": [
    "$DESCRIPTION"
  ],
  "forceUpdate": true
}
EOF
echo -e "   ${GREEN}✓${NC} app-version.json: $NEW_VERSION (build: $BUILD_DATE)"

# PASO 2: Compilar Flutter
echo ""
echo -e "${YELLOW}🔨 Paso 2: Compilando Flutter Web...${NC}"
cd "$PROJECT_PATH"
flutter build web --release 2>&1 | tail -5
if [ $? -eq 0 ]; then
    echo -e "   ${GREEN}✓${NC} Build completado exitosamente"
else
    echo -e "   ${RED}✗${NC} Error en la compilación"
    exit 1
fi

# PASO 3: Verificar que el build tiene la versión correcta
echo ""
echo -e "${YELLOW}🔍 Paso 3: Verificando versión en build...${NC}"
BUILD_VERSION=$(grep -o "REQUIRED_VERSION = '[^']*'" "$PROJECT_PATH/build/web/index.html" | cut -d"'" -f2)
if [ "$BUILD_VERSION" = "$NEW_VERSION" ]; then
    echo -e "   ${GREEN}✓${NC} Build verificado: $BUILD_VERSION"
else
    echo -e "   ${RED}✗${NC} Error: Build tiene versión incorrecta ($BUILD_VERSION)"
    exit 1
fi

# PASO 4: Subir archivos al servidor
echo ""
echo -e "${YELLOW}📤 Paso 4: Subiendo archivos al servidor...${NC}"
sshpass -p "$SERVER_PASS" rsync -avz --delete \
    -e "ssh -o StrictHostKeyChecking=no" \
    "$PROJECT_PATH/build/web/" \
    "$SERVER_USER@$SERVER_IP:$REMOTE_PATH/" 2>&1 | grep -E "(sent|total size|speedup)"

if [ $? -eq 0 ]; then
    echo -e "   ${GREEN}✓${NC} Archivos subidos correctamente"
else
    echo -e "   ${RED}✗${NC} Error subiendo archivos"
    exit 1
fi

# PASO 5: Verificar versión en servidor
echo ""
echo -e "${YELLOW}🔎 Paso 5: Verificando versión en servidor...${NC}"
SERVER_VERSION=$(sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" \
    "grep -o \"REQUIRED_VERSION = '[^']*'\" $REMOTE_PATH/index.html | cut -d\"'\" -f2")

if [ "$SERVER_VERSION" = "$NEW_VERSION" ]; then
    echo -e "   ${GREEN}✓${NC} Servidor actualizado: $SERVER_VERSION"
else
    echo -e "   ${RED}✗${NC} Error: Servidor tiene versión incorrecta ($SERVER_VERSION)"
    exit 1
fi

# Resumen final
echo ""
echo -e "${PURPLE}"
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                    ✅ DESPLIEGUE COMPLETADO                        ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${GREEN}Versión desplegada: ${YELLOW}$NEW_VERSION${NC}"
echo -e "${GREEN}Build: ${YELLOW}$BUILD_DATE${NC}"
echo -e "${GREEN}URL: ${CYAN}https://sistema.victorguzmanfotografia.com${NC}"
echo ""
echo -e "${BLUE}Los usuarios verán el popup de actualización automáticamente.${NC}"
echo ""
