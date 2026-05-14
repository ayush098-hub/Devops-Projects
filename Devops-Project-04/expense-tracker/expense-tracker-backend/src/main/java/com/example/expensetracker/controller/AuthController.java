package com.example.expensetracker.controller;

import com.example.expensetracker.dto.AuthDtos;
import com.example.expensetracker.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController @RequestMapping("/api/auth")
public class AuthController {
    private final AuthService authService;
    public AuthController(AuthService authService) { this.authService = authService; }

    @PostMapping("/register")
    public Map<String, Object> register(@Valid @RequestBody AuthDtos.RegisterRequest request) {
        return Map.of("success", true, "data", authService.register(request));
    }

    @PostMapping("/login")
    public Map<String, Object> login(@Valid @RequestBody AuthDtos.LoginRequest request) {
        return Map.of("success", true, "data", authService.login(request));
    }
}
