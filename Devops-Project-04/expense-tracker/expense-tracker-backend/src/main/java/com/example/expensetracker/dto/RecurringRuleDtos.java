package com.example.expensetracker.dto;

import com.example.expensetracker.domain.FrequencyType;
import com.example.expensetracker.domain.TransactionType;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

public class RecurringRuleDtos {
    public record RecurringRuleRequest(UUID categoryId, @NotNull TransactionType type,
                                       @NotNull BigDecimal amount, @NotNull FrequencyType frequency,
                                       @NotNull LocalDate startDate, LocalDate endDate,
                                       LocalDate nextRunDate, Boolean active, String description) {}
    public record RecurringRuleResponse(UUID id, UUID categoryId, String categoryName,
                                        TransactionType type, BigDecimal amount, FrequencyType frequency,
                                        LocalDate startDate, LocalDate endDate, LocalDate nextRunDate,
                                        boolean active, String description, LocalDateTime createdAt) {}
}
