import React, { useState } from 'react';
import { 
  User, Shield, Check, CheckCheck, Clock, 
  Image as ImageIcon, Download, AlertCircle,
  MoreVertical, Copy, Trash2
} from 'lucide-react';

interface MessageBubbleProps {
  content: string;
  timestamp: string;
  isOwn: boolean;
  isAdmin: boolean;
  senderName: string;
  senderAvatar?: string;
  imageUrl?: string;
  isRead?: boolean;
  status?: 'sending' | 'sent' | 'delivered' | 'read' | 'failed';
  onRetry?: () => void;
  onDelete?: () => void;
}

export const MessageBubble: React.FC<MessageBubbleProps> = ({
  content,
  timestamp,
  isOwn,
  isAdmin,
  senderName,
  senderAvatar,
  imageUrl,
  status = 'sent',
  onRetry,
  onDelete,
}) => {
  const [showMenu, setShowMenu] = useState(false);
  const [imageLoaded, setImageLoaded] = useState(false);
  const [imageFailed, setImageFailed] = useState(false);

  const formatTime = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const isToday = date.toDateString() === now.toDateString();
    
    if (isToday) {
      return date.toLocaleTimeString('en-US', { 
        hour: 'numeric', 
        minute: '2-digit',
        hour12: true 
      });
    }
    
    const yesterday = new Date(now);
    yesterday.setDate(yesterday.getDate() - 1);
    if (date.toDateString() === yesterday.toDateString()) {
      return `Yesterday ${date.toLocaleTimeString('en-US', { 
        hour: 'numeric', 
        minute: '2-digit',
        hour12: true 
      })}`;
    }
    
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    });
  };

  const copyToClipboard = () => {
    navigator.clipboard.writeText(content);
    setShowMenu(false);
  };

  const StatusIcon = () => {
    switch (status) {
      case 'sending':
        return <Clock className="w-3.5 h-3.5 text-slate-400 animate-pulse" />;
      case 'sent':
        return <Check className="w-3.5 h-3.5 text-slate-400" />;
      case 'delivered':
        return <CheckCheck className="w-3.5 h-3.5 text-slate-400" />;
      case 'read':
        return <CheckCheck className="w-3.5 h-3.5 text-blue-400" />;
      case 'failed':
        return <AlertCircle className="w-3.5 h-3.5 text-red-500" />;
      default:
        return null;
    }
  };

  return (
    <div className={`flex gap-3 group ${isOwn ? 'flex-row-reverse' : ''}`}>
      {/* Avatar */}
      <div className={`flex-shrink-0 ${isOwn ? 'hidden sm:block' : ''}`}>
        {senderAvatar ? (
          <img
            src={senderAvatar}
            alt={senderName}
            className="w-10 h-10 rounded-full object-cover ring-2 ring-white shadow-md"
          />
        ) : (
          <div className={`w-10 h-10 rounded-full flex items-center justify-center shadow-md ${
            isAdmin 
              ? 'bg-gradient-to-br from-purple-500 to-indigo-600' 
              : isOwn 
                ? 'bg-gradient-to-br from-blue-500 to-cyan-500'
                : 'bg-gradient-to-br from-slate-400 to-slate-500'
          }`}>
            {isAdmin ? (
              <Shield className="w-5 h-5 text-white" />
            ) : (
              <User className="w-5 h-5 text-white" />
            )}
          </div>
        )}
      </div>

      {/* Message Content */}
      <div className={`max-w-[75%] sm:max-w-[65%] ${isOwn ? 'items-end' : 'items-start'}`}>
        {/* Sender Name */}
        <div className={`flex items-center gap-2 mb-1 ${isOwn ? 'flex-row-reverse' : ''}`}>
          <span className={`text-xs font-semibold ${
            isAdmin ? 'text-purple-600' : 'text-slate-600'
          }`}>
            {isOwn ? 'You' : senderName}
          </span>
          {isAdmin && !isOwn && (
            <span className="text-[10px] bg-purple-100 text-purple-700 px-1.5 py-0.5 rounded-full font-bold">
              ADMIN
            </span>
          )}
        </div>

        {/* Bubble */}
        <div className="relative">
          <div
            className={`relative rounded-2xl px-4 py-3 shadow-sm transition-all duration-200 ${
              isOwn
                ? 'bg-gradient-to-br from-blue-600 to-blue-700 text-white rounded-tr-sm'
                : isAdmin
                  ? 'bg-gradient-to-br from-purple-50 to-indigo-50 text-slate-800 border border-purple-200 rounded-tl-sm'
                  : 'bg-white text-slate-800 border border-slate-200 rounded-tl-sm'
            } ${status === 'failed' ? 'opacity-60' : ''}`}
          >
            {/* Image */}
            {imageUrl && (
              <div className="mb-2 -mx-2 -mt-1">
                {!imageLoaded && !imageFailed && (
                  <div className="w-full h-48 bg-slate-200 animate-pulse rounded-lg flex items-center justify-center">
                    <ImageIcon className="w-8 h-8 text-slate-400" />
                  </div>
                )}
                {imageFailed ? (
                  <div className="w-full h-32 bg-slate-100 rounded-lg flex flex-col items-center justify-center gap-2">
                    <AlertCircle className="w-8 h-8 text-slate-400" />
                    <span className="text-xs text-slate-500">Failed to load image</span>
                  </div>
                ) : (
                  <img
                    src={imageUrl}
                    alt="Attachment"
                    className={`rounded-lg max-w-full cursor-pointer hover:opacity-90 transition-opacity ${
                      imageLoaded ? 'block' : 'hidden'
                    }`}
                    onLoad={() => setImageLoaded(true)}
                    onError={() => setImageFailed(true)}
                    onClick={() => window.open(imageUrl, '_blank')}
                  />
                )}
                {imageLoaded && (
                  <a
                    href={imageUrl}
                    download
                    className={`absolute bottom-3 right-3 p-1.5 rounded-full ${
                      isOwn ? 'bg-white/20 hover:bg-white/30' : 'bg-slate-900/20 hover:bg-slate-900/30'
                    } transition-colors`}
                  >
                    <Download className="w-4 h-4" />
                  </a>
                )}
              </div>
            )}

            {/* Text Content */}
            <p className="text-sm whitespace-pre-wrap break-words leading-relaxed">
              {content}
            </p>

            {/* Message Menu */}
            <button
              onClick={() => setShowMenu(!showMenu)}
              className={`absolute -right-1 top-1 opacity-0 group-hover:opacity-100 p-1 rounded-full transition-all ${
                isOwn ? 'hover:bg-white/20' : 'hover:bg-slate-100'
              }`}
            >
              <MoreVertical className={`w-4 h-4 ${isOwn ? 'text-white/70' : 'text-slate-400'}`} />
            </button>

            {showMenu && (
              <div className={`absolute top-0 ${isOwn ? 'right-full mr-2' : 'left-full ml-2'} bg-white rounded-lg shadow-xl border border-slate-200 py-1 z-10 min-w-[120px]`}>
                <button
                  onClick={copyToClipboard}
                  className="w-full px-3 py-2 text-left text-sm text-slate-700 hover:bg-slate-100 flex items-center gap-2"
                >
                  <Copy className="w-4 h-4" />
                  Copy
                </button>
                {onDelete && isOwn && (
                  <button
                    onClick={() => { onDelete(); setShowMenu(false); }}
                    className="w-full px-3 py-2 text-left text-sm text-red-600 hover:bg-red-50 flex items-center gap-2"
                  >
                    <Trash2 className="w-4 h-4" />
                    Delete
                  </button>
                )}
              </div>
            )}
          </div>

          {/* Timestamp & Status */}
          <div className={`flex items-center gap-1.5 mt-1 ${isOwn ? 'justify-end' : 'justify-start'}`}>
            <span className={`text-[11px] ${isOwn ? 'text-slate-400' : 'text-slate-500'}`}>
              {formatTime(timestamp)}
            </span>
            {isOwn && <StatusIcon />}
          </div>

          {/* Retry Button */}
          {status === 'failed' && onRetry && (
            <button
              onClick={onRetry}
              className="mt-1 text-xs text-red-600 hover:text-red-700 font-medium flex items-center gap-1"
            >
              <AlertCircle className="w-3 h-3" />
              Tap to retry
            </button>
          )}
        </div>
      </div>
    </div>
  );
};
