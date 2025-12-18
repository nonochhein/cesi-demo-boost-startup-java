# ═══════════════════════════════════════
# STAGE 1: Builder
# ═══════════════════════════════════════
FROM bellsoft/liberica-openjdk-alpine:25 AS builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# ═══════════════════════════════════════
# STAGE 2: Runtime
# ═══════════════════════════════════════
FROM bellsoft/liberica-runtime-container:jre-25-slim-musl

# ⚠️ Bonne pratique : Ne pas utiliser root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

WORKDIR /app
COPY --from=builder --chown=appuser:appgroup /app/target/*.jar app.jar

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]