#!/bin/bash

# Configuración
RG="rg-blob-seguro"
STORAGE="stlabsecureblob$RANDOM"
LOCATION="eastus"
CONTAINER="contenedorprivado"
TAGS="docente=gmtech proyecto=lab_blob_seguro"
ROL="Storage Blob Data Contributor"

# Iniciar sesión si no está autenticado
if ! az account show &>/dev/null; then
    echo "Iniciando sesión en Azure..."
    az login --only-show-errors
fi

# Obtener el usuario autenticado
USER=$(az ad signed-in-user show --query userPrincipalName -o tsv)

# Crear grupo de recursos
echo "Creando grupo de recursos..."
az group create --name $RG --location $LOCATION --tags $TAGS

# Crear cuenta de almacenamiento
echo "Creando cuenta de almacenamiento..."
az storage account create \
  --name $STORAGE \
  --resource-group $RG \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2 \
  --tags $TAGS

# Asignar rol si no lo tiene
echo "Verificando si el usuario tiene el rol '$ROL'..."
SCOPE="/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RG/providers/Microsoft.Storage/storageAccounts/$STORAGE"
ROL_ASIGNADO=$(az role assignment list --assignee $USER --scope $SCOPE --query "[?roleDefinitionName=='$ROL']" -o tsv)

if [[ -z "$ROL_ASIGNADO" ]]; then
  echo "Asignando rol '$ROL' a $USER..."
  az role assignment create \
    --assignee "$USER" \
    --role "$ROL" \
    --scope "$SCOPE"
else
  echo "✅ El usuario ya tiene el rol '$ROL'"
fi

# Esperar unos segundos para que el rol se propague
echo "Esperando a que se propague el rol (10s)..."
sleep 10

# Crear contenedor privado
echo "Creando contenedor privado..."
az storage container create \
  --name $CONTAINER \
  --account-name $STORAGE \
  --auth-mode login \
  --public-access off

# Subir archivo de prueba
echo "Subiendo archivo ejemplo.txt..."
az storage blob upload \
  --account-name $STORAGE \
  --container-name $CONTAINER \
  --name ejemplo.txt \
  --file ejemplo.txt \
  --auth-mode login

# Activar seguimiento de acceso para políticas de ciclo de vida
echo "Habilitando seguimiento de último acceso..."
az storage account blob-service-properties update \
  --account-name $STORAGE \
  --enable-last-access-tracking true

# Aplicar política de ciclo de vida
echo "Aplicando política de ciclo de vida..."
az storage account management-policy create \
  --account-name $STORAGE \
  --resource-group $RG \
  --policy '{
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
echo "✅ RESUMEN:"
echo "Cuenta: $STORAGE"
az storage blob list \
  --account-name $STORAGE \
  --container-name $CONTAINER \
  --auth-mode login \
  --output table
