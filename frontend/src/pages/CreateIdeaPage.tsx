import { useState, useEffect, useCallback } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useDropzone } from 'react-dropzone';
import {
  XMarkIcon,
  PaperClipIcon,
  ArrowLeftIcon,
  DocumentIcon,
  PhotoIcon,
  DocumentTextIcon,
  TableCellsIcon,
  CloudArrowUpIcon,
  CheckCircleIcon,
  ExclamationCircleIcon
} from '@heroicons/react/24/outline';
import { ideaService } from '../services/ideaService';
import { Idea } from '../types';
import toast from 'react-hot-toast';

const CATEGORIES = [
  'Technology',
  'Sustainability',
  'HR',
  'Customer Experience',
  'Operations',
  'Marketing',
  'Finance',
  'Other',
];

const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

// File type configurations
const FILE_TYPE_CONFIG: Record<string, { icon: React.ComponentType<{ className?: string }>; color: string; label: string }> = {
  'image/jpeg': { icon: PhotoIcon, color: 'text-blue-500', label: 'Image' },
  'image/png': { icon: PhotoIcon, color: 'text-blue-500', label: 'Image' },
  'image/gif': { icon: PhotoIcon, color: 'text-blue-500', label: 'Image' },
  'image/webp': { icon: PhotoIcon, color: 'text-blue-500', label: 'Image' },
  'application/pdf': { icon: DocumentTextIcon, color: 'text-red-500', label: 'PDF' },
  'application/msword': { icon: DocumentIcon, color: 'text-blue-600', label: 'Word' },
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document': { icon: DocumentIcon, color: 'text-blue-600', label: 'Word' },
  'application/vnd.ms-excel': { icon: TableCellsIcon, color: 'text-green-600', label: 'Excel' },
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': { icon: TableCellsIcon, color: 'text-green-600', label: 'Excel' },
  'text/plain': { icon: DocumentTextIcon, color: 'text-gray-500', label: 'Text' },
  'text/csv': { icon: TableCellsIcon, color: 'text-green-500', label: 'CSV' },
};

interface FileWithPreview extends File {
  preview?: string;
}

interface UploadStatus {
  status: 'pending' | 'uploading' | 'success' | 'error';
  error?: string;
}

