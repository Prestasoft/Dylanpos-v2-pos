#!/bin/bash

# Script para desplegar reglas de Firebase Storage

echo "🔐 Desplegando reglas de Firebase Storage..."

# Verificar autenticación
if ! firebase projects:list &>/dev/null; then
  echo "❌ No estás autenticado. Ejecuta: firebase login"
  exit 1
fi

# Desplegar reglas de storage
firebase deploy --only storage

echo "✅ Reglas de Firebase Storage desplegadas correctamente"
