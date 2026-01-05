package com.gfos.ideaboard.service;

import com.gfos.ideaboard.dto.IdeaDTO;
import com.gfos.ideaboard.entity.*;
import com.gfos.ideaboard.exception.ApiException;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.TypedQuery;
import jakarta.transaction.Transactional;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.TemporalAdjusters;
import java.util.List;
import java.util.stream.Collectors;

@ApplicationScoped
public class IdeaService {

    private static final int XP_FOR_IDEA = 50;
    private static final int XP_FOR_COMPLETED = 100;

    @PersistenceContext(unitName = "IdeaBoardPU")
    private EntityManager em;

    @Inject
    private UserService userService;

    @Inject
    private AuditService auditService;

    @Inject
    private NotificationService notificationService;

    public Idea findById(Long id) {
        return em.find(Idea.class, id);
    }

    public IdeaDTO getIdeaById(Long id, Long currentUserId) {
        Idea idea = findById(id);
        if (idea == null) {
            throw ApiException.notFound("Idea not found");
        }

        // Increment view count
        incrementViewCount(id);

        boolean isLiked = isLikedByUser(id, currentUserId);
        return IdeaDTO.fromEntity(idea, isLiked);
    }

    public List<IdeaDTO> getIdeas(String category, IdeaStatus status, Long authorId,
                                   String search, int page, int size, Long currentUserId) {
        StringBuilder jpql = new StringBuilder("SELECT i FROM Idea i WHERE 1=1");

        if (category != null && !category.isEmpty()) {
            jpql.append(" AND i.category = :category");
        }
        if (status != null) {
            jpql.append(" AND i.status = :status");
        }
        if (authorId != null) {
            jpql.append(" AND i.author.id = :authorId");
        }
        if (search != null && !search.isEmpty()) {
            jpql.append(" AND (LOWER(i.title) LIKE :search OR LOWER(i.description) LIKE :search)");
        }
        jpql.append(" ORDER BY i.createdAt DESC");

        TypedQuery<Idea> query = em.createQuery(jpql.toString(), Idea.class);

        if (category != null && !category.isEmpty()) {
            query.setParameter("category", category);
        }
        if (status != null) {
            query.setParameter("status", status);
        }
        if (authorId != null) {
            query.setParameter("authorId", authorId);
        }
        if (search != null && !search.isEmpty()) {
            query.setParameter("search", "%" + search.toLowerCase() + "%");
        }

        query.setFirstResult(page * size);
        query.setMaxResults(size);

        List<Idea> ideas = query.getResultList();

        return ideas.stream()
                .map(idea -> IdeaDTO.fromEntity(idea, isLikedByUser(idea.getId(), currentUserId)))
                .collect(Collectors.toList());
    }

    public long countIdeas(String category, IdeaStatus status, Long authorId, String search) {
        StringBuilder jpql = new StringBuilder("SELECT COUNT(i) FROM Idea i WHERE 1=1");

        if (category != null && !category.isEmpty()) {
            jpql.append(" AND i.category = :category");
        }
        if (status != null) {
            jpql.append(" AND i.status = :status");
        }
        if (authorId != null) {
            jpql.append(" AND i.author.id = :authorId");
        }
        if (search != null && !search.isEmpty()) {
            jpql.append(" AND (LOWER(i.title) LIKE :search OR LOWER(i.description) LIKE :search)");
        }

        TypedQuery<Long> query = em.createQuery(jpql.toString(), Long.class);

        if (category != null && !category.isEmpty()) {
            query.setParameter("category", category);
        }
        if (status != null) {
            query.setParameter("status", status);
        }
        if (authorId != null) {
            query.setParameter("authorId", authorId);
        }
        if (search != null && !search.isEmpty()) {
            query.setParameter("search", "%" + search.toLowerCase() + "%");
        }

        return query.getSingleResult();
    }

    @Transactional
    public IdeaDTO createIdea(String title, String description, String category,
                              List<String> tags, Long authorId) {
        User author = em.find(User.class, authorId);
        if (author == null) {
            throw ApiException.notFound("Author not found");
        }

        Idea idea = new Idea();
        idea.setTitle(title);
        idea.setDescription(description);
        idea.setCategory(category);
        idea.setTags(tags != null ? tags : List.of());
        idea.setAuthor(author);
        idea.setStatus(IdeaStatus.CONCEPT);
        idea.setProgressPercentage(0);

        em.persist(idea);

        // Award XP
        userService.addXp(authorId, XP_FOR_IDEA);

        // Audit log
        auditService.log(authorId, AuditAction.CREATE, "Idea", idea.getId(), null, null);

        return IdeaDTO.fromEntity(idea);
    }

