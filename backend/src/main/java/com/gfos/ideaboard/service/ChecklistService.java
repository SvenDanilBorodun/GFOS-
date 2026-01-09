package com.gfos.ideaboard.service;

import com.gfos.ideaboard.dto.ChecklistItemDTO;
import com.gfos.ideaboard.entity.ChecklistItem;
import com.gfos.ideaboard.entity.Idea;
import com.gfos.ideaboard.entity.User;
import com.gfos.ideaboard.entity.UserRole;
import com.gfos.ideaboard.exception.ApiException;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import java.util.List;
import java.util.stream.Collectors;

@ApplicationScoped
public class ChecklistService {

    private static final int MAX_TITLE_LENGTH = 200;

    @PersistenceContext(unitName = "IdeaBoardPU")
    private EntityManager em;

    public List<ChecklistItemDTO> getChecklistByIdea(Long ideaId) {
        List<ChecklistItem> items = em.createNamedQuery("ChecklistItem.findByIdea", ChecklistItem.class)
                .setParameter("ideaId", ideaId)
                .getResultList();

        return items.stream()
                .map(ChecklistItemDTO::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public ChecklistItemDTO createChecklistItem(Long ideaId, String title, Long currentUserId) {
        // Validate input
        if (title == null || title.trim().isEmpty()) {
            throw ApiException.badRequest("Checklist item title is required");
        }
        if (title.length() > MAX_TITLE_LENGTH) {
            throw ApiException.badRequest("Checklist item title must be " + MAX_TITLE_LENGTH + " characters or less");
        }

        Idea idea = em.find(Idea.class, ideaId);
        if (idea == null) {
            throw ApiException.notFound("Idea not found");
        }

        // Only the idea author can add checklist items
        if (!idea.getAuthor().getId().equals(currentUserId)) {
            throw ApiException.forbidden("Only the idea creator can add checklist items");
        }

        // Get the next ordinal position
        Integer maxPosition = em.createQuery(
                "SELECT COALESCE(MAX(c.ordinalPosition), -1) FROM ChecklistItem c WHERE c.idea.id = :ideaId", Integer.class)
                .setParameter("ideaId", ideaId)
                .getSingleResult();

        ChecklistItem item = new ChecklistItem();
        item.setIdea(idea);
        item.setTitle(title.trim());
        item.setIsCompleted(false);
        item.setOrdinalPosition(maxPosition + 1);

        em.persist(item);

        // Update idea progress based on checklist
        updateIdeaProgress(idea);

        return ChecklistItemDTO.fromEntity(item);
    }

    @Transactional
    public ChecklistItemDTO toggleChecklistItem(Long ideaId, Long itemId, Long currentUserId) {
        Idea idea = em.find(Idea.class, ideaId);
        if (idea == null) {
            throw ApiException.notFound("Idea not found");
        }

        // IMPORTANT: Only the idea author can check/uncheck items
        if (!idea.getAuthor().getId().equals(currentUserId)) {
            throw ApiException.forbidden("Only the idea creator can update checklist items");
        }

        ChecklistItem item = em.find(ChecklistItem.class, itemId);
        if (item == null) {
            throw ApiException.notFound("Checklist item not found");
        }

        // Verify the item belongs to this idea
        if (!item.getIdea().getId().equals(ideaId)) {
            throw ApiException.badRequest("Checklist item does not belong to this idea");
        }

        // Toggle the completion status
        item.setIsCompleted(!item.getIsCompleted());
        em.merge(item);

        // Update idea progress based on checklist completion
        updateIdeaProgress(idea);

        return ChecklistItemDTO.fromEntity(item);
    }

    @Transactional
    public void deleteChecklistItem(Long ideaId, Long itemId, Long currentUserId) {
        Idea idea = em.find(Idea.class, ideaId);
        if (idea == null) {
            throw ApiException.notFound("Idea not found");
        }

        // Only author can delete checklist items
        if (!idea.getAuthor().getId().equals(currentUserId)) {
            throw ApiException.forbidden("Only the idea creator can delete checklist items");
        }

        ChecklistItem item = em.find(ChecklistItem.class, itemId);
        if (item == null) {
            throw ApiException.notFound("Checklist item not found");
        }

        // Verify the item belongs to this idea
        if (!item.getIdea().getId().equals(ideaId)) {
            throw ApiException.badRequest("Checklist item does not belong to this idea");
        }

        em.remove(item);

        // Update idea progress
        updateIdeaProgress(idea);
    }

    @Transactional
    public ChecklistItemDTO updateChecklistItem(Long ideaId, Long itemId, String title, Long currentUserId) {
        Idea idea = em.find(Idea.class, ideaId);
        if (idea == null) {
            throw ApiException.notFound("Idea not found");
        }

        // Only author can update checklist items
        if (!idea.getAuthor().getId().equals(currentUserId)) {
            throw ApiException.forbidden("Only the idea creator can update checklist items");
        }

        if (title == null || title.trim().isEmpty()) {
            throw ApiException.badRequest("Checklist item title is required");
        }
        if (title.length() > MAX_TITLE_LENGTH) {
            throw ApiException.badRequest("Checklist item title must be " + MAX_TITLE_LENGTH + " characters or less");
        }

        ChecklistItem item = em.find(ChecklistItem.class, itemId);
        if (item == null) {
            throw ApiException.notFound("Checklist item not found");
        }

        // Verify the item belongs to this idea
        if (!item.getIdea().getId().equals(ideaId)) {
            throw ApiException.badRequest("Checklist item does not belong to this idea");
        }

        item.setTitle(title.trim());
        em.merge(item);

        return ChecklistItemDTO.fromEntity(item);
    }

    /**
     * Updates the idea's progress percentage based on checklist completion.
     * Progress = (completed items / total items) * 100
     */
    private void updateIdeaProgress(Idea idea) {
        List<ChecklistItem> items = em.createNamedQuery("ChecklistItem.findByIdea", ChecklistItem.class)
                .setParameter("ideaId", idea.getId())
                .getResultList();

        if (items.isEmpty()) {
            // No checklist items, don't change progress
            return;
        }

        long completedCount = items.stream()
                .filter(ChecklistItem::getIsCompleted)
                .count();

        int progressPercentage = (int) Math.round((double) completedCount / items.size() * 100);
        idea.setProgressPercentage(progressPercentage);
        em.merge(idea);
    }
}
