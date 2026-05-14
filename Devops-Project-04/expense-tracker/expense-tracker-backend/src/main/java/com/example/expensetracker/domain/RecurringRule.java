package com.example.expensetracker.domain;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity
@Table(name = "recurring_rules", schema = "expense_tracker")
public class RecurringRule {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private AppUser user;

    // FIX: EAGER fetch so category.getName() works without an open session
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "category_id")
    private Category category;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20, columnDefinition = "expense_tracker.transaction_type")
    private TransactionType type;

    @Column(nullable = false, precision = 12, scale = 2) private BigDecimal amount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20, columnDefinition = "expense_tracker.frequency_type")
    private FrequencyType frequency;

    @Column(name = "start_date", nullable = false) private LocalDate startDate;
    @Column(name = "end_date") private LocalDate endDate;
    @Column(name = "next_run_date") private LocalDate nextRunDate;
    @Column(nullable = false) private boolean active = true;
    @Column(columnDefinition = "text") private String description;

    @Column(name = "created_at", nullable = false) private LocalDateTime createdAt;
    @Column(name = "updated_at", nullable = false) private LocalDateTime updatedAt;

    @PrePersist void onCreate() { var n = LocalDateTime.now(); if (createdAt==null) createdAt=n; if (updatedAt==null) updatedAt=n; }
    @PreUpdate void onUpdate() { updatedAt = LocalDateTime.now(); }
}
