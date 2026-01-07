package com.gfos.ideaboard.service;

import com.gfos.ideaboard.entity.Idea;
import com.gfos.ideaboard.entity.Like;
import com.gfos.ideaboard.entity.User;
import com.gfos.ideaboard.exception.ApiException;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.persistence.NoResultException;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.TemporalAdjusters;

@ApplicationScoped
public class LikeService {

    private static final int MAX_WEEKLY_LIKES = 3;
    private static final int XP_FOR_LIKE_RECEIVED = 10;

    @PersistenceContext(unitName = "IdeaBoardPU")
    private EntityManager em;

    @Inject
    private UserService userService;

    @Inject
    private NotificationService notificationService;

    @Inject
    private GamificationService gamificationService;

    public int getRemainingLikes(Long userId) {
        LocalDateTime weekStart = getLastSundayMidnight();
        Long usedLikes = em.createNamedQuery("Like.countByUserSince", Long.class)
                .setParameter("userId", userId)
                .setParameter("since", weekStart)
                .getSingleResult();
        return Math.max(0, MAX_WEEKLY_LIKES - usedLikes.intValue());
    }

    public int getWeeklyLikesUsed(Long userId) {
        LocalDateTime weekStart = getLastSundayMidnight();
        Long usedLikes = em.createNamedQuery("Like.countByUserSince", Long.class)
                .setParameter("userId", userId)
                .setParameter("since", weekStart)
                .getSingleResult();
        return usedLikes.intValue();
    }

    @Transactional
    public void likeIdea(Long ideaId, Long userId) {
        // Check remaining likes
        int remaining = getRemainingLikes(userId);
        if (remaining <= 0) {
            throw ApiException.badRequest("No likes remaining this week. Resets every Sunday at midnight.");
        }

        // Check if already liked
        Like existingLike = findLike(userId, ideaId);
        if (existingLike != null) {
            throw ApiException.conflict("You already liked this idea");
        }

        User user = em.find(User.class, userId);
        Idea idea = em.find(Idea.class, ideaId);

        if (user == null || idea == null) {
            throw ApiException.notFound("User or Idea not found");
        }

        // Cannot like own idea
        if (idea.getAuthor().getId().equals(userId)) {
            throw ApiException.badRequest("Cannot like your own idea");
        }

        // Create like
        Like like = new Like();
        like.setUser(user);
        like.setIdea(idea);
        em.persist(like);

        // Note: like_count is automatically updated by database trigger
        // Do NOT manually increment here to avoid double counting

        // Award XP to idea author and check badges
        gamificationService.awardXpForLikeReceived(idea.getAuthor().getId());

        // Notify idea author
        notificationService.notifyLike(idea, user);
    }

    @Transactional
    public void unlikeIdea(Long ideaId, Long userId) {
        Like like = findLike(userId, ideaId);
        if (like == null) {
            throw ApiException.notFound("Like not found");
        }

        // Note: like_count is automatically updated by database trigger
        // Do NOT manually decrement here to avoid double counting

        em.remove(like);
    }

    public boolean hasUserLiked(Long userId, Long ideaId) {
        return findLike(userId, ideaId) != null;
    }

    private Like findLike(Long userId, Long ideaId) {
        try {
            return em.createNamedQuery("Like.findByUserAndIdea", Like.class)
                    .setParameter("userId", userId)
                    .setParameter("ideaId", ideaId)
                    .getSingleResult();
        } catch (NoResultException e) {
            return null;
        }
    }

    private LocalDateTime getLastSundayMidnight() {
        LocalDate today = LocalDate.now();
        LocalDate lastSunday = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.SUNDAY));
        return lastSunday.atStartOfDay();
    }
}
