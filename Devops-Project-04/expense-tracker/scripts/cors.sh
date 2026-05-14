#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${1:-expense-tracker-backend}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "Project directory '$PROJECT_DIR' not found."
  echo "Usage: $0 /path/to/expense-tracker-backend"
  exit 1
fi

cd "$PROJECT_DIR"

mkdir -p src/main/java/com/example/expensetracker/config

cat > src/main/java/com/example/expensetracker/config/CorsConfig.java <<'EOF'
package com.example.expensetracker.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

import java.util.List;

@Configuration
public class CorsConfig {

    @Bean
    public CorsFilter corsFilter() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowCredentials(true);
        config.setAllowedOriginPatterns(List.of(
                "http://localhost:3000",
                "http://127.0.0.1:3000"
        ));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));
        config.setExposedHeaders(List.of("Authorization", "Content-Type"));

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);

        return new CorsFilter(source);
    }
}
EOF

echo "Rebuilding project..."
mvn clean package -DskipTests

echo ""
echo "CORS configuration added successfully."
echo "Allowed origins:"
echo "  - http://localhost:3000"
echo "  - http://127.0.0.1:3000"
echo ""
echo "Restart the backend:"
echo "  mvn spring-boot:run"

