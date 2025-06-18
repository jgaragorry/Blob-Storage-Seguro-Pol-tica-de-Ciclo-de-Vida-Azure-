# 🛡️ Laboratorio de Blob Storage Seguro con Azure CLI

Este laboratorio crea un entorno con:
- Grupo de recursos
- Cuenta de almacenamiento con configuración segura
- Contenedor privado
- Archivo de prueba subido
- Política de ciclo de vida
- Asignación automática de rol `Storage Blob Data Contributor`

---

## 📦 Requisitos previos

- Azure CLI instalado y autenticado
- Permisos para crear recursos y asignar roles
- Tener el **ObjectId de tu usuario en Azure AD**

Puedes obtenerlo con:
```bash
az ad signed-in-user show --query objectId -o tsv
🚀 Uso del script
Dar permisos de ejecución:


chmod +x crear_lab_blob.sh eliminar_lab_blob.sh
Ejecutar el script de creación:


./crear_lab_blob.sh
Eliminar los recursos cuando termines:


./eliminar_lab_blob.sh
🧪 Verificaciones
Visita el portal de Azure y busca el contenedor privado creado.

Verifica que el archivo ejemplo.txt fue subido correctamente.

Revisa la política de ciclo de vida aplicada.

🧠 Notas
El script espera 15 segundos después de asignar el rol para garantizar la propagación.

Se usa --auth-mode login para evitar el uso de claves de acceso.

Toda la configuración es segura y orientada a entornos educativos o demostrativos.