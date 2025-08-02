#Guión para Video: Pipeline Jenkins y Despliegue Quarkus en Azure

## Información del Video

- **Duración Estimada**: 15-20 minutos
- **Audiencia**: Desarrolladores y DevOps Engineers
- **Objetivo**: Explicar el pipeline de Jenkins para aplicación Quarkus y su despliegue en Azure

---

## Estructura del Video

### 🎬 **INTRODUCCIÓN** (2-3 minutos)

#### **Presentador 1**: Saludo y contexto
>
> "¡Hola! Soy [Nombre] y hoy junto con mi compañero [Nombre] te vamos a mostrar cómo implementamos un pipeline completo de Jenkins para desplegar una aplicación Quarkus en Microsoft Azure."

#### **Presentador 2**: Agenda del video
>
> "En este video veremos:
>
> - La aplicación Quarkus que desarrollamos
> - El pipeline de Jenkins que automatiza todo el proceso
> - El despliegue en Azure App Service
> - Una demostración en vivo de la aplicación funcionando"

---

### 📁 **PARTE 1: PRESENTACIÓN DEL PROYECTO** (3-4 minutos)

#### **Presentador 1**: Mostrar la estructura del proyecto
>
> "Primero, veamos qué tenemos en nuestro proyecto:"

**[MOSTRAR EN PANTALLA]**: Explorador de archivos con la estructura del proyecto

> "Como pueden ver, tenemos:
>
> - Una aplicación Quarkus en el directorio `Quarkus-Docker`
> - Un Jenkinsfile que define nuestro pipeline
> - Archivos de Terraform para infraestructura
> - Y documentación completa del laboratorio"

#### **Presentador 2**: Explicar la aplicación Quarkus
>
> "Nuestra aplicación Quarkus es una API REST para gestión de películas que incluye:"

**[MOSTRAR EN PANTALLA]**: Código de las clases principales

> "- **Entidades**: User, Movie, Critic, Review
>
> - **Recursos REST**: Endpoints para cada entidad
> - **Base de datos**: PostgreSQL con Hibernate ORM
> - **Contenedorización**: Docker para el despliegue"

**[MOSTRAR EN PANTALLA]**: `pom.xml` destacando dependencias principales

> "Las dependencias principales son Quarkus REST, Hibernate ORM con Panache, y el driver de PostgreSQL."

---

### 🔧 **PARTE 2: ANÁLISIS DEL PIPELINE JENKINS** (5-6 minutos)

#### **Presentador 1**: Introducción al Jenkinsfile
>
> "Ahora analicemos nuestro pipeline de Jenkins paso a paso:"

**[MOSTRAR EN PANTALLA]**: Jenkinsfile completo

> "Nuestro pipeline tiene [contar] etapas principales que automatizan todo el proceso desde el código hasta el despliegue."

#### **Presentador 2**: Desglose de las etapas

**ETAPA 1: Checkout**
> "Primero, Jenkins clona nuestro repositorio:"

**[MOSTRAR EN PANTALLA]**:

```groovy
stage('Checkout') {
    steps {
        echo 'Clonando repositorio...'
        checkout scm
    }
}
```

> "Esto asegura que tenemos la última versión del código."

**ETAPA 2: Verificar Estructura**
> "Luego verificamos que todos los archivos necesarios estén presentes:"

**[MOSTRAR EN PANTALLA]**:

```groovy
stage('Verificar Estructura') {
    steps {
        sh '''
            ls -la
            cd Quarkus-Docker
            ls -la
            cat pom.xml | head -20
        '''
    }
}
```

**ETAPA 3: Test Aplicación**

#### **Presentador 1**
>
> "Ejecutamos las pruebas unitarias con Maven:"

**[MOSTRAR EN PANTALLA]**: Código de la etapa de tests

> "Esto asegura que nuestro código funciona correctamente antes de crear la imagen Docker."

**ETAPA 4: Build Aplicación**
> "Compilamos la aplicación con Maven:"

**[MOSTRAR EN PANTALLA]**:

```groovy
sh './mvnw clean package -DskipTests'
```

