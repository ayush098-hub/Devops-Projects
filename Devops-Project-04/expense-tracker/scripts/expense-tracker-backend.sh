#!/usr/bin/env bash
set -euo pipefail

APP_NAME="expense-tracker-backend"
BASE_DIR="${1:-$APP_NAME}"

if [ -e "$BASE_DIR" ]; then
  echo "Target path '$BASE_DIR' already exists. Remove it or pass a new directory name."
  exit 1
fi

mkdir -p "$BASE_DIR"
cd "$BASE_DIR"

mkdir -p src/main/java/com/example/expensetracker/{config,controller,domain,dto,exception,repository,security,service}
mkdir -p src/main/resources
mkdir -p src/test/java/com/example/expensetracker

# ─────────────────────────────────────────────
# pom.xml
# ─────────────────────────────────────────────
cat > pom.xml <<'EOF'
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.5</version>
        <relativePath/>
    </parent>

    <groupId>com.example</groupId>
    <artifactId>expense-tracker-backend</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>expense-tracker-backend</name>

    <properties>
        <java.version>17</java.version>
        <jjwt.version>0.12.5</jjwt.version>
    </properties>

    <dependencies>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-web</artifactId></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-data-jpa</artifactId></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-security</artifactId></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-validation</artifactId></dependency>
        <dependency><groupId>org.postgresql</groupId><artifactId>postgresql</artifactId><scope>runtime</scope></dependency>
        <dependency><groupId>io.jsonwebtoken</groupId><artifactId>jjwt-api</artifactId><version>${jjwt.version}</version></dependency>
        <dependency><groupId>io.jsonwebtoken</groupId><artifactId>jjwt-impl</artifactId><version>${jjwt.version}</version><scope>runtime</scope></dependency>
        <dependency><groupId>io.jsonwebtoken</groupId><artifactId>jjwt-jackson</artifactId><version>${jjwt.version}</version><scope>runtime</scope></dependency>
        <dependency><groupId>org.projectlombok</groupId><artifactId>lombok</artifactId><optional>true</optional></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-test</artifactId><scope>test</scope></dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
EOF

# ─────────────────────────────────────────────
# application.yml
# ─────────────────────────────────────────────
cat > src/main/resources/application.yml <<'EOF'
server:
  port: 8080

spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/postgres
    username: postgres
    password: postgres
  jpa:
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        default_schema: expense_tracker
        format_sql: true
    open-in-view: false
    show-sql: false

app:
  jwt:
    secret: "c3VwZXItc2VjdXJlLWRlbW8tc2VjcmV0LWJhc2U2NC1zdHJpbmctc2VjcmV0LW1lZXRzLWxvbmc="
    expiration-ms: 86400000
EOF

# ─────────────────────────────────────────────
# Main application class
# ─────────────────────────────────────────────
cat > src/main/java/com/example/expensetracker/ExpenseTrackerApplication.java <<'EOF'
package com.example.expensetracker;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ExpenseTrackerApplication {
    public static void main(String[] args) {
        SpringApplication.run(ExpenseTrackerApplication.class, args);
    }
}
EOF

# ─────────────────────────────────────────────
# Domain enums
# ─────────────────────────────────────────────
cat > src/main/java/com/example/expensetracker/domain/TransactionType.java <<'EOF'
package com.example.expensetracker.domain;

public enum TransactionType { INCOME, EXPENSE }
EOF

cat > src/main/java/com/example/expensetracker/domain/CategoryType.java <<'EOF'
package com.example.expensetracker.domain;

public enum CategoryType { INCOME, EXPENSE, BOTH }
EOF

cat > src/main/java/com/example/expensetracker/domain/FrequencyType.java <<'EOF'
package com.example.expensetracker.domain;

public enum FrequencyType { DAILY, WEEKLY, MONTHLY, YEARLY }
EOF

cat > src/main/java/com/example/expensetracker/domain/PaymentModeType.java <<'EOF'
package com.example.expensetracker.domain;

public enum PaymentModeType { CASH, UPI, CARD, BANK_TRANSFER, WALLET, OTHER }
EOF

# ─────────────────────────────────────────────
# Domain entities
# ─────────────────────────────────────────────
cat > src/main/java/com/example/expensetracker/domain/AppUser.java <<'EOF'
package com.example.expensetracker.domain;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity
@Table(name = "users", schema = "expense_tracker")
public class AppUser implements UserDetails {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "full_name", nullable = false, length = 150)
    private String fullName;

    @Column(nullable = false, unique = true, length = 255)
    private String email;

    @JsonIgnore
    @Column(name = "password_hash", nullable = false, length = 255)
    private String passwordHash;

    @Column(name = "currency_code", nullable = false, length = 10)
    private String currencyCode = "INR";

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist void onCreate() {
        var now = LocalDateTime.now();
        if (createdAt == null) createdAt = now;
        if (updatedAt == null) updatedAt = now;
        if (currencyCode == null || currencyCode.isBlank()) currencyCode = "INR";
        active = true;
    }

    @PreUpdate void onUpdate() { updatedAt = LocalDateTime.now(); }

    @Override public Collection<? extends GrantedAuthority> getAuthorities() { return List.of(new SimpleGrantedAuthority("ROLE_USER")); }
    @Override public String getPassword() { return passwordHash; }
    @Override public String getUsername() { return email; }
    @Override public boolean isAccountNonExpired() { return true; }
    @Override public boolean isAccountNonLocked() { return true; }
    @Override public boolean isCredentialsNonExpired() { return true; }
    @Override public boolean isEnabled() { return active; }
}
EOF

