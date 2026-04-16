#!/bin/bash
# ============================================================
# Aplica tasks_system_migration.sql en los 4 esquemas
# Uso:
#   ./apply_tasks_migration.sh
#
# Requisitos:
#   - SSH configurado al servidor (72.62.163.74)
#   - sshpass si la conexión requiere password
# ============================================================

set -e

SERVER="root@72.62.163.74"
REMOTE_DIR="/tmp"
MIGRATION_FILE="tasks_system_migration.sql"
SCHEMAS=("stg" "sde" "sdo" "rom")

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOCAL_SQL="$SCRIPT_DIR/$MIGRATION_FILE"

if [ ! -f "$LOCAL_SQL" ]; then
  echo "❌ No se encontró $LOCAL_SQL"
  exit 1
fi

echo "📤 Subiendo $MIGRATION_FILE al servidor..."
scp "$LOCAL_SQL" "$SERVER:$REMOTE_DIR/"

echo ""
echo "🔧 Aplicando columnas en public.users (solo una vez)..."
ssh "$SERVER" "sudo -u postgres psql victorpos -c \"
  ALTER TABLE public.users
    ADD COLUMN IF NOT EXISTS scoped_designation_id INT,
    ADD COLUMN IF NOT EXISTS linked_employee_id UUID;
\""

echo ""
for SCHEMA in "${SCHEMAS[@]}"; do
  echo "🔄 Aplicando migración en esquema: $SCHEMA"
  ssh "$SERVER" "sed 's/{{SCHEMA}}/$SCHEMA/g' $REMOTE_DIR/$MIGRATION_FILE | sudo -u postgres psql victorpos"
  echo "✅ $SCHEMA completado"
  echo ""
done

echo ""
echo "🔍 Verificando resultados..."
for SCHEMA in "${SCHEMAS[@]}"; do
  COUNT=$(ssh "$SERVER" "sudo -u postgres psql victorpos -tAc \"
    SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = '$SCHEMA' AND table_name = 'designations'
      AND column_name IN ('manager_user_id','sla_days','sla_hours','sla_minutes','color_hex');
  \"")
  TASKS_EXISTS=$(ssh "$SERVER" "sudo -u postgres psql victorpos -tAc \"
    SELECT COUNT(*) FROM information_schema.tables
    WHERE table_schema = '$SCHEMA' AND table_name = 'tasks';
  \"")
  echo "  $SCHEMA: designations +$COUNT columnas, tasks table = $TASKS_EXISTS"
done

echo ""
echo "✅ Migración de tasks completada en los 4 esquemas"
