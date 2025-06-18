#!/bin/bash

RG="rg-blob-seguro"

echo "⚠️  Esto eliminará el grupo de recursos '$RG' y TODOS los recursos dentro de él de forma permanente."
read -p "¿Estás seguro que deseas continuar? (s/N): " confirm

if [[ "$confirm" =~ ^[sS]$ ]]; then
  echo "🗑️ Eliminando grupo de recursos '$RG'..."
  az group delete --name "$RG" --yes --no-wait

  echo "⏳ Esperando a que finalice la eliminación..."
  while az group exists --name "$RG" | grep -q true; do
    echo "⌛ Aún eliminando... esperando 10 segundos..."
    sleep 10
  done

  echo "✅ El grupo de recursos '$RG' ha sido eliminado correctamente."
else
  echo "❌ Operación cancelada por el usuario."
fi