> "Esto genera el JAR ejecutable que será incluido en nuestra imagen Docker."

**ETAPA 5: Build Docker Image**

#### **Presentador 2**
>
> "Aquí es donde la magia sucede - creamos nuestra imagen Docker:"

**[MOSTRAR EN PANTALLA]**: Código de build de Docker

> "Jenkins construye la imagen usando nuestro Dockerfile y la etiqueta con el número de build para versionado."

**ETAPA 6-7: Testing de Contenedores**
> "Estas son las etapas más importantes - probamos que nuestros contenedores funcionen:"

**[MOSTRAR EN PANTALLA]**: Código de test de contenedores

> "Primero probamos con contenedores individuales, luego con Docker Compose para simular el entorno completo."

---

### 🐳 **PARTE 3: DOCKERFILE Y DOCKER COMPOSE** (2-3 minutos)

#### **Presentador 1**: Explicar el Dockerfile
>
> "Veamos cómo construimos nuestra imagen Docker:"

**[MOSTRAR EN PANTALLA]**: Dockerfile

> "Usamos un multi-stage build:
>
> 1. **Stage 1**: Maven para compilar la aplicación
> 2. **Stage 2**: Runtime con Java 17 Alpine para la imagen final"

#### **Presentador 2**: Docker Compose para desarrollo
>
> "Para desarrollo local usamos Docker Compose:"

**[MOSTRAR EN PANTALLA]**: docker-compose.yml

> "Esto nos permite levantar PostgreSQL y nuestra aplicación con un solo comando:
> `docker-compose up`"

---

### ☁️ **PARTE 4: DESPLIEGUE EN AZURE** (4-5 minutos)

#### **Presentador 1**: Arquitectura en Azure
>
> "Para el despliegue en Azure utilizamos:"

**[MOSTRAR EN PANTALLA]**: Diagrama o Azure Portal

> "- **Azure Container Registry**: Para almacenar nuestras imágenes Docker
>
> - **Azure App Service**: Para ejecutar nuestra aplicación
> - **Azure Database for PostgreSQL**: Como base de datos administrada"

#### **Presentador 2**: Proceso de despliegue
>
> "El proceso es el siguiente:"

**[MOSTRAR EN PANTALLA]**: Azure Portal navegando por los recursos

> "1. **Construimos** la imagen localmente
> 2. **Subimos** al Azure Container Registry
> 3. **Configuramos** el App Service para usar nuestra imagen
> 4. **Configuramos** las variables de entorno para la base de datos"

**[MOSTRAR COMANDOS]**:

```bash
# Build y push de la imagen
docker build -t quarkus-microservice .
az acr login --name acrquarkusapp
docker tag quarkus-microservice acrquarkusapp.azurecr.io/quarkus-microservice:latest
docker push acrquarkusapp.azurecr.io/quarkus-microservice:latest
```

---

### 🚀 **PARTE 5: DEMOSTRACIÓN EN VIVO** (3-4 minutos)

#### **Presentador 1**: Mostrar la aplicación funcionando
>
> "Ahora veamos nuestra aplicación en acción:"

**[MOSTRAR EN PANTALLA]**: Navegador web

> "Aquí está nuestra aplicación ejecutándose en Azure:"

**URLs a mostrar**:

- `https://webapp-quarkus-movies.azurewebsites.net/users/hello`
- `https://webapp-quarkus-movies.azurewebsites.net/users`
- `https://webapp-quarkus-movies.azurewebsites.net/movies`

#### **Presentador 2**: Demostrar la API
>
> "Vamos a probar algunos endpoints con Postman o curl:"

**[MOSTRAR EN PANTALLA]**: Herramienta de API testing

**Ejemplos a mostrar**:

1. **GET** `/users` - Listar usuarios
2. **POST** `/users` - Crear un usuario
3. **GET** `/movies` - Listar películas
4. **POST** `/movies` - Crear una película

#### **Presentador 1**: Mostrar logs y monitoreo
>
> "También podemos ver los logs en tiempo real:"

**[MOSTRAR EN PANTALLA]**: Azure Portal - Log Stream

> "Azure nos proporciona monitoreo completo de nuestra aplicación."