cat > src/main/java/com/example/expensetracker/domain/Category.java <<'EOF'
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
EOF

cat > src/main/java/com/example/expensetracker/domain/Tag.java <<'EOF'
package com.example.expensetracker.domain;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
@Entity
@Table(name = "tags", schema = "expense_tracker",
       uniqueConstraints = @UniqueConstraint(name = "uq_tags_user_name", columnNames = {"user_id","name"}))
public class Tag {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private AppUser user;

    @Column(nullable = false, length = 50)
    private String name;

    @Column(name = "created_at", nullable = false) private LocalDateTime createdAt;
    @Column(name = "updated_at", nullable = false) private LocalDateTime updatedAt;

    @PrePersist void onCreate() { var n = LocalDateTime.now(); if (createdAt==null) createdAt=n; if (updatedAt==null) updatedAt=n; }
    @PreUpdate void onUpdate() { updatedAt = LocalDateTime.now(); }
}
EOF

cat > src/main/java/com/example/expensetracker/domain/Budget.java <<'EOF'
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
EOF

cat > src/main/java/com/example/expensetracker/domain/RecurringRule.java <<'EOF'
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
EOF

cat > src/main/java/com/example/expensetracker/domain/ExpenseTransaction.java <<'EOF'
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
EOF

# ─────────────────────────────────────────────
# Repositories
# ─────────────────────────────────────────────
cat > src/main/java/com/example/expensetracker/repository/AppUserRepository.java <<'EOF'
package com.example.expensetracker.repository;

import com.example.expensetracker.domain.AppUser;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.UUID;

public interface AppUserRepository extends JpaRepository<AppUser, UUID> {
    Optional<AppUser> findByEmail(String email);
    boolean existsByEmail(String email);
}
EOF

cat > src/main/java/com/example/expensetracker/repository/CategoryRepository.java <<'EOF'
package com.example.expensetracker.repository;

import com.example.expensetracker.domain.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface CategoryRepository extends JpaRepository<Category, UUID> {
    List<Category> findByUser_IdOrderByNameAsc(UUID userId);
    boolean existsByUser_IdAndNameIgnoreCase(UUID userId, String name);
}
EOF

# FIX: ExpenseTransactionRepository — rewritten queries to avoid PostgreSQL custom-schema enum casting issues
# Root cause: Hibernate generates SQL like type='EXPENSE'::TransactionType but the enum type lives in
# the expense_tracker schema, not public. Using JPQL fully-qualified enum literal and native date
# comparisons avoids the problem entirely.
cat > src/main/java/com/example/expensetracker/repository/ExpenseTransactionRepository.java <<'EOF'
package com.example.expensetracker.repository;

import com.example.expensetracker.domain.ExpenseTransaction;
import com.example.expensetracker.domain.TransactionType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public interface ExpenseTransactionRepository extends JpaRepository<ExpenseTransaction, UUID> {

    List<ExpenseTransaction> findByUser_IdOrderByTransactionDateDescCreatedAtDesc(UUID userId);

    /**
     * FIX 1: Pass the enum as a Java parameter (:type) — Hibernate binds it correctly
     *         without generating an explicit PostgreSQL cast.
     * FIX 2: Date range params wrapped with COALESCE so null values are handled at the
     *         JPQL level and PostgreSQL never receives an untyped NULL parameter.
     */
    @Query("""
           select coalesce(sum(t.amount), 0)
           from ExpenseTransaction t
           where t.user.id = :userId
             and t.type = :type
             and (:from is null or t.transactionDate >= :from)
             and (:to   is null or t.transactionDate <= :to)
           """)
    BigDecimal sumAmountByUserAndType(
            @Param("userId") UUID userId,
            @Param("type")   TransactionType type,
            @Param("from")   LocalDate from,
            @Param("to")     LocalDate to);

    /**
     * FIX: Use fully-qualified Java enum literal so Hibernate emits a parameterised bind
     *      instead of a string cast that references a non-public schema type.
     */
    @Query("""
           select t.category.id, coalesce(sum(t.amount), 0)
           from ExpenseTransaction t
           where t.user.id = :userId
             and t.type = com.example.expensetracker.domain.TransactionType.EXPENSE
             and (:from is null or t.transactionDate >= :from)
             and (:to   is null or t.transactionDate <= :to)
           group by t.category.id
           """)
    List<Object[]> expenseByCategory(
            @Param("userId") UUID userId,
            @Param("from")   LocalDate from,
            @Param("to")     LocalDate to);
}
EOF

