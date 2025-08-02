# Laboratorio Jenkins + Quarkus + Azure

## Resumen del Proyecto

Este proyecto implementa un pipeline completo de CI/CD para una aplicación Quarkus que se despliega en Azure App Service usando Docker containers.

### Arquitectura de la Solución

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Jenkins       │    │   Azure         │    │   Aplicación    │
│   Pipeline      │───▶│   App Service   │───▶│   Quarkus       │
│                 │    │   + PostgreSQL  │    │   (REST API)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Estructura del Proyecto

```
Examen-Parcial/
├── Jenkinsfile                     # Pipeline Parte 1: Build + Docker
├── Jenkinsfile-Azure               # Pipeline Parte 2: Deploy Azure
├── Laboratorio.md                  # Instrucciones del laboratorio
├── azure-terraform/
│   └── main.tf                     # Infraestructura como código
├── Quarkus-Docker/
│   ├── Dockerfile                  # Multi-stage Docker build
│   ├── docker-compose.yml          # Para desarrollo local
│   ├── pom.xml                     # Configuración Maven
│   └── src/
│       ├── main/
│       │   ├── java/org/almeida/micro/
│       │   │   ├── User.java       # Entidad Usuario
│       │   │   ├── UserResource.java
│       │   │   ├── Movie.java      # Entidad Película
│       │   │   ├── MovieResource.java
│       │   │   ├── Critic.java     # Entidad Crítico
│       │   │   ├── CriticResource.java
│       │   │   ├── Review.java     # Entidad Reseña
│       │   │   └── ReviewResource.java
│       │   └── resources/
│       │       ├── application.properties
│       │       └── application-azure.properties
│       └── test/
└── README.md                       # Este archivo
```

## Parte 1: Pipeline de Build y Docker

### Características del Pipeline (`Jenkinsfile`)

1. **Checkout del código fuente**
2. **Verificación de estructura del proyecto**
3. **Ejecución de tests unitarios**
4. **Build de la aplicación Quarkus**
5. **Construcción de imagen Docker**
6. **Testing del contenedor**
7. **Testing con Docker Compose**
8. **Push opcional al registry**

### Comandos para ejecutar localmente

```bash
# Desarrollo local con Docker Compose
cd Quarkus-Docker
docker-compose up -d

# Verificar que funciona
curl http://localhost:8080/users/hello
curl http://localhost:8080/users
curl http://localhost:8080/movies
```

## Parte 2: Despliegue en Azure

### Infraestructura Azure (Terraform)

El archivo `azure-terraform/main.tf` crea:

- **Resource Group**: Contenedor para todos los recursos
- **Azure Container Registry**: Para almacenar imágenes Docker
- **PostgreSQL Flexible Server**: Base de datos gestionada
- **App Service Plan**: Plan de hosting para la aplicación
- **Linux Web App**: Aplicación containerizada

### Pipeline de Azure (`Jenkinsfile-Azure`)

1. **Build de la aplicación**
2. **Autenticación con Azure**
3. **Terraform init/plan/apply**
4. **Build y push de imagen Docker a ACR**
5. **Deploy en App Service**
6. **Testing del deployment**

## Configuración en Jenkins

### Requisitos Previos

1. **Jenkins con plugins instalados**:
   - Pipeline Plugin
   - Docker Pipeline Plugin
   - Azure CLI Plugin
   - Terraform Plugin

2. **Herramientas en el agente Jenkins**:
   - Docker
   - Azure CLI
   - Terraform
   - Git
   - jq
   - Maven (o usar el wrapper incluido)

### Credenciales Necesarias

1. **Azure Service Principal** (ID: `azure-service-principal`)

   ```bash
   az ad sp create-for-rbac --name jenkins-sp --role Contributor \
     --scopes /subscriptions/<SUBSCRIPTION-ID> --sdk-auth
   ```

2. **Docker Registry** (si usas Docker Hub)

### Configuración de Jobs

#### Job 1: Quarkus Build Pipeline

- **Tipo**: Pipeline
- **SCM**: Git (este repositorio)
- **Script Path**: `Jenkinsfile`

#### Job 2: Azure Deployment Pipeline

- **Tipo**: Pipeline
- **SCM**: Git (este repositorio)
- **Script Path**: `Jenkinsfile-Azure`
- **Parámetros**:
  - `ACTION`: choice (plan/apply/destroy)
  - `AUTO_APPROVE`: boolean

## API Endpoints

La aplicación Quarkus expone los siguientes endpoints:

### Usuarios

- `GET /users` - Listar usuarios
- `POST /users` - Crear usuario
- `GET /users/hello` - Health check

### Películas

- `GET /movies` - Listar películas
- `POST /movies` - Crear película
- `GET /movies/{id}/reviews` - Reseñas de una película

### Críticos

- `GET /critics` - Listar críticos
- `POST /critics` - Crear crítico
- `GET /critics/{id}/reviews` - Reseñas de un crítico

### Reseñas

- `GET /reviews` - Listar reseñas
- `POST /reviews` - Crear reseña

## Ejecución del Laboratorio

### Paso 1: Configurar Jenkins

1. Instalar Jenkins con Docker (usar Dockerfile del laboratorio)
2. Configurar credenciales de Azure
3. Instalar plugins necesarios

### Paso 2: Ejecutar Primera Parte

1. Crear job "Quarkus-Build-Pipeline"
2. Configurar SCM apuntando a este repositorio
3. Ejecutar pipeline
4. Verificar que se crean las imágenes Docker

### Paso 3: Ejecutar Segunda Parte

1. Crear job "Azure-Deployment-Pipeline"
2. Ejecutar con ACTION=plan primero
3. Revisar el plan de Terraform
4. Ejecutar con ACTION=apply
5. Verificar la aplicación en Azure

### Paso 4: Testing

1. Probar endpoints en la URL de Azure
2. Verificar logs en Azure App Service
3. Monitorear recursos creados

### Paso 5: Limpieza

1. Ejecutar pipeline con ACTION=destroy
2. Verificar que todos los recursos se eliminaron

## Solución de Problemas

### Problemas Comunes

1. **Error de autenticación Azure**:
   - Verificar Service Principal
   - Comprobar permisos en la suscripción

2. **Error en build de Docker**:
   - Verificar que Maven compile correctamente
   - Comprobar que el JAR se genere

3. **App Service no responde**:
   - Verificar logs en Azure Portal
   - Comprobar variables de entorno
   - Verificar conectividad a PostgreSQL

4. **Error de Terraform**:
   - Verificar sintaxis en main.tf
   - Comprobar que no existan recursos duplicados

### Logs Útiles

```bash
# Ver logs de Jenkins
docker logs jenkins

# Ver logs de App Service
az webapp log tail --name <app-name> --resource-group <rg-name>

# Ver estado de Terraform
terraform show
```

## Entregables

1. ✅ Jenkinsfile para build y Docker
2. ✅ Dockerfile optimizado para Quarkus
3. ✅ Docker Compose para desarrollo
4. ✅ Configuración de Terraform para Azure
5. ✅ Jenkinsfile para deployment en Azure
6. ✅ Documentación completa

## URLs de Ejemplo

Después del deployment exitoso:

- **Aplicación**: <https://app-quarkus-dev-XXXX.azurewebsites.net>
- **Health Check**: <https://app-quarkus-dev-XXXX.azurewebsites.net/users/hello>
- **API Users**: <https://app-quarkus-dev-XXXX.azurewebsites.net/users>
