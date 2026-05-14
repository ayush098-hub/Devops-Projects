package com.example.expensetracker.service;

import com.example.expensetracker.domain.Category;
import com.example.expensetracker.domain.RecurringRule;
import com.example.expensetracker.dto.RecurringRuleDtos;
import com.example.expensetracker.exception.ApiException;
import com.example.expensetracker.repository.AppUserRepository;
import com.example.expensetracker.repository.CategoryRepository;
import com.example.expensetracker.repository.RecurringRuleRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;

@Service
public class RecurringRuleService {
    private final RecurringRuleRepository recurringRuleRepository;
    private final CategoryRepository categoryRepository;
    private final AppUserRepository userRepository;

    public RecurringRuleService(RecurringRuleRepository recurringRuleRepository,
                                CategoryRepository categoryRepository,
                                AppUserRepository userRepository) {
        this.recurringRuleRepository = recurringRuleRepository;
        this.categoryRepository = categoryRepository;
        this.userRepository = userRepository;
    }

    // FIX: @Transactional(readOnly=true) keeps the Hibernate session open
    @Transactional(readOnly = true)
    public List<RecurringRuleDtos.RecurringRuleResponse> list(UUID userId) {
        return recurringRuleRepository.findByUser_IdOrderByCreatedAtDesc(userId).stream().map(this::toResponse).toList();
    }

    @Transactional
    public RecurringRuleDtos.RecurringRuleResponse create(UUID userId, RecurringRuleDtos.RecurringRuleRequest request) {
        var user = userRepository.findById(userId).orElseThrow(() -> new ApiException("User not found"));
        Category category = null;
        if (request.categoryId() != null) {
            category = categoryRepository.findById(request.categoryId()).orElseThrow(() -> new ApiException("Category not found"));
            if (!category.getUser().getId().equals(userId)) throw new ApiException("Category does not belong to this user");
        }
        RecurringRule rule = RecurringRule.builder().user(user).category(category)
                .type(request.type()).amount(request.amount()).frequency(request.frequency())
                .startDate(request.startDate()).endDate(request.endDate()).nextRunDate(request.nextRunDate())
                .active(request.active() == null || request.active()).description(request.description()).build();
        return toResponse(recurringRuleRepository.save(rule));
    }

    private RecurringRuleDtos.RecurringRuleResponse toResponse(RecurringRule r) {
        return new RecurringRuleDtos.RecurringRuleResponse(r.getId(),
                r.getCategory() == null ? null : r.getCategory().getId(),
                r.getCategory() == null ? null : r.getCategory().getName(),
                r.getType(), r.getAmount(), r.getFrequency(),
                r.getStartDate(), r.getEndDate(), r.getNextRunDate(),
                r.isActive(), r.getDescription(), r.getCreatedAt());
    }
}
