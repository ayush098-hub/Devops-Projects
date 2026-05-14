package com.example.expensetracker.service;

import com.example.expensetracker.domain.AppUser;
import com.example.expensetracker.dto.AuthDtos;
import com.example.expensetracker.exception.ApiException;
import com.example.expensetracker.repository.AppUserRepository;
import com.example.expensetracker.security.JwtService;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {
    private final AppUserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;

    public AuthService(AppUserRepository userRepository, PasswordEncoder passwordEncoder,
                       AuthenticationManager authenticationManager, JwtService jwtService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.authenticationManager = authenticationManager;
        this.jwtService = jwtService;
    }

    public AuthDtos.AuthResponse register(AuthDtos.RegisterRequest request) {
        if (userRepository.existsByEmail(request.email())) throw new ApiException("Email already registered");
        AppUser user = AppUser.builder()
                .fullName(request.fullName())
                .email(request.email().toLowerCase())
                .passwordHash(passwordEncoder.encode(request.password()))
                .currencyCode(request.currencyCode() == null || request.currencyCode().isBlank() ? "INR" : request.currencyCode())
                .build();
        user = userRepository.save(user);
        return new AuthDtos.AuthResponse(user.getId(), user.getFullName(), user.getEmail(), jwtService.generateToken(user));
    }

    public AuthDtos.AuthResponse login(AuthDtos.LoginRequest request) {
        authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(request.email().toLowerCase(), request.password()));
        AppUser user = userRepository.findByEmail(request.email().toLowerCase()).orElseThrow(() -> new ApiException("User not found"));
        return new AuthDtos.AuthResponse(user.getId(), user.getFullName(), user.getEmail(), jwtService.generateToken(user));
    }
}