---

### 🎯 **CONCLUSIONES** (2 minutos)

#### **Presentador 2**: Beneficios de esta solución
>
> "Lo que hemos implementado nos da:"

> "✅ **Automatización completa** desde código hasta producción
> ✅ **Calidad asegurada** con tests automatizados
> ✅ **Escalabilidad** en la nube de Azure
> ✅ **Monitoreo** y logs centralizados
> ✅ **Facilidad de despliegue** con un solo push al repositorio"

#### **Presentador 1**: Próximos pasos
>
> "Para mejorar aún más esta solución, se podría:"

> "- Implementar **CI/CD automático** conectando GitHub con Jenkins
>
> - Agregar **más tests** de integración y end-to-end
> - Configurar **alertas automáticas** de monitoreo
> - Implementar **blue-green deployments** para zero downtime"

#### **Ambos presentadores**: Cierre
>
> **Presentador 2**: "Esperamos que este video te haya sido útil para entender cómo implementar un pipeline completo de DevOps con Jenkins, Docker y Azure."

> **Presentador 1**: "Si tienes preguntas o quieres ver el código completo, puedes encontrarlo en nuestro repositorio de GitHub. ¡No olvides suscribirte y darnos like si el contenido te fue útil!"

---

## 📋 **CHECKLIST PARA LA GRABACIÓN**

### Antes de grabar

- [ ] **Probar** que todos los servicios en Azure estén funcionando
- [ ] **Verificar** que Jenkins esté accesible
- [ ] **Preparar** datos de prueba para la demostración
- [ ] **Tener** Postman o herramienta de API configurada
- [ ] **Verificar** que la pantalla se vea bien en la grabación

### Durante la grabación

- [ ] **Hablar claramente** y no muy rápido
- [ ] **Hacer zoom** cuando muestren código
- [ ] **Explicar** lo que están haciendo antes de hacerlo
- [ ] **Usar** el cursor para señalar elementos importantes
- [ ] **Pausar** entre secciones para que sea fácil de seguir

### Pantallas a preparar

- [ ] **VS Code** con el proyecto abierto
- [ ] **Jenkins** con el pipeline visible
- [ ] **Azure Portal** con los recursos creados
- [ ] **Terminal** con comandos preparados
- [ ] **Navegador** con pestañas de la aplicación

---

## 💡 **CONSEJOS PARA UNA BUENA PRESENTACIÓN**

### Para el Presentador 1

- **Enfócate** en la parte técnica y arquitectura
- **Explica** el código de manera clara
- **Usa** analogías cuando sea necesario
- **Mantén** un ritmo pausado

### Para el Presentador 2

- **Enfócate** en los beneficios de negocio
- **Haz** las demostraciones prácticas
- **Explica** el valor de cada paso
- **Mantén** la energía alta

### Para ambos

- **Practiquen** antes de grabar
- **Coordinen** quién habla en cada parte
- **Tengan** un plan B si algo falla
- **Mantengan** el video dinámico

---

## 🎬 **SCRIPT DE TRANSICIONES**

### Entre secciones
>
> "Ahora que hemos visto [tema anterior], pasemos a analizar [siguiente tema]..."

### Para mostrar código
>
> "Veamos esto en código..." / "Si miramos aquí..."

### Para demostraciones
>
> "Ahora veamos esto en acción..." / "Demostremos esto..."

### Para conclusiones
>
> "Como pueden ver..." / "Esto nos muestra que..."

---

## 📊 **MÉTRICAS DE ÉXITO DEL VIDEO**

### Lo que queremos lograr

- **Claridad**: Que cualquier desarrollador pueda replicar el proceso
- **Completitud**: Cubrir todo el flujo desde desarrollo hasta producción
- **Practicidad**: Mostrar ejemplos reales funcionando
- **Valor**: Que el espectador aprenda algo útil para su trabajo

### Puntos clave a enfatizar

1. **Automatización** reduce errores humanos
2. **Testing** asegura calidad
3. **Containerización** facilita despliegues
4. **Cloud** proporciona escalabilidad
5. **DevOps** acelera tiempo al mercado
