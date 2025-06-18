#!/bin/bash

RG="rg-blob-seguro"

echo "⚠️ Este script eliminará el grupo de recursos '$RG' y todo su contenido."
read -p "¿Estás seguro? (s/N): " confirm
if [[ "$confirm" =~ ^[sS]$ ]]; then
  echo "🗑️ Eliminando grupo de recursos '$RG'..."
  az group delete --name "$RG" --yes --no-wait
  echo "🕒 Eliminación en progreso..."
else
  echo "❌ Cancelado por el usuario."
fi