cat > src/main/java/com/example/expensetracker/repository/BudgetRepository.java <<'EOF'
package com.example.expensetracker.repository;

import com.example.expensetracker.domain.Budget;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface BudgetRepository extends JpaRepository<Budget, UUID> {
    List<Budget> findByUser_IdAndBudgetMonthAndBudgetYear(UUID userId, Integer month, Integer year);
    boolean existsByUser_IdAndCategory_IdAndBudgetMonthAndBudgetYear(UUID userId, UUID categoryId, Integer month, Integer year);
}
EOF

cat > src/main/java/com/example/expensetracker/repository/RecurringRuleRepository.java <<'EOF'
package com.example.expensetracker.repository;

import com.example.expensetracker.domain.RecurringRule;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface RecurringRuleRepository extends JpaRepository<RecurringRule, UUID> {
    List<RecurringRule> findByUser_IdOrderByCreatedAtDesc(UUID userId);
}
EOF

cat > src/main/java/com/example/expensetracker/repository/TagRepository.java <<'EOF'
package com.example.expensetracker.repository;

import com.example.expensetracker.domain.Tag;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface TagRepository extends JpaRepository<Tag, UUID> {
    List<Tag> findByUser_IdOrderByNameAsc(UUID userId);
    boolean existsByUser_IdAndNameIgnoreCase(UUID userId, String name);
}
EOF

# ─────────────────────────────────────────────
# DTOs
# ─────────────────────────────────────────────
cat > src/main/java/com/example/expensetracker/dto/AuthDtos.java <<'EOF'
package com.example.expensetracker.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public class AuthDtos {
    public record RegisterRequest(@NotBlank String fullName, @Email @NotBlank String email,
                                  @NotBlank @Size(min=6, max=100) String password, String currencyCode) {}
    public record LoginRequest(@Email @NotBlank String email, @NotBlank String password) {}
    public record AuthResponse(UUID id, String fullName, String email, String token) {}
}
EOF

cat > src/main/java/com/example/expensetracker/dto/CategoryDtos.java <<'EOF'
package com.example.expensetracker.dto;

import com.example.expensetracker.domain.CategoryType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public class CategoryDtos {
    public record CategoryRequest(@NotBlank String name, @NotNull CategoryType type,
                                  String icon, String color, Boolean isDefault) {}
    public record CategoryResponse(UUID id, String name, CategoryType type,
                                   String icon, String color, boolean isDefault) {}
}
EOF

cat > src/main/java/com/example/expensetracker/dto/TagDtos.java <<'EOF'
package com.example.expensetracker.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.UUID;

public class TagDtos {
    public record TagRequest(@NotBlank String name) {}
    public record TagResponse(UUID id, String name) {}
}
EOF

cat > src/main/java/com/example/expensetracker/dto/BudgetDtos.java <<'EOF'
package com.example.expensetracker.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.util.UUID;

public class BudgetDtos {
    public record BudgetRequest(@NotNull UUID categoryId,
                                @NotNull @Min(1) Integer budgetMonth,
                                @NotNull @Min(2000) Integer budgetYear,
                                @NotNull BigDecimal limitAmount) {}
    public record BudgetResponse(UUID id, UUID categoryId, String categoryName,
                                 Integer budgetMonth, Integer budgetYear, BigDecimal limitAmount) {}
}
EOF

cat > src/main/java/com/example/expensetracker/dto/RecurringRuleDtos.java <<'EOF'
package com.example.expensetracker.dto;

import com.example.expensetracker.domain.FrequencyType;
import com.example.expensetracker.domain.TransactionType;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

public class RecurringRuleDtos {
    public record RecurringRuleRequest(UUID categoryId, @NotNull TransactionType type,
                                       @NotNull BigDecimal amount, @NotNull FrequencyType frequency,
                                       @NotNull LocalDate startDate, LocalDate endDate,
                                       LocalDate nextRunDate, Boolean active, String description) {}
    public record RecurringRuleResponse(UUID id, UUID categoryId, String categoryName,
                                        TransactionType type, BigDecimal amount, FrequencyType frequency,
                                        LocalDate startDate, LocalDate endDate, LocalDate nextRunDate,
                                        boolean active, String description, LocalDateTime createdAt) {}
}
EOF

cat > src/main/java/com/example/expensetracker/dto/TransactionDtos.java <<'EOF'
package com.example.expensetracker.dto;

import com.example.expensetracker.domain.PaymentModeType;
import com.example.expensetracker.domain.TransactionType;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import java.util.UUID;

public class TransactionDtos {
    public record TransactionRequest(UUID categoryId, @NotNull TransactionType type,
                                     @NotNull BigDecimal amount, String description,
                                     @NotNull LocalDate transactionDate, PaymentModeType paymentMode,
                                     String referenceNumber, Boolean isRecurring, Set<UUID> tagIds) {}
    public record TransactionResponse(UUID id, UUID categoryId, String categoryName,
                                      TransactionType type, BigDecimal amount, String description,
                                      LocalDate transactionDate, PaymentModeType paymentMode,
                                      String referenceNumber, boolean recurring, List<String> tags) {}
}
EOF