    @Transactional
    public IdeaDTO updateIdea(Long id, String title, String description, String category,
                              List<String> tags, Long currentUserId) {
        Idea idea = findById(id);
        if (idea == null) {
            throw ApiException.notFound("Idea not found");
        }

        // Check ownership (only author or admin can update)
        if (!idea.getAuthor().getId().equals(currentUserId)) {
            User currentUser = em.find(User.class, currentUserId);
            if (currentUser == null || currentUser.getRole() != UserRole.ADMIN) {
                throw ApiException.forbidden("Not authorized to update this idea");
            }
        }

        if (title != null) idea.setTitle(title);
        if (description != null) idea.setDescription(description);
        if (category != null) idea.setCategory(category);
        if (tags != null) idea.setTags(tags);

        em.merge(idea);

        auditService.log(currentUserId, AuditAction.UPDATE, "Idea", id, null, null);

        return IdeaDTO.fromEntity(idea);
    }

    @Transactional
    public IdeaDTO updateStatus(Long id, IdeaStatus status, Integer progressPercentage, Long currentUserId) {
        Idea idea = findById(id);
        if (idea == null) {
            throw ApiException.notFound("Idea not found");
        }

        // Check permission (only PM or Admin)
        User currentUser = em.find(User.class, currentUserId);
        if (currentUser == null ||
            (currentUser.getRole() != UserRole.PROJECT_MANAGER && currentUser.getRole() != UserRole.ADMIN)) {
            throw ApiException.forbidden("Not authorized to change status");
        }

        IdeaStatus oldStatus = idea.getStatus();
        idea.setStatus(status);

        if (progressPercentage != null) {
            idea.setProgressPercentage(progressPercentage);
        }

        // Auto-set progress based on status
        if (status == IdeaStatus.COMPLETED) {
            idea.setProgressPercentage(100);
            // Award XP to author for completion
            userService.addXp(idea.getAuthor().getId(), XP_FOR_COMPLETED);
        } else if (status == IdeaStatus.CONCEPT) {
            idea.setProgressPercentage(0);
        }

        em.merge(idea);

        // Notify author of status change
        if (oldStatus != status) {
            notificationService.notifyStatusChange(idea, oldStatus, status, currentUser);
            auditService.log(currentUserId, AuditAction.STATUS_CHANGE, "Idea", id,
                    "{\"status\":\"" + oldStatus + "\"}",
                    "{\"status\":\"" + status + "\"}");
        }

        return IdeaDTO.fromEntity(idea);
    }

    @Transactional
    public void deleteIdea(Long id, Long currentUserId) {
        Idea idea = findById(id);
        if (idea == null) {
            throw ApiException.notFound("Idea not found");
        }

        // Only admin can delete
        User currentUser = em.find(User.class, currentUserId);
        if (currentUser == null || currentUser.getRole() != UserRole.ADMIN) {
            throw ApiException.forbidden("Only admins can delete ideas");
        }

        auditService.log(currentUserId, AuditAction.DELETE, "Idea", id, null, null);
        em.remove(idea);
    }

    @Transactional
    public void incrementViewCount(Long ideaId) {
        em.createQuery("UPDATE Idea i SET i.viewCount = i.viewCount + 1 WHERE i.id = :id")
                .setParameter("id", ideaId)
                .executeUpdate();
    }

    public List<IdeaDTO> getTopIdeasThisWeek(int limit, Long currentUserId) {
        LocalDateTime weekStart = getLastSundayMidnight();

        // Get ideas with most likes this week
        List<Object[]> results = em.createQuery(
                "SELECT i, COUNT(l) as weeklyLikes FROM Idea i " +
                "LEFT JOIN Like l ON l.idea = i AND l.createdAt >= :weekStart " +
                "GROUP BY i ORDER BY weeklyLikes DESC, i.likeCount DESC", Object[].class)
                .setParameter("weekStart", weekStart)
                .setMaxResults(limit)
                .getResultList();

        return results.stream()
                .map(row -> {
                    Idea idea = (Idea) row[0];
                    return IdeaDTO.fromEntity(idea, isLikedByUser(idea.getId(), currentUserId));
                })
                .collect(Collectors.toList());
    }

    public List<String> getCategories() {
        return em.createQuery(
                "SELECT DISTINCT i.category FROM Idea i ORDER BY i.category", String.class)
                .getResultList();
    }

    public List<String> getPopularTags(int limit) {
        return em.createQuery(
                "SELECT t FROM Idea i JOIN i.tags t GROUP BY t ORDER BY COUNT(t) DESC", String.class)
                .setMaxResults(limit)
                .getResultList();
    }

    private boolean isLikedByUser(Long ideaId, Long userId) {
        if (userId == null) return false;
        Long count = em.createQuery(
                "SELECT COUNT(l) FROM Like l WHERE l.idea.id = :ideaId AND l.user.id = :userId", Long.class)
                .setParameter("ideaId", ideaId)
                .setParameter("userId", userId)
                .getSingleResult();
        return count > 0;
    }

    private LocalDateTime getLastSundayMidnight() {
        LocalDate today = LocalDate.now();
        LocalDate lastSunday = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.SUNDAY));
        return lastSunday.atStartOfDay();
    }
}
