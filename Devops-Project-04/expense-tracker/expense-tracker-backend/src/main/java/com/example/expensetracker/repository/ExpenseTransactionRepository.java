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
