package com.example.expensetracker.repository;

import com.example.expensetracker.domain.RecurringRule;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface RecurringRuleRepository extends JpaRepository<RecurringRule, UUID> {
    List<RecurringRule> findByUser_IdOrderByCreatedAtDesc(UUID userId);
}
