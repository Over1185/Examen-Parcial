#!/bin/bash

# Script para probar la aplicación Quarkus localmente
echo "🚀 Iniciando pruebas locales de la aplicación Quarkus Movies API"

# Verificar que Docker esté corriendo
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker no está corriendo. Por favor, inicia Docker Desktop."
    exit 1
fi

# Navegar al directorio del proyecto
cd "$(dirname "$0")/Quarkus-Docker"

echo "📁 Directorio actual: $(pwd)"

# Construir la aplicación
echo "🔨 Construyendo aplicación con Maven..."
chmod +x mvnw
./mvnw clean package -DskipTests

if [ $? -ne 0 ]; then
    echo "❌ Error al construir la aplicación"
    exit 1
fi

# Verificar que el JAR fue creado
if [ ! -f "target/quarkus-postgres-1.0.0-SNAPSHOT-runner.jar" ]; then
    echo "❌ JAR no encontrado"
    exit 1
fi

echo "✅ JAR creado exitosamente"

# Construir imagen Docker
echo "🐳 Construyendo imagen Docker..."
docker build -t quarkus-microservice:test .

if [ $? -ne 0 ]; then
    echo "❌ Error al construir imagen Docker"
    exit 1
fi

echo "✅ Imagen Docker creada exitosamente"

# Levantar servicios con docker-compose
echo "🚀 Levantando servicios con Docker Compose..."
docker-compose up -d

# Esperar a que los servicios estén listos
echo "⏳ Esperando a que los servicios estén listos..."
sleep 60

# Verificar que los contenedores están corriendo
echo "📊 Estado de los contenedores:"
docker-compose ps

# Función para probar un endpoint
test_endpoint() {
    local url=$1
    local description=$2
    
    echo "🔍 Probando $description: $url"
    
    for i in {1..5}; do
        if curl -f -s "$url" > /dev/null; then
            echo "✅ $description - OK"
            return 0
        else
            echo "⏳ Intento $i/5 fallido, reintentando en 10 segundos..."
            sleep 10
        fi
    done
    
    echo "❌ $description - FALLÓ"
    return 1
}

# Probar endpoints
echo ""
echo "🧪 Probando endpoints de la API..."

test_endpoint "http://localhost:8080/users/hello" "Health Check"
test_endpoint "http://localhost:8080/users" "Usuarios API"
test_endpoint "http://localhost:8080/movies" "Películas API"
test_endpoint "http://localhost:8080/critics" "Críticos API"
test_endpoint "http://localhost:8080/reviews" "Reseñas API"

# Probar creación de datos
echo ""
echo "📝 Probando creación de datos..."

# Crear un usuario
echo "👤 Creando usuario de prueba..."
curl -X POST http://localhost:8080/users \
    -H "Content-Type: application/json" \
    -d '{"name":"Test User","email":"test@example.com","phone":"123456789"}' \
    > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Usuario creado exitosamente"
else
    echo "❌ Error al crear usuario"
fi

# Crear una película
echo "🎬 Creando película de prueba..."
curl -X POST http://localhost:8080/movies \
    -H "Content-Type: application/json" \
    -d '{"title":"Test Movie"}' \
    > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Película creada exitosamente"
else
    echo "❌ Error al crear película"
fi

# Verificar que los datos se crearon
echo ""
echo "🔍 Verificando datos creados..."

echo "👥 Usuarios:"
curl -s http://localhost:8080/users | jq '.' 2>/dev/null || curl -s http://localhost:8080/users

echo ""
echo "🎬 Películas:"
curl -s http://localhost:8080/movies | jq '.' 2>/dev/null || curl -s http://localhost:8080/movies

# Mostrar logs de la aplicación
echo ""
echo "📋 Logs de la aplicación (últimas 20 líneas):"
docker-compose logs --tail=20 quarkus-app

echo ""
echo "🎉 Pruebas completadas!"
echo ""
echo "📱 La aplicación está corriendo en: http://localhost:8080"
echo "🐘 PostgreSQL está corriendo en: localhost:5432"
echo ""
echo "🛑 Para detener los servicios ejecuta: docker-compose down"
echo "🧹 Para limpiar todo ejecuta: docker-compose down -v && docker system prune -f"