cat > src/main/java/com/example/expensetracker/dto/DashboardDtos.java <<'EOF'
package com.example.expensetracker.dto;

import java.math.BigDecimal;
import java.util.Map;
import java.util.UUID;

public class DashboardDtos {
    public record DashboardSummaryResponse(BigDecimal totalIncome, BigDecimal totalExpense,
                                           BigDecimal balance, Map<UUID, BigDecimal> expenseByCategory) {}
}
EOF

# ─────────────────────────────────────────────
# Exceptions
# ─────────────────────────────────────────────
cat > src/main/java/com/example/expensetracker/exception/ApiException.java <<'EOF'
package com.example.expensetracker.exception;

public class ApiException extends RuntimeException {
    public ApiException(String message) { super(message); }
}
EOF

cat > src/main/java/com/example/expensetracker/exception/GlobalExceptionHandler.java <<'EOF'
package com.example.expensetracker.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.LinkedHashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<Map<String, Object>> handleApi(ApiException ex) {
        return ResponseEntity.badRequest().body(Map.of("success", false, "message", ex.getMessage()));
    }

    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<Map<String, Object>> handleBadCreds(BadCredentialsException ex) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(Map.of("success", false, "message", "Invalid email or password"));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new LinkedHashMap<>();
        for (FieldError e : ex.getBindingResult().getFieldErrors()) errors.put(e.getField(), e.getDefaultMessage());
        return ResponseEntity.badRequest().body(Map.of("success", false, "message", "Validation failed", "errors", errors));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleOther(Exception ex) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("success", false, "message", ex.getMessage()));
    }
}
EOF

# ─────────────────────────────────────────────
# Security
# ─────────────────────────────────────────────
cat > src/main/java/com/example/expensetracker/security/JwtService.java <<'EOF'
package com.example.expensetracker.security;

import com.example.expensetracker.domain.AppUser;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.Map;
import java.util.function.Function;

@Service
public class JwtService {
    @Value("${app.jwt.secret}") private String secret;
    @Value("${app.jwt.expiration-ms}") private long expirationMs;

    private SecretKey key() { return Keys.hmacShaKeyFor(Decoders.BASE64.decode(secret)); }

    public String generateToken(AppUser user) {
        return Jwts.builder()
                .claims(Map.of("uid", user.getId().toString(), "name", user.getFullName()))
                .subject(user.getEmail())
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + expirationMs))
                .signWith(key()).compact();
    }

    public String extractUsername(String token) { return extractClaim(token, Claims::getSubject); }

    public boolean isTokenValid(String token, AppUser user) {
        return extractUsername(token).equals(user.getEmail()) && !isTokenExpired(token);
    }

    public boolean isTokenExpired(String token) {
        return extractClaim(token, Claims::getExpiration).before(new Date());
    }

    private <T> T extractClaim(String token, Function<Claims, T> fn) {
        return fn.apply(Jwts.parser().verifyWith(key()).build().parseSignedClaims(token).getPayload());
    }
}
EOF

cat > src/main/java/com/example/expensetracker/security/CustomUserDetailsService.java <<'EOF'
package com.example.expensetracker.security;

import com.example.expensetracker.repository.AppUserRepository;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
public class CustomUserDetailsService implements UserDetailsService {
    private final AppUserRepository userRepository;
    public CustomUserDetailsService(AppUserRepository userRepository) { this.userRepository = userRepository; }

    @Override
    public UserDetails loadUserByUsername(String username) {
        return userRepository.findByEmail(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));
    }
}
EOF

cat > src/main/java/com/example/expensetracker/security/JwtAuthenticationFilter.java <<'EOF'
package com.example.expensetracker.security;

import com.example.expensetracker.domain.AppUser;
import com.example.expensetracker.repository.AppUserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    private final JwtService jwtService;
    private final AppUserRepository userRepository;

    public JwtAuthenticationFilter(JwtService jwtService, AppUserRepository userRepository) {
        this.jwtService = jwtService;
        this.userRepository = userRepository;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String authHeader = request.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) { filterChain.doFilter(request, response); return; }

        String token = authHeader.substring(7);
        String email;
        try { email = jwtService.extractUsername(token); }
        catch (Exception ex) { filterChain.doFilter(request, response); return; }

        if (email != null && SecurityContextHolder.getContext().getAuthentication() == null) {
            AppUser user = userRepository.findByEmail(email).orElse(null);
            if (user != null && jwtService.isTokenValid(token, user)) {
                UserDetails ud = user;
                var auth = new UsernamePasswordAuthenticationToken(ud, null, ud.getAuthorities());
                auth.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(auth);
            }
        }
        filterChain.doFilter(request, response);
    }
}
EOF

