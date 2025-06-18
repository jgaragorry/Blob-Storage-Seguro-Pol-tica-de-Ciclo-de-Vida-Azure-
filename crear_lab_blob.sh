#!/bin/bash

# Configuración
RG="rg-blob-seguro"
LOCATION="eastus"
STORAGE="stlabsecureblob$RANDOM"
CONTAINER="contenedor-seguro"

echo "🔧 Creando grupo de recursos..."
az group create --name $RG --location $LOCATION --tags docente=gmtech proyecto=lab_blob_seguro

echo "🔧 Creando cuenta de almacenamiento..."
az storage account create \
  --name $STORAGE \
  --resource-group $RG \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2 \
  --tags docente=gmtech proyecto=lab_blob_seguro \
  --enable-hierarchical-namespace false

echo "🔍 Obteniendo Object ID del usuario actual..."
OBJECT_ID=$(az ad signed-in-user show --query objectId -o tsv)

echo "🔐 Asignando rol 'Storage Blob Data Contributor' al usuario..."
az role assignment create \
  --assignee-object-id "$OBJECT_ID" \
  --assignee-principal-type User \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RG/providers/Microsoft.Storage/storageAccounts/$STORAGE"

echo "⏳ Esperando a que se propague el rol (15s)..."
sleep 15

echo "📦 Creando contenedor privado..."
az storage container create --account-name $STORAGE --name $CONTAINER --auth-mode login --public-access off

echo "📄 Creando archivo ejemplo.txt..."
echo "Hola desde Azure Blob Storage" > ejemplo.txt

echo "📤 Subiendo archivo ejemplo.txt..."
az storage blob upload \
  --account-name $STORAGE \
  --container-name $CONTAINER \
  --name ejemplo.txt \
  --file ejemplo.txt \
  --auth-mode login

echo "🔁 Habilitando seguimiento de último acceso..."
az storage blob-service-properties update \
  --account-name $STORAGE \
  --resource-group $RG \
  --enable-last-access-tracking true \
  --tracking-granularity-in-days 1 \
  --blob-types blockBlob

echo "⏱️ Esperando 10 segundos antes de aplicar política..."
sleep 10

echo "📋 Aplicando política de ciclo de vida..."
az storage account management-policy create \
  --account-name $STORAGE \
  --resource-group $RG \
  --policy '{
    "rules": [
      {
        "enabled": true,
        "name": "mover-cool-eliminar",
        "type": "Lifecycle",
        "definition": {
          "actions": {
            "baseBlob": {
              "tierToCool": {
                "daysAfterLastAccessTimeGreaterThan": 30
              },
              "delete": {
                "daysAfterLastAccessTimeGreaterThan": 90
              }
            }
          },
          "filters": {
            "blobTypes": [ "blockBlob" ]
          }
        }
      }
    ]
  }'

echo "🔍 Verificando configuración final..."

echo "📄 Política de ciclo de vida actual:"
az storage account management-policy show \
  --account-name $STORAGE \
  --resource-group $RG \
  --query "policy.rules" \
  --output jsonc

echo "📄 Seguimiento del último acceso:"
az storage account blob-service-properties show \
  --account-name $STORAGE \
  --resource-group $RG \
  --query "lastAccessTimeTrackingPolicy" \
  --output jsonc

echo "✅ Todo listo. Cuenta creada: $STORAGE"
