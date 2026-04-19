#!/bin/bash
# ============================================================
# SCRIPT DE DESPLIEGUE A LABS - VICTOR GUZMAN POS
# Servidor: lab.victorguzmanfotografia.com (2.24.215.25)
# Solo despliega frontend Flutter Web compilado
# ============================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuración
LABS_IP="2.24.215.25"
LABS_USER="root"
LABS_PASS="Elary16081991@"
REMOTE_PATH="/var/www/victorpos-app"

echo -e "${PURPLE}"
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║              🧪 DESPLIEGUE A LABS (PRUEBAS)                      ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Paso 1: Seleccionar ambiente
echo -e "${YELLOW}¿Qué desea desplegar?${NC}"
echo "  [f] Solo Frontend (Flutter Web)"
echo "  [b] Solo Backend (API Node.js)"
echo "  [a] Ambos (Frontend + Backend)"
echo "  [d] Solo sincronizar Base de Datos"
read -p "Seleccione (f/b/a/d): " DEPLOY_TYPE
DEPLOY_TYPE=${DEPLOY_TYPE:-f}

# Paso 2: Descripción
read -p "Descripción del cambio (Enter para skip): " DESCRIPTION
DESCRIPTION=${DESCRIPTION:-"Despliegue a labs"}

echo ""
echo -e "${CYAN}📋 Despliegue: ${DEPLOY_TYPE} | ${DESCRIPTION}${NC}"
echo ""

# ---- FRONTEND ----
if [[ "$DEPLOY_TYPE" == "f" || "$DEPLOY_TYPE" == "a" ]]; then
    echo -e "${YELLOW}🔨 Compilando Flutter Web...${NC}"
    flutter build web --release 2>&1 | grep -E "(Compiling|Built|Error)" || true

    if [ ! -d "build/web" ]; then
        echo -e "${RED}❌ Error: build/web no existe${NC}"
        exit 1
    fi
    echo -e "   ${GREEN}✓${NC} Build completado"

    echo -e "${YELLOW}📤 Subiendo frontend a labs...${NC}"
    sshpass -p "$LABS_PASS" rsync -avz --delete \
        -e "ssh -o StrictHostKeyChecking=no" \
        build/web/ \
        "$LABS_USER@$LABS_IP:$REMOTE_PATH/" 2>&1 | grep -E "(sent|total size|speedup)"
    echo -e "   ${GREEN}✓${NC} Frontend subido"
fi

# ---- BACKEND ----
if [[ "$DEPLOY_TYPE" == "b" || "$DEPLOY_TYPE" == "a" ]]; then
    echo -e "${YELLOW}📤 Sincronizando API backend a labs...${NC}"
    sshpass -p "$LABS_PASS" rsync -avz \
        --exclude='node_modules' --exclude='.env' --exclude='uploads' \
        -e "ssh -o StrictHostKeyChecking=no" \
        /var/www/victorpos-api/ \
        "$LABS_USER@$LABS_IP:/var/www/victorpos-api/" 2>&1 | grep -E "(sent|total size|speedup)" || {
        # Si no hay API local, copiar desde producción
        echo "Copiando desde producción..."
        sshpass -p "$LABS_PASS" ssh -o StrictHostKeyChecking=no "$LABS_USER@$LABS_IP" \
            "sshpass -p 'Elary16081991@' rsync -avz --exclude='node_modules' --exclude='.env' --exclude='uploads' -e 'ssh -o StrictHostKeyChecking=no' root@72.62.163.74:/var/www/victorpos-api/ /var/www/victorpos-api/" 2>&1 | tail -3
    }

    echo -e "${YELLOW}🔄 Reiniciando API en labs...${NC}"
    sshpass -p "$LABS_PASS" ssh -o StrictHostKeyChecking=no "$LABS_USER@$LABS_IP" \
        "cd /var/www/victorpos-api && npm install --production 2>&1 | tail -2 && pm2 restart victorpos-api" 2>&1 | tail -3
    echo -e "   ${GREEN}✓${NC} Backend actualizado"
fi

# ---- BASE DE DATOS ----
if [[ "$DEPLOY_TYPE" == "d" ]]; then
    echo -e "${YELLOW}📦 Sincronizando BD desde producción...${NC}"
    sshpass -p "$LABS_PASS" ssh -o StrictHostKeyChecking=no "$LABS_USER@$LABS_IP" "
        # Dump desde producción
        sshpass -p 'Elary16081991@' ssh -o StrictHostKeyChecking=no root@72.62.163.74 'sudo -u postgres pg_dump victorpos --no-owner --no-privileges' > /tmp/victorpos_dump.sql
        # Restaurar
        sudo -u postgres psql -c 'DROP DATABASE victorpos;' 2>/dev/null
        sudo -u postgres psql -c 'CREATE DATABASE victorpos OWNER victorpos;'
        sudo -u postgres psql victorpos < /tmp/victorpos_dump.sql 2>&1 | tail -3
        # Permisos
        sudo -u postgres psql victorpos -c 'GRANT USAGE ON SCHEMA stg TO victorpos; GRANT USAGE ON SCHEMA sde TO victorpos; GRANT USAGE ON SCHEMA sdo TO victorpos; GRANT USAGE ON SCHEMA rom TO victorpos; GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA stg TO victorpos; GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA sde TO victorpos; GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA sdo TO victorpos; GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA rom TO victorpos; GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO victorpos; GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA stg TO victorpos; GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA sde TO victorpos; GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA sdo TO victorpos; GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA rom TO victorpos; GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO victorpos;' 2>/dev/null
        rm /tmp/victorpos_dump.sql
        echo 'BD sincronizada'
    " 2>&1
    echo -e "   ${GREEN}✓${NC} Base de datos sincronizada"
fi

echo ""
echo -e "${PURPLE}"
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║              ✅ DESPLIEGUE LABS COMPLETADO                        ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${GREEN}Servidor:${NC} ${CYAN}http://2.24.215.25${NC}"
echo -e "${GREEN}URL:${NC} ${CYAN}http://lab.victorguzmanfotografia.com${NC} (cuando DNS esté configurado)"
echo ""
echo -e "${BLUE}Descripción: ${DESCRIPTION}${NC}"
