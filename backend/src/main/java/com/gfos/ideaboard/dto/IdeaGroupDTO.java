package com.gfos.ideaboard.dto;

import com.gfos.ideaboard.entity.IdeaGroup;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

public class IdeaGroupDTO {

    private Long id;
    private Long ideaId;
    private String ideaTitle;
    private String name;
    private String description;
    private UserDTO createdBy;
    private List<GroupMemberDTO> members;
    private Integer memberCount;
    private Integer unreadCount;
    private GroupMessageDTO lastMessage;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public IdeaGroupDTO() {}

    public static IdeaGroupDTO fromEntity(IdeaGroup group) {
        return fromEntity(group, 0, null);
    }

    public static IdeaGroupDTO fromEntity(IdeaGroup group, int unreadCount, GroupMessageDTO lastMessage) {
        IdeaGroupDTO dto = new IdeaGroupDTO();
        dto.setId(group.getId());
        dto.setIdeaId(group.getIdea().getId());
        dto.setIdeaTitle(group.getIdea().getTitle());
        dto.setName(group.getName());
        dto.setDescription(group.getDescription());
        dto.setCreatedBy(UserDTO.fromEntity(group.getCreatedBy()));
        dto.setMembers(group.getMembers().stream()
                .map(GroupMemberDTO::fromEntity)
                .collect(Collectors.toList()));
        dto.setMemberCount(group.getMembers().size());
        dto.setUnreadCount(unreadCount);
        dto.setLastMessage(lastMessage);
        dto.setCreatedAt(group.getCreatedAt());
        dto.setUpdatedAt(group.getUpdatedAt());
        return dto;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getIdeaId() {
        return ideaId;
    }

    public void setIdeaId(Long ideaId) {
        this.ideaId = ideaId;
    }

    public String getIdeaTitle() {
        return ideaTitle;
    }

    public void setIdeaTitle(String ideaTitle) {
        this.ideaTitle = ideaTitle;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public UserDTO getCreatedBy() {
        return createdBy;
    }

    public void setCreatedBy(UserDTO createdBy) {
        this.createdBy = createdBy;
    }

    public List<GroupMemberDTO> getMembers() {
        return members;
    }

    public void setMembers(List<GroupMemberDTO> members) {
        this.members = members;
    }

    public Integer getMemberCount() {
        return memberCount;
    }

    public void setMemberCount(Integer memberCount) {
        this.memberCount = memberCount;
    }

    public Integer getUnreadCount() {
        return unreadCount;
    }

    public void setUnreadCount(Integer unreadCount) {
        this.unreadCount = unreadCount;
    }

    public GroupMessageDTO getLastMessage() {
        return lastMessage;
    }

    public void setLastMessage(GroupMessageDTO lastMessage) {
        this.lastMessage = lastMessage;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
