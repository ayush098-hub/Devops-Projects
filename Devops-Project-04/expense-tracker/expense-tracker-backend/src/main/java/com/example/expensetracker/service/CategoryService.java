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
