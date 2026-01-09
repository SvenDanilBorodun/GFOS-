package com.gfos.ideaboard.service;

import com.gfos.ideaboard.dto.GroupMessageDTO;
import com.gfos.ideaboard.dto.IdeaGroupDTO;
import com.gfos.ideaboard.entity.*;
import com.gfos.ideaboard.exception.ApiException;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import java.util.List;
import java.util.stream.Collectors;

@ApplicationScoped
public class GroupService {

    private static final int MAX_MESSAGE_LENGTH = 2000;

    @PersistenceContext(unitName = "IdeaBoardPU")
    private EntityManager em;

    @Inject
    private NotificationService notificationService;

    /**
     * Creates a group for an idea. Called automatically when an idea is created.
     */
    @Transactional
    public IdeaGroup createGroupForIdea(Idea idea, User creator) {
        IdeaGroup group = new IdeaGroup();
        group.setIdea(idea);
        group.setName("Group: " + idea.getTitle());
        group.setDescription("Discussion group for idea: " + idea.getTitle());
        group.setCreatedBy(creator);

        em.persist(group);

        // Add the creator as a member with CREATOR role
        GroupMember creatorMember = new GroupMember();
        creatorMember.setGroup(group);
        creatorMember.setUser(creator);
        creatorMember.setRole(GroupMemberRole.CREATOR);

        em.persist(creatorMember);

        return group;
    }

    /**
     * Gets all groups that a user is a member of.
     */
    public List<IdeaGroupDTO> getUserGroups(Long userId) {
        List<IdeaGroup> groups = em.createNamedQuery("IdeaGroup.findByUser", IdeaGroup.class)
                .setParameter("userId", userId)
                .getResultList();

        return groups.stream()
                .map(group -> {
                    int unreadCount = getUnreadMessageCount(group.getId(), userId);
                    GroupMessageDTO lastMessage = getLastMessage(group.getId());
                    return IdeaGroupDTO.fromEntity(group, unreadCount, lastMessage);
                })
                .collect(Collectors.toList());
    }

    /**
     * Gets a group by its ID.
     */
    public IdeaGroupDTO getGroup(Long groupId, Long userId) {
        IdeaGroup group = em.find(IdeaGroup.class, groupId);
        if (group == null) {
            throw ApiException.notFound("Group not found");
        }

        // Check if user is a member
        if (!isMember(groupId, userId)) {
            throw ApiException.forbidden("You are not a member of this group");
        }

        int unreadCount = getUnreadMessageCount(groupId, userId);
        GroupMessageDTO lastMessage = getLastMessage(groupId);
        return IdeaGroupDTO.fromEntity(group, unreadCount, lastMessage);
    }

    /**
     * Gets a group by idea ID.
     */
    public IdeaGroupDTO getGroupByIdea(Long ideaId, Long userId) {
        List<IdeaGroup> groups = em.createNamedQuery("IdeaGroup.findByIdea", IdeaGroup.class)
                .setParameter("ideaId", ideaId)
                .getResultList();

        if (groups.isEmpty()) {
            throw ApiException.notFound("No group found for this idea");
        }

        IdeaGroup group = groups.get(0);
        boolean userIsMember = isMember(group.getId(), userId);

        int unreadCount = userIsMember ? getUnreadMessageCount(group.getId(), userId) : 0;
        GroupMessageDTO lastMessage = getLastMessage(group.getId());

        IdeaGroupDTO dto = IdeaGroupDTO.fromEntity(group, unreadCount, lastMessage);
        return dto;
    }

    /**
     * Allows a user to join a group.
     */
    @Transactional
    public IdeaGroupDTO joinGroup(Long groupId, Long userId) {
        IdeaGroup group = em.find(IdeaGroup.class, groupId);
        if (group == null) {
            throw ApiException.notFound("Group not found");
        }

        // Check if already a member
        if (isMember(groupId, userId)) {
            throw ApiException.badRequest("You are already a member of this group");
        }

        User user = em.find(User.class, userId);
        if (user == null) {
            throw ApiException.notFound("User not found");
        }

        GroupMember member = new GroupMember();
        member.setGroup(group);
        member.setUser(user);
        member.setRole(GroupMemberRole.MEMBER);

        em.persist(member);

        // Notify group creator that someone joined
        notificationService.notifyGroupJoin(group, user);

        return IdeaGroupDTO.fromEntity(group);
    }

    /**
     * Allows a user to join a group by idea ID.
     */
    @Transactional
    public IdeaGroupDTO joinGroupByIdea(Long ideaId, Long userId) {
        List<IdeaGroup> groups = em.createNamedQuery("IdeaGroup.findByIdea", IdeaGroup.class)
                .setParameter("ideaId", ideaId)
                .getResultList();

        if (groups.isEmpty()) {
            throw ApiException.notFound("No group found for this idea");
        }

        return joinGroup(groups.get(0).getId(), userId);
    }

    /**
     * Allows a user to leave a group.
     */
    @Transactional
    public void leaveGroup(Long groupId, Long userId) {
        IdeaGroup group = em.find(IdeaGroup.class, groupId);
        if (group == null) {
            throw ApiException.notFound("Group not found");
        }

        // Check if the user is the creator
        if (group.getCreatedBy().getId().equals(userId)) {
            throw ApiException.badRequest("Group creator cannot leave the group");
        }

        List<GroupMember> members = em.createNamedQuery("GroupMember.findByGroupAndUser", GroupMember.class)
                .setParameter("groupId", groupId)
                .setParameter("userId", userId)
                .getResultList();

        if (members.isEmpty()) {
            throw ApiException.badRequest("You are not a member of this group");
        }

        em.remove(members.get(0));
    }

