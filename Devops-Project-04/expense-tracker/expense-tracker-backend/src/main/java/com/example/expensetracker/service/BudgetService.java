package com.example.expensetracker.service;

import com.example.expensetracker.domain.AppUser;
import com.example.expensetracker.domain.Budget;
import com.example.expensetracker.domain.Category;
import com.example.expensetracker.dto.BudgetDtos;
import com.example.expensetracker.exception.ApiException;
import com.example.expensetracker.repository.AppUserRepository;
import com.example.expensetracker.repository.BudgetRepository;
import com.example.expensetracker.repository.CategoryRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;

@Service
public class BudgetService {
    private final BudgetRepository budgetRepository;
    private final CategoryRepository categoryRepository;
    private final AppUserRepository userRepository;

    public BudgetService(BudgetRepository budgetRepository, CategoryRepository categoryRepository,
                         AppUserRepository userRepository) {
        this.budgetRepository = budgetRepository;
        this.categoryRepository = categoryRepository;
        this.userRepository = userRepository;
    }

    // FIX: @Transactional(readOnly=true) keeps the Hibernate session open while we map
    //      category.getId() / category.getName() from the EAGER-loaded Category.
    @Transactional(readOnly = true)
    public List<BudgetDtos.BudgetResponse> list(UUID userId, Integer month, Integer year) {
        return budgetRepository.findByUser_IdAndBudgetMonthAndBudgetYear(userId, month, year)
                .stream().map(this::toResponse).toList();
    }

    @Transactional
    public BudgetDtos.BudgetResponse create(UUID userId, BudgetDtos.BudgetRequest request) {
        AppUser user = userRepository.findById(userId).orElseThrow(() -> new ApiException("User not found"));
        Category category = categoryRepository.findById(request.categoryId()).orElseThrow(() -> new ApiException("Category not found"));
        if (!category.getUser().getId().equals(userId)) throw new ApiException("Category does not belong to this user");
        if (budgetRepository.existsByUser_IdAndCategory_IdAndBudgetMonthAndBudgetYear(userId, request.categoryId(), request.budgetMonth(), request.budgetYear()))
            throw new ApiException("Budget already exists for this category and month");
        Budget budget = Budget.builder().user(user).category(category)
                .budgetMonth(request.budgetMonth()).budgetYear(request.budgetYear()).limitAmount(request.limitAmount()).build();
        return toResponse(budgetRepository.save(budget));
    }

    private BudgetDtos.BudgetResponse toResponse(Budget b) {
        return new BudgetDtos.BudgetResponse(b.getId(), b.getCategory().getId(), b.getCategory().getName(),
                b.getBudgetMonth(), b.getBudgetYear(), b.getLimitAmount());
    }
}
