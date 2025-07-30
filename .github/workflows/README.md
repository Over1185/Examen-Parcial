# GitHub Actions CI/CD Workflows

Este directorio contiene los workflows de GitHub Actions para automatizar el CI/CD de la aplicación Quarkus.

## Workflows Disponibles

### 1. CI - Build and Test (`ci.yml`)

- **Trigger**: Push a main/develop y Pull Requests
- **Funcionalidad**:
  - Ejecuta tests unitarios
  - Compila la aplicación
  - Construye imagen Docker
  - Ejecuta tests de la imagen

### 2. Deploy to Azure (`azure-deploy.yml`)

- **Trigger**: Push a main y manual
- **Funcionalidad**:
  - Construye y despliega a Azure App Service
  - Sube imagen a Azure Container Registry
  - Ejecuta verificaciones post-deploy

### 3. Deploy Multi-Environment (`azure-deploy-advanced.yml`)

- **Trigger**: Push, PR y manual
- **Funcionalidad**:
  - Deploy a staging en PR
  - Deploy a production en push a main
  - Smoke tests automáticos

## Configuración Requerida

### Secrets de GitHub

Configura estos secrets en Settings > Secrets and variables > Actions:

1. **AZURE_CREDENTIALS**: Credenciales del Service Principal de Azure

   ```bash
   az ad sp create-for-rbac --name "github-actions-sp" \
     --role contributor \
     --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
     --sdk-auth
   ```

### Variables de Entorno

Los workflows usan estas variables (modificables en los archivos):

- `AZURE_WEBAPP_NAME`: webapp-quarkus-movies
- `AZURE_RESOURCE_GROUP`: rg-quarkus-app
- `CONTAINER_REGISTRY`: acrquarkusapp.azurecr.io
- `IMAGE_NAME`: quarkus-microservice

## Uso

1. **Push a main**: Ejecuta CI + Deploy a producción
2. **Pull Request**: Ejecuta CI + Deploy a staging
3. **Manual**: Workflow dispatch con selección de ambiente

## Estructura del Proyecto

```
.github/
└── workflows/
    ├── ci.yml                    # CI básico
    ├── azure-deploy.yml          # Deploy simple
    └── azure-deploy-advanced.yml # Deploy multi-ambiente
```
