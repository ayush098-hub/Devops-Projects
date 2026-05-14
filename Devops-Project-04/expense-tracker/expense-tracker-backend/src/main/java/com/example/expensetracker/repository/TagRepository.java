package com.example.expensetracker.repository;

import com.example.expensetracker.domain.Tag;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface TagRepository extends JpaRepository<Tag, UUID> {
    List<Tag> findByUser_IdOrderByNameAsc(UUID userId);
    boolean existsByUser_IdAndNameIgnoreCase(UUID userId, String name);
}
