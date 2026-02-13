import React, { useState, useEffect, useRef } from 'react';
import { 
  MessageCircle, X, Send, Loader2, Bot, User, 
  Headphones, Sparkles, ChevronRight 
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { messagingService } from '../../services/messagingService';
import { Message, Conversation } from '../../types';
import { useNavigate } from 'react-router-dom';

interface QuickAction {
  label: string;
  icon: React.ReactNode;
  message: string;
}

const quickActions: QuickAction[] = [
  { label: 'Track Order', icon: <span>📦</span>, message: 'I want to track my order' },
  { label: 'Payment Help', icon: <span>💳</span>, message: 'I need help with payment' },
  { label: 'Returns', icon: <span>↩️</span>, message: 'I want to return an item' },
  { label: 'General Query', icon: <span>❓</span>, message: 'I have a general question' },
];

export const SupportChatbot: React.FC = () => {
  const { user, profile } = useAuth();
  const navigate = useNavigate();
  const [isOpen, setIsOpen] = useState(false);
  const [isExpanded, setIsExpanded] = useState(false);
  const [message, setMessage] = useState('');
  const [messages, setMessages] = useState<Message[]>([]);
  const [loading, setLoading] = useState(false);
  const [sending, setSending] = useState(false);
  const [conversation, setConversation] = useState<Conversation | null>(null);
  const [showQuickActions, setShowQuickActions] = useState(true);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  // Listen for openChat event from product inquiry buttons
  useEffect(() => {
    const handleOpenChat = () => {
      setIsOpen(true);
    };

    window.addEventListener('openChat', handleOpenChat);
    return () => {
      window.removeEventListener('openChat', handleOpenChat);
    };
  }, []);

  useEffect(() => {
    if (isOpen && user) {
      initConversation();
    }
  }, [isOpen, user]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const scrollToBottom = () => {
    setTimeout(() => {
      messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    }, 100);
  };

  const initConversation = async () => {
    if (!user) return;
    
    setLoading(true);
    try {
      // Get or create a support conversation
      const conv = await messagingService.getOrCreateConversation({
        type: 'buyer_admin',
        buyerId: user.id,
      });
      setConversation(conv);
      
      // Load existing messages
      const msgs = await messagingService.getMessages(conv.id);
      setMessages(msgs);
      setShowQuickActions(msgs.length === 0);
      
      // Subscribe to new messages
      const subscription = messagingService.subscribeToMessages(conv.id, (newMsg) => {
        setMessages(prev => [...prev, newMsg]);
      });
      
      return () => {
        subscription.unsubscribe();
      };
    } catch (error) {
      console.error('Error initializing conversation:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSendMessage = async (customMessage?: string) => {
    const msgToSend = customMessage || message.trim();
    if (!msgToSend || !user || !conversation || sending) return;

    setSending(true);
    setShowQuickActions(false);

    try {
      await messagingService.sendMessage({
        conversationId: conversation.id,
        senderId: user.id,
        senderType: 'buyer',
        content: msgToSend,
      });
      setMessage('');
      inputRef.current?.focus();
    } catch (error) {
      console.error('Error sending message:', error);
      alert('Failed to send message');
    } finally {
      setSending(false);
    }
  };

  const handleQuickAction = (action: QuickAction) => {
    handleSendMessage(action.message);
  };

  const handleLoginRedirect = () => {
    setIsOpen(false);
    navigate('/login');
  };

  const handleViewInbox = () => {
    setIsOpen(false);
    navigate('/messages');
  };

  return (
    <>
      {/* Floating Button */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className={`fixed bottom-6 right-6 z-50 transition-all duration-500 transform ${
          isOpen ? 'scale-0 opacity-0' : 'scale-100 opacity-100'
        }`}
      >
        <div className="relative group">
          {/* Pulse Animation */}
          <div className="absolute inset-0 bg-gradient-to-r from-blue-500 to-purple-600 rounded-full animate-ping opacity-25"></div>
          
          {/* Main Button */}
          <div className="relative bg-gradient-to-br from-blue-600 via-purple-600 to-pink-600 text-white p-4 rounded-full shadow-2xl hover:shadow-purple-500/50 hover:scale-110 transition-all duration-300">
            <div className="absolute inset-0 bg-gradient-to-br from-white/20 to-transparent rounded-full opacity-0 group-hover:opacity-100 transition-opacity"></div>
            <Headphones className="w-7 h-7 relative z-10" />
          </div>
          
          {/* Notification Badge */}
          <div className="absolute -top-1 -right-1 w-4 h-4 bg-green-500 rounded-full border-2 border-white animate-pulse"></div>
        </div>
      </button>

      {/* Chat Window */}
      <div className={`fixed z-50 transition-all duration-500 ease-out ${
        isOpen 
          ? 'opacity-100 translate-y-0 pointer-events-auto' 
          : 'opacity-0 translate-y-8 pointer-events-none'
      } ${
        isExpanded 
          ? 'bottom-0 right-0 w-full h-full sm:bottom-4 sm:right-4 sm:w-[480px] sm:h-[700px] sm:rounded-2xl' 
          : 'bottom-4 right-4 w-[380px] h-[550px] rounded-2xl'
      }`}>
        <div className="bg-white h-full w-full sm:rounded-2xl shadow-2xl flex flex-col overflow-hidden border border-gray-200">
          
          {/* Header */}
          <div className="bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 text-white p-4 relative overflow-hidden flex-shrink-0">
            {/* Decorative Elements */}
            <div className="absolute top-0 right-0 w-40 h-40 bg-white/10 rounded-full -translate-y-1/2 translate-x-1/2 blur-2xl"></div>
            <div className="absolute bottom-0 left-0 w-32 h-32 bg-purple-400/20 rounded-full translate-y-1/2 -translate-x-1/2 blur-xl"></div>
            
            <div className="relative z-10 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="relative">
                  <div className="w-12 h-12 bg-white/20 backdrop-blur-sm rounded-xl flex items-center justify-center">
                    <Bot className="w-7 h-7" />
                  </div>
                  <div className="absolute -bottom-1 -right-1 w-4 h-4 bg-green-400 rounded-full border-2 border-white"></div>
                </div>
                <div>
                  <h3 className="font-bold text-lg flex items-center gap-2">
                    Support Assistant
                    <Sparkles className="w-4 h-4 text-yellow-300" />
                  </h3>
                  <p className="text-sm text-white/80">We're here to help 24/7</p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setIsExpanded(!isExpanded)}
                  className="p-2 hover:bg-white/10 rounded-lg transition-colors hidden sm:block"
                  title={isExpanded ? 'Minimize' : 'Expand'}
                >
                  <ChevronRight className={`w-5 h-5 transition-transform ${isExpanded ? 'rotate-45' : '-rotate-45'}`} />
                </button>
                <button
                  onClick={() => setIsOpen(false)}
                  className="p-2 hover:bg-white/10 rounded-lg transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
            </div>
          </div>

          {/* Content */}
          {!user ? (
            /* Login Prompt */
            <div className="flex-1 flex flex-col items-center justify-center p-6 bg-gradient-to-b from-slate-50 to-white">
              <div className="w-20 h-20 bg-gradient-to-br from-blue-100 to-purple-100 rounded-2xl flex items-center justify-center mb-6">
                <User className="w-10 h-10 text-blue-600" />
              </div>
              <h3 className="text-xl font-bold text-gray-800 mb-2">Welcome!</h3>
              <p className="text-gray-600 text-center mb-6">
                Please log in to chat with our support team
              </p>
              <button
                onClick={handleLoginRedirect}
                className="bg-gradient-to-r from-blue-600 to-purple-600 text-white px-8 py-3 rounded-xl font-semibold hover:shadow-lg hover:shadow-blue-500/30 transition-all transform hover:scale-105"
              >
                Login to Continue
              </button>
            </div>
          ) : loading ? (
            /* Loading State */
            <div className="flex-1 flex items-center justify-center bg-slate-50">
              <div className="text-center">
                <Loader2 className="w-10 h-10 animate-spin text-blue-600 mx-auto mb-3" />
                <p className="text-gray-500">Connecting to support...</p>
              </div>
            </div>
          ) : (
            <>
              {/* Messages Area */}
              <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-gradient-to-b from-slate-50 to-white">
                {/* Welcome Message */}
                {messages.length === 0 && (
                  <div className="text-center py-4">
                    <div className="inline-flex items-center gap-2 bg-white px-4 py-2 rounded-full shadow-sm border border-gray-100">
                      <span className="text-2xl">👋</span>
                      <span className="text-gray-600 text-sm">How can we help you today?</span>
                    </div>
                  </div>
                )}

                {/* Quick Actions */}
                {showQuickActions && messages.length === 0 && (
                  <div className="grid grid-cols-2 gap-2 mt-4">
                    {quickActions.map((action, idx) => (
                      <button
                        key={idx}
                        onClick={() => handleQuickAction(action)}
                        className="flex items-center gap-2 p-3 bg-white rounded-xl border border-gray-200 hover:border-blue-300 hover:bg-blue-50 transition-all text-left group"
                      >
                        <span className="text-xl">{action.icon}</span>
                        <span className="text-sm font-medium text-gray-700 group-hover:text-blue-600">
                          {action.label}
                        </span>
                      </button>
                    ))}
                  </div>
                )}

                {/* Messages */}
                {messages.map((msg) => {
                  const isOwn = msg.sender_id === user?.id;
                  const isPaymentRequest = msg.content.startsWith('[PAYMENT_REQUEST]');
                  
                  if (isPaymentRequest) {
                    const paymentData = JSON.parse(msg.content.replace('[PAYMENT_REQUEST]', ''));
                    return (
                      <div key={msg.id} className="flex justify-start">
                        <div className="max-w-[85%] bg-gradient-to-br from-emerald-50 to-teal-50 border border-emerald-200 rounded-2xl p-4 shadow-sm">
                          <div className="flex items-center gap-2 mb-2">
                            <span className="text-2xl">💳</span>
                            <span className="font-semibold text-emerald-800">Payment Request</span>
                          </div>
                          <p className="text-3xl font-bold text-gray-900 mb-2">৳{paymentData.amount}</p>
                          <p className="text-gray-600 text-sm mb-4">{paymentData.description}</p>
                          <div className="flex gap-2">
                            <button
                              onClick={() => navigate(`/checkout?payment_request=${paymentData.id}&amount=${paymentData.amount}`)}
                              className="flex-1 bg-gradient-to-r from-emerald-500 to-teal-500 text-white px-4 py-2 rounded-xl font-semibold hover:shadow-lg transition-all"
                            >
                              Pay Now
                            </button>
                          </div>
                          <p className="text-xs text-gray-500 mt-2">
                            {new Date(msg.created_at).toLocaleString()}
                          </p>
                        </div>
                      </div>
                    );
                  }

                  return (
                    <div key={msg.id} className={`flex ${isOwn ? 'justify-end' : 'justify-start'}`}>
                      <div className={`max-w-[80%] rounded-2xl px-4 py-3 shadow-sm ${
                        isOwn
                          ? 'bg-gradient-to-br from-blue-600 to-purple-600 text-white'
                          : 'bg-white border border-gray-200 text-gray-800'
                      }`}>
                        {!isOwn && (
                          <div className="flex items-center gap-2 mb-1">
                            <Bot className="w-4 h-4 text-purple-500" />
                            <span className="text-xs font-semibold text-purple-600">Support Team</span>
                          </div>
                        )}
                        <p className="text-sm whitespace-pre-wrap leading-relaxed">{msg.content}</p>
                        <p className={`text-xs mt-2 ${isOwn ? 'text-blue-200' : 'text-gray-400'}`}>
                          {new Date(msg.created_at).toLocaleTimeString([], { 
                            hour: '2-digit', 
                            minute: '2-digit' 
                          })}
                        </p>
                      </div>
                    </div>
                  );
                })}
                <div ref={messagesEndRef} />
              </div>

              {/* View in Inbox Button */}
              {messages.length > 0 && (
                <div className="px-4 py-2 bg-slate-50 border-t border-gray-100">
                  <button
                    onClick={handleViewInbox}
                    className="w-full text-sm text-blue-600 hover:text-purple-600 font-medium transition-colors"
                  >
                    View full conversation in inbox →
                  </button>
                </div>
              )}

              {/* Input Area */}
              <div className="p-4 border-t border-gray-100 bg-white flex-shrink-0">
                <div className="flex gap-2">
                  <input
                    ref={inputRef}
                    type="text"
                    value={message}
                    onChange={(e) => setMessage(e.target.value)}
                    onKeyPress={(e) => e.key === 'Enter' && !e.shiftKey && handleSendMessage()}
                    placeholder="Type your message..."
                    className="flex-1 px-4 py-3 bg-slate-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all"
                    disabled={sending}
                  />
                  <button
                    onClick={() => handleSendMessage()}
                    disabled={sending || !message.trim()}
                    className="bg-gradient-to-r from-blue-600 to-purple-600 text-white px-5 py-3 rounded-xl hover:shadow-lg hover:shadow-purple-500/30 transition-all disabled:opacity-50 disabled:cursor-not-allowed disabled:shadow-none"
                  >
                    {sending ? (
                      <Loader2 className="w-5 h-5 animate-spin" />
                    ) : (
                      <Send className="w-5 h-5" />
                    )}
                  </button>
                </div>
              </div>
            </>
          )}
        </div>
      </div>
    </>
  );
};
