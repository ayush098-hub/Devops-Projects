package com.example.expensetracker.repository;

import com.example.expensetracker.domain.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface CategoryRepository extends JpaRepository<Category, UUID> {
    List<Category> findByUser_IdOrderByNameAsc(UUID userId);
    boolean existsByUser_IdAndNameIgnoreCase(UUID userId, String name);
}