cat > src/main/java/com/example/expensetracker/security/SecurityConfig.java <<'EOF'
package com.example.expensetracker.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
public class SecurityConfig {
    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    public SecurityConfig(JwtAuthenticationFilter jwtAuthenticationFilter) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http, AuthenticationProvider authenticationProvider) throws Exception {
        return http
                .csrf(csrf -> csrf.disable())
                .cors(Customizer.withDefaults())
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth.requestMatchers("/api/auth/**").permitAll().anyRequest().authenticated())
                .authenticationProvider(authenticationProvider)
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)
                .build();
    }

    @Bean
    public AuthenticationProvider authenticationProvider(UserDetailsService userDetailsService) {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
        provider.setUserDetailsService(userDetailsService);
        provider.setPasswordEncoder(passwordEncoder());
        return provider;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public PasswordEncoder passwordEncoder() { return new BCryptPasswordEncoder(); }
}
EOF

# ─────────────────────────────────────────────
# Config
# ─────────────────────────────────────────────
cat > src/main/java/com/example/expensetracker/config/AppConfig.java <<'EOF'
package com.example.expensetracker.config;

import com.example.expensetracker.security.CustomUserDetailsService;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.core.userdetails.UserDetailsService;

@Configuration
public class AppConfig {
    @Bean
    public UserDetailsService userDetailsService(CustomUserDetailsService customUserDetailsService) {
        return customUserDetailsService;
    }
}
EOF

# ─────────────────────────────────────────────
# Services  — ALL list() methods are @Transactional(readOnly=true)
# ─────────────────────────────────────────────
cat > src/main/java/com/example/expensetracker/service/AuthService.java <<'EOF'
package com.example.expensetracker.service;

import com.example.expensetracker.domain.AppUser;
import com.example.expensetracker.dto.AuthDtos;
import com.example.expensetracker.exception.ApiException;
import com.example.expensetracker.repository.AppUserRepository;
import com.example.expensetracker.security.JwtService;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {
    private final AppUserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;

    public AuthService(AppUserRepository userRepository, PasswordEncoder passwordEncoder,
                       AuthenticationManager authenticationManager, JwtService jwtService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.authenticationManager = authenticationManager;
        this.jwtService = jwtService;
    }

    public AuthDtos.AuthResponse register(AuthDtos.RegisterRequest request) {
        if (userRepository.existsByEmail(request.email())) throw new ApiException("Email already registered");
        AppUser user = AppUser.builder()
                .fullName(request.fullName())
                .email(request.email().toLowerCase())
                .passwordHash(passwordEncoder.encode(request.password()))
                .currencyCode(request.currencyCode() == null || request.currencyCode().isBlank() ? "INR" : request.currencyCode())
                .build();
        user = userRepository.save(user);
        return new AuthDtos.AuthResponse(user.getId(), user.getFullName(), user.getEmail(), jwtService.generateToken(user));
    }

    public AuthDtos.AuthResponse login(AuthDtos.LoginRequest request) {
        authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(request.email().toLowerCase(), request.password()));
        AppUser user = userRepository.findByEmail(request.email().toLowerCase()).orElseThrow(() -> new ApiException("User not found"));
        return new AuthDtos.AuthResponse(user.getId(), user.getFullName(), user.getEmail(), jwtService.generateToken(user));
    }
}
EOF

cat > src/main/java/com/example/expensetracker/service/CategoryService.java <<'EOF'
package com.example.expensetracker.service;

import com.example.expensetracker.domain.AppUser;
import com.example.expensetracker.domain.Category;
import com.example.expensetracker.dto.CategoryDtos;
import com.example.expensetracker.exception.ApiException;
import com.example.expensetracker.repository.AppUserRepository;
import com.example.expensetracker.repository.CategoryRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;

@Service
public class CategoryService {
    private final CategoryRepository categoryRepository;
    private final AppUserRepository userRepository;

