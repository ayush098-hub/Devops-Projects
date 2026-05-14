package com.example.expensetracker.dto;

import com.example.expensetracker.domain.PaymentModeType;
import com.example.expensetracker.domain.TransactionType;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import java.util.UUID;

public class TransactionDtos {
    public record TransactionRequest(UUID categoryId, @NotNull TransactionType type,
                                     @NotNull BigDecimal amount, String description,
                                     @NotNull LocalDate transactionDate, PaymentModeType paymentMode,
                                     String referenceNumber, Boolean isRecurring, Set<UUID> tagIds) {}
    public record TransactionResponse(UUID id, UUID categoryId, String categoryName,
                                      TransactionType type, BigDecimal amount, String description,
                                      LocalDate transactionDate, PaymentModeType paymentMode,
                                      String referenceNumber, boolean recurring, List<String> tags) {}
}
