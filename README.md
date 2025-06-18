# 🧪 Laboratorio Azure Blob Storage Seguro + Ciclo de Vida

Este laboratorio práctico permite crear un contenedor Blob seguro en Azure, aplicar una política de ciclo de vida para automatizar el ahorro de costos, y demostrar cómo trabajar con niveles de acceso y cifrado por defecto.

---

## 🎯 Objetivos

- Crear un contenedor Blob con acceso privado.
- Subir un archivo usando Azure CLI.
- Aplicar etiquetas para trazabilidad.
- Aplicar una política de ciclo de vida:
  - Mover blobs a "Cool" después de 30 días sin acceso.
  - Eliminar blobs después de 90 días sin acceso.

---

## 📁 Estructura

blob_seguro_ciclo_vida/
├── crear_lab_blob.sh
├── eliminar_lab_blob.sh
├── ejemplo.txt
└── README.md


---

## ⚙️ Requisitos

- Cuenta de Azure activa.
- Azure CLI instalada y autenticada (`az login`).
- Acceso a Bash (Linux, WSL o Git Bash).

---

## 🚀 Pasos para ejecutar

### 1. Clonar el repositorio

```bash
git clone https://github.com/jgaragorry/laboratorios-linux-azure-gmtech.git
cd laboratorios-linux-azure-gmtech/blob_seguro_ciclo_vida


2. Crear la infraestructura
bash crear_lab_blob.sh


Esto hará lo siguiente:

✅ Crear un grupo de recursos rg-blob-seguro
✅ Crear una cuenta de almacenamiento stlabsecureblob
✅ Crear un contenedor con acceso privado
✅ Subir un archivo de prueba ejemplo.txt
✅ Aplicar etiquetas: docente=gmtech, proyecto=lab_blob_seguro
✅ Configurar la política de ciclo de vida

🧹 Limpieza
Cuando finalices, elimina todo con:

bash eliminar_lab_blob.sh


Esto elimina el grupo de recursos y todos los recursos creados.


🧑‍🏫 Aplicaciones educativas
Seguridad: acceso privado, cifrado por defecto.

Costos: políticas automáticas para migrar o eliminar blobs.

Gestión: uso de etiquetas y automatización.


---

### 🧪 `crear_lab_blob.sh`

```bash
#!/bin/bash

RG="rg-blob-seguro"
STORAGE="stlabsecureblob$RANDOM"
LOCATION="eastus"
CONTAINER="contenedorprivado"
TAGS="docente=gmtech proyecto=lab_blob_seguro"

# Crear grupo
az group create --name $RG --location $LOCATION --tags $TAGS

# Crear cuenta de almacenamiento
az storage account create \
  --name $STORAGE \
  --resource-group $RG \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2 \
  --tags $TAGS

# Crear contenedor privado
az storage container create \
  --name $CONTAINER \
  --account-name $STORAGE \
  --auth-mode login \
  --public-access off

# Subir archivo de prueba
az storage blob upload \
  --account-name $STORAGE \
  --container-name $CONTAINER \
  --name ejemplo.txt \
  --file ejemplo.txt \
  --auth-mode login

# Aplicar política de ciclo de vida
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
echo "Cuenta: $STORAGE"
az storage blob list \
  --account-name $STORAGE \
  --container-name $CONTAINER \
  --auth-mode login \
  --output table


🧹 eliminar_lab_blob.sh

#!/bin/bash

RG="rg-blob-seguro"

echo "Eliminando grupo de recursos $RG..."
az group delete --name $RG --yes --no-wait

📄 ejemplo.txt

Este es un archivo de prueba para el laboratorio de almacenamiento seguro con ciclo de vida.
