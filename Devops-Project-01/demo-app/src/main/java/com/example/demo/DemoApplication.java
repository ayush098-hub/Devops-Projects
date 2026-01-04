// DemoApplication.java - Main Spring Boot Application
package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.stereotype.Component;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.ui.Model;

@SpringBootApplication
public class DemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}

// HomeController.java - Serves the frontend
@Controller
class HomeController {
    
    @Value("${app.version:1.0.0}")
    private String appVersion;
    
    @GetMapping("/")
    public String home(Model model) {
        model.addAttribute("version", appVersion);
        return "index";
    }
}

// HealthController.java - Health check endpoint for CI/CD
@RestController
class HealthController {
    
    @Value("${app.version:1.0.0}")
    private String appVersion;
    
    @GetMapping("/api/health")
    public HealthResponse health() {
        return new HealthResponse("UP", appVersion, System.currentTimeMillis());
    }
    
    @GetMapping("/api/version")
    public VersionResponse version() {
        return new VersionResponse(appVersion, "Demo Application");
    }
}

// Health Response DTO
class HealthResponse {
    private String status;
    private String version;
    private long timestamp;
    
    public HealthResponse(String status, String version, long timestamp) {
        this.status = status;
        this.version = version;
        this.timestamp = timestamp;
    }
    
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getVersion() { return version; }
    public void setVersion(String version) { this.version = version; }
    public long getTimestamp() { return timestamp; }
    public void setTimestamp(long timestamp) { this.timestamp = timestamp; }
}

// Version Response DTO
class VersionResponse {
    private String version;
    private String appName;
    
    public VersionResponse(String version, String appName) {
        this.version = version;
        this.appName = appName;
    }
    
    public String getVersion() { return version; }
    public void setVersion(String version) { this.version = version; }
    public String getAppName() { return appName; }
    public void setAppName(String appName) { this.appName = appName; }
}

// Custom Health Indicator for Spring Boot Actuator
@Component
class CustomHealthIndicator implements HealthIndicator {
    @Override
    public Health health() {
        // Add custom health check logic here
        return Health.up()
                .withDetail("app", "Demo Application")
                .withDetail("status", "running")
                .build();
    }
}
