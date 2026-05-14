package com.example.expensetracker.domain;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity
@Table(name = "budgets", schema = "expense_tracker",
       uniqueConstraints = @UniqueConstraint(name = "uq_budget_user_category_month_year",
               columnNames = {"user_id","category_id","budget_month","budget_year"}))
public class Budget {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private AppUser user;

    // FIX: EAGER fetch so category.getName() works without an open session
    @ManyToOne(fetch = FetchType.EAGER, optional = false)
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;

    @Column(name = "budget_month", nullable = false) private Integer budgetMonth;
    @Column(name = "budget_year", nullable = false) private Integer budgetYear;
    @Column(name = "limit_amount", nullable = false, precision = 12, scale = 2) private BigDecimal limitAmount;

    @Column(name = "created_at", nullable = false) private LocalDateTime createdAt;
    @Column(name = "updated_at", nullable = false) private LocalDateTime updatedAt;

    @PrePersist void onCreate() { var n = LocalDateTime.now(); if (createdAt==null) createdAt=n; if (updatedAt==null) updatedAt=n; }
    @PreUpdate void onUpdate() { updatedAt = LocalDateTime.now(); }
}
