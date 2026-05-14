package com.example.expensetracker.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.UUID;

public class TagDtos {
    public record TagRequest(@NotBlank String name) {}
    public record TagResponse(UUID id, String name) {}
}
