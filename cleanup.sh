#!/bin/bash

# Script para limpiar todos los recursos creados durante las pruebas
echo "🧹 Limpiando recursos del laboratorio Quarkus + Jenkins + Azure"

# Navegar al directorio del proyecto
cd "$(dirname "$0")"

echo "📁 Directorio actual: $(pwd)"

# Detener y eliminar contenedores de Docker Compose
if [ -f "Quarkus-Docker/docker-compose.yml" ]; then
    echo "🛑 Deteniendo servicios de Docker Compose..."
    cd Quarkus-Docker
    docker-compose down -v
    cd ..
else
    echo "ℹ️ No se encontró docker-compose.yml"
fi

# Eliminar contenedores de prueba que puedan haber quedado
echo "🗑️ Eliminando contenedores de prueba..."
docker stop quarkus-test postgres-test 2>/dev/null || true
docker rm quarkus-test postgres-test 2>/dev/null || true

# Eliminar redes de prueba
echo "🔌 Eliminando redes de prueba..."
docker network rm quarkus-test-network 2>/dev/null || true
docker network rm quarkus-docker_quarkus-network 2>/dev/null || true

# Eliminar imágenes Docker creadas
echo "🐳 Eliminando imágenes Docker..."
docker rmi quarkus-microservice:test 2>/dev/null || true
docker rmi quarkus-microservice:latest 2>/dev/null || true
docker rmi quarkus-microservice:azure 2>/dev/null || true

# Eliminar imágenes por patrón
docker images | grep quarkus-microservice | awk '{print $1":"$2}' | xargs docker rmi 2>/dev/null || true

# Limpiar imágenes no utilizadas
echo "🧹 Limpiando imágenes Docker no utilizadas..."
docker system prune -f

# Eliminar volúmenes no utilizados
echo "💾 Limpiando volúmenes no utilizados..."
docker volume prune -f

# Limpiar archivos temporales de build
echo "📁 Limpiando archivos de build..."
if [ -d "Quarkus-Docker/target" ]; then
    rm -rf Quarkus-Docker/target
    echo "✅ Directorio target eliminado"
fi

# Limpiar archivos de Terraform
if [ -d "azure-terraform" ]; then
    cd azure-terraform
    echo "🏗️ Limpiando archivos de Terraform..."
    rm -f terraform.tfstate*
    rm -f terraform.tfvars
    rm -f .terraform.lock.hcl
    rm -f tfplan
    rm -f terraform-outputs.json
    rm -f azure-credentials.json
    rm -rf .terraform/
    cd ..
    echo "✅ Archivos de Terraform limpiados"
fi

# Mostrar espacio liberado
echo ""
echo "📊 Información del sistema Docker después de la limpieza:"
docker system df

echo ""
echo "🎉 Limpieza completada!"
echo ""
echo "📋 Recursos eliminados:"
echo "   ✅ Contenedores de Docker Compose"
echo "   ✅ Contenedores de prueba"
echo "   ✅ Redes Docker"
echo "   ✅ Imágenes Docker de Quarkus"
echo "   ✅ Archivos de build (target/)"
echo "   ✅ Archivos temporales de Terraform"
echo "   ✅ Volúmenes no utilizados"
echo ""
echo "⚠️ NOTA: Esta limpieza es solo para recursos locales."
echo "   Si desplegaste en Azure, ejecuta el pipeline con ACTION=destroy"
echo "   o elimina manualmente los recursos desde Azure Portal."