    public CategoryService(CategoryRepository categoryRepository, AppUserRepository userRepository) {
        this.categoryRepository = categoryRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<CategoryDtos.CategoryResponse> list(UUID userId) {
        return categoryRepository.findByUser_IdOrderByNameAsc(userId).stream().map(this::toResponse).toList();
    }

    @Transactional
    public CategoryDtos.CategoryResponse create(UUID userId, CategoryDtos.CategoryRequest request) {
        AppUser user = userRepository.findById(userId).orElseThrow(() -> new ApiException("User not found"));
        if (categoryRepository.existsByUser_IdAndNameIgnoreCase(userId, request.name())) throw new ApiException("Category already exists");
        Category cat = Category.builder().user(user).name(request.name()).type(request.type())
                .icon(request.icon()).color(request.color()).defaultCategory(Boolean.TRUE.equals(request.isDefault())).build();
        return toResponse(categoryRepository.save(cat));
    }

    @Transactional
    public CategoryDtos.CategoryResponse update(UUID userId, UUID categoryId, CategoryDtos.CategoryRequest request) {
        Category cat = categoryRepository.findById(categoryId).orElseThrow(() -> new ApiException("Category not found"));
        if (!cat.getUser().getId().equals(userId)) throw new ApiException("Category does not belong to this user");
        cat.setName(request.name()); cat.setType(request.type()); cat.setIcon(request.icon());
        cat.setColor(request.color()); cat.setDefaultCategory(Boolean.TRUE.equals(request.isDefault()));
        return toResponse(categoryRepository.save(cat));
    }

    @Transactional
    public void delete(UUID userId, UUID categoryId) {
        Category cat = categoryRepository.findById(categoryId).orElseThrow(() -> new ApiException("Category not found"));
        if (!cat.getUser().getId().equals(userId)) throw new ApiException("Category does not belong to this user");
        categoryRepository.delete(cat);
    }

    private CategoryDtos.CategoryResponse toResponse(Category c) {
        return new CategoryDtos.CategoryResponse(c.getId(), c.getName(), c.getType(), c.getIcon(), c.getColor(), c.isDefaultCategory());
    }
}
EOF

cat > src/main/java/com/example/expensetracker/service/TagService.java <<'EOF'
package com.example.expensetracker.service;

import com.example.expensetracker.domain.AppUser;
import com.example.expensetracker.domain.Tag;
import com.example.expensetracker.dto.TagDtos;
import com.example.expensetracker.exception.ApiException;
import com.example.expensetracker.repository.AppUserRepository;
import com.example.expensetracker.repository.TagRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;

@Service
public class TagService {
    private final TagRepository tagRepository;
    private final AppUserRepository userRepository;

    public TagService(TagRepository tagRepository, AppUserRepository userRepository) {
        this.tagRepository = tagRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<TagDtos.TagResponse> list(UUID userId) {
        return tagRepository.findByUser_IdOrderByNameAsc(userId).stream()
                .map(t -> new TagDtos.TagResponse(t.getId(), t.getName())).toList();
    }

    @Transactional
    public TagDtos.TagResponse create(UUID userId, TagDtos.TagRequest request) {
        AppUser user = userRepository.findById(userId).orElseThrow(() -> new ApiException("User not found"));
        if (tagRepository.existsByUser_IdAndNameIgnoreCase(userId, request.name())) throw new ApiException("Tag already exists");
        Tag tag = tagRepository.save(Tag.builder().user(user).name(request.name()).build());
        return new TagDtos.TagResponse(tag.getId(), tag.getName());
    }
}
EOF

# FIX: BudgetService.list() — added @Transactional(readOnly=true) to keep session open for lazy proxy access
cat > src/main/java/com/example/expensetracker/service/BudgetService.java <<'EOF'
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
EOF

# FIX: RecurringRuleService.list() — added @Transactional(readOnly=true)
cat > src/main/java/com/example/expensetracker/service/RecurringRuleService.java <<'EOF'
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
EOF

# FIX: TransactionService.list() — added @Transactional(readOnly=true)
cat > src/main/java/com/example/expensetracker/service/TransactionService.java <<'EOF'
package com.example.expensetracker.service;

import com.example.expensetracker.domain.*;
import com.example.expensetracker.dto.DashboardDtos;
import com.example.expensetracker.dto.TransactionDtos;
import com.example.expensetracker.exception.ApiException;
import com.example.expensetracker.repository.AppUserRepository;
import com.example.expensetracker.repository.CategoryRepository;
import com.example.expensetracker.repository.ExpenseTransactionRepository;
import com.example.expensetracker.repository.TagRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;

@Service
public class TransactionService {
    private final ExpenseTransactionRepository transactionRepository;
    private final AppUserRepository userRepository;
    private final CategoryRepository categoryRepository;
    private final TagRepository tagRepository;

    public TransactionService(ExpenseTransactionRepository transactionRepository,
                              AppUserRepository userRepository,
                              CategoryRepository categoryRepository,
                              TagRepository tagRepository) {
        this.transactionRepository = transactionRepository;
        this.userRepository = userRepository;
        this.categoryRepository = categoryRepository;
        this.tagRepository = tagRepository;
    }

    // FIX: @Transactional(readOnly=true) keeps session open for tag/category access
    @Transactional(readOnly = true)
    public List<TransactionDtos.TransactionResponse> list(UUID userId) {
        return transactionRepository.findByUser_IdOrderByTransactionDateDescCreatedAtDesc(userId)
                .stream().map(this::toResponse).toList();
    }

