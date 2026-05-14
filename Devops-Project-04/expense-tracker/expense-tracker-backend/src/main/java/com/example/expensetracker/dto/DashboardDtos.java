package com.example.expensetracker.dto;

import java.math.BigDecimal;
import java.util.Map;
import java.util.UUID;

public class DashboardDtos {
    public record DashboardSummaryResponse(BigDecimal totalIncome, BigDecimal totalExpense,
                                           BigDecimal balance, Map<UUID, BigDecimal> expenseByCategory) {}
}
