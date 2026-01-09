import { useState, useEffect } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import {
  HeartIcon,
  ChatBubbleLeftIcon,
  PencilIcon,
  TrashIcon,
  ArrowLeftIcon,
  PaperClipIcon,
  ArrowDownTrayIcon,
  CheckCircleIcon,
  PlusIcon,
  ClipboardDocumentListIcon,
  EnvelopeIcon,
} from '@heroicons/react/24/outline';
import { CheckCircleIcon as CheckCircleSolidIcon } from '@heroicons/react/24/solid';
import { HeartIcon as HeartSolidIcon } from '@heroicons/react/24/solid';
import { ideaService } from '../services/ideaService';
import { Idea, Comment, IdeaStatus, ChecklistItem } from '../types';
import { useAuth } from '../context/AuthContext';
import { format } from 'date-fns';
import toast from 'react-hot-toast';

const EMOJI_LIST = ['thumbs_up', 'heart', 'celebrate', 'thinking', 'fire'];

const EMOJI_DISPLAY: Record<string, string> = {
  thumbs_up: '👍',
  heart: '❤️',
  celebrate: '🎉',
  thinking: '🤔',
  fire: '🔥',
};

export default function IdeaDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { user } = useAuth();
  const navigate = useNavigate();
  const [idea, setIdea] = useState<Idea | null>(null);
  const [comments, setComments] = useState<Comment[]>([]);
  const [loading, setLoading] = useState(true);
  const [newComment, setNewComment] = useState('');
  const [submittingComment, setSubmittingComment] = useState(false);
  const [showStatusModal, setShowStatusModal] = useState(false);
  const [checklistItems, setChecklistItems] = useState<ChecklistItem[]>([]);
  const [newChecklistItem, setNewChecklistItem] = useState('');
  const [addingChecklistItem, setAddingChecklistItem] = useState(false);

  const canManageStatus = user?.role === 'PROJECT_MANAGER' || user?.role === 'ADMIN';
  const canDelete = user?.role === 'ADMIN';
  const isAuthor = user?.id === idea?.author.id;

  useEffect(() => {
    if (id) {
      fetchIdea();
      fetchComments();
    }
  }, [id]);

  const fetchIdea = async () => {
    try {
      const data = await ideaService.getIdea(Number(id));
      setIdea(data);
      setChecklistItems(data.checklistItems || []);
    } catch (error) {
      console.error('Failed to fetch idea:', error);
      toast.error('Failed to load idea');
      navigate('/ideas');
    } finally {
      setLoading(false);
    }
  };

  const fetchComments = async () => {
    try {
      const data = await ideaService.getComments(Number(id));
      setComments(data);
    } catch (error) {
      console.error('Failed to fetch comments:', error);
    }
  };

  const handleLike = async () => {
    if (!idea) return;

    // Prevent users from liking their own ideas
    if (isAuthor) {
      toast.error('You cannot like your own idea');
      return;
    }

    try {
      if (idea.isLikedByCurrentUser) {
        await ideaService.unlikeIdea(idea.id);
      } else {
        await ideaService.likeIdea(idea.id);
      }
      setIdea((prev) =>
        prev
          ? {
              ...prev,
              isLikedByCurrentUser: !prev.isLikedByCurrentUser,
              likeCount: prev.isLikedByCurrentUser
                ? prev.likeCount - 1
                : prev.likeCount + 1,
            }
          : null
      );
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to update like';
      toast.error(message);
    }
  };

  const handleCommentSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newComment.trim() || newComment.length > 200) return;

    setSubmittingComment(true);
    try {
      const comment = await ideaService.createComment(Number(id), {
        content: newComment.trim(),
      });
      setComments((prev) => [comment, ...prev]);
      setNewComment('');
      setIdea((prev) =>
        prev ? { ...prev, commentCount: prev.commentCount + 1 } : null
      );
      toast.success('Comment added');
    } catch (error) {
      toast.error('Failed to add comment');
    } finally {
      setSubmittingComment(false);
    }
  };

  const handleDeleteComment = async (commentId: number) => {
    if (!confirm('Delete this comment?')) return;

    try {
      await ideaService.deleteComment(commentId);
      setComments((prev) => prev.filter((c) => c.id !== commentId));
      setIdea((prev) =>
        prev ? { ...prev, commentCount: prev.commentCount - 1 } : null
      );
      toast.success('Comment deleted');
    } catch (error) {
      toast.error('Failed to delete comment');
    }
  };

  const handleReaction = async (commentId: number, emoji: string) => {
    try {
      await ideaService.addReaction(commentId, emoji);
      fetchComments();
    } catch (error: unknown) {
      // If 409 conflict, user already reacted - try to remove instead
      if (error && typeof error === 'object' && 'response' in error) {
        const axiosError = error as { response?: { status?: number } };
        if (axiosError.response?.status === 409) {
          try {
            await ideaService.removeReaction(commentId, emoji);
            fetchComments();
            return;
          } catch {
            toast.error('Failed to remove reaction');
            return;
          }
        }
      }
      toast.error('Failed to add reaction');
    }
  };

  const handleStatusChange = async (status: IdeaStatus, progress: number) => {
    try {
      const updated = await ideaService.updateStatus(Number(id), status, progress);
      setIdea(updated);
      setShowStatusModal(false);
      toast.success('Status updated');
    } catch (error) {
      toast.error('Failed to update status');
    }
  };

  const handleDelete = async () => {
    if (!confirm('Are you sure you want to delete this idea? This action cannot be undone.')) {
      return;
    }

    try {
      await ideaService.deleteIdea(Number(id));
      toast.success('Idea deleted');
      navigate('/ideas');
    } catch (error) {
      toast.error('Failed to delete idea');
    }
  };

  const handleDownloadFile = async (fileId: number, filename: string) => {
    try {
      const blob = await ideaService.downloadFile(Number(id), fileId);
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = filename;
      a.click();
      window.URL.revokeObjectURL(url);
    } catch (error) {
      toast.error('Failed to download file');
    }
  };

  // Checklist handlers
  const handleAddChecklistItem = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newChecklistItem.trim() || newChecklistItem.length > 200) return;

    setAddingChecklistItem(true);
    try {
      const item = await ideaService.createChecklistItem(Number(id), newChecklistItem.trim());
      setChecklistItems((prev) => [...prev, item]);
      setNewChecklistItem('');
      // Update progress in idea
      const updatedIdea = await ideaService.getIdea(Number(id));
      setIdea(updatedIdea);
      toast.success('Checklist item added');
    } catch (error) {
      toast.error('Failed to add checklist item');
    } finally {
      setAddingChecklistItem(false);
    }
  };

  const handleToggleChecklistItem = async (itemId: number) => {
    try {
      const updatedItem = await ideaService.toggleChecklistItem(Number(id), itemId);
      setChecklistItems((prev) =>
        prev.map((item) => (item.id === itemId ? updatedItem : item))
      );
      // Update progress in idea
      const updatedIdea = await ideaService.getIdea(Number(id));
      setIdea(updatedIdea);
    } catch (error) {
      toast.error('Failed to update checklist item');
    }
  };

  const handleDeleteChecklistItem = async (itemId: number) => {
    if (!confirm('Delete this checklist item?')) return;

    try {
      await ideaService.deleteChecklistItem(Number(id), itemId);
      setChecklistItems((prev) => prev.filter((item) => item.id !== itemId));
      // Update progress in idea
      const updatedIdea = await ideaService.getIdea(Number(id));
      setIdea(updatedIdea);
      toast.success('Checklist item deleted');
    } catch (error) {
      toast.error('Failed to delete checklist item');
    }
  };

  // Calculate checklist progress
  const checklistProgress = checklistItems.length > 0
    ? Math.round((checklistItems.filter((item) => item.isCompleted).length / checklistItems.length) * 100)
    : 0;

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary-600" />
      </div>
    );
  }

  if (!idea) {
    return (
      <div className="text-center py-12">
        <h2 className="text-xl font-semibold text-gray-900 dark:text-white">Idea not found</h2>
        <Link to="/ideas" className="link mt-4 inline-block">
          Back to Ideas
        </Link>
      </div>
    );
  }

  const getStatusClass = (status: IdeaStatus) => {
    switch (status) {
      case 'COMPLETED':
        return 'badge-success';
      case 'IN_PROGRESS':
        return 'badge-warning';
      default:
        return 'badge-gray';
    }
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Back button */}
      <Link
        to="/ideas"
        className="inline-flex items-center gap-2 text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
      >
        <ArrowLeftIcon className="w-4 h-4" />
        Back to Ideas
      </Link>

      {/* Main content card */}
      <article className="card">
        {/* Header */}
        <div className="p-6 border-b border-gray-100 dark:border-gray-700">
          <div className="flex items-start justify-between mb-4">
            <div className="flex items-center gap-3">
              <span className={getStatusClass(idea.status)}>
                {idea.status.replace('_', ' ')}
              </span>
              <span className="badge-gray">{idea.category}</span>
            </div>
            <div className="flex items-center gap-2">
              {(isAuthor || canDelete) && (
                <Link
                  to={`/ideas/${idea.id}/edit`}
                  className="btn-icon"
                  title="Edit"
                >
                  <PencilIcon className="w-5 h-5" />
                </Link>
              )}
              {canDelete && (
                <button
                  onClick={handleDelete}
                  className="btn-icon text-error-500 hover:bg-error-50 dark:hover:bg-error-900/20"
                  title="Delete"
                >
                  <TrashIcon className="w-5 h-5" />
                </button>
              )}
            </div>
          </div>

          <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
            {idea.title}
          </h1>

          {/* Author info */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="avatar-md">
                {idea.author.firstName?.[0]}{idea.author.lastName?.[0]}
              </div>
              <div>
                <p className="font-medium text-gray-900 dark:text-white">
                  {idea.author.firstName} {idea.author.lastName}
                </p>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  {format(new Date(idea.createdAt), 'MMMM d, yyyy')}
                </p>
              </div>
            </div>
            {!isAuthor && (
              <Link
                to={`/messages?user=${idea.author.id}`}
                className="btn-secondary flex items-center gap-2"
              >
                <EnvelopeIcon className="w-4 h-4" />
                Message Creator
              </Link>
            )}
          </div>
        </div>

        {/* Description */}
        <div className="p-6 border-b border-gray-100 dark:border-gray-700">
          <p className="text-gray-700 dark:text-gray-300 whitespace-pre-wrap">
            {idea.description}
          </p>

          {/* Tags */}
          <div className="flex flex-wrap gap-2 mt-6">
            {idea.tags.map((tag) => (
              <span key={tag} className="badge-primary">
                #{tag}
              </span>
            ))}
          </div>
        </div>

        {/* Checklist Section */}
        <div className="p-6 border-b border-gray-100 dark:border-gray-700">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-medium text-gray-900 dark:text-white flex items-center gap-2">
              <ClipboardDocumentListIcon className="w-5 h-5" />
              Checklist
              {checklistItems.length > 0 && (
                <span className="text-sm font-normal text-gray-500 dark:text-gray-400">
                  ({checklistItems.filter((item) => item.isCompleted).length}/{checklistItems.length})
                </span>
              )}
            </h3>
            {checklistItems.length > 0 && (
              <span className="text-sm font-medium text-primary-600">{checklistProgress}%</span>
            )}
          </div>

          {/* Progress bar for checklist */}
          {checklistItems.length > 0 && (
            <div className="progress-bar h-2 mb-4">
              <div
                className="progress-bar-fill bg-primary-500 transition-all duration-300"
                style={{ width: `${checklistProgress}%` }}
              />
            </div>
          )}

          {/* Checklist items */}
          <div className="space-y-2">
            {checklistItems.length === 0 && !isAuthor && (
              <p className="text-gray-500 dark:text-gray-400 text-sm">No checklist items yet.</p>
            )}
            {checklistItems.map((item) => (
              <div
                key={item.id}
                className={`flex items-center gap-3 p-3 rounded-lg transition-colors ${
                  item.isCompleted
                    ? 'bg-success-50 dark:bg-success-900/20'
                    : 'bg-gray-50 dark:bg-gray-700/50'
                }`}
              >
                {isAuthor ? (
                  <button
                    onClick={() => handleToggleChecklistItem(item.id)}
                    className="flex-shrink-0 focus:outline-none"
                    title="Toggle completion"
                  >
                    {item.isCompleted ? (
                      <CheckCircleSolidIcon className="w-6 h-6 text-success-500" />
                    ) : (
                      <CheckCircleIcon className="w-6 h-6 text-gray-400 hover:text-primary-500" />
                    )}
                  </button>
                ) : (
                  <div className="flex-shrink-0">
                    {item.isCompleted ? (
                      <CheckCircleSolidIcon className="w-6 h-6 text-success-500" />
                    ) : (
                      <CheckCircleIcon className="w-6 h-6 text-gray-400" />
                    )}
                  </div>
                )}
                <span
                  className={`flex-1 ${
                    item.isCompleted
                      ? 'text-gray-500 dark:text-gray-400 line-through'
                      : 'text-gray-900 dark:text-white'
                  }`}
                >
                  {item.title}
                </span>
                {isAuthor && (
                  <button
                    onClick={() => handleDeleteChecklistItem(item.id)}
                    className="btn-icon text-gray-400 hover:text-error-500 flex-shrink-0"
                    title="Delete item"
                  >
                    <TrashIcon className="w-4 h-4" />
                  </button>
                )}
              </div>
            ))}
          </div>

          {/* Add new checklist item (only for author) */}
          {isAuthor && (
            <form onSubmit={handleAddChecklistItem} className="mt-4">
              <div className="flex gap-2">
                <input
                  type="text"
                  value={newChecklistItem}
                  onChange={(e) => setNewChecklistItem(e.target.value)}
                  placeholder="Add a checklist item..."
                  maxLength={200}
                  className="input flex-1"
                />
                <button
                  type="submit"
                  disabled={!newChecklistItem.trim() || addingChecklistItem}
                  className="btn-primary flex items-center gap-2"
                >
                  <PlusIcon className="w-4 h-4" />
                  {addingChecklistItem ? 'Adding...' : 'Add'}
                </button>
              </div>
              <p className="text-xs text-gray-500 mt-1">
                Only you can check off items on this checklist.
              </p>
            </form>
          )}
        </div>

        {/* Progress (for in-progress ideas) */}
        {idea.status === 'IN_PROGRESS' && (
          <div className="p-6 border-b border-gray-100 dark:border-gray-700">
            <div className="flex items-center justify-between mb-2">
              <span className="font-medium text-gray-900 dark:text-white">Progress</span>
              <span className="text-primary-600 font-bold">{idea.progressPercentage}%</span>
            </div>
            <div className="progress-bar h-3">
              <div
                className="progress-bar-fill bg-primary-500"
                style={{ width: `${idea.progressPercentage}%` }}
              />
            </div>
          </div>
        )}

        {/* File attachments */}
        {idea.attachments.length > 0 && (
          <div className="p-6 border-b border-gray-100 dark:border-gray-700">
            <h3 className="font-medium text-gray-900 dark:text-white mb-3 flex items-center gap-2">
              <PaperClipIcon className="w-5 h-5" />
              Attachments
            </h3>
            <div className="space-y-2">
              {idea.attachments.map((file) => (
                <div
                  key={file.id}
                  className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg"
                >
                  <div className="flex items-center gap-3">
                    <PaperClipIcon className="w-5 h-5 text-gray-400" />
                    <div>
                      <p className="font-medium text-gray-900 dark:text-white">
                        {file.originalName}
                      </p>
                      <p className="text-xs text-gray-500">
                        {(file.fileSize / 1024).toFixed(1)} KB
                      </p>
                    </div>
                  </div>
                  <button
                    onClick={() => handleDownloadFile(file.id, file.originalName)}
                    className="btn-icon"
                    title="Download"
                  >
                    <ArrowDownTrayIcon className="w-5 h-5" />
                  </button>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Actions */}
        <div className="p-6 flex items-center justify-between">
          <div className="flex items-center gap-4">
            {isAuthor ? (
              <span
                className="flex items-center gap-2 px-4 py-2 rounded-lg font-medium bg-gray-100 dark:bg-gray-700 text-gray-400 dark:text-gray-500 cursor-not-allowed"
                title="You cannot like your own idea"
              >
                <HeartIcon className="w-5 h-5" />
                {idea.likeCount} {idea.likeCount === 1 ? 'Like' : 'Likes'}
              </span>
            ) : (
              <button
                onClick={handleLike}
                className={`flex items-center gap-2 px-4 py-2 rounded-lg font-medium transition-colors ${
                  idea.isLikedByCurrentUser
                    ? 'bg-red-50 dark:bg-red-900/20 text-red-600'
                    : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-red-50 dark:hover:bg-red-900/20 hover:text-red-600'
                }`}
              >
                {idea.isLikedByCurrentUser ? (
                  <HeartSolidIcon className="w-5 h-5" />
                ) : (
                  <HeartIcon className="w-5 h-5" />
                )}
                {idea.likeCount} {idea.likeCount === 1 ? 'Like' : 'Likes'}
              </button>
            )}

            <div className="flex items-center gap-2 text-gray-500 dark:text-gray-400">
              <ChatBubbleLeftIcon className="w-5 h-5" />
              {idea.commentCount} {idea.commentCount === 1 ? 'Comment' : 'Comments'}
            </div>
          </div>

          {canManageStatus && (
            <button
              onClick={() => setShowStatusModal(true)}
              className="btn-secondary"
            >
              Update Status
            </button>
          )}
        </div>
      </article>

      {/* Comments section */}
      <div className="card">
        <div className="p-6 border-b border-gray-100 dark:border-gray-700">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
            Comments ({comments.length})
          </h2>
        </div>

        {/* New comment form */}
        <form onSubmit={handleCommentSubmit} className="p-6 border-b border-gray-100 dark:border-gray-700">
          <div className="flex gap-3">
            <div className="avatar-md flex-shrink-0">
              {user?.firstName?.[0]}{user?.lastName?.[0]}
            </div>
            <div className="flex-1">
              <textarea
                value={newComment}
                onChange={(e) => setNewComment(e.target.value)}
                placeholder="Add a comment... (max 200 characters)"
                maxLength={200}
                rows={3}
                className="input resize-none"
              />
              <div className="flex items-center justify-between mt-2">
                <span className={`text-sm ${newComment.length > 180 ? 'text-warning-600' : 'text-gray-500'}`}>
                  {newComment.length}/200
                </span>
                <button
                  type="submit"
                  disabled={!newComment.trim() || submittingComment}
                  className="btn-primary"
                >
                  {submittingComment ? 'Posting...' : 'Post Comment'}
                </button>
              </div>
            </div>
          </div>
        </form>

        {/* Comments list */}
        <div className="divide-y divide-gray-100 dark:divide-gray-700">
          {comments.length === 0 ? (
            <div className="p-8 text-center text-gray-500 dark:text-gray-400">
              No comments yet. Be the first to comment!
            </div>
          ) : (
            comments.map((comment) => (
              <div key={comment.id} className="p-6">
                <div className="flex gap-3">
                  <div className="avatar-md flex-shrink-0">
                    {comment.author.firstName?.[0]}{comment.author.lastName?.[0]}
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center justify-between mb-1">
                      <div>
                        <span className="font-medium text-gray-900 dark:text-white">
                          {comment.author.firstName} {comment.author.lastName}
                        </span>
                        <span className="text-sm text-gray-500 dark:text-gray-400 ml-2">
                          {format(new Date(comment.createdAt), 'MMM d, h:mm a')}
                        </span>
                      </div>
                      {(user?.id === comment.author.id || user?.role === 'ADMIN') && (
                        <button
                          onClick={() => handleDeleteComment(comment.id)}
                          className="btn-icon text-gray-400 hover:text-error-500"
                        >
                          <TrashIcon className="w-4 h-4" />
                        </button>
                      )}
                    </div>
                    <p className="text-gray-700 dark:text-gray-300">{comment.content}</p>

                    {/* Reactions */}
                    <div className="flex items-center gap-2 mt-3">
                      {EMOJI_LIST.map((emoji) => {
                        const reaction = comment.reactions.find((r) => r.emoji === emoji);
                        return (
                          <button
                            key={emoji}
                            onClick={() => handleReaction(comment.id, emoji)}
                            className={`px-2 py-1 rounded-full text-sm flex items-center gap-1 transition-colors ${
                              reaction && reaction.count > 0
                                ? 'bg-primary-50 dark:bg-primary-900/20'
                                : 'bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600'
                            }`}
                          >
                            {EMOJI_DISPLAY[emoji]}
                            {reaction && reaction.count > 0 && (
                              <span className="text-xs">{reaction.count}</span>
                            )}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Status Modal */}
      {showStatusModal && (
        <StatusModal
          currentStatus={idea.status}
          currentProgress={idea.progressPercentage}
          onSave={handleStatusChange}
          onClose={() => setShowStatusModal(false)}
        />
      )}
    </div>
  );
}

interface StatusModalProps {
  currentStatus: IdeaStatus;
  currentProgress: number;
  onSave: (status: IdeaStatus, progress: number) => void;
  onClose: () => void;
}

function StatusModal({ currentStatus, currentProgress, onSave, onClose }: StatusModalProps) {
  const [status, setStatus] = useState(currentStatus);
  const [progress, setProgress] = useState(currentProgress);

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content p-6" onClick={(e) => e.stopPropagation()}>
        <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-6">
          Update Status
        </h2>

        <div className="space-y-4">
          <div>
            <label className="label">Status</label>
            <select
              value={status}
              onChange={(e) => {
                const newStatus = e.target.value as IdeaStatus;
                setStatus(newStatus);
                if (newStatus === 'COMPLETED') setProgress(100);
                if (newStatus === 'CONCEPT') setProgress(0);
              }}
              className="input"
            >
              <option value="CONCEPT">Concept</option>
              <option value="IN_PROGRESS">In Progress</option>
              <option value="COMPLETED">Completed</option>
            </select>
          </div>

          {status === 'IN_PROGRESS' && (
            <div>
              <label className="label">Progress ({progress}%)</label>
              <input
                type="range"
                min="0"
                max="100"
                value={progress}
                onChange={(e) => setProgress(Number(e.target.value))}
                className="w-full"
              />
            </div>
          )}
        </div>

        <div className="flex justify-end gap-3 mt-6">
          <button onClick={onClose} className="btn-secondary">
            Cancel
          </button>
          <button onClick={() => onSave(status, progress)} className="btn-primary">
            Save Changes
          </button>
        </div>
      </div>
    </div>
  );
}
