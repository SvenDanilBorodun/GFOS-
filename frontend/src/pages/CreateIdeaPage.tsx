import { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useDropzone } from 'react-dropzone';
import { XMarkIcon, PaperClipIcon, ArrowLeftIcon } from '@heroicons/react/24/outline';
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
  const [files, setFiles] = useState<File[]>([]);
  const [existingFiles, setExistingFiles] = useState<{ id: number; name: string }[]>([]);
  const [errors, setErrors] = useState<Record<string, string>>({});

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
        idea.attachments.map((a) => ({ id: a.id, name: a.originalName }))
      );
    } catch (error) {
      toast.error('Failed to load idea');
      navigate('/ideas');
    } finally {
      setLoadingIdea(false);
    }
  };

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop: (acceptedFiles) => {
      const validFiles = acceptedFiles.filter((file) => {
        if (file.size > MAX_FILE_SIZE) {
          toast.error(`${file.name} is too large (max 10MB)`);
          return false;
        }
        return true;
      });
      setFiles((prev) => [...prev, ...validFiles]);
    },
    accept: {
      'image/*': ['.png', '.jpg', '.jpeg', '.gif'],
      'application/pdf': ['.pdf'],
      'application/msword': ['.doc'],
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document': ['.docx'],
    },
    maxSize: MAX_FILE_SIZE,
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

      // Upload new files
      for (const file of files) {
        await ideaService.uploadFile(idea.id, file);
      }

      toast.success(isEditing ? 'Idea updated!' : 'Idea submitted!');
      navigate(`/ideas/${idea.id}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to save idea';
      toast.error(message);
    } finally {
      setLoading(false);
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
    setFiles((prev) => prev.filter((_, i) => i !== index));
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

          {/* Existing files */}
          {existingFiles.length > 0 && (
            <div className="space-y-2 mb-3">
              {existingFiles.map((file) => (
                <div
                  key={file.id}
                  className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg"
                >
                  <div className="flex items-center gap-2">
                    <PaperClipIcon className="w-5 h-5 text-gray-400" />
                    <span className="text-sm text-gray-700 dark:text-gray-300">{file.name}</span>
                  </div>
                  <button
                    type="button"
                    onClick={() => handleRemoveExistingFile(file.id)}
                    className="text-gray-400 hover:text-error-500"
                  >
                    <XMarkIcon className="w-5 h-5" />
                  </button>
                </div>
              ))}
            </div>
          )}

          {/* New files */}
          {files.length > 0 && (
            <div className="space-y-2 mb-3">
              {files.map((file, index) => (
                <div
                  key={index}
                  className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg"
                >
                  <div className="flex items-center gap-2">
                    <PaperClipIcon className="w-5 h-5 text-gray-400" />
                    <span className="text-sm text-gray-700 dark:text-gray-300">{file.name}</span>
                    <span className="text-xs text-gray-500">
                      ({(file.size / 1024).toFixed(1)} KB)
                    </span>
                  </div>
                  <button
                    type="button"
                    onClick={() => handleRemoveFile(index)}
                    className="text-gray-400 hover:text-error-500"
                  >
                    <XMarkIcon className="w-5 h-5" />
                  </button>
                </div>
              ))}
            </div>
          )}

          {/* Dropzone */}
          <div
            {...getRootProps()}
            className={`border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition-colors
                       ${
                         isDragActive
                           ? 'border-primary-500 bg-primary-50 dark:bg-primary-900/20'
                           : 'border-gray-300 dark:border-gray-600 hover:border-primary-400'
                       }`}
          >
            <input {...getInputProps()} />
            <PaperClipIcon className="w-10 h-10 text-gray-400 mx-auto mb-3" />
            <p className="text-gray-600 dark:text-gray-400">
              {isDragActive
                ? 'Drop files here...'
                : 'Drag & drop files here, or click to select'}
            </p>
            <p className="text-xs text-gray-500 mt-1">
              Supports images, PDF, Word (max 10MB each)
            </p>
          </div>
        </div>

        {/* Submit buttons */}
        <div className="flex items-center justify-end gap-3 pt-4 border-t border-gray-100 dark:border-gray-700">
          <button
            type="button"
            onClick={() => navigate(-1)}
            className="btn-secondary"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={loading}
            className="btn-primary"
          >
            {loading ? (
              <div className="animate-spin rounded-full h-5 w-5 border-t-2 border-b-2 border-white" />
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