export default function CreateIdeaPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const isEditing = !!id;

  const [loading, setLoading] = useState(false);
  const [loadingIdea, setLoadingIdea] = useState(isEditing);
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    category: '',
    tags: [] as string[],
  });
  const [tagInput, setTagInput] = useState('');
  const [files, setFiles] = useState<FileWithPreview[]>([]);
  const [uploadStatuses, setUploadStatuses] = useState<Map<string, UploadStatus>>(new Map());
  const [existingFiles, setExistingFiles] = useState<{ id: number; name: string; mimeType?: string }[]>([]);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isUploading, setIsUploading] = useState(false);

  useEffect(() => {
    if (isEditing) {
      fetchIdea();
    }
  }, [id]);

  const fetchIdea = async () => {
    try {
      const idea = await ideaService.getIdea(Number(id));
      setFormData({
        title: idea.title,
        description: idea.description,
        category: idea.category,
        tags: idea.tags,
      });
      setExistingFiles(
        idea.attachments.map((a) => ({ id: a.id, name: a.originalName, mimeType: a.mimeType }))
      );
    } catch (error) {
      toast.error('Failed to load idea');
      navigate('/ideas');
    } finally {
      setLoadingIdea(false);
    }
  };

  // Clean up previews when component unmounts
  useEffect(() => {
    return () => {
      files.forEach(file => {
        if (file.preview) URL.revokeObjectURL(file.preview);
      });
    };
  }, [files]);

  const onDrop = useCallback((acceptedFiles: File[], rejectedFiles: any[]) => {
    // Handle rejected files
    rejectedFiles.forEach(({ file, errors }) => {
      const errorMessages = errors.map((e: any) => {
        if (e.code === 'file-too-large') return 'File is too large (max 10MB)';
        if (e.code === 'file-invalid-type') return 'File type not supported';
        return e.message;
      }).join(', ');
      toast.error(`${file.name}: ${errorMessages}`);
    });

    // Process accepted files with previews
    const filesWithPreviews = acceptedFiles.map(file => {
      const fileWithPreview = file as FileWithPreview;
      if (file.type.startsWith('image/')) {
        fileWithPreview.preview = URL.createObjectURL(file);
      }
      return fileWithPreview;
    });

    setFiles(prev => [...prev, ...filesWithPreviews]);
  }, []);

  const { getRootProps, getInputProps, isDragActive, isDragReject } = useDropzone({
    onDrop,
    accept: {
      'image/*': ['.png', '.jpg', '.jpeg', '.gif', '.webp'],
      'application/pdf': ['.pdf'],
      'application/msword': ['.doc'],
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document': ['.docx'],
      'application/vnd.ms-excel': ['.xls'],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': ['.xlsx'],
      'text/plain': ['.txt'],
      'text/csv': ['.csv'],
    },
    maxSize: MAX_FILE_SIZE,
    multiple: true,
  });

  const validate = () => {
    const newErrors: Record<string, string> = {};

    if (!formData.title.trim()) {
      newErrors.title = 'Title is required';
    } else if (formData.title.length > 200) {
      newErrors.title = 'Title must be less than 200 characters';
    }

    if (!formData.description.trim()) {
      newErrors.description = 'Description is required';
    }

    if (!formData.category) {
      newErrors.category = 'Please select a category';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;

    setLoading(true);
    try {
      let idea: Idea;

      if (isEditing) {
        idea = await ideaService.updateIdea(Number(id), formData);
      } else {
        idea = await ideaService.createIdea(formData);
      }

      // Upload new files with progress tracking
      if (files.length > 0) {
        setIsUploading(true);
        const newStatuses = new Map<string, UploadStatus>();
        files.forEach(file => newStatuses.set(file.name, { status: 'pending' }));
        setUploadStatuses(newStatuses);

        let successCount = 0;
        let errorCount = 0;

        for (const file of files) {
          setUploadStatuses(prev => {
            const updated = new Map(prev);
            updated.set(file.name, { status: 'uploading' });
            return updated;
          });

          try {
            await ideaService.uploadFile(idea.id, file);
            setUploadStatuses(prev => {
              const updated = new Map(prev);
              updated.set(file.name, { status: 'success' });
              return updated;
            });
            successCount++;
          } catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Upload failed';
            setUploadStatuses(prev => {
              const updated = new Map(prev);
              updated.set(file.name, { status: 'error', error: errorMessage });
              return updated;
            });
            errorCount++;
          }
        }

        setIsUploading(false);

        if (errorCount > 0) {
          toast.error(`${errorCount} file(s) failed to upload`);
        }
        if (successCount > 0) {
          toast.success(`${successCount} file(s) uploaded successfully`);
        }
      }

      toast.success(isEditing ? 'Idea updated!' : 'Idea submitted!');
      navigate(`/ideas/${idea.id}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to save idea';
      toast.error(message);
    } finally {
      setLoading(false);
      setIsUploading(false);
    }
  };

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>
  ) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    if (errors[name]) {
      setErrors((prev) => ({ ...prev, [name]: '' }));
    }
  };

  const handleAddTag = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' || e.key === ',') {
      e.preventDefault();
      const tag = tagInput.trim().toLowerCase().replace(/[^a-z0-9-]/g, '');
      if (tag && !formData.tags.includes(tag) && formData.tags.length < 5) {
        setFormData((prev) => ({ ...prev, tags: [...prev.tags, tag] }));
      }
      setTagInput('');
    }
  };

  const handleRemoveTag = (tagToRemove: string) => {
    setFormData((prev) => ({
      ...prev,
      tags: prev.tags.filter((tag) => tag !== tagToRemove),
    }));
  };

  const handleRemoveFile = (index: number) => {
    const fileToRemove = files[index];
    if (fileToRemove.preview) {
      URL.revokeObjectURL(fileToRemove.preview);
    }
    setFiles((prev) => prev.filter((_, i) => i !== index));
    setUploadStatuses(prev => {
      const updated = new Map(prev);
      updated.delete(fileToRemove.name);
      return updated;
    });
  };

  const getFileIcon = (mimeType?: string) => {
    if (!mimeType) return { Icon: PaperClipIcon, color: 'text-gray-400' };
    const config = FILE_TYPE_CONFIG[mimeType];
    if (config) return { Icon: config.icon, color: config.color };
    if (mimeType.startsWith('image/')) return { Icon: PhotoIcon, color: 'text-blue-500' };
    return { Icon: DocumentIcon, color: 'text-gray-400' };
  };

  const formatFileSize = (bytes: number) => {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
    return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
  };

  const handleRemoveExistingFile = async (fileId: number) => {
    try {
      await ideaService.deleteFile(Number(id), fileId);
      setExistingFiles((prev) => prev.filter((f) => f.id !== fileId));
      toast.success('File removed');
    } catch (error) {
      toast.error('Failed to remove file');
    }
  };

  if (loadingIdea) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary-600" />
      </div>
    );
  }

  return (
    <div className="max-w-2xl mx-auto">
      {/* Header */}
      <div className="mb-6">
        <button
          onClick={() => navigate(-1)}
          className="inline-flex items-center gap-2 text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors mb-4"
        >
          <ArrowLeftIcon className="w-4 h-4" />
          Back
        </button>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
          {isEditing ? 'Edit Idea' : 'Submit New Idea'}
        </h1>
        <p className="text-gray-600 dark:text-gray-400">
          {isEditing
            ? 'Update your innovation idea'
            : 'Share your innovation idea with the team'}
        </p>
      </div>

      <form onSubmit={handleSubmit} className="card p-6 space-y-6">
        {/* Title */}
        <div className="form-group">
          <label htmlFor="title" className="label">
            Title <span className="text-error-500">*</span>
          </label>
          <input
            type="text"
            id="title"
            name="title"
            value={formData.title}
            onChange={handleChange}
            className={errors.title ? 'input-error' : 'input'}
            placeholder="A clear, concise title for your idea"
          />
          {errors.title && <p className="form-error">{errors.title}</p>}
        </div>

        {/* Category */}
        <div className="form-group">
          <label htmlFor="category" className="label">
            Category <span className="text-error-500">*</span>
          </label>
          <select
            id="category"
            name="category"
            value={formData.category}
            onChange={handleChange}
            className={errors.category ? 'input-error' : 'input'}
          >
            <option value="">Select a category</option>
            {CATEGORIES.map((cat) => (
              <option key={cat} value={cat}>
                {cat}
              </option>
            ))}
          </select>
          {errors.category && <p className="form-error">{errors.category}</p>}
        </div>

        {/* Description */}
        <div className="form-group">
          <label htmlFor="description" className="label">
            Description <span className="text-error-500">*</span>
          </label>
          <textarea
            id="description"
            name="description"
            value={formData.description}
            onChange={handleChange}
            rows={6}
            className={errors.description ? 'input-error' : 'input'}
            placeholder="Describe your idea in detail. What problem does it solve? What benefits would it bring?"
          />
          {errors.description && <p className="form-error">{errors.description}</p>}
        </div>

        {/* Tags */}
        <div className="form-group">
          <label htmlFor="tags" className="label">
            Tags (max 5)
          </label>
          <div className="flex flex-wrap gap-2 mb-2">
            {formData.tags.map((tag) => (
              <span
                key={tag}
                className="inline-flex items-center gap-1 px-2 py-1 bg-primary-100 dark:bg-primary-900/30 text-primary-700 dark:text-primary-300 rounded-full text-sm"
              >
                #{tag}
                <button
                  type="button"
                  onClick={() => handleRemoveTag(tag)}
                  className="hover:text-primary-900 dark:hover:text-primary-100"
                >
                  <XMarkIcon className="w-4 h-4" />
                </button>
              </span>
            ))}
          </div>
          <input
            type="text"
            id="tags"
            value={tagInput}
            onChange={(e) => setTagInput(e.target.value)}
            onKeyDown={handleAddTag}
            className="input"
            placeholder="Type a tag and press Enter"
            disabled={formData.tags.length >= 5}
          />
          <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
            Press Enter or comma to add a tag
          </p>
        </div>

        {/* File Upload */}
        <div className="form-group">
          <label className="label">Attachments</label>
          <p className="text-xs text-gray-500 dark:text-gray-400 mb-3">
            Add documents, images, or spreadsheets to support your idea
          </p>

          {/* Existing files */}
          {existingFiles.length > 0 && (
            <div className="space-y-2 mb-4">
              <p className="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide">
                Current Attachments
              </p>
              {existingFiles.map((file) => {
                const { Icon, color } = getFileIcon(file.mimeType);
                return (
                  <div
                    key={file.id}
                    className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg border border-gray-200 dark:border-gray-600"
                  >
                    <div className="flex items-center gap-3">
                      <div className={`p-2 rounded-lg bg-white dark:bg-gray-800 ${color}`}>
                        <Icon className="w-5 h-5" />
                      </div>
                      <span className="text-sm font-medium text-gray-700 dark:text-gray-300 truncate max-w-[200px]">
                        {file.name}
                      </span>
                    </div>
                    <button
                      type="button"
                      onClick={() => handleRemoveExistingFile(file.id)}
                      className="p-1 text-gray-400 hover:text-error-500 hover:bg-error-50 dark:hover:bg-error-900/20 rounded transition-colors"
                      title="Remove file"
                    >
                      <XMarkIcon className="w-5 h-5" />
                    </button>
                  </div>
                );
              })}
            </div>
          )}

          {/* New files */}
          {files.length > 0 && (
            <div className="space-y-2 mb-4">
              <p className="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide">
                Files to Upload ({files.length})
              </p>
              <div className="grid gap-2">
                {files.map((file, index) => {
                  const { Icon, color } = getFileIcon(file.type);
                  const uploadStatus = uploadStatuses.get(file.name);
                  const isImage = file.type.startsWith('image/');

                  return (
                    <div
                      key={`${file.name}-${index}`}
                      className={`flex items-center justify-between p-3 rounded-lg border transition-all
                        ${uploadStatus?.status === 'error'
                          ? 'bg-error-50 dark:bg-error-900/20 border-error-300 dark:border-error-700'
                          : uploadStatus?.status === 'success'
                          ? 'bg-success-50 dark:bg-success-900/20 border-success-300 dark:border-success-700'
                          : 'bg-gray-50 dark:bg-gray-700/50 border-gray-200 dark:border-gray-600'
                        }`}
                    >
                      <div className="flex items-center gap-3 flex-1 min-w-0">
                        {/* Image preview or file icon */}
                        {isImage && file.preview ? (
                          <div className="w-12 h-12 rounded-lg overflow-hidden flex-shrink-0 bg-gray-100 dark:bg-gray-800">
                            <img
                              src={file.preview}
                              alt={file.name}
                              className="w-full h-full object-cover"
                            />
                          </div>
                        ) : (
                          <div className={`p-2 rounded-lg bg-white dark:bg-gray-800 flex-shrink-0 ${color}`}>
                            <Icon className="w-5 h-5" />
                          </div>
                        )}
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium text-gray-700 dark:text-gray-300 truncate">
                            {file.name}
                          </p>
                          <p className="text-xs text-gray-500 dark:text-gray-400">
                            {formatFileSize(file.size)}
                            {uploadStatus?.error && (
                              <span className="text-error-600 dark:text-error-400 ml-2">
                                - {uploadStatus.error}
                              </span>
                            )}
                          </p>
                        </div>
                      </div>

                      {/* Status indicators */}
                      <div className="flex items-center gap-2 ml-2">
                        {uploadStatus?.status === 'uploading' && (
                          <div className="animate-spin rounded-full h-5 w-5 border-2 border-primary-500 border-t-transparent" />
                        )}
                        {uploadStatus?.status === 'success' && (
                          <CheckCircleIcon className="w-5 h-5 text-success-500" />
                        )}
                        {uploadStatus?.status === 'error' && (
                          <ExclamationCircleIcon className="w-5 h-5 text-error-500" />
                        )}
                        {(!uploadStatus || uploadStatus.status === 'pending') && !isUploading && (
                          <button
                            type="button"
                            onClick={() => handleRemoveFile(index)}
                            className="p-1 text-gray-400 hover:text-error-500 hover:bg-error-50 dark:hover:bg-error-900/20 rounded transition-colors"
                            title="Remove file"
                          >
                            <XMarkIcon className="w-5 h-5" />
                          </button>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* Dropzone */}
          <div
            {...getRootProps()}
            className={`border-2 border-dashed rounded-xl p-8 text-center cursor-pointer transition-all
              ${isDragReject
                ? 'border-error-500 bg-error-50 dark:bg-error-900/20'
                : isDragActive
                ? 'border-primary-500 bg-primary-50 dark:bg-primary-900/20 scale-[1.02]'
                : 'border-gray-300 dark:border-gray-600 hover:border-primary-400 hover:bg-gray-50 dark:hover:bg-gray-800/50'
              }`}
          >
            <input {...getInputProps()} />
            <div className="flex flex-col items-center">
              <div className={`p-3 rounded-full mb-3 transition-colors
                ${isDragActive
                  ? 'bg-primary-100 dark:bg-primary-900/50'
                  : 'bg-gray-100 dark:bg-gray-800'
                }`}>
                <CloudArrowUpIcon className={`w-8 h-8 transition-colors
                  ${isDragActive
                    ? 'text-primary-600 dark:text-primary-400'
                    : 'text-gray-400'
                  }`}
                />
              </div>
              <p className="text-gray-700 dark:text-gray-300 font-medium">
                {isDragReject
                  ? 'File type not supported'
                  : isDragActive
                  ? 'Drop files here...'
                  : 'Drag & drop files here'}
              </p>
              <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                or <span className="text-primary-600 dark:text-primary-400 font-medium">browse</span> to select
              </p>
              <div className="flex flex-wrap justify-center gap-2 mt-4">
                <span className="inline-flex items-center px-2 py-1 rounded-full text-xs bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400">
                  <PhotoIcon className="w-3 h-3 mr-1" /> Images
                </span>
                <span className="inline-flex items-center px-2 py-1 rounded-full text-xs bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400">
                  <DocumentTextIcon className="w-3 h-3 mr-1" /> PDF
                </span>
                <span className="inline-flex items-center px-2 py-1 rounded-full text-xs bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400">
                  <DocumentIcon className="w-3 h-3 mr-1" /> Word
                </span>
                <span className="inline-flex items-center px-2 py-1 rounded-full text-xs bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400">
                  <TableCellsIcon className="w-3 h-3 mr-1" /> Excel
                </span>
              </div>
              <p className="text-xs text-gray-400 mt-3">
                Max 10MB per file
              </p>
            </div>
          </div>
        </div>

        {/* Submit buttons */}
        <div className="flex items-center justify-end gap-3 pt-4 border-t border-gray-100 dark:border-gray-700">
          <button
            type="button"
            onClick={() => navigate(-1)}
            className="btn-secondary"
            disabled={loading || isUploading}
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={loading || isUploading}
            className="btn-primary min-w-[140px]"
          >
            {loading || isUploading ? (
              <div className="flex items-center gap-2">
                <div className="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent" />
                <span>{isUploading ? 'Uploading...' : 'Saving...'}</span>
              </div>
            ) : isEditing ? (
              'Update Idea'
            ) : (
              'Submit Idea'
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
