import React, { useState, useRef, useEffect } from 'react';
import { 
  Send, Paperclip, Image as ImageIcon, Smile, 
  X, Loader2, Mic, MicOff, Camera
} from 'lucide-react';

interface ChatInputProps {
  onSendMessage: (content: string) => Promise<void>;
  onSendImage?: (file: File) => Promise<void>;
  onTyping?: (isTyping: boolean) => void;
  disabled?: boolean;
  placeholder?: string;
  maxLength?: number;
}

const EMOJI_LIST = ['😀', '😂', '😍', '🥰', '😊', '🙏', '👍', '❤️', '🔥', '✨', '💯', '🎉', '😎', '🤔', '👏', '💪'];

export const ChatInput: React.FC<ChatInputProps> = ({
  onSendMessage,
  onSendImage,
  onTyping,
  disabled = false,
  placeholder = 'Type your message...',
  maxLength = 2000,
}) => {
  const [message, setMessage] = useState('');
  const [sending, setSending] = useState(false);
  const [showEmoji, setShowEmoji] = useState(false);
  const [showAttachment, setShowAttachment] = useState(false);
  const [selectedImage, setSelectedImage] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [uploadProgress, setUploadProgress] = useState(0);
  
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const typingTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    return () => {
      if (imagePreview) {
        URL.revokeObjectURL(imagePreview);
      }
      if (typingTimeoutRef.current) {
        clearTimeout(typingTimeoutRef.current);
      }
    };
  }, [imagePreview]);

  const handleInputChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    const value = e.target.value;
    if (value.length <= maxLength) {
      setMessage(value);
      
      // Handle typing indicator
      if (onTyping) {
        onTyping(true);
        
        if (typingTimeoutRef.current) {
          clearTimeout(typingTimeoutRef.current);
        }
        
        typingTimeoutRef.current = setTimeout(() => {
          onTyping(false);
        }, 2000);
      }
    }
    
    // Auto-resize textarea
    if (inputRef.current) {
      inputRef.current.style.height = 'auto';
      inputRef.current.style.height = `${Math.min(inputRef.current.scrollHeight, 120)}px`;
    }
  };

  const handleSend = async () => {
    if ((!message.trim() && !selectedImage) || sending || disabled) return;

    setSending(true);
    try {
      if (selectedImage && onSendImage) {
        await onSendImage(selectedImage);
        clearImagePreview();
      }
      
      if (message.trim()) {
        await onSendMessage(message.trim());
        setMessage('');
        if (inputRef.current) {
          inputRef.current.style.height = 'auto';
        }
      }
    } catch (error) {
      console.error('Failed to send message:', error);
    } finally {
      setSending(false);
      onTyping?.(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const handleImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Validate file
    if (!file.type.startsWith('image/')) {
      alert('Please select an image file');
      return;
    }

    if (file.size > 10 * 1024 * 1024) { // 10MB limit
      alert('Image size must be less than 10MB');
      return;
    }

    setSelectedImage(file);
    setImagePreview(URL.createObjectURL(file));
    setShowAttachment(false);
  };

  const clearImagePreview = () => {
    if (imagePreview) {
      URL.revokeObjectURL(imagePreview);
    }
    setSelectedImage(null);
    setImagePreview(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const insertEmoji = (emoji: string) => {
    const newMessage = message + emoji;
    if (newMessage.length <= maxLength) {
      setMessage(newMessage);
      inputRef.current?.focus();
    }
    setShowEmoji(false);
  };

  const charCount = message.length;
  const isNearLimit = charCount > maxLength * 0.9;

  return (
    <div className="relative">
      {/* Image Preview */}
      {imagePreview && (
        <div className="px-4 py-3 border-t border-slate-200 bg-slate-50">
          <div className="relative inline-block">
            <img
              src={imagePreview}
              alt="Preview"
              className="h-24 w-auto rounded-lg object-cover"
            />
            <button
              onClick={clearImagePreview}
              className="absolute -top-2 -right-2 p-1 bg-red-500 text-white rounded-full shadow-lg hover:bg-red-600 transition-colors"
            >
              <X className="w-4 h-4" />
            </button>
            {uploadProgress > 0 && uploadProgress < 100 && (
              <div className="absolute inset-0 bg-black/50 rounded-lg flex items-center justify-center">
                <div className="text-white text-sm font-semibold">{uploadProgress}%</div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Emoji Picker */}
      {showEmoji && (
        <div className="absolute bottom-full left-0 mb-2 bg-white rounded-xl shadow-xl border border-slate-200 p-3 z-20">
          <div className="grid grid-cols-8 gap-2">
            {EMOJI_LIST.map((emoji) => (
              <button
                key={emoji}
                onClick={() => insertEmoji(emoji)}
                className="text-2xl hover:bg-slate-100 rounded-lg p-1 transition-colors"
              >
                {emoji}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Attachment Menu */}
      {showAttachment && (
        <div className="absolute bottom-full left-0 mb-2 bg-white rounded-xl shadow-xl border border-slate-200 p-2 z-20">
          <button
            onClick={() => fileInputRef.current?.click()}
            className="flex items-center gap-3 px-4 py-3 hover:bg-slate-100 rounded-lg transition-colors w-full"
          >
            <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
              <ImageIcon className="w-5 h-5 text-blue-600" />
            </div>
            <div className="text-left">
              <div className="font-semibold text-slate-900">Photo</div>
              <div className="text-xs text-slate-500">Share an image</div>
            </div>
          </button>
          <button
            className="flex items-center gap-3 px-4 py-3 hover:bg-slate-100 rounded-lg transition-colors w-full"
            onClick={() => {
              // Could implement camera capture
              setShowAttachment(false);
            }}
          >
            <div className="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center">
              <Camera className="w-5 h-5 text-green-600" />
            </div>
            <div className="text-left">
              <div className="font-semibold text-slate-900">Camera</div>
              <div className="text-xs text-slate-500">Take a photo</div>
            </div>
          </button>
        </div>
      )}

      {/* Input Area */}
      <div className="px-4 py-3 bg-white border-t border-slate-200">
        <div className="flex items-end gap-2">
          {/* Attachment Button */}
          {onSendImage && (
            <button
              onClick={() => {
                setShowAttachment(!showAttachment);
                setShowEmoji(false);
              }}
              disabled={disabled}
              className="p-2.5 text-slate-500 hover:text-slate-700 hover:bg-slate-100 rounded-full transition-all disabled:opacity-50"
            >
              <Paperclip className="w-5 h-5" />
            </button>
          )}

          {/* Emoji Button */}
          <button
            onClick={() => {
              setShowEmoji(!showEmoji);
              setShowAttachment(false);
            }}
            disabled={disabled}
            className="p-2.5 text-slate-500 hover:text-slate-700 hover:bg-slate-100 rounded-full transition-all disabled:opacity-50"
          >
            <Smile className="w-5 h-5" />
          </button>

          {/* Text Input */}
          <div className="flex-1 relative">
            <textarea
              ref={inputRef}
              value={message}
              onChange={handleInputChange}
              onKeyDown={handleKeyDown}
              placeholder={placeholder}
              disabled={disabled || sending}
              rows={1}
              className="w-full px-4 py-3 bg-slate-100 border-0 rounded-2xl resize-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition-all text-slate-900 placeholder:text-slate-400 disabled:opacity-50"
              style={{ maxHeight: '120px' }}
            />
            {isNearLimit && (
              <span className={`absolute right-3 bottom-2 text-xs ${
                charCount >= maxLength ? 'text-red-500' : 'text-slate-400'
              }`}>
                {charCount}/{maxLength}
              </span>
            )}
          </div>

          {/* Send Button */}
          <button
            onClick={handleSend}
            disabled={(!message.trim() && !selectedImage) || sending || disabled}
            className={`p-3 rounded-full transition-all transform ${
              message.trim() || selectedImage
                ? 'bg-gradient-to-r from-blue-600 to-indigo-600 text-white shadow-lg hover:shadow-xl hover:scale-105'
                : 'bg-slate-200 text-slate-400'
            } disabled:opacity-50 disabled:transform-none disabled:hover:shadow-none`}
          >
            {sending ? (
              <Loader2 className="w-5 h-5 animate-spin" />
            ) : (
              <Send className="w-5 h-5" />
            )}
          </button>
        </div>
      </div>

      {/* Hidden File Input */}
      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        onChange={handleImageSelect}
        className="hidden"
      />
    </div>
  );
};
