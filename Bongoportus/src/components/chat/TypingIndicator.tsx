import React from 'react';

interface TypingIndicatorProps {
  userName?: string;
  isAdmin?: boolean;
}

export const TypingIndicator: React.FC<TypingIndicatorProps> = ({ 
  userName = 'Someone', 
  isAdmin = false 
}) => {
  return (
    <div className="flex items-center gap-3 px-4 py-2">
      <div className={`w-8 h-8 rounded-full flex items-center justify-center ${
        isAdmin ? 'bg-purple-100' : 'bg-slate-100'
      }`}>
        <span className="text-sm">{isAdmin ? '👤' : '👤'}</span>
      </div>
      <div className="flex items-center gap-2">
        <div className="flex items-center gap-1 px-3 py-2 bg-slate-100 rounded-full">
          <div className="w-2 h-2 bg-slate-400 rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
          <div className="w-2 h-2 bg-slate-400 rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
          <div className="w-2 h-2 bg-slate-400 rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
        </div>
        <span className="text-xs text-slate-500">
          {userName} is typing...
        </span>
      </div>
    </div>
  );
};
