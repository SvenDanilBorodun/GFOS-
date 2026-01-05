package com.gfos.ideaboard.service;

import com.gfos.ideaboard.dto.NotificationDTO;
import com.gfos.ideaboard.entity.*;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import java.util.List;
import java.util.stream.Collectors;

@ApplicationScoped
public class NotificationService {

    @PersistenceContext(unitName = "IdeaBoardPU")
    private EntityManager em;

    public List<NotificationDTO> getNotificationsByUser(Long userId, int limit) {
        List<Notification> notifications = em.createNamedQuery("Notification.findByUser", Notification.class)
                .setParameter("userId", userId)
                .setMaxResults(limit)
                .getResultList();
        return notifications.stream()
                .map(NotificationDTO::fromEntity)
                .collect(Collectors.toList());
    }

    public long getUnreadCount(Long userId) {
        return em.createNamedQuery("Notification.countUnreadByUser", Long.class)
                .setParameter("userId", userId)
                .getSingleResult();
    }

    @Transactional
    public void markAsRead(Long notificationId, Long userId) {
        Notification notification = em.find(Notification.class, notificationId);
        if (notification != null && notification.getUser().getId().equals(userId)) {
            notification.setIsRead(true);
            em.merge(notification);
        }
    }

    @Transactional
    public void markAllAsRead(Long userId) {
        em.createQuery("UPDATE Notification n SET n.isRead = true WHERE n.user.id = :userId AND n.isRead = false")
                .setParameter("userId", userId)
                .executeUpdate();
    }

    @Transactional
    public void notifyLike(Idea idea, User liker) {
        Notification notification = new Notification();
        notification.setUser(idea.getAuthor());
        notification.setType(NotificationType.LIKE);
        notification.setTitle("New Like");
        notification.setMessage(liker.getFirstName() + " liked your idea \"" + truncate(idea.getTitle(), 50) + "\"");
        notification.setLink("/ideas/" + idea.getId());
        notification.setSender(liker);
        notification.setRelatedEntityType("Idea");
        notification.setRelatedEntityId(idea.getId());
        em.persist(notification);
    }

    @Transactional
    public void notifyComment(Idea idea, User commenter, String commentContent) {
        Notification notification = new Notification();
        notification.setUser(idea.getAuthor());
        notification.setType(NotificationType.COMMENT);
        notification.setTitle("New Comment");
        notification.setMessage(commenter.getFirstName() + " commented on \"" + truncate(idea.getTitle(), 30) + "\": " + truncate(commentContent, 50));
        notification.setLink("/ideas/" + idea.getId());
        notification.setSender(commenter);
        notification.setRelatedEntityType("Idea");
        notification.setRelatedEntityId(idea.getId());
        em.persist(notification);
    }

    @Transactional
    public void notifyReaction(Comment comment, User reactor, String emoji) {
        Notification notification = new Notification();
        notification.setUser(comment.getAuthor());
        notification.setType(NotificationType.REACTION);
        notification.setTitle("New Reaction");
        notification.setMessage(reactor.getFirstName() + " reacted to your comment");
        notification.setLink("/ideas/" + comment.getIdea().getId());
        notification.setSender(reactor);
        notification.setRelatedEntityType("Comment");
        notification.setRelatedEntityId(comment.getId());
        em.persist(notification);
    }

    @Transactional
    public void notifyStatusChange(Idea idea, IdeaStatus oldStatus, IdeaStatus newStatus, User changedBy) {
        Notification notification = new Notification();
        notification.setUser(idea.getAuthor());
        notification.setType(NotificationType.STATUS_CHANGE);
        notification.setTitle("Status Updated");
        notification.setMessage("Your idea \"" + truncate(idea.getTitle(), 30) + "\" status changed to " + formatStatus(newStatus));
        notification.setLink("/ideas/" + idea.getId());
        notification.setSender(changedBy);
        notification.setRelatedEntityType("Idea");
        notification.setRelatedEntityId(idea.getId());
        em.persist(notification);
    }

    @Transactional
    public void notifyBadgeEarned(User user, Badge badge) {
        Notification notification = new Notification();
        notification.setUser(user);
        notification.setType(NotificationType.BADGE_EARNED);
        notification.setTitle("Badge Earned!");
        notification.setMessage("Congratulations! You earned the \"" + badge.getName() + "\" badge");
        notification.setLink("/profile");
        notification.setRelatedEntityType("Badge");
        notification.setRelatedEntityId(badge.getId());
        em.persist(notification);
    }

    @Transactional
    public void notifyLevelUp(User user, int newLevel) {
        Notification notification = new Notification();
        notification.setUser(user);
        notification.setType(NotificationType.LEVEL_UP);
        notification.setTitle("Level Up!");
        notification.setMessage("Congratulations! You reached Level " + newLevel);
        notification.setLink("/profile");
        em.persist(notification);
    }

    @Transactional
    public void createNotification(Long userId, NotificationType type, String message,
                                    String relatedEntityType, Long relatedEntityId) {
        User user = em.find(User.class, userId);
        if (user == null) return;

        Notification notification = new Notification();
        notification.setUser(user);
        notification.setType(type);
        notification.setTitle(type.name().replace("_", " "));
        notification.setMessage(message);
        notification.setRelatedEntityType(relatedEntityType);
        notification.setRelatedEntityId(relatedEntityId);
        if (type == NotificationType.BADGE_EARNED || type == NotificationType.LEVEL_UP) {
            notification.setLink("/profile");
        }
        em.persist(notification);
    }

    private String truncate(String text, int maxLength) {
        if (text == null) return "";
        if (text.length() <= maxLength) return text;
        return text.substring(0, maxLength - 3) + "...";
    }

    private String formatStatus(IdeaStatus status) {
        return switch (status) {
            case CONCEPT -> "Concept";
            case IN_PROGRESS -> "In Progress";
            case COMPLETED -> "Completed";
        };
    }
}
