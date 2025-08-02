# Multi-stage build para optimizar la imagen
FROM maven:3.9.4-eclipse-temurin-17 AS build

# Copiar archivos de configuración de Maven
COPY pom.xml /app/
COPY src /app/src/

# Establecer directorio de trabajo
WORKDIR /app

# Construir la aplicación
RUN mvn clean package -DskipTests

# Imagen final
FROM eclipse-temurin:17-jre-alpine

# Crear usuario no-root para seguridad
RUN addgroup -g 1001 -S quarkus && \
    adduser -u 1001 -S quarkus -G quarkus

# Copiar el JAR construido
COPY --from=build /app/target/quarkus-postgres-1.0.0-SNAPSHOT-runner.jar /app/application.jar

# Cambiar propietario del archivo
RUN chown -R quarkus:quarkus /app

# Cambiar a usuario no-root
USER quarkus

# Exponer puerto
EXPOSE 8080

# Comando para ejecutar la aplicación
CMD ["java", "-jar", "/app/application.jar"]
