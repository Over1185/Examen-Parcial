# Despliegue de Aplicación Quarkus en Azure App Service desde Cero

## Tabla de Contenidos

1. [Requisitos Previos](#requisitos-previos)
2. [Configuración Inicial de Azure](#configuración-inicial-de-azure)
3. [Crear Azure Container Registry](#crear-azure-container-registry)
4. [Crear Azure App Service Plan](#crear-azure-app-service-plan)
5. [Crear Azure App Service](#crear-azure-app-service)
6. [Configurar Base de Datos PostgreSQL](#configurar-base-de-datos-postgresql)
7. [Despliegue con Docker](#despliegue-con-docker)
8. [Configuración de Variables de Entorno](#configuración-de-variables-de-entorno)
9. [Verificación del Despliegue](#verificación-del-despliegue)
10. [Configuración de Dominio Personalizado (Opcional)](#configuración-de-dominio-personalizado)

---

## Requisitos Previos

### Lo que necesitas antes de empezar

- **Cuenta de Azure** (puedes crear una gratuita en [portal.azure.com](https://portal.azure.com))
- **Docker Desktop** instalado en tu máquina local
- **Azure CLI** instalado ([Descargar aquí](https://docs.microsoft.com/es-es/cli/azure/install-azure-cli))
- **Git** para clonar el repositorio
- El proyecto Quarkus que ya tienes en tu repositorio

---

## Configuración Inicial de Azure

### Paso 1: Crear una cuenta de Azure (si no tienes una)

1. **Ve al Portal de Azure**: [https://portal.azure.com](https://portal.azure.com)
2. **Haz clic en "Crear una cuenta gratuita"**
3. **Completa el registro** con tu información personal
4. **Verifica tu identidad** (tarjeta de crédito para verificación, no se cobrará)
5. **Accede al Portal de Azure**

### Paso 2: Instalar Azure CLI

```bash
# Para Windows (usando PowerShell como administrador)
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi

# Para macOS
brew install azure-cli

# Para Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### Paso 3: Iniciar sesión en Azure CLI

```bash
# Abrir terminal y ejecutar
az login

# Verificar que estás conectado
az account show

# Listar todas las suscripciones disponibles
az account list --output table
```

---

## Crear Azure Container Registry

### Opción A: Usando Azure Portal (Interfaz Gráfica)

1. **Accede al Portal de Azure**: [portal.azure.com](https://portal.azure.com)
2. **Busca "Container registries"** en la barra de búsqueda
3. **Haz clic en "+ Create"**
4. **Completa la información**:
   - **Subscription**: Selecciona tu suscripción
   - **Resource group**: Crea uno nuevo llamado `rg-quarkus-app`
   - **Registry name**: `acrquarkusapp` (debe ser único globalmente)
   - **Location**: `East US` o la región más cercana
   - **SKU**: `Basic` (para desarrollo)
5. **Haz clic en "Review + create"**
6. **Haz clic en "Create"**

### Opción B: Usando Azure CLI

```bash
# Crear grupo de recursos
az group create --name rg-quarkus-app --location eastus

# Crear Azure Container Registry
az acr create \
  --resource-group rg-quarkus-app \
  --name acrquarkusapp \
  --sku Basic \
  --admin-enabled true

# Obtener las credenciales del registry
az acr credential show --name acrquarkusapp
```

---

## Crear Azure App Service Plan

### Opción A: Usando Azure Portal

1. **En el Portal de Azure, busca "App Service plans"**
2. **Haz clic en "+ Create"**
3. **Configura el plan**:
   - **Resource group**: `rg-quarkus-app`
   - **Name**: `asp-quarkus-app`
   - **Operating System**: `Linux`
   - **Region**: `East US`
   - **Pricing Tier**: `B1` (Basic - para desarrollo)
4. **Haz clic en "Review + create"**
5. **Haz clic en "Create"**

### Opción B: Usando Azure CLI

```bash
# Crear App Service Plan
az appservice plan create \
  --name asp-quarkus-app \
  --resource-group rg-quarkus-app \
  --sku B1 \
  --is-linux
```

---

## Crear Azure App Service

### Opción A: Usando Azure Portal

1. **En el Portal de Azure, busca "App Services"**
2. **Haz clic en "+ Create"**
3. **Configura la Web App**:
   - **Resource group**: `rg-quarkus-app`
   - **Name**: `webapp-quarkus-movies` (debe ser único)
   - **Publish**: `Docker Container`
   - **Operating System**: `Linux`
   - **Region**: `East US`
   - **App Service Plan**: Selecciona `asp-quarkus-app`
4. **En la pestaña "Docker"**:
   - **Options**: `Single Container`
   - **Image Source**: `Azure Container Registry`
   - **Registry**: Selecciona `acrquarkusapp`
   - **Image**: `quarkus-microservice`
   - **Tag**: `latest`
5. **Haz clic en "Review + create"**
6. **Haz clic en "Create"**

### Opción B: Usando Azure CLI

```bash
# Crear Web App con contenedor
az webapp create \
  --resource-group rg-quarkus-app \
  --plan asp-quarkus-app \
  --name webapp-quarkus-movies \
  --deployment-container-image-name acrquarkusapp.azurecr.io/quarkus-microservice:latest
```

---

## Configurar Base de Datos PostgreSQL

### Opción A: Usando Azure Portal

1. **Busca "Azure Database for PostgreSQL"**
2. **Selecciona "Flexible server"**
3. **Haz clic en "+ Create"**
4. **Configura la base de datos**:
   - **Resource group**: `rg-quarkus-app`
   - **Server name**: `postgres-quarkus-app`
   - **Region**: `East US`
   - **PostgreSQL version**: `15`
   - **Workload type**: `Development`
   - **Compute + storage**: `Burstable, B1ms` (1 vCore, 2 GiB RAM)
5. **En "Authentication"**:
   - **Admin username**: `postgres`
   - **Password**: `QuarkusApp2024!`
6. **En "Networking"**:
   - **Connectivity method**: `Public access`
   - **Allow public access from any Azure service**: ✓
7. **Haz clic en "Review + create"**
8. **Haz clic en "Create"**

### Opción B: Usando Azure CLI

```bash
# Crear PostgreSQL Flexible Server
az postgres flexible-server create \
  --resource-group rg-quarkus-app \
  --name postgres-quarkus-app \
  --location eastus \
  --admin-user postgres \
  --admin-password QuarkusApp2024! \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --public-access 0.0.0.0 \
  --storage-size 32

# Crear la base de datos
az postgres flexible-server db create \
  --resource-group rg-quarkus-app \
  --server-name postgres-quarkus-app \
  --database-name quarkusdb
```

---

## Despliegue con Docker

### Paso 1: Preparar la imagen Docker localmente

```bash
# Navegar al directorio del proyecto Quarkus
cd "C:\Users\Over\Desktop\Examen Parcial 3\Examen-Parcial\Quarkus-Docker"

# Construir la aplicación con Maven
./mvnw clean package -DskipTests

# Construir la imagen Docker
docker build -t quarkus-microservice:latest .

# Verificar que la imagen se creó
docker images | grep quarkus-microservice
```

### Paso 2: Subir la imagen al Azure Container Registry

```bash
# Hacer login al ACR
az acr login --name acrquarkusapp

# Etiquetar la imagen para el registry
docker tag quarkus-microservice:latest acrquarkusapp.azurecr.io/quarkus-microservice:latest

# Subir la imagen
docker push acrquarkusapp.azurecr.io/quarkus-microservice:latest

# Verificar que se subió
az acr repository list --name acrquarkusapp --output table
```

---

## Configuración de Variables de Entorno

### Opción A: Usando Azure Portal

1. **Ve a tu App Service** `webapp-quarkus-movies`
2. **En el menú izquierdo, selecciona "Configuration"**
3. **En la pestaña "Application settings"**, agrega las siguientes variables:

| Name | Value |
|------|-------|
| `QUARKUS_DATASOURCE_DB_KIND` | `postgresql` |
| `QUARKUS_DATASOURCE_USERNAME` | `postgres` |
| `QUARKUS_DATASOURCE_PASSWORD` | `QuarkusApp2024!` |
| `QUARKUS_DATASOURCE_JDBC_URL` | `jdbc:postgresql://postgres-quarkus-app.postgres.database.azure.com:5432/quarkusdb?sslmode=require` |
| `QUARKUS_HIBERNATE_ORM_DATABASE_GENERATION` | `update` |
| `WEBSITES_PORT` | `8080` |

4. **Haz clic en "Save"**

### Opción B: Usando Azure CLI

```bash
# Configurar variables de entorno de la aplicación
az webapp config appsettings set \
  --resource-group rg-quarkus-app \
  --name webapp-quarkus-movies \
  --settings \
    QUARKUS_DATASOURCE_DB_KIND=postgresql \
    QUARKUS_DATASOURCE_USERNAME=postgres \
    QUARKUS_DATASOURCE_PASSWORD=QuarkusApp2024! \
    QUARKUS_DATASOURCE_JDBC_URL="jdbc:postgresql://postgres-quarkus-app.postgres.database.azure.com:5432/quarkusdb?sslmode=require" \
    QUARKUS_HIBERNATE_ORM_DATABASE_GENERATION=update \
    WEBSITES_PORT=8080
```

---

## Configurar la Conexión del Container Registry

### Usando Azure Portal

1. **Ve a tu App Service** `webapp-quarkus-movies`
2. **En el menú izquierdo, selecciona "Deployment Center"**
3. **Configura el registry**:
   - **Source**: `Azure Container Registry`
   - **Registry**: `acrquarkusapp`
   - **Image**: `quarkus-microservice`
   - **Tag**: `latest`
4. **Haz clic en "Save"**

### Usando Azure CLI

```bash
# Configurar el container registry
az webapp config container set \
  --name webapp-quarkus-movies \
  --resource-group rg-quarkus-app \
  --docker-custom-image-name acrquarkusapp.azurecr.io/quarkus-microservice:latest \
  --docker-registry-server-url https://acrquarkusapp.azurecr.io

# Obtener credenciales del ACR y configurarlas
ACR_USERNAME=$(az acr credential show --name acrquarkusapp --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name acrquarkusapp --query passwords[0].value --output tsv)

az webapp config appsettings set \
  --resource-group rg-quarkus-app \
  --name webapp-quarkus-movies \
  --settings \
    DOCKER_REGISTRY_SERVER_URL=https://acrquarkusapp.azurecr.io \
    DOCKER_REGISTRY_SERVER_USERNAME=$ACR_USERNAME \
    DOCKER_REGISTRY_SERVER_PASSWORD=$ACR_PASSWORD
```

---

## Verificación del Despliegue

### Paso 1: Verificar que la aplicación está corriendo

```bash
# Obtener la URL de la aplicación
az webapp show \
  --resource-group rg-quarkus-app \
  --name webapp-quarkus-movies \
  --query defaultHostName \
  --output tsv
```

### Paso 2: Probar los endpoints

```bash
# URL base de tu aplicación
APP_URL="https://webapp-quarkus-movies.azurewebsites.net"

# Probar endpoint de salud
curl $APP_URL/users/hello

# Probar endpoints de la API
curl $APP_URL/users
curl $APP_URL/movies
curl $APP_URL/critics
curl $APP_URL/reviews
```

### Paso 3: Verificar logs de la aplicación

#### Usando Azure Portal

1. **Ve a tu App Service**
2. **En el menú izquierdo, selecciona "Log stream"**
3. **Observa los logs en tiempo real**

#### Usando Azure CLI

```bash
# Ver logs de la aplicación
az webapp log tail \
  --resource-group rg-quarkus-app \
  --name webapp-quarkus-movies
```

---

## Configuración de Dominio Personalizado (Opcional)

### Si tienes un dominio propio

1. **En tu App Service, ve a "Custom domains"**
2. **Haz clic en "+ Add custom domain"**
3. **Ingresa tu dominio** (ej: `api.midominio.com`)
4. **Sigue las instrucciones para validar el dominio**
5. **Configura el SSL certificate** (puedes usar un certificado gratuito de App Service)

---

## Comandos de Utilidad

### Reiniciar la aplicación

```bash
az webapp restart \
  --resource-group rg-quarkus-app \
  --name webapp-quarkus-movies
```

### Actualizar la imagen Docker

```bash
# Después de hacer cambios al código y crear nueva imagen
docker tag quarkus-microservice:latest acrquarkusapp.azurecr.io/quarkus-microservice:v2
docker push acrquarkusapp.azurecr.io/quarkus-microservice:v2

# Actualizar la configuración del container
az webapp config container set \
  --name webapp-quarkus-movies \
  --resource-group rg-quarkus-app \
  --docker-custom-image-name acrquarkusapp.azurecr.io/quarkus-microservice:v2
```

### Escalar la aplicación

```bash
# Escalar a 2 instancias
az appservice plan update \
  --name asp-quarkus-app \
  --resource-group rg-quarkus-app \
  --number-of-workers 2
```

---

## Monitoreo y Diagnóstico

### Habilitar Application Insights

1. **En tu App Service, ve a "Application Insights"**
2. **Haz clic en "Turn on Application Insights"**
3. **Crea un nuevo recurso o usa uno existente**
4. **Configura la recopilación de datos**

### Métricas importantes a monitorear

- **Response time**
- **Request rate**
- **Error rate**
- **CPU usage**
- **Memory usage**

---

## Solución de Problemas Comunes

### La aplicación no inicia

1. **Verifica los logs** con `az webapp log tail`
2. **Verifica las variables de entorno** en Configuration
3. **Verifica que la imagen Docker se construyó correctamente**

### No se puede conectar a la base de datos

1. **Verifica la string de conexión**
2. **Verifica que PostgreSQL permite conexiones externas**
3. **Verifica las credenciales de la base de datos**

### La aplicación es lenta

1. **Considera escalar el App Service Plan**
2. **Verifica las métricas de performance**
3. **Optimiza las consultas de base de datos**

---

## Costos Estimados (Mensual)

| Recurso | Tier | Costo Estimado |
|---------|------|----------------|
| App Service Plan B1 | Basic | ~$13 USD |
| PostgreSQL Flexible Server B1ms | Burstable | ~$12 USD |
| Azure Container Registry | Basic | ~$5 USD |
| **Total** | | **~$30 USD/mes** |

> **Nota**: Los costos son aproximados y pueden variar según la región y el uso.

---

## Conclusión

¡Felicidades! Has desplegado exitosamente tu aplicación Quarkus en Azure App Service. Tu aplicación ahora está:

- ✅ **Corriendo en la nube**
- ✅ **Escalable automáticamente**
- ✅ **Monitoreada con Application Insights**
- ✅ **Respaldada por una base de datos PostgreSQL administrada**
- ✅ **Accesible desde cualquier parte del mundo**

### Próximos pasos recomendados

1. **Configurar CI/CD** con GitHub Actions o Azure DevOps

---

## CI/CD con GitHub Actions

### Configuración del Pipeline de GitHub Actions

Para automatizar el despliegue de tu aplicación Quarkus en Azure cada vez que hagas push al repositorio, necesitas crear workflows de GitHub Actions. Basándome en tu repositorio `https://github.com/Over1185/Examen-Parcial`, aquí está la configuración completa.

### Estructura de archivos que necesitas crear

En tu repositorio, necesitas crear la siguiente estructura:

```
.github/
└── workflows/
    ├── ci.yml                    # Pipeline de CI (Build y Tests)
    └── azure-deploy.yml          # Pipeline de Deploy a Azure
```

### Paso 1: Crear el directorio .github/workflows

```bash
# En la raíz de tu repositorio
mkdir -p .github/workflows
```

### Paso 2: Crear el workflow de CI (Build y Tests)

Crea el archivo `.github/workflows/ci.yml`:

```yaml
name: CI - Build and Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test-and-build:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout código
      uses: actions/checkout@v4
      
    - name: Configurar Java 17
      uses: actions/setup-java@v3
      with:
        java-version: '17'
        distribution: 'temurin'
        
    - name: Cache dependencias Maven
      uses: actions/cache@v3
      with:
        path: ~/.m2
        key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
        restore-keys: ${{ runner.os }}-m2
        
    - name: Ejecutar tests
      working-directory: ./Quarkus-Docker
      run: ./mvnw clean test
      
    - name: Compilar aplicación
      working-directory: ./Quarkus-Docker
      run: ./mvnw clean package -DskipTests
      
    - name: Construir imagen Docker
      working-directory: ./Quarkus-Docker
      run: |
        docker build -t quarkus-microservice:${{ github.sha }} .
        docker tag quarkus-microservice:${{ github.sha }} quarkus-microservice:latest
        
    - name: Probar imagen Docker
      run: |
        docker run -d --name test-container -p 8080:8080 quarkus-microservice:latest
        sleep 30
        curl -f http://localhost:8080/users/hello || exit 1
        docker stop test-container
        docker rm test-container
```

### Paso 3: Crear el workflow de Deploy a Azure

Crea el archivo `.github/workflows/azure-deploy.yml`:

```yaml
name: Deploy to Azure

on:
  push:
    branches: [ main ]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        default: 'production'
        type: choice
        options:
        - production
        - staging

env:
  AZURE_WEBAPP_NAME: webapp-quarkus-movies
  AZURE_RESOURCE_GROUP: rg-quarkus-app
  CONTAINER_REGISTRY: acrquarkusapp.azurecr.io
  IMAGE_NAME: quarkus-microservice

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout código
      uses: actions/checkout@v4
      
    - name: Configurar Java 17
      uses: actions/setup-java@v3
      with:
        java-version: '17'
        distribution: 'temurin'
        
    - name: Cache dependencias Maven
      uses: actions/cache@v3
      with:
        path: ~/.m2
        key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
        restore-keys: ${{ runner.os }}-m2
        
    - name: Compilar aplicación
      working-directory: ./Quarkus-Docker
      run: ./mvnw clean package -DskipTests
      
    - name: Login a Azure
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
        
    - name: Login a Azure Container Registry
      run: |
        az acr login --name acrquarkusapp
        
    - name: Construir y subir imagen Docker
      working-directory: ./Quarkus-Docker
      run: |
        IMAGE_TAG=${{ env.CONTAINER_REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
        IMAGE_LATEST=${{ env.CONTAINER_REGISTRY }}/${{ env.IMAGE_NAME }}:latest
        
        docker build -t $IMAGE_TAG -t $IMAGE_LATEST .
        docker push $IMAGE_TAG
        docker push $IMAGE_LATEST
        
    - name: Deploy a Azure App Service
      uses: azure/webapps-deploy@v2
      with:
        app-name: ${{ env.AZURE_WEBAPP_NAME }}
        images: ${{ env.CONTAINER_REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
        
    - name: Verificar deployment
      run: |
        echo "Esperando que la aplicación esté lista..."
        sleep 60
        APP_URL="https://${{ env.AZURE_WEBAPP_NAME }}.azurewebsites.net"
        curl -f $APP_URL/users/hello || exit 1
        echo "✅ Deployment exitoso! App disponible en: $APP_URL"
```

### Paso 4: Configurar Secrets en GitHub

En tu repositorio de GitHub, ve a **Settings > Secrets and variables > Actions** y agrega los siguientes secrets:

#### AZURE_CREDENTIALS

Ejecuta este comando para crear un Service Principal:

```bash
az ad sp create-for-rbac --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
  --sdk-auth
```

Copia la salida JSON completa y pégala como el valor del secret `AZURE_CREDENTIALS`:

```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

### Paso 5: Crear workflow avanzado con múltiples ambientes

Para un setup más avanzado, crea `.github/workflows/azure-deploy-advanced.yml`:

```yaml
name: Deploy to Azure (Multi-Environment)

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        default: 'staging'
        type: choice
        options:
        - staging
        - production

env:
  CONTAINER_REGISTRY: acrquarkusapp.azurecr.io
  IMAGE_NAME: quarkus-microservice

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}
      image-digest: ${{ steps.build.outputs.digest }}
      
    steps:
    - name: Checkout código
      uses: actions/checkout@v4
      
    - name: Configurar Java 17
      uses: actions/setup-java@v3
      with:
        java-version: '17'
        distribution: 'temurin'
        
    - name: Cache dependencias Maven
      uses: actions/cache@v3
      with:
        path: ~/.m2
        key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
        restore-keys: ${{ runner.os }}-m2
        
    - name: Ejecutar tests
      working-directory: ./Quarkus-Docker
      run: ./mvnw clean test
      
    - name: Compilar aplicación
      working-directory: ./Quarkus-Docker
      run: ./mvnw clean package -DskipTests
      
    - name: Login a Azure
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
        
    - name: Login a ACR
      run: az acr login --name acrquarkusapp
      
    - name: Extraer metadata
      id: meta
      uses: docker/metadata-action@v4
      with:
        images: ${{ env.CONTAINER_REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=sha,prefix={{branch}}-
          type=raw,value=latest,enable={{is_default_branch}}
          
    - name: Construir y subir imagen
      id: build
      working-directory: ./Quarkus-Docker
      run: |
        IMAGE_TAG=${{ env.CONTAINER_REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
        docker build -t $IMAGE_TAG .
        docker push $IMAGE_TAG
        echo "digest=$(docker inspect --format='{{index .RepoDigests 0}}' $IMAGE_TAG)" >> $GITHUB_OUTPUT

  deploy-staging:
    if: github.event_name == 'pull_request' || (github.event_name == 'workflow_dispatch' && github.event.inputs.environment == 'staging')
    needs: build
    runs-on: ubuntu-latest
    environment: staging
    
    steps:
    - name: Login a Azure
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
        
    - name: Deploy a Staging
      uses: azure/webapps-deploy@v2
      with:
        app-name: webapp-quarkus-movies-staging
        images: ${{ env.CONTAINER_REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}

  deploy-production:
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    needs: build
    runs-on: ubuntu-latest
    environment: production
    
    steps:
    - name: Login a Azure
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
        
    - name: Deploy a Production
      uses: azure/webapps-deploy@v2
      with:
        app-name: webapp-quarkus-movies
        images: ${{ env.CONTAINER_REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
        
    - name: Ejecutar smoke tests
      run: |
        echo "Ejecutando smoke tests..."
        sleep 60
        APP_URL="https://webapp-quarkus-movies.azurewebsites.net"
        
        # Test health endpoint
        curl -f $APP_URL/users/hello || exit 1
        
        # Test API endpoints
        curl -f $APP_URL/users || exit 1
        curl -f $APP_URL/movies || exit 1
        curl -f $APP_URL/critics || exit 1
        curl -f $APP_URL/reviews || exit 1
        
        echo "✅ Todos los smoke tests pasaron!"
```

### Paso 6: Configurar notificaciones (opcional)

Crea `.github/workflows/notify.yml` para notificaciones:

```yaml
name: Notifications

on:
  workflow_run:
    workflows: ["Deploy to Azure"]
    types:
      - completed

jobs:
  notify:
    runs-on: ubuntu-latest
    if: ${{ github.event.workflow_run.conclusion == 'failure' }}
    
    steps:
    - name: Notificar fallo en Slack
      uses: 8398a7/action-slack@v3
      with:
        status: failure
        channel: '#deployments'
        webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### Comandos para agregar los archivos a tu repositorio

Ejecuta estos comandos en la raíz de tu repositorio local:

```bash
# Crear la estructura de directorios
mkdir -p .github/workflows

# Crear los archivos (necesitarás copiar el contenido de arriba)
touch .github/workflows/ci.yml
touch .github/workflows/azure-deploy.yml
touch .github/workflows/azure-deploy-advanced.yml

# Agregar al repositorio
git add .github/
git commit -m "feat: agregar workflows de GitHub Actions para CI/CD"
git push origin main
```

### Verificación del Setup

Una vez que agregues los archivos y hagas push:

1. **Ve a tu repositorio en GitHub**
2. **Haz clic en la pestaña "Actions"**
3. **Verifica que los workflows aparezcan**
4. **Haz un pequeño cambio y push para probar el pipeline**

### Beneficios de esta configuración

- ✅ **Automatización completa**: Desde push hasta producción
- ✅ **Tests automáticos**: Se ejecutan en cada PR
- ✅ **Multi-ambiente**: Staging y Production
- ✅ **Rollback fácil**: Usando tags de imagen
- ✅ **Monitoreo**: Smoke tests post-deployment
- ✅ **Notificaciones**: En caso de fallos

Tu repositorio ya tiene toda la estructura necesaria, solo necesitas agregar estos workflows para tener un CI/CD completo.
