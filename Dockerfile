# ---------- Build stage ----------
FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /app
 
# Copy only Maven descriptors first for layer caching
COPY pom.xml .
# If you have a parent POM or modules, copy them accordingly
 
# Download dependencies (cached if pom.xml unchanged)
RUN mvn -q -e -U -B dependency:go-offline
 
# Copy the rest of the source
COPY . .
 
# Build the WAR (skip tests if you like for faster builds)
RUN mvn -q -e -B -DskipTests package
 
# ---------- Runtime stage ----------
FROM tomcat:9.0-jdk17-temurin
# Tomcat 9 matches Servlet/JSP typical for legacy J2EE apps
 
# Optional: remove default ROOT app
RUN rm -rf /usr/local/tomcat/webapps/*
 
# Copy built WAR to Tomcat webapps; rename to ROOT.war to serve at "/"
COPY --from=build /app/target/*.war /usr/local/tomcat/webapps/ROOT.war
 
EXPOSE 8080
CMD ["catalina.sh", "run"]
 
