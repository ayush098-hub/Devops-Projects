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
