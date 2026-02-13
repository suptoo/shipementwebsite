import React from 'react';
import { ConversationsList } from '../components/messaging/ConversationsList';
import { Inbox, MessageCircle, Sparkles } from 'lucide-react';

export const Messages: React.FC = () => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-purple-50 py-8">
      <div className="container mx-auto px-4 max-w-4xl">
        {/* Header */}
        <div className="mb-8">
          <div className="bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 rounded-3xl p-8 text-white shadow-2xl relative overflow-hidden">
            <div className="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full -translate-y-1/2 translate-x-1/2 blur-3xl"></div>
            <div className="absolute bottom-0 left-0 w-48 h-48 bg-purple-400/20 rounded-full translate-y-1/2 -translate-x-1/2 blur-2xl"></div>
            <div className="relative z-10 flex items-center gap-4">
              <div className="w-16 h-16 bg-white/20 backdrop-blur-sm rounded-2xl flex items-center justify-center">
                <Inbox className="w-8 h-8" />
              </div>
              <div>
                <h1 className="text-3xl font-black flex items-center gap-2">
                  My Messages
                  <Sparkles className="w-6 h-6 text-yellow-300" />
                </h1>
                <p className="text-white/80 mt-1">Your conversations with sellers and support</p>
              </div>
            </div>
          </div>
        </div>
        
        {/* Conversations */}
        <ConversationsList />
      </div>
    </div>
  );
};
