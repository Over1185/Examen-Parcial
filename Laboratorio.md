# 3. Laboratorio: Ejecución de pipeline en Jenkins para despliegue de infraestructura en Azure

## Paso 1: Configurar DOCKERFILE completo con Git, jq, az CLI y Terraform incluidos para tus pipelines con Terraform en Azure

Ideal para ejecutar pipelines como el tuyo que usan GitHub, Azure y Terraform.

### Descripción

En este laboratorio, ejecutarás un pipeline en Jenkins para el despliegue automatizado de infraestructura en Microsoft Azure. Usarás Terraform para definir tu infraestructura como código (IaC) y configurarás un pipeline que gestione la implementación y actualización de dicha infraestructura de forma eficiente a través de Azure CLI y Azure Service Principal.

### Requisitos Previos

1. Cuenta de Azure con permisos para crear recursos.
2. Azure CLI instalado en la máquina de Jenkins.
3. Jenkins instalado con los siguientes plugins:
   - Azure CLI Plugin
   - Pipeline Plugin
   - Terraform Plugin
   - Pipeline Stage View Plugin
   - Pipeline Utility Steps Plugin

## Paso 2: Dockerfile completo para tu Jenkins que incluye:

- git
- jq
- azure-cli
- terraform

Ideal para ejecutar pipelines como el tuyo que usan GitHub, Azure y Terraform

```dockerfile
FROM jenkins/jenkins:lts
USER root

# Instala dependencias básicas, Git, jq y certificados
RUN apt-get update && \
    apt-get install -y git jq curl apt-transport-https ca-certificates gnupg lsb-release software-properties-common unzip software-properties-common gnupg2

# Instala Azure CLI
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
    install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/azure-cli.list && \
    apt-get update && \
    apt-get install -y azure-cli && \
    rm -f microsoft.gpg

# Instala Terraform
ENV TERRAFORM_VERSION=1.8.4
RUN curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip && \
    unzip terraform.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform.zip

# Verificaciones opcionales (puedes quitarlas si no deseas salidas de versión)
RUN git --version && jq --version && az version && terraform -version

USER jenkins
```

### Guarda el Dockerfile

Guarda el contenido en un archivo llamado exactamente: `Dockerfile` en un directorio vacío, por ejemplo:

```bash
mkdir jenkins-azure-terraform
cd jenkins-azure-terraform
# guarda el Dockerfile dentro
```

### Construye la imagen Docker

```bash
docker build -t jenkins-azure-terraform .
```

### Ejecuta el contenedor con esa imagen

```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins-azure-terraform
```

Ve a tu navegador y abre: http://localhost:8080

Para el primer uso, Jenkins te pedirá el unlock admin password, que puedes obtener con:

```bash
docker exec -it jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

## Paso 2: Crear un Azure Service Principal

Este servicio se usará para autenticarse desde Jenkins.

### Cómo crear un Service Principal en Azure paso a paso

1. Abre una terminal con Azure CLI (puedes usar Azure Cloud Shell o tu propia máquina con Azure CLI instalado).

2. Ejecuta el siguiente comando (sustituye `<NOMBRE-SP>` con un nombre representativo, por ejemplo `jenkins-sp`):

```bash
az ad sp create-for-rbac --name <NOMBRE-SP> --role Contributor --scopes /subscriptions/<ID-DE-TU-SUSCRIPCION> --sdk-auth
```

**Ejemplo:**

```bash
az ad sp create-for-rbac --name jenkins-sp --role Contributor \
  --scopes /subscriptions/12345678-aaaa-bbbb-cccc-1234567890ab --sdk-auth
