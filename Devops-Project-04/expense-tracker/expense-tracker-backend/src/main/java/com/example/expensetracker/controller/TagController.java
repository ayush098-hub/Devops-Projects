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
