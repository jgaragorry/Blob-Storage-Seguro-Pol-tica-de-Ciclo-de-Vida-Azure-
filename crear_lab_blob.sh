#!/bin/bash

# Variables
RG="rg-blob-seguro"
STORAGE="stlabsecureblob$RANDOM"
LOCATION="eastus"
CONTAINER="privado"
USER_EMAIL="$(az account show --query user.name -o tsv)"
POLICY_NAME="DefaultManagementPolicy"

echo "🔧 Creando grupo de recursos..."
az group create --name "$RG" --location "$LOCATION" --tags docente=gmtech proyecto=lab_blob_seguro

echo "🔧 Creando cuenta de almacenamiento..."
az storage account create --name "$STORAGE" --resource-group "$RG" --location "$LOCATION"   --sku Standard_LRS --kind StorageV2 --access-tier Hot --https-only true   --tags docente=gmtech proyecto=lab_blob_seguro

echo "🔐 Verificando y asignando rol 'Storage Blob Data Contributor' si es necesario..."
if ! az role assignment list --assignee "$USER_EMAIL" --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RG/providers/Microsoft.Storage/storageAccounts/$STORAGE" --query "[?roleDefinitionName=='Storage Blob Data Contributor']" | grep -q "roleDefinitionName"; then
  az role assignment create --assignee "$USER_EMAIL"     --role "Storage Blob Data Contributor"     --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RG/providers/Microsoft.Storage/storageAccounts/$STORAGE"
  echo "⏳ Esperando propagación del rol (15s)..."
  sleep 15
fi

echo "📦 Creando contenedor privado..."
az storage container create --name "$CONTAINER" --account-name "$STORAGE" --auth-mode login

echo "📄 Creando archivo ejemplo.txt..."
echo "Este es un archivo de ejemplo para cargar en Azure Blob." > ejemplo.txt

echo "📤 Subiendo archivo ejemplo.txt..."
az storage blob upload --account-name "$STORAGE" --container-name "$CONTAINER" --name ejemplo.txt   --file ejemplo.txt --auth-mode login

echo "🔁 Habilitando seguimiento del último acceso..."
az storage account blob-service-properties update   --account-name "$STORAGE"   --resource-group "$RG"   --last-access-time-tracking-policy '{"enable": true, "trackingGranularityInDays": 1, "blobType": ["blockBlob"]}'

echo "⏱️ Esperando 10 segundos..."
sleep 10

echo "📋 Aplicando política de ciclo de vida..."
az storage account management-policy create --account-name "$STORAGE" --resource-group "$RG" --policy '{
  "policy": {
    "rules": [
      {
        "enabled": true,
        "name": "delete-old-blobs",
        "type": "Lifecycle",
        "definition": {
          "filters": {
            "blobTypes": [ "blockBlob" ],
            "prefixMatch": [ "" ]
          },
          "actions": {
            "baseBlob": {
              "delete": {
                "daysAfterLastAccessTimeGreaterThan": 30
              }
            }
          }
        }
      }
    ]
  }
}'

echo "✅ Todo listo. Cuenta de almacenamiento: $STORAGE"
