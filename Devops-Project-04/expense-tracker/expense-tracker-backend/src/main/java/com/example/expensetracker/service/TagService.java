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