    /**
     * Gets all messages in a group.
     */
    public List<GroupMessageDTO> getGroupMessages(Long groupId, Long userId) {
        // Verify user is a member
        if (!isMember(groupId, userId)) {
            throw ApiException.forbidden("You are not a member of this group");
        }

        List<GroupMessage> messages = em.createNamedQuery("GroupMessage.findByGroup", GroupMessage.class)
                .setParameter("groupId", groupId)
                .getResultList();

        return messages.stream()
                .map(GroupMessageDTO::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Sends a message to a group.
     */
    @Transactional
    public GroupMessageDTO sendMessage(Long groupId, String content, Long senderId) {
        // Validate content
        if (content == null || content.trim().isEmpty()) {
            throw ApiException.badRequest("Message content is required");
        }
        if (content.length() > MAX_MESSAGE_LENGTH) {
            throw ApiException.badRequest("Message content must be " + MAX_MESSAGE_LENGTH + " characters or less");
        }

        IdeaGroup group = em.find(IdeaGroup.class, groupId);
        if (group == null) {
            throw ApiException.notFound("Group not found");
        }

        // Verify sender is a member
        if (!isMember(groupId, senderId)) {
            throw ApiException.forbidden("You are not a member of this group");
        }

        User sender = em.find(User.class, senderId);
        if (sender == null) {
            throw ApiException.notFound("User not found");
        }

        GroupMessage message = new GroupMessage();
        message.setGroup(group);
        message.setSender(sender);
        message.setContent(content.trim());

        em.persist(message);

        // Update group's updatedAt
        group.setUpdatedAt(message.getCreatedAt());
        em.merge(group);

        // Mark as read by sender
        markMessageAsRead(message.getId(), senderId);

        // Notify other group members
        notificationService.notifyGroupMessage(group, sender, content);

        return GroupMessageDTO.fromEntity(message);
    }

    /**
     * Marks all messages in a group as read for a user.
     */
    @Transactional
    public void markAllMessagesAsRead(Long groupId, Long userId) {
        // Get all unread messages
        List<GroupMessage> messages = em.createNamedQuery("GroupMessage.findByGroup", GroupMessage.class)
                .setParameter("groupId", groupId)
                .getResultList();

        for (GroupMessage message : messages) {
            // Skip messages sent by the user
            if (message.getSender().getId().equals(userId)) {
                continue;
            }

            // Check if already read
            List<GroupMessageRead> reads = em.createNamedQuery("GroupMessageRead.findByMessageAndUser", GroupMessageRead.class)
                    .setParameter("messageId", message.getId())
                    .setParameter("userId", userId)
                    .getResultList();

            if (reads.isEmpty()) {
                markMessageAsRead(message.getId(), userId);
            }
        }
    }

    /**
     * Marks a single message as read.
     */
    @Transactional
    public void markMessageAsRead(Long messageId, Long userId) {
        GroupMessage message = em.find(GroupMessage.class, messageId);
        if (message == null) {
            return;
        }

        User user = em.find(User.class, userId);
        if (user == null) {
            return;
        }

        // Check if already marked as read
        List<GroupMessageRead> existing = em.createNamedQuery("GroupMessageRead.findByMessageAndUser", GroupMessageRead.class)
                .setParameter("messageId", messageId)
                .setParameter("userId", userId)
                .getResultList();

        if (existing.isEmpty()) {
            GroupMessageRead read = new GroupMessageRead();
            read.setMessage(message);
            read.setUser(user);
            em.persist(read);
        }
    }

    /**
     * Checks if a user is a member of a group.
     */
    public boolean isMember(Long groupId, Long userId) {
        Long count = em.createQuery(
                "SELECT COUNT(gm) FROM GroupMember gm WHERE gm.group.id = :groupId AND gm.user.id = :userId", Long.class)
                .setParameter("groupId", groupId)
                .setParameter("userId", userId)
                .getSingleResult();
        return count > 0;
    }

    /**
     * Gets the count of unread messages for a user in a group.
     */
    public int getUnreadMessageCount(Long groupId, Long userId) {
        Long count = em.createNamedQuery("GroupMessage.countUnreadByUser", Long.class)
                .setParameter("groupId", groupId)
                .setParameter("userId", userId)
                .getSingleResult();
        return count.intValue();
    }

    /**
     * Gets the last message in a group.
     */
    public GroupMessageDTO getLastMessage(Long groupId) {
        List<GroupMessage> messages = em.createNamedQuery("GroupMessage.findRecentByGroup", GroupMessage.class)
                .setParameter("groupId", groupId)
                .setMaxResults(1)
                .getResultList();

        if (messages.isEmpty()) {
            return null;
        }

        return GroupMessageDTO.fromEntity(messages.get(0));
    }

    /**
     * Gets total unread group messages for a user across all groups.
     */
    public int getTotalUnreadCount(Long userId) {
        List<IdeaGroup> groups = em.createNamedQuery("IdeaGroup.findByUser", IdeaGroup.class)
                .setParameter("userId", userId)
                .getResultList();

        int total = 0;
        for (IdeaGroup group : groups) {
            total += getUnreadMessageCount(group.getId(), userId);
        }
        return total;
    }
}
