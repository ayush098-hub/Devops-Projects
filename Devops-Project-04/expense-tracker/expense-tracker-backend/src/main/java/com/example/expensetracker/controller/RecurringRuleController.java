package com.example.expensetracker.controller;

import com.example.expensetracker.domain.AppUser;
import com.example.expensetracker.dto.RecurringRuleDtos;
import com.example.expensetracker.service.RecurringRuleService;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController @RequestMapping("/api/recurring-rules")
public class RecurringRuleController {
    private final RecurringRuleService recurringRuleService;
    public RecurringRuleController(RecurringRuleService recurringRuleService) { this.recurringRuleService = recurringRuleService; }

    @GetMapping  public Map<String, Object> list(@AuthenticationPrincipal AppUser user) { return Map.of("success", true, "data", recurringRuleService.list(user.getId())); }
    @PostMapping public Map<String, Object> create(@AuthenticationPrincipal AppUser user, @Valid @RequestBody RecurringRuleDtos.RecurringRuleRequest req) { return Map.of("success", true, "data", recurringRuleService.create(user.getId(), req)); }
}
