import api from './api';
import { User } from '../types';

interface PaginatedResponse<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  number: number;
  size: number;
}

interface UserStats {
  totalUsers: number;
  activeUsers: number;
  ideasPerUser: number;
}

const userService = {
  async getCurrentUser(): Promise<User> {
    const response = await api.get<User>('/users/me');
    return response.data;
  },

  async updateCurrentUser(data: Partial<User>): Promise<User> {
    const response = await api.put<User>('/users/me', data);
    return response.data;
  },

  async getUserById(id: number): Promise<User> {
    const response = await api.get<User>(`/users/${id}`);
    return response.data;
  },

  async getAllUsers(): Promise<User[]> {
    const response = await api.get<User[]>('/users');
    return response.data;
  },

  async updateUserRole(userId: number, role: string): Promise<void> {
    await api.put(`/users/${userId}/role`, { role });
  },

  async setUserActive(userId: number, isActive: boolean): Promise<void> {
    await api.put(`/users/${userId}/status`, { isActive });
  },

  async getRemainingLikes(): Promise<{ remaining: number; used: number }> {
    const response = await api.get<{ remaining: number; used: number }>('/users/me/likes/remaining');
    return response.data;
  },

  async getUserBadges(userId: number): Promise<any[]> {
    const response = await api.get<any[]>(`/users/${userId}/badges`);
    return response.data;
  },

  async getLeaderboard(limit: number = 10): Promise<User[]> {
    const response = await api.get<User[]>(`/users/leaderboard?limit=${limit}`);
    return response.data;
  }
};

export default userService;
