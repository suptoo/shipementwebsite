import React, { useState, useEffect } from 'react';
import { MessageCircle, Package, User, Clock, ChevronRight, Inbox, Loader2 } from 'lucide-react';
import { messagingService } from '../../services/messagingService';
import { useAuth } from '../../context/AuthContext';
import { Conversation } from '../../types';
import { ConversationWindow } from './ConversationWindow';

export const ConversationsList: React.FC = () => {
  const { user, profile } = useAuth();
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedConversation, setSelectedConversation] = useState<Conversation | null>(null);
  const [unreadCount, setUnreadCount] = useState(0);

  useEffect(() => {
    if (user && profile) {
      loadConversations();
      loadUnreadCount();
    }
  }, [user, profile]);

  const loadConversations = async () => {
    if (!user || !profile) return;

    try {
      const userRole = profile.role === 'admin' ? 'admin' : 
                      profile.role === 'seller' ? 'seller' : 'buyer';
      const data = await messagingService.getUserConversations(user.id, userRole);
      setConversations(data);
    } catch (error) {
      console.error('Error loading conversations:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadUnreadCount = async () => {
    if (!user || !profile) return;

    try {
      const userRole = profile.role === 'admin' ? 'admin' : 
                      profile.role === 'seller' ? 'seller' : 'buyer';
      const count = await messagingService.getUnreadCount(user.id, userRole);
      setUnreadCount(count);
    } catch (error) {
      console.error('Error loading unread count:', error);
    }
  };

  const getConversationIcon = (type: string) => {
    switch (type) {
      case 'buyer_seller':
        return <Package className="w-6 h-6" />;
      case 'buyer_admin':
      case 'seller_admin':
        return <MessageCircle className="w-6 h-6" />;
      default:
        return <User className="w-6 h-6" />;
    }
  };

  const getConversationTitle = (conv: Conversation) => {
    if (profile?.role === 'seller') {
      return conv.buyer?.full_name || 'Customer';
    } else if (profile?.role === 'admin') {
      if (conv.type === 'buyer_admin') {
        return conv.buyer?.full_name || 'User';
      } else {
        return conv.seller?.business_name || 'Seller';
      }
    } else {
      // Buyer
      if (conv.type === 'buyer_seller') {
        return conv.seller?.business_name || 'Seller';
      } else {
        return 'Support Team';
      }
    }
  };

  const getConversationSubtitle = (conv: Conversation) => {
    if (conv.product) {
      return `📦 ${conv.product.name}`;
    } else if (conv.order) {
      return `🧾 Order: ${conv.order.order_number}`;
    } else if (conv.subject) {
      return conv.subject;
    }
    return '💬 Direct message';
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-16">
        <div className="text-center">
          <Loader2 className="w-10 h-10 animate-spin text-blue-600 mx-auto mb-3" />
          <p className="text-gray-500">Loading conversations...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Stats Bar */}
      {unreadCount > 0 && (
        <div className="bg-gradient-to-r from-blue-500 to-purple-500 text-white rounded-xl p-4 flex items-center justify-between shadow-lg">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-white/20 rounded-lg flex items-center justify-center">
              <Inbox className="w-5 h-5" />
            </div>
            <div>
              <p className="font-bold">{unreadCount} Unread Messages</p>
              <p className="text-sm text-white/80">Stay up to date with your conversations</p>
            </div>
          </div>
        </div>
      )}

      {conversations.length === 0 ? (
        <div className="bg-white rounded-2xl shadow-lg p-12 text-center border border-gray-100">
          <div className="w-24 h-24 bg-gradient-to-br from-blue-100 to-purple-100 rounded-2xl flex items-center justify-center mx-auto mb-6">
            <MessageCircle className="w-12 h-12 text-blue-500" />
          </div>
          <h3 className="text-xl font-bold text-gray-800 mb-2">No conversations yet</h3>
          <p className="text-gray-500 max-w-md mx-auto">
            Start a conversation by clicking the chat button on any product, or use the support chatbot below!
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {conversations.map((conv, index) => (
            <div
              key={conv.id}
              onClick={() => setSelectedConversation(conv)}
              className="group bg-white rounded-2xl shadow-sm hover:shadow-xl transition-all duration-300 cursor-pointer border border-gray-100 hover:border-blue-200 overflow-hidden"
              style={{ animation: `fadeInUp 0.4s ease-out ${index * 0.05}s both` }}
            >
              <div className="flex items-center gap-4 p-5">
                {/* Avatar */}
                <div className="relative flex-shrink-0">
                  <div className="w-14 h-14 bg-gradient-to-br from-blue-500 to-purple-600 rounded-2xl flex items-center justify-center text-white shadow-lg group-hover:scale-110 transition-transform">
                    {getConversationIcon(conv.type)}
                  </div>
                  {conv.status === 'active' && (
                    <div className="absolute -bottom-1 -right-1 w-4 h-4 bg-green-500 rounded-full border-2 border-white"></div>
                  )}
                </div>
                
                {/* Content */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between mb-1">
                    <h3 className="font-bold text-gray-800 group-hover:text-blue-600 transition-colors truncate">
                      {getConversationTitle(conv)}
                    </h3>
                    <div className="flex items-center gap-1 text-gray-400 text-sm">
                      <Clock className="w-4 h-4" />
                      {new Date(conv.last_message_at || conv.created_at).toLocaleDateString()}
                    </div>
                  </div>
                  <p className="text-gray-500 truncate text-sm">
                    {getConversationSubtitle(conv)}
                  </p>
                  <div className="flex items-center gap-2 mt-2">
                    <span className={`text-xs font-semibold px-2.5 py-1 rounded-lg ${
                      conv.status === 'active' 
                        ? 'bg-green-100 text-green-700' 
                        : 'bg-gray-100 text-gray-600'
                    }`}>
                      {conv.status === 'active' ? '● Active' : conv.status}
                    </span>
                    {conv.product && (
                      <span className="text-xs bg-blue-100 text-blue-700 px-2.5 py-1 rounded-lg font-semibold">
                        Product Inquiry
                      </span>
                    )}
                  </div>
                </div>

                {/* Arrow */}
                <ChevronRight className="w-6 h-6 text-gray-300 group-hover:text-blue-500 group-hover:translate-x-1 transition-all flex-shrink-0" />
              </div>
            </div>
          ))}
        </div>
      )}

      {selectedConversation && (
        <ConversationWindow
          conversation={selectedConversation}
          onClose={() => {
            setSelectedConversation(null);
            loadConversations();
            loadUnreadCount();
          }}
        />
      )}
    </div>
  );
};
