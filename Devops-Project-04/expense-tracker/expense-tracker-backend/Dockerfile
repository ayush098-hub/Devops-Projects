FROM maven:3.8.3-openjdk-17 AS builder
WORKDIR /app
COPY . .
RUN mvn clean install;

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /app/target/expense-tracker-backend-0.0.1-SNAPSHOT.jar .
CMD ["java","-jar","expense-tracker-backend-0.0.1-SNAPSHOT.jar"]

