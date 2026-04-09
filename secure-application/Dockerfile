FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn package -DskipTests -B

FROM eclipse-temurin:17-jre
WORKDIR /app

# Download the Splunk OTel Java Agent with CSA (Application Security)
ARG AGENT_VERSION=2.25.1
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/* \
    && curl -L "https://repo1.maven.org/maven2/com/splunk/splunk-otel-javaagent-csa/${AGENT_VERSION}/splunk-otel-javaagent-csa-${AGENT_VERSION}.jar" \
       -o /app/splunk-otel-javaagent.jar

COPY --from=build /app/target/door-game-1.0.0.jar /app/door-game.jar

EXPOSE 8080

ENTRYPOINT ["java", \
    "-javaagent:/app/splunk-otel-javaagent.jar", \
    "-jar", "/app/door-game.jar"]
