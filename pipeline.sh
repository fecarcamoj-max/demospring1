#!/bin/bash

set -e

# --- CONFIGURACIÓN ---
REPO_PATH="/home/ubuntu/demospring1"
IMAGE_NAME="holamundo"
CONTAINER_NAME="container-holamundo"
PORT_HOST="8080"
PORT_CONTAINER="8080"
BRANCH="master"

# Redirigir salida a un log para auditoría del cron
exec >> /var/log/cicd_deploy.log 2>&1

echo "========================================="
echo "Ejecutando verificación: $(date)"
echo "========================================="

# Navegar al repositorio
cd "$REPO_PATH" || {
    echo "Error: No se pudo acceder a $REPO_PATH"
    exit 1
}

# Asegurar que estamos en la rama correcta
git checkout "$BRANCH"

# Actualizar referencias remotas
git fetch origin "$BRANCH"

# Comparar local vs remoto
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse @{u})

if [ "$LOCAL" = "$REMOTE" ]; then
    echo "No hay cambios en la rama $BRANCH. Todo actualizado."
    exit 0
fi

echo "¡Cambios detectados! Iniciando pipeline de CI/CD..."

# 1. Actualizar repositorio
echo "Actualizando repositorio (git pull)..."
git pull origin "$BRANCH"

# 2. Eliminar el contenedor principal si existe
if [ "$(docker ps -aq -f name=^/${CONTAINER_NAME}$)" ]; then
    echo "Deteniendo y eliminando contenedor antiguo..."
    docker rm -f "$CONTAINER_NAME"
fi

# 3. Eliminar cualquier contenedor que esté usando el puerto 8080
echo "Buscando contenedores usando el puerto $PORT_HOST..."

CONTAINERS_USING_PORT=$(docker ps -aq --filter "publish=$PORT_HOST")

if [ -n "$CONTAINERS_USING_PORT" ]; then
    echo "Eliminando contenedores que usan el puerto $PORT_HOST..."
    docker rm -f $CONTAINERS_USING_PORT
else
    echo "No hay contenedores usando el puerto $PORT_HOST."
fi

# Esperar un momento para asegurar que Docker libere el puerto
sleep 3

# 4. Eliminar imagen anterior
if [ "$(docker images -q "$IMAGE_NAME")" ]; then
    echo "Eliminando imagen anterior..."
    docker rmi -f "$IMAGE_NAME"
fi

# 5. Construir imagen
echo "Construyendo la nueva imagen..."
docker build -t "$IMAGE_NAME" .

# 6. Desplegar contenedor
echo "Iniciando el nuevo contenedor en el puerto $PORT_HOST..."

CONTAINER_ID=$(docker run -d \
    --name "$CONTAINER_NAME" \
    -p "${PORT_HOST}:${PORT_CONTAINER}" \
    --restart always \
    "$IMAGE_NAME")

if [ -z "$CONTAINER_ID" ]; then
    echo "ERROR: No se pudo iniciar el contenedor."
    exit 1
fi

echo "Contenedor iniciado: $CONTAINER_ID"

# 7. Verificación final
echo "Verificando que el contenedor esté en ejecución..."

if docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Contenedor $CONTAINER_NAME ejecutándose correctamente."
else
    echo "ERROR: El contenedor no está en ejecución."
    docker logs "$CONTAINER_NAME" || true
    exit 1
fi

echo "========================================="
echo "¡Despliegue ejecutado con éxito!"
echo "========================================="