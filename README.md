# Laboratorio: Azure Blob Storage Seguro con Ciclo de Vida

Este repositorio contiene un laboratorio práctico para crear una cuenta de almacenamiento en Azure con:
- Contenedor privado.
- Subida de archivo.
- Habilitación de seguimiento de último acceso.
- Política de ciclo de vida que elimina blobs no accedidos en 30 días.
- Asignación automática de rol si es necesario.

## Requisitos

- Azure CLI instalada y autenticada (`az login`).
- Permisos suficientes para crear grupos de recursos, cuentas de almacenamiento y asignar roles.
- Subscripción activa en Azure.

## Archivos incluidos

- `crear_lab_blob.sh`: Script principal que crea todos los recursos y configura la política.
- `eliminar_lab_blob.sh`: Script para eliminar el laboratorio y liberar recursos.
- `ejemplo.txt`: Archivo de prueba que se sube al contenedor.

## Uso

### 1. Crear el laboratorio

```bash
./crear_lab_blob.sh
```

Este script:
- Crea grupo de recursos.
- Crea cuenta de almacenamiento.
- Verifica y asigna el rol `Storage Blob Data Contributor` si es necesario.
- Crea un contenedor privado.
- Carga un archivo de ejemplo.
- Activa el seguimiento del último acceso.
- Aplica una política de ciclo de vida.

### 2. Eliminar el laboratorio

```bash
./eliminar_lab_blob.sh
```

Confirma cuando se te solicite. Esto liberará los recursos.

---

🔒 _Este laboratorio fue diseñado para prácticas seguras de gestión del ciclo de vida de objetos en Azure Storage._