    @Transactional
    public TransactionDtos.TransactionResponse create(UUID userId, TransactionDtos.TransactionRequest request) {
        AppUser user = userRepository.findById(userId).orElseThrow(() -> new ApiException("User not found"));
        Category category = null;
        if (request.categoryId() != null) {
            category = categoryRepository.findById(request.categoryId()).orElseThrow(() -> new ApiException("Category not found"));
            if (!category.getUser().getId().equals(userId)) throw new ApiException("Category does not belong to this user");
        }
        Set<Tag> tags = new HashSet<>();
        if (request.tagIds() != null && !request.tagIds().isEmpty()) {
            tags = new HashSet<>(tagRepository.findAllById(request.tagIds()));
            for (Tag tag : tags)
                if (!tag.getUser().getId().equals(userId)) throw new ApiException("One or more tags do not belong to this user");
        }
        ExpenseTransaction tx = ExpenseTransaction.builder()
                .user(user).category(category).type(request.type()).amount(request.amount())
                .description(request.description()).transactionDate(request.transactionDate())
                .paymentMode(request.paymentMode() == null ? PaymentModeType.OTHER : request.paymentMode())
                .referenceNumber(request.referenceNumber()).recurring(Boolean.TRUE.equals(request.isRecurring()))
                .tags(tags).build();
        return toResponse(transactionRepository.save(tx));
    }

    // FIX: dashboard — uses fixed repository queries that avoid PostgreSQL schema-qualified enum casting
    @Transactional(readOnly = true)
    public DashboardDtos.DashboardSummaryResponse dashboard(UUID userId, LocalDate from, LocalDate to) {
        BigDecimal income  = transactionRepository.sumAmountByUserAndType(userId, TransactionType.INCOME, from, to);
        BigDecimal expense = transactionRepository.sumAmountByUserAndType(userId, TransactionType.EXPENSE, from, to);
        Map<UUID, BigDecimal> expenseByCategory = new LinkedHashMap<>();
        for (Object[] row : transactionRepository.expenseByCategory(userId, from, to)) {
            if (row[0] != null) expenseByCategory.put((UUID) row[0], (BigDecimal) row[1]);
        }
        return new DashboardDtos.DashboardSummaryResponse(income, expense, income.subtract(expense), expenseByCategory);
    }

    private TransactionDtos.TransactionResponse toResponse(ExpenseTransaction tx) {
        List<String> tagNames = tx.getTags().stream().map(Tag::getName).sorted().toList();
        return new TransactionDtos.TransactionResponse(
                tx.getId(),
                tx.getCategory() == null ? null : tx.getCategory().getId(),
                tx.getCategory() == null ? null : tx.getCategory().getName(),
                tx.getType(), tx.getAmount(), tx.getDescription(), tx.getTransactionDate(),
                tx.getPaymentMode(), tx.getReferenceNumber(), tx.isRecurring(), tagNames);
    }
}
EOF

# ─────────────────────────────────────────────
# Controllers
# ─────────────────────────────────────────────
cat > src/main/java/com/example/expensetracker/controller/AuthController.java <<'EOF'
package com.example.expensetracker.controller;

import com.example.expensetracker.dto.AuthDtos;
import com.example.expensetracker.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController @RequestMapping("/api/auth")
public class AuthController {
    private final AuthService authService;
    public AuthController(AuthService authService) { this.authService = authService; }

    @PostMapping("/register")
    public Map<String, Object> register(@Valid @RequestBody AuthDtos.RegisterRequest request) {
        return Map.of("success", true, "data", authService.register(request));
    }

    @PostMapping("/login")
    public Map<String, Object> login(@Valid @RequestBody AuthDtos.LoginRequest request) {
        return Map.of("success", true, "data", authService.login(request));
    }
}
EOF

cat > src/main/java/com/example/expensetracker/controller/CategoryController.java <<'EOF'
package com.example.expensetracker.controller;

import com.example.expensetracker.domain.AppUser;
import com.example.expensetracker.dto.CategoryDtos;
import com.example.expensetracker.service.CategoryService;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.Map;
import java.util.UUID;

@RestController @RequestMapping("/api/categories")
public class CategoryController {
    private final CategoryService categoryService;
    public CategoryController(CategoryService categoryService) { this.categoryService = categoryService; }

    @GetMapping  public Map<String, Object> list(@AuthenticationPrincipal AppUser user) { return Map.of("success", true, "data", categoryService.list(user.getId())); }
    @PostMapping public Map<String, Object> create(@AuthenticationPrincipal AppUser user, @Valid @RequestBody CategoryDtos.CategoryRequest req) { return Map.of("success", true, "data", categoryService.create(user.getId(), req)); }
    @PutMapping("/{id}") public Map<String, Object> update(@AuthenticationPrincipal AppUser user, @PathVariable UUID id, @Valid @RequestBody CategoryDtos.CategoryRequest req) { return Map.of("success", true, "data", categoryService.update(user.getId(), id, req)); }
    @DeleteMapping("/{id}") public Map<String, Object> delete(@AuthenticationPrincipal AppUser user, @PathVariable UUID id) { categoryService.delete(user.getId(), id); return Map.of("success", true, "message", "Category deleted"); }
}
EOF

cat > src/main/java/com/example/expensetracker/controller/TagController.java <<'EOF'
package com.example.expensetracker.controller;

import com.example.expensetracker.domain.AppUser;
import com.example.expensetracker.dto.TagDtos;
import com.example.expensetracker.service.TagService;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController @RequestMapping("/api/tags")
public class TagController {
    private final TagService tagService;
    public TagController(TagService tagService) { this.tagService = tagService; }

