###############################
# EJECUTAR BUILD - COMPILACION.

FROM maven:3.9.9-eclipse-temurin-21 AS builder

# Directorio Inicial.
WORKDIR /app

# Copio desde tu proyecto el pom.xml y la llevo al directorio
# principal de docker, xq ahí la voy a ejecutar.
COPY pom.xml .

# Se corren las dependencias para que se ejecuten offline
RUN mvn dependency:go-offline

# Tomo la carpeta del código fuente y la monto en docker
COPY src ./src

RUN mvn clean package -DskipTests

#####################################
# Ejecutar el proyecto compilado - RunTime.

FROM eclipse-temurin:21-jre 

WORKDIR /app

COPY --from=builder /app/target/*.jar app.jar

#Se expone el puerto 8080

EXPOSE 8080 

ENTRYPOINT ["java", "-jar", "app.jar"]



