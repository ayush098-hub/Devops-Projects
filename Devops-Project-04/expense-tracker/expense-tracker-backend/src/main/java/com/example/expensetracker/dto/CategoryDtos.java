package com.example.expensetracker.dto;

import com.example.expensetracker.domain.CategoryType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public class CategoryDtos {
    public record CategoryRequest(@NotBlank String name, @NotNull CategoryType type,
                                  String icon, String color, Boolean isDefault) {}
    public record CategoryResponse(UUID id, String name, CategoryType type,
                                   String icon, String color, boolean isDefault) {}
}
