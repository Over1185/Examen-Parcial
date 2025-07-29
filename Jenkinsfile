pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE_NAME = 'quarkus-microservice'
        DOCKER_TAG = "${BUILD_NUMBER}"
        DOCKER_REGISTRY = 'docker.io'
        APP_NAME = 'quarkus-movies-api'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Clonando repositorio...'
                checkout scm
            }
        }
        
        stage('Verificar Estructura') {
            steps {
                echo 'Verificando estructura del proyecto...'
                sh '''
                    ls -la
                    cd Quarkus-Docker
                    ls -la
                    cat pom.xml | head -20
                '''
            }
        }
        
        stage('Test Aplicación Quarkus') {
            steps {
                echo 'Ejecutando tests de la aplicación Quarkus...'
                dir('Quarkus-Docker') {
                    sh '''
                        # Ejecutar tests con Maven wrapper
                        chmod +x mvnw
                        ./mvnw test -DskipITs=true
                    '''
                }
            }
        }
        
        stage('Build Aplicación') {
            steps {
                echo 'Construyendo aplicación Quarkus...'
                dir('Quarkus-Docker') {
                    sh '''
                        # Construir la aplicación
                        ./mvnw clean package -DskipTests
                        
                        # Verificar que el JAR fue creado
                        ls -la target/
                        if [ ! -f "target/quarkus-postgres-1.0.0-SNAPSHOT-runner.jar" ]; then
                            echo "Error: JAR no encontrado"
                            exit 1
                        fi
                    '''
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo 'Construyendo imagen Docker...'
                dir('Quarkus-Docker') {
                    script {
                        // Construir la imagen Docker
                        def dockerImage = docker.build("${DOCKER_IMAGE_NAME}:${DOCKER_TAG}")
                        
                        // También crear tag 'latest'
                        sh "docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_TAG} ${DOCKER_IMAGE_NAME}:latest"
                        
                        // Listar imágenes creadas
                        sh "docker images | grep ${DOCKER_IMAGE_NAME}"
                    }
                }
            }
        }
        
        stage('Test Docker Container') {
            steps {
                echo 'Probando contenedor Docker...'
                dir('Quarkus-Docker') {
                    script {
                        try {
                            // Levantar PostgreSQL para pruebas
                            sh '''
                                docker network create quarkus-test-network || true
                                
                                docker run -d --name postgres-test \
                                    --network quarkus-test-network \
                                    -e POSTGRES_DB=quarkusdb \
                                    -e POSTGRES_USER=postgres \
                                    -e POSTGRES_PASSWORD=admin \
                                    postgres:15-alpine
                                
                                # Esperar a que PostgreSQL esté listo
                                sleep 30
                            '''
                            
                            // Ejecutar la aplicación Quarkus
                            sh '''
                                docker run -d --name quarkus-test \
                                    --network quarkus-test-network \
                                    -p 8081:8080 \
                                    -e QUARKUS_DATASOURCE_JDBC_URL=jdbc:postgresql://postgres-test:5432/quarkusdb \
                                    ${DOCKER_IMAGE_NAME}:${DOCKER_TAG}
                                
                                # Esperar a que la aplicación esté lista
                                sleep 45
                                
                                # Probar endpoints
                                curl -f http://localhost:8081/users/hello || exit 1
                                curl -f http://localhost:8081/users || exit 1
                                curl -f http://localhost:8081/movies || exit 1
                                curl -f http://localhost:8081/critics || exit 1
                                curl -f http://localhost:8081/reviews || exit 1
                                
                                echo "✅ Todos los endpoints respondieron correctamente"
                            '''
                        } finally {
                            // Limpiar contenedores de prueba
                            sh '''
                                docker stop quarkus-test postgres-test || true
                                docker rm quarkus-test postgres-test || true
                                docker network rm quarkus-test-network || true
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Docker Compose Test') {
            steps {
                echo 'Probando con Docker Compose...'
                dir('Quarkus-Docker') {
                    script {
                        try {
                            sh '''
                                # Levantar servicios con docker-compose
                                docker-compose up -d
                                
                                # Esperar a que los servicios estén listos
                                echo "Esperando a que los servicios estén listos..."
                                sleep 60
                                
                                # Verificar que los contenedores están corriendo
                                docker-compose ps
                                
                                # Probar la aplicación
                                for i in {1..5}; do
                                    if curl -f http://localhost:8080/users/hello; then
                                        echo "✅ Aplicación respondiendo correctamente"
                                        break
                                    else
                                        echo "Intento $i fallido, reintentando..."
                                        sleep 10
                                    fi
                                done
                                
                                # Probar otros endpoints
                                curl -f http://localhost:8080/users
                                curl -f http://localhost:8080/movies
                            '''
                        } finally {
                            // Limpiar
                            sh '''
                                docker-compose logs quarkus-app
                                docker-compose down
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Push to Registry') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                    expression { params.FORCE_DEPLOY == true }
                }
            }
            steps {
                echo 'Subiendo imagen a registry...'
                script {
                    // Aquí puedes configurar push a Docker Hub, Azure Container Registry, etc.
                    echo "Imagen ${DOCKER_IMAGE_NAME}:${DOCKER_TAG} lista para deploy"
                    
                    // Ejemplo para Docker Hub (requiere credenciales configuradas):
                    // docker.withRegistry('https://registry-1.docker.io/v2/', 'docker-hub-credentials') {
                    //     def image = docker.image("${DOCKER_IMAGE_NAME}:${DOCKER_TAG}")
                    //     image.push()
                    //     image.push("latest")
                    // }
                }
            }
        }
    }
    
    post {
        always {
            echo 'Limpiando workspace...'
            // Limpiar imágenes Docker no utilizadas
            sh '''
                docker system prune -f
                docker images
            '''
        }
        success {
            echo '✅ Pipeline completado exitosamente!'
            echo "Imagen Docker creada: ${DOCKER_IMAGE_NAME}:${DOCKER_TAG}"
        }
        failure {
            echo '❌ Pipeline falló'
            // Aquí puedes agregar notificaciones
        }
    }
}
