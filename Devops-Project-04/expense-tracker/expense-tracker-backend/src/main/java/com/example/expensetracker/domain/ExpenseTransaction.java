package com.example.expensetracker.domain;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity
@Table(name = "transactions", schema = "expense_tracker")
public class ExpenseTransaction {
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
    @Column(columnDefinition = "text") private String description;
    @Column(name = "transaction_date", nullable = false) private LocalDate transactionDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_mode", nullable = false, length = 20, columnDefinition = "expense_tracker.payment_mode_type")
    private PaymentModeType paymentMode = PaymentModeType.OTHER;

    @Column(name = "reference_number", length = 100) private String referenceNumber;
    @Column(name = "is_recurring", nullable = false) private boolean recurring = false;

    @ManyToMany
    @JoinTable(name = "transaction_tags", schema = "expense_tracker",
               joinColumns = @JoinColumn(name = "transaction_id"),
               inverseJoinColumns = @JoinColumn(name = "tag_id"))
    @Builder.Default
    private Set<Tag> tags = new HashSet<>();

    @Column(name = "created_at", nullable = false) private LocalDateTime createdAt;
    @Column(name = "updated_at", nullable = false) private LocalDateTime updatedAt;

    @PrePersist void onCreate() { var n = LocalDateTime.now(); if (createdAt==null) createdAt=n; if (updatedAt==null) updatedAt=n; }
    @PreUpdate void onUpdate() { updatedAt = LocalDateTime.now(); }
}
