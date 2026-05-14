package com.example.expensetracker.security;

import com.example.expensetracker.domain.AppUser;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.Map;
import java.util.function.Function;

@Service
public class JwtService {
    @Value("${app.jwt.secret}") private String secret;
    @Value("${app.jwt.expiration-ms}") private long expirationMs;

    private SecretKey key() { return Keys.hmacShaKeyFor(Decoders.BASE64.decode(secret)); }

    public String generateToken(AppUser user) {
        return Jwts.builder()
                .claims(Map.of("uid", user.getId().toString(), "name", user.getFullName()))
                .subject(user.getEmail())
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + expirationMs))
                .signWith(key()).compact();
    }

    public String extractUsername(String token) { return extractClaim(token, Claims::getSubject); }

    public boolean isTokenValid(String token, AppUser user) {
        return extractUsername(token).equals(user.getEmail()) && !isTokenExpired(token);
    }

    public boolean isTokenExpired(String token) {
        return extractClaim(token, Claims::getExpiration).before(new Date());
    }

    private <T> T extractClaim(String token, Function<Claims, T> fn) {
        return fn.apply(Jwts.parser().verifyWith(key()).build().parseSignedClaims(token).getPayload());
    }
}
