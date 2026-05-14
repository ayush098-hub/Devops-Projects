package com.example.expensetracker.controller;

import com.example.expensetracker.domain.AppUser;
import com.example.expensetracker.dto.DashboardDtos;
import com.example.expensetracker.dto.TransactionDtos;
import com.example.expensetracker.service.TransactionService;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.Map;

@RestController @RequestMapping("/api/transactions")
public class TransactionController {
    private final TransactionService transactionService;
    public TransactionController(TransactionService transactionService) { this.transactionService = transactionService; }

    @GetMapping  public Map<String, Object> list(@AuthenticationPrincipal AppUser user) { return Map.of("success", true, "data", transactionService.list(user.getId())); }
    @PostMapping public Map<String, Object> create(@AuthenticationPrincipal AppUser user, @Valid @RequestBody TransactionDtos.TransactionRequest req) { return Map.of("success", true, "data", transactionService.create(user.getId(), req)); }

    @GetMapping("/dashboard")
    public Map<String, Object> dashboard(@AuthenticationPrincipal AppUser user,
                                         @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
                                         @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        DashboardDtos.DashboardSummaryResponse response = transactionService.dashboard(user.getId(), from, to);
        return Map.of("success", true, "data", response);
    }
}
