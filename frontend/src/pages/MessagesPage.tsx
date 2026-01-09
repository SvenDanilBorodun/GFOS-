import { useState, useEffect, useRef } from 'react';
import { useSearchParams } from 'react-router-dom';
import {
  PaperAirplaneIcon,
  ChatBubbleLeftRightIcon,
  ArrowLeftIcon,
} from '@heroicons/react/24/outline';
import { messageService } from '../services/messageService';
import userService from '../services/userService';
import { Message, Conversation, User } from '../types';
import { useAuth } from '../context/AuthContext';
import { format, isToday, isYesterday } from 'date-fns';
import toast from 'react-hot-toast';

export default function MessagesPage() {
  const { user } = useAuth();
  const [searchParams, setSearchParams] = useSearchParams();
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [messages, setMessages] = useState<Message[]>([]);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const [sendingMessage, setSendingMessage] = useState(false);
  const [showMobileList, setShowMobileList] = useState(true);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const [allUsers, setAllUsers] = useState<User[]>([]);
  const [showNewConversation, setShowNewConversation] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  // Check if user id is in URL params
  useEffect(() => {
    const userId = searchParams.get('user');
    if (userId) {
      loadConversationFromUrl(Number(userId));
    }
  }, [searchParams]);

  useEffect(() => {
    fetchConversations();
    fetchAllUsers();
  }, []);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const loadConversationFromUrl = async (userId: number) => {
    try {
      const users = await userService.getAllUsers();
      const targetUser = users.find(u => u.id === userId);
      if (targetUser) {
        setSelectedUser(targetUser);
        setShowMobileList(false);
        await fetchMessages(userId);
      }
    } catch (error) {
      console.error('Failed to load conversation from URL:', error);
    }
  };

  const fetchConversations = async () => {
    try {
      const data = await messageService.getConversations();
      setConversations(data);
    } catch (error) {
      console.error('Failed to fetch conversations:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchAllUsers = async () => {
    try {
      const users = await userService.getAllUsers();
      // Filter out current user
      setAllUsers(users.filter(u => u.id !== user?.id));
    } catch (error) {
      console.error('Failed to fetch users:', error);
    }
  };

  const fetchMessages = async (userId: number) => {
    try {
      const data = await messageService.getConversation(userId);
      setMessages(data);
      // Mark conversation as read
      await messageService.markConversationAsRead(userId);
      // Update unread count in conversations list
      setConversations(prev =>
        prev.map(c =>
          c.otherUser.id === userId ? { ...c, unreadCount: 0 } : c
        )
      );
    } catch (error) {
      console.error('Failed to fetch messages:', error);
    }
  };

  const handleSelectConversation = async (otherUser: User) => {
    setSelectedUser(otherUser);
    setShowMobileList(false);
    setShowNewConversation(false);
    setSearchParams({ user: otherUser.id.toString() });
    await fetchMessages(otherUser.id);
  };

  const handleStartNewConversation = (targetUser: User) => {
    setSelectedUser(targetUser);
    setMessages([]);
    setShowNewConversation(false);
    setShowMobileList(false);
    setSearchParams({ user: targetUser.id.toString() });
  };

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newMessage.trim() || !selectedUser) return;

    setSendingMessage(true);
    try {
      const message = await messageService.sendMessage({
        recipientId: selectedUser.id,
        content: newMessage.trim(),
      });
      setMessages(prev => [...prev, message]);
      setNewMessage('');

      // Update or add conversation in list
      const existingConvIndex = conversations.findIndex(c => c.otherUser.id === selectedUser.id);
      if (existingConvIndex >= 0) {
        setConversations(prev => {
          const updated = [...prev];
          updated[existingConvIndex] = {
            ...updated[existingConvIndex],
            lastMessage: message,
            lastMessageAt: message.createdAt,
          };
          return updated.sort((a, b) =>
            new Date(b.lastMessageAt).getTime() - new Date(a.lastMessageAt).getTime()
          );
        });
      } else {
        // Add new conversation
        setConversations(prev => [{
          otherUser: selectedUser,
          lastMessage: message,
          unreadCount: 0,
          lastMessageAt: message.createdAt,
        }, ...prev]);
      }
    } catch (error) {
      toast.error('Failed to send message');
    } finally {
      setSendingMessage(false);
    }
  };

  const handleBackToList = () => {
    setShowMobileList(true);
    setSelectedUser(null);
    setSearchParams({});
  };

  const formatMessageDate = (dateStr: string) => {
    const date = new Date(dateStr);
    if (isToday(date)) {
      return format(date, 'h:mm a');
    } else if (isYesterday(date)) {
      return 'Yesterday ' + format(date, 'h:mm a');
    }
    return format(date, 'MMM d, h:mm a');
  };

  const formatConversationDate = (dateStr: string) => {
    const date = new Date(dateStr);
    if (isToday(date)) {
      return format(date, 'h:mm a');
    } else if (isYesterday(date)) {
      return 'Yesterday';
    }
    return format(date, 'MMM d');
  };

  const filteredUsers = allUsers.filter(u =>
    u.firstName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    u.lastName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    u.username?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary-600" />
      </div>
    );
  }

  return (
    <div className="h-[calc(100vh-180px)] flex flex-col">
      <div className="flex items-center justify-between mb-4">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Messages</h1>
        <button
          onClick={() => setShowNewConversation(true)}
          className="btn-primary"
        >
          New Message
        </button>
      </div>

      <div className="flex-1 flex card overflow-hidden">
        {/* Conversations List */}
        <div className={`w-full md:w-80 border-r border-gray-200 dark:border-gray-700 flex flex-col ${
          !showMobileList ? 'hidden md:flex' : 'flex'
        }`}>
          <div className="p-4 border-b border-gray-200 dark:border-gray-700">
            <h2 className="font-semibold text-gray-900 dark:text-white">Conversations</h2>
          </div>

          <div className="flex-1 overflow-y-auto">
            {conversations.length === 0 ? (
              <div className="p-8 text-center text-gray-500 dark:text-gray-400">
                <ChatBubbleLeftRightIcon className="w-12 h-12 mx-auto mb-3 opacity-50" />
                <p>No conversations yet</p>
                <p className="text-sm mt-1">Start a new message to begin chatting</p>
              </div>
            ) : (
              conversations.map((conv) => (
                <button
                  key={conv.otherUser.id}
                  onClick={() => handleSelectConversation(conv.otherUser)}
                  className={`w-full p-4 flex items-start gap-3 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors text-left border-b border-gray-100 dark:border-gray-700 ${
                    selectedUser?.id === conv.otherUser.id
                      ? 'bg-primary-50 dark:bg-primary-900/20'
                      : ''
                  }`}
                >
                  <div className="avatar-md flex-shrink-0">
                    {conv.otherUser.firstName?.[0]}{conv.otherUser.lastName?.[0]}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between">
                      <span className="font-medium text-gray-900 dark:text-white truncate">
                        {conv.otherUser.firstName} {conv.otherUser.lastName}
                      </span>
                      {conv.lastMessageAt && (
                        <span className="text-xs text-gray-500 dark:text-gray-400 flex-shrink-0">
                          {formatConversationDate(conv.lastMessageAt)}
                        </span>
                      )}
                    </div>
                    <div className="flex items-center justify-between mt-1">
                      <p className="text-sm text-gray-500 dark:text-gray-400 truncate">
                        {conv.lastMessage?.content}
                      </p>
                      {conv.unreadCount > 0 && (
                        <span className="ml-2 bg-primary-600 text-white text-xs rounded-full px-2 py-0.5 flex-shrink-0">
                          {conv.unreadCount}
                        </span>
                      )}
                    </div>
                  </div>
                </button>
              ))
            )}
          </div>
        </div>

        {/* Chat Window */}
        <div className={`flex-1 flex flex-col ${
          showMobileList ? 'hidden md:flex' : 'flex'
        }`}>
          {selectedUser ? (
            <>
              {/* Chat Header */}
              <div className="p-4 border-b border-gray-200 dark:border-gray-700 flex items-center gap-3">
                <button
                  onClick={handleBackToList}
                  className="md:hidden btn-icon"
                >
                  <ArrowLeftIcon className="w-5 h-5" />
                </button>
                <div className="avatar-md">
                  {selectedUser.firstName?.[0]}{selectedUser.lastName?.[0]}
                </div>
                <div>
                  <h3 className="font-medium text-gray-900 dark:text-white">
                    {selectedUser.firstName} {selectedUser.lastName}
                  </h3>
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    @{selectedUser.username}
                  </p>
                </div>
              </div>

              {/* Messages */}
              <div className="flex-1 overflow-y-auto p-4 space-y-4">
                {messages.length === 0 ? (
                  <div className="h-full flex items-center justify-center text-gray-500 dark:text-gray-400">
                    <div className="text-center">
                      <ChatBubbleLeftRightIcon className="w-12 h-12 mx-auto mb-3 opacity-50" />
                      <p>No messages yet</p>
                      <p className="text-sm">Send a message to start the conversation</p>
                    </div>
                  </div>
                ) : (
                  messages.map((msg) => {
                    const isSentByMe = msg.sender.id === user?.id;
                    return (
                      <div
                        key={msg.id}
                        className={`flex ${isSentByMe ? 'justify-end' : 'justify-start'}`}
                      >
                        <div
                          className={`max-w-[70%] rounded-2xl px-4 py-2 ${
                            isSentByMe
                              ? 'bg-primary-600 text-white rounded-br-sm'
                              : 'bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-white rounded-bl-sm'
                          }`}
                        >
                          <p className="whitespace-pre-wrap break-words">{msg.content}</p>
                          {msg.ideaTitle && (
                            <p className={`text-xs mt-1 ${
                              isSentByMe ? 'text-primary-200' : 'text-gray-500 dark:text-gray-400'
                            }`}>
                              Re: {msg.ideaTitle}
                            </p>
                          )}
                          <p className={`text-xs mt-1 ${
                            isSentByMe ? 'text-primary-200' : 'text-gray-500 dark:text-gray-400'
                          }`}>
                            {formatMessageDate(msg.createdAt)}
                          </p>
                        </div>
                      </div>
                    );
                  })
                )}
                <div ref={messagesEndRef} />
              </div>

              {/* Message Input */}
              <form onSubmit={handleSendMessage} className="p-4 border-t border-gray-200 dark:border-gray-700">
                <div className="flex gap-3">
                  <input
                    type="text"
                    value={newMessage}
                    onChange={(e) => setNewMessage(e.target.value)}
                    placeholder="Type a message..."
                    maxLength={2000}
                    className="input flex-1"
                    autoFocus
                  />
                  <button
                    type="submit"
                    disabled={!newMessage.trim() || sendingMessage}
                    className="btn-primary px-4"
                  >
                    <PaperAirplaneIcon className="w-5 h-5" />
                  </button>
                </div>
              </form>
            </>
          ) : (
            <div className="flex-1 flex items-center justify-center text-gray-500 dark:text-gray-400">
              <div className="text-center">
                <ChatBubbleLeftRightIcon className="w-16 h-16 mx-auto mb-4 opacity-50" />
                <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
                  Select a conversation
                </h3>
                <p>Choose a conversation from the list or start a new message</p>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* New Conversation Modal */}
      {showNewConversation && (
        <div className="modal-overlay" onClick={() => setShowNewConversation(false)}>
          <div className="modal-content p-6 max-w-md" onClick={(e) => e.stopPropagation()}>
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
              New Message
            </h2>

            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search users..."
              className="input mb-4"
              autoFocus
            />

            <div className="max-h-80 overflow-y-auto">
              {filteredUsers.length === 0 ? (
                <p className="text-center text-gray-500 dark:text-gray-400 py-4">
                  No users found
                </p>
              ) : (
                filteredUsers.map((targetUser) => (
                  <button
                    key={targetUser.id}
                    onClick={() => handleStartNewConversation(targetUser)}
                    className="w-full p-3 flex items-center gap-3 hover:bg-gray-50 dark:hover:bg-gray-700/50 rounded-lg transition-colors"
                  >
                    <div className="avatar-md">
                      {targetUser.firstName?.[0]}{targetUser.lastName?.[0]}
                    </div>
                    <div className="text-left">
                      <p className="font-medium text-gray-900 dark:text-white">
                        {targetUser.firstName} {targetUser.lastName}
                      </p>
                      <p className="text-sm text-gray-500 dark:text-gray-400">
                        @{targetUser.username}
                      </p>
                    </div>
                  </button>
                ))
              )}
            </div>

            <div className="flex justify-end mt-4">
              <button
                onClick={() => setShowNewConversation(false)}
                className="btn-secondary"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
