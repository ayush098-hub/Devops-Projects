package com.example.expensetracker.repository;

import com.example.expensetracker.domain.Budget;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface BudgetRepository extends JpaRepository<Budget, UUID> {
    List<Budget> findByUser_IdAndBudgetMonthAndBudgetYear(UUID userId, Integer month, Integer year);
    boolean existsByUser_IdAndCategory_IdAndBudgetMonthAndBudgetYear(UUID userId, UUID categoryId, Integer month, Integer year);
}
