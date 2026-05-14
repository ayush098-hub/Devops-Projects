package com.example.expensetracker.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public class AuthDtos {
    public record RegisterRequest(@NotBlank String fullName, @Email @NotBlank String email,
                                  @NotBlank @Size(min=6, max=100) String password, String currencyCode) {}
    public record LoginRequest(@Email @NotBlank String email, @NotBlank String password) {}
    public record AuthResponse(UUID id, String fullName, String email, String token) {}
}
