package com.example.expensetracker.domain;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity
@Table(name = "categories", schema = "expense_tracker",
       uniqueConstraints = @UniqueConstraint(name = "uq_categories_user_name", columnNames = {"user_id","name"}))
public class Category {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private AppUser user;

    @Column(nullable = false, length = 100)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20, columnDefinition = "expense_tracker.category_type")
    private CategoryType type = CategoryType.EXPENSE;

    @Column(length = 100) private String icon;
    @Column(length = 20) private String color;

    @Column(name = "is_default", nullable = false)
    private boolean defaultCategory = false;

    @Column(name = "created_at", nullable = false) private LocalDateTime createdAt;
    @Column(name = "updated_at", nullable = false) private LocalDateTime updatedAt;

    @PrePersist void onCreate() { var n = LocalDateTime.now(); if (createdAt==null) createdAt=n; if (updatedAt==null) updatedAt=n; }
    @PreUpdate void onUpdate() { updatedAt = LocalDateTime.now(); }
}
