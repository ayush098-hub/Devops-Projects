package com.example.expensetracker.controller;

import com.example.expensetracker.domain.AppUser;
import com.example.expensetracker.dto.BudgetDtos;
import com.example.expensetracker.service.BudgetService;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController @RequestMapping("/api/budgets")
public class BudgetController {
    private final BudgetService budgetService;
    public BudgetController(BudgetService budgetService) { this.budgetService = budgetService; }

    @GetMapping  public Map<String, Object> list(@AuthenticationPrincipal AppUser user, @RequestParam Integer month, @RequestParam Integer year) { return Map.of("success", true, "data", budgetService.list(user.getId(), month, year)); }
    @PostMapping public Map<String, Object> create(@AuthenticationPrincipal AppUser user, @Valid @RequestBody BudgetDtos.BudgetRequest req) { return Map.of("success", true, "data", budgetService.create(user.getId(), req)); }
}
