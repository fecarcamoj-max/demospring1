#!/bin/bash

# --- CONFIGURACIÓN ---
REPO_PATH="/home/ubuntu/demospring1"
IMAGE_NAME="holamundo"
CONTAINER_NAME="container-holamundo"
PORT_HOST="8080"
PORT_CONTAINER="8080"
BRANCH="master" # Rama de repositorio...

# Redirigir salida a un log para auditoría del cron
exec >> /var/log/cicd_deploy.log 2>&1

echo "========================================="
echo "Ejecutando verificación: $(date)"
echo "========================================="

# Navegar al repositorio
cd "$REPO_PATH" || { echo "Error: No se pudo acceder a $REPO_PATH"; exit 1; }

# Asegurar que estamos en la rama correcta
git checkout $BRANCH

# Traer la información más reciente del remoto sin fusionar
git fetch origin $BRANCH

# Comparar la rama local con la rama remota
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse @{u})

if [ "$LOCAL" = "$REMOTE" ]; then
    echo "No hay cambios en la rama $BRANCH. Todo actualizado."
    exit 0
fi

echo "¡Cambios detectados! Iniciando pipeline de CI/CD..."

# 1. Hacer pull de los nuevos cambios
echo "Actualizando repositorio (git pull)..."
git pull origin $BRANCH

# 2. Detener y eliminar el contenedor anterior (si existe)
if [ "$(docker ps -aq -f name=^/${CONTAINER_NAME}$)" ]; then
    echo "Deteniendo y eliminando contenedor antiguo..."
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
fi

# 3. Eliminar la imagen anterior para no dejar imágenes "dangling" (<none>)
if [ "$(docker images -q $IMAGE_NAME)" ]; then
    echo "Eliminando imagen anterior..."
    docker rmi $IMAGE_NAME
fi

# 4. Construir la nueva imagen de Docker
echo "Construyendo la nueva imagen..."
docker build -t $IMAGE_NAME .

# 5. Desplegar el nuevo contenedor
echo "Iniciando el nuevo contenedor en el puerto $PORT_HOST..."
docker run -d --name $CONTAINER_NAME -p ${PORT_HOST}:${PORT_CONTAINER} --restart always $IMAGE_NAME

echo "¡Despliegue ejecutado con éxito!"