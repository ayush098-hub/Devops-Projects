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
