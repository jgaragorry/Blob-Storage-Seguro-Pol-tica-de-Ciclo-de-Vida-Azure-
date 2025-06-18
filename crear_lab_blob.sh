#!/bin/bash

RG="rg-blob-seguro"
STORAGE="stlabsecureblob$RANDOM"
LOCATION="eastus"
CONTAINER="contenedorprivado"
TAGS="docente=gmtech proyecto=lab_blob_seguro"

# Crear grupo
az group create --name $RG --location $LOCATION --tags $TAGS

# Crear cuenta de almacenamiento
az storage account create   --name $STORAGE   --resource-group $RG   --location $LOCATION   --sku Standard_LRS   --kind StorageV2   --tags $TAGS

# Crear contenedor privado
az storage container create   --name $CONTAINER   --account-name $STORAGE   --auth-mode login   --public-access off

# Subir archivo de prueba
az storage blob upload   --account-name $STORAGE   --container-name $CONTAINER   --name ejemplo.txt   --file ejemplo.txt   --auth-mode login

# Aplicar política de ciclo de vida
az storage account management-policy create   --account-name $STORAGE   --resource-group $RG   --policy '{
    "rules": [
      {
        "name": "mover-cool-eliminar",
        "enabled": true,
        "type": "Lifecycle",
        "definition": {
          "filters": {
            "blobTypes": ["blockBlob"]
          },
          "actions": {
            "baseBlob": {
              "tierToCool": {
                "daysAfterLastAccessTimeGreaterThan": 30
              },
              "delete": {
                "daysAfterLastAccessTimeGreaterThan": 90
              }
            }
          }
        }
      }
    ]
  }'

# Mostrar resumen
echo "Cuenta: $STORAGE"
az storage blob list   --account-name $STORAGE   --container-name $CONTAINER   --auth-mode login   --output table
