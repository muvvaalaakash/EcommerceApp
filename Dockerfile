# ---------- Stage 1: Build with Maven ----------
FROM maven:3.9.9-eclipse-temurin-8 AS build
# If your project needs JDK 8; if it compiles only on 11/17, switch to temurin-11/17

# Set workdir
WORKDIR /app

# Copy just the pom first to leverage Docker layer caching
COPY ./EcommerceApp/pom.xml ./EcommerceApp/pom.xml

# Pre-download dependencies (speeds up subsequent builds)
RUN --mount=type=cache,target=/root/.m2 \
    mvn -f ./EcommerceApp/pom.xml -B -e -DskipTests dependency:go-offline

# Copy the full source and build
COPY ./EcommerceApp ./EcommerceApp

# Build WAR (adjust if the module name differs)
RUN --mount=type=cache,target=/root/.m2 \
    mvn -f ./EcommerceApp/pom.xml -B -e -DskipTests clean package

# ---------- Stage 2: Runtime with Tomcat ----------
FROM tomcat:9.0-jdk8-temurin
# If you need Tomcat 10 + Jakarta, change image and web.xml/packages accordingly

# Remove default ROOT app
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the built WAR into Tomcat webapps as ROOT
# If your WAR name is different, change the path accordingly (e.g., target/EcommerceApp.war)
COPY --from=build /app/EcommerceApp/target/*.war /usr/local/tomcat/webapps/ROOT.war

# (Optional) If your app uses SQLite DB file, create a persistent directory
# and point your JDBC URL to this path (e.g., jdbc:sqlite:/data/ecomm.db)
RUN mkdir -p /data
VOLUME ["/data"]

# Expose Tomcat HTTP port
EXPOSE 8080

# Health check (Tomcat root)
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD curl -fsS http://localhost:8080/ || exit 1

# Start Tomcat
CMD ["catalina.sh", "run"]
