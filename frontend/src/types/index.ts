// User types
export type UserRole = 'EMPLOYEE' | 'PROJECT_MANAGER' | 'ADMIN';

export interface User {
  id: number;
  username: string;
  email: string;
  firstName: string;
  lastName: string;
  role: UserRole;
  avatarUrl?: string;
  xpPoints: number;
  level: number;
  isActive: boolean;
  lastLogin?: string;
  createdAt: string;
  updatedAt: string;
}

export interface UserBadge {
  id: number;
  badge: Badge;
  earnedAt: string;
}

export interface BadgeWithStatus extends Badge {
  earned: boolean;
  earnedAt?: string;
}

// Idea types
export type IdeaStatus = 'CONCEPT' | 'IN_PROGRESS' | 'COMPLETED';

export interface Idea {
  id: number;
  title: string;
  description: string;
  category: string;
  status: IdeaStatus;
  progressPercentage: number;
  author: User;
  tags: string[];
  likeCount: number;
  commentCount: number;
  viewCount: number;
  isFeatured: boolean;
  isLikedByCurrentUser?: boolean;
  attachments: FileAttachment[];
  checklistItems: ChecklistItem[];
  createdAt: string;
  updatedAt: string;
}

// Checklist types
export interface ChecklistItem {
  id: number;
  ideaId: number;
  title: string;
  isCompleted: boolean;
  ordinalPosition: number;
  createdAt: string;
  updatedAt: string;
}

export interface IdeaCreateRequest {
  title: string;
  description: string;
  category: string;
  tags: string[];
}

export interface IdeaUpdateRequest {
  title?: string;
  description?: string;
  category?: string;
  tags?: string[];
  status?: IdeaStatus;
  progressPercentage?: number;
}

// File attachment types
export interface FileAttachment {
  id: number;
  filename: string;
  originalName: string;
  mimeType: string;
  fileSize: number;
  uploadedAt: string;
}

// Like types
export interface Like {
  id: number;
  userId: number;
  ideaId: number;
  createdAt: string;
}

export interface LikeStatus {
  remainingLikes: number;
  weeklyLikesUsed: number;
  maxWeeklyLikes: number;
}

// Comment types
export interface Comment {
  id: number;
  ideaId: number;
  author: User;
  content: string;
  reactionCount: number;
  reactions: CommentReaction[];
  createdAt: string;
  updatedAt: string;
}

export interface CommentCreateRequest {
  content: string;
}

export interface CommentReaction {
  id: number;
  emoji: string;
  userId: number;
  count: number;
}

// Survey types
export interface Survey {
  id: number;
  creator: User;
  question: string;
  description?: string;
  options: SurveyOption[];
  isActive: boolean;
  isAnonymous: boolean;
  allowMultipleVotes: boolean;
  totalVotes: number;
  hasVoted?: boolean;
  userVotedOptionIds?: number[];
  expiresAt?: string;
  createdAt: string;
}

export interface SurveyOption {
  id: number;
  optionText: string;
  voteCount: number;
  percentage?: number;
}

export interface SurveyCreateRequest {
  question: string;
  description?: string;
  options: string[];
  isAnonymous?: boolean;
  allowMultipleVotes?: boolean;
  expiresAt?: string;
}

// Badge types
export interface Badge {
  id: number;
  name: string;
  displayName?: string;
  description: string;
  icon: string;
  criteria?: string;
  xpReward: number;
}

// Notification types
export type NotificationType =
  | 'LIKE'
  | 'COMMENT'
  | 'REACTION'
  | 'STATUS_CHANGE'
  | 'BADGE_EARNED'
  | 'LEVEL_UP'
  | 'MENTION'
  | 'MESSAGE';

export interface Notification {
  id: number;
  type: NotificationType;
  title: string;
  message: string;
  link?: string;
  isRead: boolean;
  sender?: User;
  createdAt: string;
}

// Message types
export interface Message {
  id: number;
  sender: User;
  recipient: User;
  ideaId?: number;
  ideaTitle?: string;
  content: string;
  isRead: boolean;
  createdAt: string;
}

export interface Conversation {
  otherUser: User;
  lastMessage: Message;
  unreadCount: number;
  lastMessageAt: string;
}

export interface SendMessageRequest {
  recipientId: number;
  content: string;
  ideaId?: number;
}

// Audit log types
export type AuditAction = 'CREATE' | 'UPDATE' | 'DELETE' | 'STATUS_CHANGE' | 'LOGIN' | 'LOGOUT';

export interface AuditLog {
  id: number;
  user?: User;
  action: AuditAction;
  entityType: string;
  entityId?: number;
  oldValue?: Record<string, unknown>;
  newValue?: Record<string, unknown>;
  ipAddress?: string;
  createdAt: string;
}

// Dashboard types
export interface CategoryBreakdown {
  category: string;
  count: number;
}

export interface WeeklyActivity {
  date: string;
  ideas: number;
}

export interface DashboardStats {
  totalIdeas: number;
  totalUsers: number;
  ideasThisWeek: number;
  popularCategory: string;
  completedIdeas: number;
  inProgressIdeas: number;
  conceptIdeas: number;
  totalLikes: number;
  totalComments: number;
  activeSurveys: number;
  categoryBreakdown: CategoryBreakdown[];
  weeklyActivity: WeeklyActivity[];
}

export interface TopIdea {
  idea: Idea;
  weeklyLikes: number;
  rank: number;
}

// Auth types
export interface LoginRequest {
  username: string;
  password: string;
}

export interface RegisterRequest {
  username: string;
  email: string;
  password: string;
  firstName: string;
  lastName: string;
}

export interface AuthResponse {
  token: string;
  refreshToken: string;
  user: User;
  expiresIn: number;
}

// Pagination types
export interface Page<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  size: number;
  number: number;
  first: boolean;
  last: boolean;
}

export interface PageRequest {
  page?: number;
  size?: number;
  sort?: string;
  direction?: 'ASC' | 'DESC';
}

// Filter types
export interface IdeaFilter extends PageRequest {
  category?: string;
  status?: IdeaStatus;
  authorId?: number;
  search?: string;
  tags?: string[];
}

// API Response types
export interface ApiError {
  status: number;
  message: string;
  timestamp: string;
  path?: string;
  errors?: Record<string, string>;
}
