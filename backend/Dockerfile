# --- Etapa 1: compilar con Maven ---
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn clean package -DskipTests -B

# --- Etapa 2: correr en Tomcat ---
FROM tomcat:10.1-jdk17
ENV JAVA_OPTS="-Dfile.encoding=UTF-8 -Dserver.tomcat.uri-encoding=UTF-8"
RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=build /app/target/geotravel.war /usr/local/tomcat/webapps/ROOT.war
EXPOSE 8080
CMD ["catalina.sh", "run"]