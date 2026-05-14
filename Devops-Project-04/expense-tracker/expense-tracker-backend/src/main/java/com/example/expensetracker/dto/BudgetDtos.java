package com.example.expensetracker.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.util.UUID;

public class BudgetDtos {
    public record BudgetRequest(@NotNull UUID categoryId,
                                @NotNull @Min(1) Integer budgetMonth,
                                @NotNull @Min(2000) Integer budgetYear,
                                @NotNull BigDecimal limitAmount) {}
    public record BudgetResponse(UUID id, UUID categoryId, String categoryName,
                                 Integer budgetMonth, Integer budgetYear, BigDecimal limitAmount) {}
}
