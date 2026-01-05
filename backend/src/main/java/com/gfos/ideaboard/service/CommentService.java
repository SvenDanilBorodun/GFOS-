package com.gfos.ideaboard.service;

import com.gfos.ideaboard.dto.CommentDTO;
import com.gfos.ideaboard.entity.*;
import com.gfos.ideaboard.exception.ApiException;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.persistence.NoResultException;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import java.util.List;
import java.util.stream.Collectors;

@ApplicationScoped
public class CommentService {

    private static final int MAX_COMMENT_LENGTH = 200;
    private static final int XP_FOR_COMMENT = 5;

    @PersistenceContext(unitName = "IdeaBoardPU")
    private EntityManager em;

    @Inject
    private UserService userService;

    @Inject
    private NotificationService notificationService;

    public List<CommentDTO> getCommentsByIdea(Long ideaId) {
        List<Comment> comments = em.createNamedQuery("Comment.findByIdea", Comment.class)
                .setParameter("ideaId", ideaId)
                .getResultList();
        return comments.stream()
                .map(CommentDTO::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public CommentDTO createComment(Long ideaId, String content, Long authorId) {
        if (content == null || content.trim().isEmpty()) {
            throw ApiException.badRequest("Comment content is required");
        }
        if (content.length() > MAX_COMMENT_LENGTH) {
            throw ApiException.badRequest("Comment must be " + MAX_COMMENT_LENGTH + " characters or less");
        }

        Idea idea = em.find(Idea.class, ideaId);
        if (idea == null) {
            throw ApiException.notFound("Idea not found");
        }

        User author = em.find(User.class, authorId);
        if (author == null) {
            throw ApiException.notFound("User not found");
        }

        Comment comment = new Comment();
        comment.setIdea(idea);
        comment.setAuthor(author);
        comment.setContent(content.trim());
        em.persist(comment);

        // Update idea comment count
        idea.incrementCommentCount();
        em.merge(idea);

        // Award XP
        userService.addXp(authorId, XP_FOR_COMMENT);

        // Notify idea author (if not commenting on own idea)
        if (!idea.getAuthor().getId().equals(authorId)) {
            notificationService.notifyComment(idea, author, content);
        }

        return CommentDTO.fromEntity(comment);
    }

    @Transactional
    public void deleteComment(Long commentId, Long currentUserId) {
        Comment comment = em.find(Comment.class, commentId);
        if (comment == null) {
            throw ApiException.notFound("Comment not found");
        }

        // Check permission
        User currentUser = em.find(User.class, currentUserId);
        if (!comment.getAuthor().getId().equals(currentUserId) &&
            currentUser.getRole() != UserRole.ADMIN) {
            throw ApiException.forbidden("Not authorized to delete this comment");
        }

        Idea idea = comment.getIdea();
        idea.decrementCommentCount();
        em.merge(idea);

        em.remove(comment);
    }

    @Transactional
    public void addReaction(Long commentId, String emoji, Long userId) {
        Comment comment = em.find(Comment.class, commentId);
        if (comment == null) {
            throw ApiException.notFound("Comment not found");
        }

        User user = em.find(User.class, userId);
        if (user == null) {
            throw ApiException.notFound("User not found");
        }

        // Check if already reacted with this emoji
        CommentReaction existing = findReaction(commentId, userId, emoji);
        if (existing != null) {
            throw ApiException.conflict("Already reacted with this emoji");
        }

        CommentReaction reaction = new CommentReaction();
        reaction.setComment(comment);
        reaction.setUser(user);
        reaction.setEmoji(emoji);
        em.persist(reaction);

        comment.incrementReactionCount();
        em.merge(comment);

        // Notify comment author
        if (!comment.getAuthor().getId().equals(userId)) {
            notificationService.notifyReaction(comment, user, emoji);
        }
    }

    @Transactional
    public void removeReaction(Long commentId, String emoji, Long userId) {
        CommentReaction reaction = findReaction(commentId, userId, emoji);
        if (reaction == null) {
            throw ApiException.notFound("Reaction not found");
        }

        Comment comment = reaction.getComment();
        comment.decrementReactionCount();
        em.merge(comment);

        em.remove(reaction);
    }

    private CommentReaction findReaction(Long commentId, Long userId, String emoji) {
        try {
            return em.createNamedQuery("CommentReaction.findByCommentAndUserAndEmoji", CommentReaction.class)
                    .setParameter("commentId", commentId)
                    .setParameter("userId", userId)
                    .setParameter("emoji", emoji)
                    .getSingleResult();
        } catch (NoResultException e) {
            return null;
        }
    }
}