```

### COMO VER MI USUARIO AZURE CLI

1. Abre tu terminal (puede ser local o Azure Cloud Shell): https://portal.azure.com/#cloudshell/

2. Inicia sesión en tu cuenta de Azure si no lo has hecho:
   ```bash
   az login
   ```

3. Una vez autenticado, ejecuta:
   ```bash
   az account list --output table
   ```

   Esto mostrará una tabla como:

```bash
az ad sp create-for-rbac --name <NOMBRE-SP> --role Contributor --scopes /subscriptions/<ID-DE-TU-SUSCRIPCION> --sdk-auth
```

Copia la salida JSON y guárdala como secreto de Jenkins con ID `azure-service-principal`.

### ¿Cómo hacerlo?

1. Ve a: **Jenkins > Manage Jenkins > Credentials > (tu almacén, como "Global") > Add Credentials**.

2. Configura así:
   - **Kind:** Secret text
   - **Secret:** (pega aquí todo el JSON generado con `az ad sp create-for-rbac --sdk-auth`)
   - **ID:** azure-service-principal
   - **Description:** Credencial para autenticación con Azure desde Jenkins

## Paso 3: Configurar el pipeline en Jenkins

### Pipeline para Despliegue de Infraestructura en Azure

#### Objetivo

Crear un Jenkinsfile que defina un pipeline declarativo para:

1. Obtener el código desde un repositorio.
2. Inicializar Terraform.
3. Generar el plan de infraestructura.
4. Aplicar el plan, desplegando la infraestructura en Azure.

#### Requisitos previos en Jenkins

1. Jenkins instalado y en ejecución.
2. Terraform instalado en el entorno de Jenkins (puede instalarse globalmente o en la imagen Docker).
3. Azure CLI instalado y configurado en el agente Jenkins.
4. Jenkins con los siguientes plugins instalados:
   - Pipeline
   - Credentials Binding Plugin
   - Terraform Plugin (opcional)
   - Azure CLI Plugin (opcional si usas directamente az login vía terminal)

### Paso 1: Estructura de archivos del proyecto Terraform

#### Estructura esperada del repositorio Git

Tu repositorio debe tener al menos los siguientes archivos:
https://github.com/jaimepsayago/azure-appservice-tf/tree/main

### Paso 2: Jenkinsfile

Este Jenkinsfile se encarga de:
- Clonar el repositorio.
- Loguearse a Azure.
- Ejecutar Terraform init, plan y apply.

```groovy
pipeline {
    agent any
    
    environment {
        TF_IN_AUTOMATION = "true"
    }
    
    stages {
        stage('Clonar Repositorio') {
            steps {
                git branch: 'main', url: 'https://github.com/jaimepsayago/azure-appservice-tf'
            }
        }
        
        stage('Autenticación Azure') {
            steps {
                withCredentials([string(credentialsId: 'azure-service-principal', variable: 'AZURE_CREDENTIALS_JSON')]) {
                    sh '''
                        echo "$AZURE_CREDENTIALS_JSON" > azure-credentials.json
                        
                        export ARM_CLIENT_ID=$(jq -r .clientId azure-credentials.json)
                        export ARM_CLIENT_SECRET=$(jq -r .clientSecret azure-credentials.json)
                        export ARM_TENANT_ID=$(jq -r .tenantId azure-credentials.json)
                        export ARM_SUBSCRIPTION_ID=$(jq -r .subscriptionId azure-credentials.json)
                        
                        echo "client_id = \\"$ARM_CLIENT_ID\\"" > terraform.tfvars
                        echo "client_secret = \\"$ARM_CLIENT_SECRET\\"" >> terraform.tfvars
                        echo "tenant_id = \\"$ARM_TENANT_ID\\"" >> terraform.tfvars
                        echo "subscription_id = \\"$ARM_SUBSCRIPTION_ID\\"" >> terraform.tfvars
                        
                        az login --service-principal \
                            --username $ARM_CLIENT_ID \
                            --password $ARM_CLIENT_SECRET \
                            --tenant $ARM_TENANT_ID
                            
                        az account set --subscription $ARM_SUBSCRIPTION_ID
                    '''
                }
            }
        }
        
        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }
        
        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -out=tfplan'
            }
        }
        
        stage('Aprobación') {
            steps {
                input message: '¿Deseas aplicar los cambios en Azure?'
            }
        }
        
        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve tfplan'
            }
        }
    }
}
```

#### ¿Qué hace cada etapa?

| Etapa | Descripción |
|-------|-------------|
| Clonar repositorio | Descarga el código fuente de Terraform desde GitHub u otro repositorio. |
| Autenticación con Azure | Usa el Service Principal (guardado como secreto) para hacer login automático a Azure. |
| Terraform Init | Inicializa Terraform (descarga providers y backend si lo hay). |
| Terraform Plan | Genera el plan de ejecución, que muestra qué recursos se crearán, modificarán o destruirán. |
| Aprobación Manual | Pausa el pipeline hasta que un operador apruebe el despliegue. |
| Terraform Apply | Aplica el plan y despliega la infraestructura en Azure. |

### Paso 3: Ejecutar en Jenkins

1. Crea un nuevo Pipeline Job en Jenkins.
2. Configura Git en tools.
3. Crear credenciales de git en Jenkins.
4. Configura el SCM (repositorio Git) donde tienes el proyecto.
5. Asegúrate de tener Terraform, Azure CLI y jq instalados en Jenkins.
6. Ejecuta el pipeline y aprueba manualmente el apply.

### Resultado esperado

Al finalizar el pipeline, tendrás:
- Un grupo de recursos en Azure llamado `rg-tf-appservice`.
- Un App Service Plan gratuito.
- Una Web App con una URL pública tipo: https://tf-webapp-example.azurewebsites.net/

## Tarea

### Primera parte:
- Construir un Jenkins Pipeline para construir y ejecutar un contenedor Docker con una aplicación Quarkus

### Segunda parte:
- Despliegue del proyecto Quarkus en Azure App Service (con Docker)