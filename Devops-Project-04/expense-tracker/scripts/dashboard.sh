
#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${1:-expense-tracker-backend}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "Project directory '$PROJECT_DIR' not found."
  exit 1
fi

cd "$PROJECT_DIR"

mkdir -p src/main/java/com/example/expensetracker/repository

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

    @Query(value = """
        SELECT COALESCE(SUM(amount), 0)
        FROM expense_tracker.transactions
        WHERE user_id = :userId
          AND type = CAST(:#{#type.name()} AS expense_tracker.transaction_type)
          AND (:fromDate IS NULL OR transaction_date >= :fromDate)
          AND (:toDate IS NULL OR transaction_date <= :toDate)
        """, nativeQuery = true)
    BigDecimal sumAmountByUserAndType(
            @Param("userId") UUID userId,
            @Param("type") TransactionType type,
            @Param("fromDate") LocalDate fromDate,
            @Param("toDate") LocalDate toDate
    );

    @Query(value = """
        SELECT category_id, COALESCE(SUM(amount), 0)
        FROM expense_tracker.transactions
        WHERE user_id = :userId
          AND type = CAST('EXPENSE' AS expense_tracker.transaction_type)
          AND (:fromDate IS NULL OR transaction_date >= :fromDate)
          AND (:toDate IS NULL OR transaction_date <= :toDate)
        GROUP BY category_id
        ORDER BY COALESCE(SUM(amount), 0) DESC
        """, nativeQuery = true)
    List<Object[]> expenseByCategory(
            @Param("userId") UUID userId,
            @Param("fromDate") LocalDate fromDate,
            @Param("toDate") LocalDate toDate
    );
}
EOF

echo "Rebuilding project..."
mvn clean package -DskipTests

echo
echo "Dashboard enum fix applied successfully."
echo "Restart the backend:"
echo "  cd $PROJECT_DIR"
echo "  mvn spring-boot:run"

