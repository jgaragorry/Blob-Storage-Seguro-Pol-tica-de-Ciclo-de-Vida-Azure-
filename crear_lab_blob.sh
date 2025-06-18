#!/bin/bash

# Nombre del grupo de recursos y cuenta de almacenamiento
RG="rg-blob-seguro"
STORAGE="stlabsecureblob$RANDOM"
LOCATION="eastus"
CONTAINER="privado"
ARCHIVO="ejemplo.txt"
ROL="Storage Blob Data Contributor"
USER_EMAIL=$(az account show --query user.name -o tsv)

echo "🔧 Creando grupo de recursos..."
az group create --name $RG --location $LOCATION --tags docente=gmtech proyecto=lab_blob_seguro

echo "🔧 Creando cuenta de almacenamiento..."
az storage account create \
  --name $STORAGE \
  --resource-group $RG \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2 \
  --enable-hierarchical-namespace false \
  --https-only true \
  --tags docente=gmtech proyecto=lab_blob_seguro

echo "🔐 Verificando y asignando rol '$ROL' si es necesario..."
ASSIGNED=$(az role assignment list --assignee "$USER_EMAIL" --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RG/providers/Microsoft.Storage/storageAccounts/$STORAGE" --query "[?roleDefinitionName=='$ROL'] | length(@)" -o tsv)

if [[ "$ASSIGNED" == "0" ]]; then
  echo "🛠️ Asignando rol a $USER_EMAIL..."
  az role assignment create \
    --assignee "$USER_EMAIL" \
    --role "$ROL" \
    --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RG/providers/Microsoft.Storage/storageAccounts/$STORAGE" || \
    echo "⚠️ No se pudo asignar el rol. Asegúrate de tener permisos suficientes o hazlo manualmente desde el portal."
else
  echo "✅ Rol ya asignado."
fi

echo "⏳ Esperando 15 segundos para propagación del rol..."
sleep 15

echo "📦 Creando contenedor privado..."
az storage container create \
  --name $CONTAINER \
  --account-name $STORAGE \
  --auth-mode login \
  --public-access off

echo "📄 Creando archivo $ARCHIVO..."
echo "Este es un archivo de prueba para el laboratorio de blob seguro." > $ARCHIVO

echo "📤 Subiendo archivo..."
az storage blob upload \
  --account-name $STORAGE \
  --container-name $CONTAINER \
  --name $ARCHIVO \
  --file $ARCHIVO \
  --auth-mode login

echo "⏱️ Esperando 10 segundos..."
sleep 10

echo "📋 Aplicando política de ciclo de vida..."
cat > lifecycle.json <<EOF
{
  "rules": [
    {
      "enabled": true,
      "name": "delete-after-7-days",
      "type": "Lifecycle",
      "definition": {
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": ["$CONTAINER/"]
        },
        "actions": {
          "baseBlob": {
            "delete": {
              "daysAfterModificationGreaterThan": 7
            }
          }
        }
      }
    }
  ]
}
EOF

az storage account management-policy create \
  --account-name $STORAGE \
  --resource-group $RG \
  --policy @lifecycle.json

echo "✅ Todo listo. Cuenta de almacenamiento: $STORAGE"