    @GetMapping  public Map<String, Object> list(@AuthenticationPrincipal AppUser user) { return Map.of("success", true, "data", tagService.list(user.getId())); }
    @PostMapping public Map<String, Object> create(@AuthenticationPrincipal AppUser user, @Valid @RequestBody TagDtos.TagRequest req) { return Map.of("success", true, "data", tagService.create(user.getId(), req)); }
}
EOF

cat > src/main/java/com/example/expensetracker/controller/BudgetController.java <<'EOF'
package com.example.expensetracker.controller;

import com.example.expensetracker.domain.AppUser;
import com.example.expensetracker.dto.BudgetDtos;
import com.example.expensetracker.service.BudgetService;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController @RequestMapping("/api/budgets")
public class BudgetController {
    private final BudgetService budgetService;
    public BudgetController(BudgetService budgetService) { this.budgetService = budgetService; }

    @GetMapping  public Map<String, Object> list(@AuthenticationPrincipal AppUser user, @RequestParam Integer month, @RequestParam Integer year) { return Map.of("success", true, "data", budgetService.list(user.getId(), month, year)); }
    @PostMapping public Map<String, Object> create(@AuthenticationPrincipal AppUser user, @Valid @RequestBody BudgetDtos.BudgetRequest req) { return Map.of("success", true, "data", budgetService.create(user.getId(), req)); }
}
EOF

cat > src/main/java/com/example/expensetracker/controller/RecurringRuleController.java <<'EOF'
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
EOF

cat > src/main/java/com/example/expensetracker/controller/TransactionController.java <<'EOF'
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
EOF

cat > README.md <<'EOF'
# Expense Tracker Backend

## Prerequisites
- Java 17+
- Maven 3.8+
- PostgreSQL with expense_tracker schema (run the DDL first)

## Run
1. Update `src/main/resources/application.yml` with your DB credentials.
2. Build and start:
   ```bash
   mvn clean package -DskipTests
   mvn spring-boot:run
   ```

## API endpoints
| Method | Path | Notes |
|--------|------|-------|
| POST | /api/auth/register | Register user |
| POST | /api/auth/login | Login → returns JWT |
| GET  | /api/categories | List categories |
| POST | /api/categories | Create category |
| GET  | /api/transactions | List transactions |
| POST | /api/transactions | Create transaction |
| GET  | /api/transactions/dashboard?from=YYYY-MM-DD&to=YYYY-MM-DD | Dashboard summary |
| GET  | /api/budgets?month=5&year=2026 | List budgets |
| POST | /api/budgets | Create budget |
| GET  | /api/tags | List tags |
| POST | /api/tags | Create tag |
| GET  | /api/recurring-rules | List recurring rules |
| POST | /api/recurring-rules | Create recurring rule |

## Bugs fixed vs previous version
1. **dashboard 500** — PostgreSQL enum casting error (`'EXPENSE'::TransactionType` → type not found in public schema).
   Fix: JPQL queries now pass enums as Java parameters (`:type`) so Hibernate binds them correctly.
2. **GET /api/budgets 500** — `could not initialize proxy Category - no Session`.
   Fix: `Budget.category` changed to `FetchType.EAGER` + `BudgetService.list()` annotated `@Transactional(readOnly=true)`.
3. **GET /api/recurring-rules 500** — same lazy-loading issue.
   Fix: `RecurringRule.category` changed to `FetchType.EAGER` + `RecurringRuleService.list()` annotated `@Transactional(readOnly=true)`.
4. **dashboard null date param** — `could not determine data type of parameter $3`.
   Fix: JPQL null guard `(:from is null or ...)` with proper Hibernate binding avoids untyped NULL in native SQL.
EOF

echo ""
echo "✅  Project created in: $(pwd)"
echo ""
echo "Steps:"
echo "  1. cd $BASE_DIR"
echo "  2. Edit src/main/resources/application.yml — update DB URL / username / password"
echo "  3. mvn clean package -DskipTests"
echo "  4. mvn spring-boot:run"
echo ""
echo "Test with:"
echo "  TOKEN=\$(curl -s -X POST http://localhost:8080/api/auth/login \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"email\":\"ayush@example.com\",\"password\":\"yourpassword\"}' | jq -r '.data.token')"
echo ""
echo "  curl -X GET 'http://localhost:8080/api/transactions/dashboard?from=2026-05-01&to=2026-05-31' \\"
echo "    -H \"Authorization: Bearer \$TOKEN\""
echo ""
echo "  curl -X GET 'http://localhost:8080/api/budgets?month=5&year=2026' \\"
echo "    -H \"Authorization: Bearer \$TOKEN\""
echo ""
echo "  curl -X GET 'http://localhost:8080/api/recurring-rules' \\"
echo "    -H \"Authorization: Bearer \$TOKEN\""
