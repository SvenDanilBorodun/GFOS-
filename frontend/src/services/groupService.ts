import api from './api';
import { IdeaGroup, GroupMessage } from '../types';

export const groupService = {
  // Get all groups the user is a member of
  async getUserGroups(): Promise<IdeaGroup[]> {
    const response = await api.get<IdeaGroup[]>('/groups');
    return response.data;
  },

  // Get a specific group by ID
  async getGroup(groupId: number): Promise<IdeaGroup> {
    const response = await api.get<IdeaGroup>(`/groups/${groupId}`);
    return response.data;
  },

  // Get group by idea ID
  async getGroupByIdea(ideaId: number): Promise<IdeaGroup> {
    const response = await api.get<IdeaGroup>(`/groups/idea/${ideaId}`);
    return response.data;
  },

  // Join a group
  async joinGroup(groupId: number): Promise<IdeaGroup> {
    const response = await api.post<IdeaGroup>(`/groups/${groupId}/join`);
    return response.data;
  },

  // Join a group by idea ID
  async joinGroupByIdea(ideaId: number): Promise<IdeaGroup> {
    const response = await api.post<IdeaGroup>(`/groups/idea/${ideaId}/join`);
    return response.data;
  },

  // Leave a group
  async leaveGroup(groupId: number): Promise<void> {
    await api.delete(`/groups/${groupId}/leave`);
  },

  // Get all messages in a group
  async getGroupMessages(groupId: number): Promise<GroupMessage[]> {
    const response = await api.get<GroupMessage[]>(`/groups/${groupId}/messages`);
    return response.data;
  },

  // Send a message to a group
  async sendGroupMessage(groupId: number, content: string): Promise<GroupMessage> {
    const response = await api.post<GroupMessage>(`/groups/${groupId}/messages`, { content });
    return response.data;
  },

  // Mark all messages in a group as read
  async markAllAsRead(groupId: number): Promise<void> {
    await api.put(`/groups/${groupId}/messages/read`);
  },

  // Check if user is a member of a group
  async checkMembership(groupId: number): Promise<{ isMember: boolean }> {
    const response = await api.get<{ isMember: boolean }>(`/groups/${groupId}/membership`);
    return response.data;
  },

  // Check if user is a member of a group by idea ID
  async checkMembershipByIdea(ideaId: number): Promise<{ isMember: boolean; groupId?: number }> {
    const response = await api.get<{ isMember: boolean; groupId?: number }>(`/groups/idea/${ideaId}/membership`);
    return response.data;
  },

  // Get total unread count across all groups
  async getTotalUnreadCount(): Promise<{ unreadCount: number }> {
    const response = await api.get<{ unreadCount: number }>('/groups/unread-count');
    return response.data;
  },
};
