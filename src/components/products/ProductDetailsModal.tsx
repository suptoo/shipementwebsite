import React, { useState, useEffect, useRef, useCallback, useMemo, memo } from 'react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../context/AuthContext';
import { Product, Inquiry } from '../../types';
import { 
  X, Star, ShoppingCart, Send, Loader2, 
  Package, TruckIcon, ShieldCheck, MessageCircle,
  Info, User, Shield, Check, CheckCheck, Heart,
  Share2, Zap, Award, Clock, AlertCircle, RefreshCw,
  Sparkles, ChevronLeft, ChevronRight, Volume2, VolumeX,
  Copy, MoreVertical
} from 'lucide-react';
import { ensureProfileRecord } from '../../lib/profileUtils';

interface ProductDetailsModalProps {
  product: Product;
  onClose: () => void;
  initialTab?: 'details' | 'chat';
  onAddToCart?: () => void;
}

// Custom chat message type for the inquiries/messages flow
interface ChatMessage {
  id: string;
  inquiry_id: string;
  sender_id: string;
  content: string;
  is_read: boolean;
  created_at: string;
  image_url?: string | null;
  status?: 'sending' | 'sent' | 'delivered' | 'read' | 'failed';
  tempId?: string;
  sender?: {
    id: string;
    email: string;
    role: 'admin' | 'seller' | 'user';
    full_name: string | null;
    avatar_url: string | null;
    phone: string | null;
    is_verified: boolean;
    is_blocked: boolean;
  };
}

// Message Bubble Props Interface
interface MessageBubbleProps {
  content: string;
  timestamp: string;
  isOwn: boolean;
  isAdmin: boolean;
  senderName: string;
  senderAvatar?: string;
  imageUrl?: string;
  status?: 'sending' | 'sent' | 'delivered' | 'read' | 'failed';
  onRetry?: () => void;
}

// Message Bubble Component
const MessageBubble: React.FC<MessageBubbleProps> = ({ content, timestamp, isOwn, isAdmin, senderName, senderAvatar, imageUrl, status = 'sent', onRetry }) => {
  const [showMenu, setShowMenu] = useState(false);

  const formattedTime = useMemo(() => {
    const date = new Date(timestamp);
    const now = new Date();
    const isToday = date.toDateString() === now.toDateString();
    
    if (isToday) {
      return date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true });
    }
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit', hour12: true });
  }, [timestamp]);

  const StatusIcon = useCallback(() => {
    switch (status) {
      case 'sending': return <Clock className="w-3.5 h-3.5 text-slate-400 animate-pulse" />;
      case 'sent': return <Check className="w-3.5 h-3.5 text-slate-400" />;
      case 'delivered': return <CheckCheck className="w-3.5 h-3.5 text-slate-400" />;
      case 'read': return <CheckCheck className="w-3.5 h-3.5 text-blue-400" />;
      case 'failed': return <AlertCircle className="w-3.5 h-3.5 text-red-500" />;
      default: return null;
    }
  }, [status]);

  return (
    <div className={`flex gap-3 group ${isOwn ? 'flex-row-reverse' : ''}`}>
      {/* Avatar */}
      <div className={`flex-shrink-0 ${isOwn ? 'hidden sm:block' : ''}`}>
        {senderAvatar ? (
          <img src={senderAvatar} alt={senderName} className="w-10 h-10 rounded-full object-cover ring-2 ring-white shadow-md" />
        ) : (
          <div className={`w-10 h-10 rounded-full flex items-center justify-center shadow-md ${
            isAdmin ? 'bg-gradient-to-br from-purple-500 to-indigo-600' 
            : isOwn ? 'bg-gradient-to-br from-blue-500 to-cyan-500'
            : 'bg-gradient-to-br from-slate-400 to-slate-500'
          }`}>
            {isAdmin ? <Shield className="w-5 h-5 text-white" /> : <User className="w-5 h-5 text-white" />}
          </div>
        )}
      </div>

      {/* Message Content */}
      <div className={`max-w-[75%] sm:max-w-[65%] ${isOwn ? 'items-end' : 'items-start'}`}>
        {/* Sender Name */}
        <div className={`flex items-center gap-2 mb-1 ${isOwn ? 'flex-row-reverse' : ''}`}>
          <span className={`text-xs font-semibold ${isAdmin ? 'text-purple-600' : 'text-slate-600'}`}>
            {isOwn ? 'You' : senderName}
          </span>
          {isAdmin && !isOwn && (
            <span className="text-[10px] bg-purple-100 text-purple-700 px-1.5 py-0.5 rounded-full font-bold">ADMIN</span>
          )}
        </div>

        {/* Bubble */}
        <div className="relative">
          <div className={`relative rounded-2xl px-4 py-3 shadow-sm transition-all duration-200 ${
            isOwn ? 'bg-gradient-to-br from-blue-600 to-blue-700 text-white rounded-tr-sm'
            : isAdmin ? 'bg-gradient-to-br from-purple-50 to-indigo-50 text-slate-800 border border-purple-200 rounded-tl-sm'
            : 'bg-white text-slate-800 border border-slate-200 rounded-tl-sm'
          } ${status === 'failed' ? 'opacity-60' : ''}`}>
            {imageUrl && (
              <div className="mb-2 -mx-2 -mt-1">
                <img src={imageUrl} alt="Attachment" className="rounded-lg max-w-full cursor-pointer hover:opacity-90" onClick={() => window.open(imageUrl, '_blank')} />
              </div>
            )}
            <p className="text-sm whitespace-pre-wrap break-words leading-relaxed">{content}</p>
            
            <button onClick={() => setShowMenu(!showMenu)} className={`absolute -right-1 top-1 opacity-0 group-hover:opacity-100 p-1 rounded-full transition-all ${isOwn ? 'hover:bg-white/20' : 'hover:bg-slate-100'}`}>
              <MoreVertical className={`w-4 h-4 ${isOwn ? 'text-white/70' : 'text-slate-400'}`} />
            </button>

            {showMenu && (
              <div className={`absolute top-0 ${isOwn ? 'right-full mr-2' : 'left-full ml-2'} bg-white rounded-lg shadow-xl border border-slate-200 py-1 z-10 min-w-[100px]`}>
                <button onClick={() => { navigator.clipboard.writeText(content); setShowMenu(false); }} className="w-full px-3 py-2 text-left text-sm text-slate-700 hover:bg-slate-100 flex items-center gap-2">
                  <Copy className="w-4 h-4" /> Copy
                </button>
              </div>
            )}
          </div>

          {/* Timestamp & Status */}
          <div className={`flex items-center gap-1.5 mt-1 ${isOwn ? 'justify-end' : 'justify-start'}`}>
            <span className={`text-[11px] ${isOwn ? 'text-slate-400' : 'text-slate-500'}`}>{formattedTime}</span>
            {isOwn && <StatusIcon />}
          </div>

          {status === 'failed' && onRetry && (
            <button onClick={onRetry} className="mt-1 text-xs text-red-600 hover:text-red-700 font-medium flex items-center gap-1">
              <AlertCircle className="w-3 h-3" /> Tap to retry
            </button>
          )}
        </div>
      </div>
    </div>
  );
};

// Memoize MessageBubble
const MemoizedMessageBubble = memo(MessageBubble);

// Typing Indicator Component
interface TypingIndicatorProps {
  userName?: string;
  isAdmin?: boolean;
}

const TypingIndicator: React.FC<TypingIndicatorProps> = ({ userName = 'Someone', isAdmin = false }) => (
  <div className="flex items-center gap-3 px-4 py-2">
    <div className={`w-8 h-8 rounded-full flex items-center justify-center ${isAdmin ? 'bg-purple-100' : 'bg-slate-100'}`}>
      {isAdmin ? <Shield className="w-4 h-4 text-purple-600" /> : <User className="w-4 h-4 text-slate-500" />}
    </div>
    <div className="flex items-center gap-2">
      <div className="flex items-center gap-1 px-3 py-2 bg-slate-100 rounded-full">
        <div className="w-2 h-2 bg-slate-400 rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
        <div className="w-2 h-2 bg-slate-400 rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
        <div className="w-2 h-2 bg-slate-400 rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
      </div>
      <span className="text-xs text-slate-500">{userName} is typing...</span>
    </div>
  </div>
);

export const ProductDetailsModal: React.FC<ProductDetailsModalProps> = ({ 
  product, 
  onClose,
  initialTab = 'details',
  onAddToCart
}) => {
  const { user, profile } = useAuth();
  const [inquiry, setInquiry] = useState<Inquiry | null>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [newMessage, setNewMessage] = useState('');
  // Only show loading for chat tab - details tab renders immediately
  const [chatLoading, setChatLoading] = useState(false);
  const [sending, setSending] = useState(false);
  const [activeTab, setActiveTab] = useState<'details' | 'chat'>(initialTab);
  const [error, setError] = useState<string | null>(null);
  const [adminTyping, setAdminTyping] = useState(false);
  const [connectionStatus, setConnectionStatus] = useState<'connected' | 'connecting' | 'disconnected'>('disconnected');
  const [soundEnabled, setSoundEnabled] = useState(true);
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [isWishlisted, setIsWishlisted] = useState(false);
  const [unreadCount, setUnreadCount] = useState(0);
  
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const channelRef = useRef<any>(null);

  // Memoized product images - prevents recalculation on every render
  const productImages = useMemo(() => 
    product.images?.length 
      ? product.images.map(img => img.image_url)
      : [(product as any).image_url || null],
    [product.images, (product as any).image_url]
  );

  // Only initialize chat when switching to chat tab - lazy load chat
  useEffect(() => {
    if (user && activeTab === 'chat' && !inquiry && !chatLoading) {
      initializeChat();
    }
    
    return () => {
      if (channelRef.current) {
        supabase.removeChannel(channelRef.current);
      }
    };
  }, [user, activeTab]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  useEffect(() => {
    if (activeTab === 'chat') {
      setUnreadCount(0);
      inputRef.current?.focus();
    }
  }, [activeTab]);

  // Close on Escape
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', handleEscape);
    return () => window.removeEventListener('keydown', handleEscape);
  }, [onClose]);

  const scrollToBottom = useCallback(() => {
    requestAnimationFrame(() => {
      messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    });
  }, []);

  const initializeChat = async () => {
    if (!user) return;
    setError(null);
    setConnectionStatus('connecting');
    setChatLoading(true);

    try {
      // Run profile check in parallel with inquiry fetch
      const [, existingInquiryResult] = await Promise.all([
        ensureProfileRecord(user),
        supabase
          .from('inquiries')
          .select('*')
          .eq('user_id', user.id)
          .eq('product_id', product.id)
          .eq('status', 'open')
          .maybeSingle()
      ]);

      const { data: existingInquiry, error: fetchError } = existingInquiryResult;
      if (fetchError && fetchError.code !== 'PGRST116') throw fetchError;

      let currentInquiry = existingInquiry;

      if (!existingInquiry) {
        const { data: newInquiry, error: createError } = await supabase
          .from('inquiries')
          .insert({
            user_id: user.id,
            product_id: product.id,
            message: `Inquiry about: ${product.name}`,
            survey_amount: `৳${product.price.toLocaleString()}`,
            survey_address: 'Pending',
            survey_days: 7,
            status: 'open',
          })
          .select()
          .single();

        if (createError) throw createError;
        currentInquiry = newInquiry;
      }

      setInquiry(currentInquiry);
      await fetchMessages(currentInquiry.id);
      setupRealtimeSubscription(currentInquiry.id);
      setConnectionStatus('connected');
    } catch (err: any) {
      console.error('Chat initialization error:', err);
      setError(err.message || 'Failed to initialize chat');
      setConnectionStatus('disconnected');
    } finally {
      setChatLoading(false);
    }
  };

  const fetchMessages = async (inquiryId: string) => {
    try {
      const { data, error } = await supabase
        .from('messages')
        .select(`*, sender:profiles!sender_id(id, email, role, full_name, avatar_url)`)
        .eq('inquiry_id', inquiryId)
        .order('created_at', { ascending: true });

      if (error) throw error;
      
      const ChatMessages = (data || []).map(msg => ({ ...msg, status: 'delivered' as const }));
      setMessages(ChatMessages);
    } catch (err: any) {
      console.error('Error fetching messages:', err);
      setError('Failed to load messages');
    }
  };

  const setupRealtimeSubscription = (inquiryId: string) => {
    if (channelRef.current) {
      supabase.removeChannel(channelRef.current);
    }

    channelRef.current = supabase
      .channel(`product-chat:${inquiryId}`)
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'messages', filter: `inquiry_id=eq.${inquiryId}` },
        async (payload) => {
          const { data: fullMessage } = await supabase
            .from('messages')
            .select(`*, sender:profiles!sender_id(id, email, role, full_name, avatar_url)`)
            .eq('id', payload.new.id)
            .single();

          if (fullMessage) {
            const ChatMessage = { ...fullMessage, status: 'delivered' as const };
            setMessages(prev => {
              const exists = prev.some(m => m.id === fullMessage.id || m.tempId === fullMessage.id);
              if (exists) return prev.map(m => m.tempId === fullMessage.id ? ChatMessage : m);
              return [...prev, ChatMessage];
            });

            if (fullMessage.sender_id !== user?.id) {
              if (activeTab !== 'chat') setUnreadCount(prev => prev + 1);
            }
          }
        }
      )
      .subscribe((status) => {
        setConnectionStatus(status === 'SUBSCRIBED' ? 'connected' : 'connecting');
      });
  };

  const handleSendMessage = async (e?: React.FormEvent) => {
    e?.preventDefault();
    if (!newMessage.trim() || !user || !inquiry || sending) return;

    const tempId = `temp-${Date.now()}`;
    const messageContent = newMessage.trim();
    
    const optimisticMessage: ChatMessage = {
      id: tempId,
      tempId,
      inquiry_id: inquiry.id,
      sender_id: user.id,
      content: messageContent,
      is_read: false,
      created_at: new Date().toISOString(),
      status: 'sending',
      sender: {
        id: user.id,
        email: user.email || '',
        role: profile?.role || 'user',
        full_name: profile?.full_name || null,
        avatar_url: profile?.avatar_url || null,
        phone: null,
        is_verified: false,
        is_blocked: false
      }
    };

    setMessages(prev => [...prev, optimisticMessage]);
    setNewMessage('');
    setSending(true);

    try {
      await ensureProfileRecord(user);
      
      const { data, error } = await supabase
        .from('messages')
        .insert({ inquiry_id: inquiry.id, sender_id: user.id, content: messageContent })
        .select()
        .single();

      if (error) throw error;

      setMessages(prev => prev.map(m => m.tempId === tempId ? { ...m, id: data.id, status: 'sent' as const } : m));
    } catch (err: any) {
      console.error('Error sending message:', err);
      setMessages(prev => prev.map(m => m.tempId === tempId ? { ...m, status: 'failed' as const } : m));
    } finally {
      setSending(false);
    }
  };

  const handleRetryMessage = async (message: ChatMessage) => {
    setMessages(prev => prev.filter(m => m.tempId !== message.tempId));
    setNewMessage(message.content);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  const isOwnMessage = (senderId: string) => senderId === user?.id;

  return (
    <div 
      className="fixed inset-0 bg-black/70 backdrop-blur-md flex items-center justify-center p-2 sm:p-4 z-50 animate-in fade-in duration-300"
      onClick={(e) => e.target === e.currentTarget && onClose()}
    >
      <div className="bg-white rounded-3xl max-w-6xl w-full h-[95vh] sm:h-[90vh] flex flex-col shadow-2xl transform transition-all overflow-hidden">
        {/* Header */}
        <div className="relative bg-gradient-to-r from-slate-900 via-blue-900 to-indigo-900 text-white p-4 sm:p-5">
          <div className="absolute inset-0 bg-[url('data:image/svg+xml,%3Csvg width=%2760%27 height=%2760%27 viewBox=%270 0 60 60%27 xmlns=%27http://www.w3.org/2000/svg%27%3E%3Cg fill=%27none%27 fill-rule=%27evenodd%27%3E%3Cg fill=%27%23ffffff%27 fill-opacity=%270.03%27%3E%3Cpath d=%27M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z%27/%3E%3C/g%3E%3C/g%3E%3C/svg%3E')]" />
          
          <div className="relative flex justify-between items-start">
            <div className="flex items-center gap-4">
              <div className="hidden sm:flex w-14 h-14 bg-white/10 rounded-2xl items-center justify-center backdrop-blur-sm">
                <Package className="w-7 h-7" />
              </div>
              <div>
                <h2 className="text-xl sm:text-2xl font-bold tracking-tight line-clamp-1">{product.name}</h2>
                <p className="text-blue-200 text-sm flex items-center gap-2 mt-1">
                  <Sparkles className="w-4 h-4" />
                  Product Details & Live Support
                </p>
              </div>
            </div>
            
            <div className="flex items-center gap-2">
              {/* Connection Status */}
              <div className={`hidden sm:flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium ${
                connectionStatus === 'connected' ? 'bg-green-500/20 text-green-300' 
                : connectionStatus === 'connecting' ? 'bg-yellow-500/20 text-yellow-300'
                : 'bg-red-500/20 text-red-300'
              }`}>
                <div className={`w-2 h-2 rounded-full ${
                  connectionStatus === 'connected' ? 'bg-green-400 animate-pulse' 
                  : connectionStatus === 'connecting' ? 'bg-yellow-400 animate-bounce'
                  : 'bg-red-400'
                }`} />
                {connectionStatus === 'connected' ? 'Live' : connectionStatus === 'connecting' ? 'Connecting...' : 'Offline'}
              </div>

              <button onClick={onClose} className="p-2.5 hover:bg-white/10 rounded-xl transition-all hover:scale-105">
                <X className="w-6 h-6" />
              </button>
            </div>
          </div>
        </div>

        {/* Tabs */}
        <div className="flex border-b border-slate-200 bg-slate-50/80 backdrop-blur-sm">
          <button
            onClick={() => setActiveTab('details')}
            className={`flex-1 py-3.5 px-4 font-semibold transition-all relative ${
              activeTab === 'details' ? 'text-blue-600 bg-white' : 'text-slate-500 hover:text-slate-700 hover:bg-white/50'
            }`}
          >
            <Info className="w-5 h-5 inline mr-2" />
            Product Details
            {activeTab === 'details' && <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-gradient-to-r from-blue-600 to-indigo-600" />}
          </button>
          <button
            onClick={() => setActiveTab('chat')}
            className={`flex-1 py-3.5 px-4 font-semibold transition-all relative ${
              activeTab === 'chat' ? 'text-blue-600 bg-white' : 'text-slate-500 hover:text-slate-700 hover:bg-white/50'
            }`}
          >
            <MessageCircle className="w-5 h-5 inline mr-2" />
            Chat with Admin
            {unreadCount > 0 && activeTab !== 'chat' && (
              <span className="absolute top-2 right-4 min-w-[20px] h-5 bg-red-500 text-white text-xs font-bold rounded-full flex items-center justify-center px-1.5 animate-bounce">
                {unreadCount}
              </span>
            )}
            {activeTab === 'chat' && <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-gradient-to-r from-blue-600 to-indigo-600" />}
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-hidden">
          {activeTab === 'details' ? (
            /* Product Details Tab */
            <div className="h-full overflow-y-auto">
              <div className="p-4 sm:p-6 lg:p-8">
                <div className="grid lg:grid-cols-2 gap-6 lg:gap-10">
                  {/* Product Image Gallery */}
                  <div className="space-y-4">
                    <div className="relative bg-gradient-to-br from-slate-100 to-slate-200 rounded-3xl overflow-hidden aspect-square">
                      {productImages[currentImageIndex] ? (
                        <img 
                          src={productImages[currentImageIndex]} 
                          alt={product.name} 
                          loading="lazy"
                          decoding="async"
                          className="w-full h-full object-contain p-6 transition-transform duration-300 hover:scale-105" 
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center">
                          <Package className="w-32 h-32 text-slate-300" />
                        </div>
                      )}
                      
                      {/* Image Navigation */}
                      {productImages.length > 1 && (
                        <>
                          <button onClick={() => setCurrentImageIndex(prev => prev > 0 ? prev - 1 : productImages.length - 1)} className="absolute left-4 top-1/2 -translate-y-1/2 p-2 bg-white/90 rounded-full shadow-lg hover:bg-white transition-all">
                            <ChevronLeft className="w-5 h-5 text-slate-700" />
                          </button>
                          <button onClick={() => setCurrentImageIndex(prev => prev < productImages.length - 1 ? prev + 1 : 0)} className="absolute right-4 top-1/2 -translate-y-1/2 p-2 bg-white/90 rounded-full shadow-lg hover:bg-white transition-all">
                            <ChevronRight className="w-5 h-5 text-slate-700" />
                          </button>
                          <div className="absolute bottom-4 left-1/2 -translate-x-1/2 flex gap-2">
                            {productImages.map((_, idx) => (
                              <button key={idx} onClick={() => setCurrentImageIndex(idx)} className={`w-2.5 h-2.5 rounded-full transition-all ${idx === currentImageIndex ? 'bg-blue-600 w-6' : 'bg-white/70 hover:bg-white'}`} />
                            ))}
                          </div>
                        </>
                      )}

                      {/* Badges */}
                      <div className="absolute top-4 left-4 flex flex-col gap-2">
                        {product.is_featured && (
                          <span className="px-3 py-1.5 bg-gradient-to-r from-yellow-400 to-orange-500 text-white text-xs font-bold rounded-full flex items-center gap-1.5 shadow-lg">
                            <Award className="w-3.5 h-3.5" /> Featured
                          </span>
                        )}
                        {product.discount_price && product.discount_price < product.price && (
                          <span className="px-3 py-1.5 bg-gradient-to-r from-red-500 to-pink-600 text-white text-xs font-bold rounded-full shadow-lg">
                            {Math.round(((product.price - product.discount_price) / product.price) * 100)}% OFF
                          </span>
                        )}
                      </div>

                      {/* Action Buttons */}
                      <div className="absolute top-4 right-4 flex flex-col gap-2">
                        <button onClick={() => setIsWishlisted(!isWishlisted)} className={`p-2.5 rounded-full shadow-lg transition-all hover:scale-110 ${isWishlisted ? 'bg-red-500 text-white' : 'bg-white/90 text-slate-600 hover:bg-white'}`}>
                          <Heart className={`w-5 h-5 ${isWishlisted ? 'fill-white' : ''}`} />
                        </button>
                        <button className="p-2.5 bg-white/90 rounded-full shadow-lg hover:bg-white transition-all hover:scale-110">
                          <Share2 className="w-5 h-5 text-slate-600" />
                        </button>
                      </div>
                    </div>

                    {/* Product Features */}
                    <div className="grid grid-cols-3 gap-3">
                      <div className="bg-blue-50 rounded-2xl p-4 text-center">
                        <TruckIcon className="w-7 h-7 text-blue-600 mx-auto mb-2" />
                        <span className="text-xs font-semibold text-slate-700">Free Delivery</span>
                      </div>
                      <div className="bg-green-50 rounded-2xl p-4 text-center">
                        <ShieldCheck className="w-7 h-7 text-green-600 mx-auto mb-2" />
                        <span className="text-xs font-semibold text-slate-700">7 Days Return</span>
                      </div>
                      <div className="bg-purple-50 rounded-2xl p-4 text-center">
                        <Zap className="w-7 h-7 text-purple-600 mx-auto mb-2" />
                        <span className="text-xs font-semibold text-slate-700">Fast Support</span>
                      </div>
                    </div>
                  </div>

                  {/* Product Info */}
                  <div className="flex flex-col">
                    <div className="mb-4">
                      <span className="inline-flex items-center gap-1.5 px-4 py-2 bg-gradient-to-r from-blue-100 to-indigo-100 text-blue-700 rounded-full text-sm font-semibold">
                        <Package className="w-4 h-4" />
                        {(product.category as any)?.name || product.category || 'Category'}
                      </span>
                    </div>

                    <h1 className="text-2xl sm:text-3xl lg:text-4xl font-black text-slate-900 mb-4 leading-tight">{product.name}</h1>

                    {/* Rating */}
                    <div className="flex items-center gap-3 mb-6">
                      <div className="flex items-center gap-1 bg-yellow-50 px-3 py-1.5 rounded-full">
                        {[...Array(5)].map((_, i) => (
                          <Star key={i} className={`w-5 h-5 ${i < Math.round(product.rating) ? 'text-yellow-400 fill-yellow-400' : 'text-slate-200 fill-slate-200'}`} />
                        ))}
                        <span className="ml-2 font-bold text-slate-800">{product.rating.toFixed(1)}</span>
                      </div>
                      <span className="text-slate-500">({product.total_reviews.toLocaleString()} reviews)</span>
                    </div>

                    {/* Price */}
                    <div className="mb-6 p-4 bg-gradient-to-r from-slate-50 to-blue-50 rounded-2xl">
                      <div className="flex items-baseline gap-3">
                        <span className="text-4xl sm:text-5xl font-black bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">
                          ৳{(product.discount_price || product.price).toLocaleString()}
                        </span>
                        {product.discount_price && product.discount_price < product.price && (
                          <span className="text-xl text-slate-400 line-through">৳{product.price.toLocaleString()}</span>
                        )}
                      </div>
                      <p className="text-sm text-slate-500 mt-1">Inclusive of all taxes</p>
                    </div>

                    {/* Stock Status */}
                    <div className="flex items-center gap-2 mb-6">
                      {product.stock_quantity > 0 ? (
                        <>
                          <Check className="w-5 h-5 text-green-500" />
                          <span className="text-green-600 font-semibold">In Stock</span>
                          <span className="text-slate-500">({product.stock_quantity} available)</span>
                        </>
                      ) : (
                        <>
                          <X className="w-5 h-5 text-red-500" />
                          <span className="text-red-600 font-semibold">Out of Stock</span>
                        </>
                      )}
                    </div>

                    {/* Description */}
                    {product.description && (
                      <div className="mb-6">
                        <h3 className="text-lg font-bold text-slate-900 mb-3">Description</h3>
                        <p className="text-slate-600 leading-relaxed">{product.description}</p>
                      </div>
                    )}

                    <div className="flex-1" />

                    {/* Actions */}
                    <div className="space-y-3 mt-6">
                      <button onClick={() => setActiveTab('chat')} className="w-full bg-gradient-to-r from-blue-600 via-indigo-600 to-purple-600 text-white py-4 rounded-2xl font-bold text-lg hover:shadow-xl hover:shadow-blue-500/25 transition-all transform hover:scale-[1.02] flex items-center justify-center gap-3">
                        <MessageCircle className="w-6 h-6" />
                        Chat with Admin
                        <Sparkles className="w-5 h-5" />
                      </button>
                      <button onClick={onAddToCart} disabled={product.stock_quantity === 0} className="w-full bg-slate-100 text-slate-700 py-4 rounded-2xl font-bold text-lg hover:bg-slate-200 transition-all flex items-center justify-center gap-3 disabled:opacity-50 disabled:cursor-not-allowed">
                        <ShoppingCart className="w-6 h-6" />
                        Add to Cart
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ) : (
            /* Chat Tab */
            <div className="h-full flex flex-col bg-gradient-to-b from-slate-50 to-white">
              {!user ? (
                <div className="flex-1 flex items-center justify-center p-6">
                  <div className="text-center max-w-md">
                    <div className="w-24 h-24 bg-gradient-to-br from-blue-100 to-indigo-100 rounded-full flex items-center justify-center mx-auto mb-6">
                      <MessageCircle className="w-12 h-12 text-blue-600" />
                    </div>
                    <h3 className="text-2xl font-bold text-slate-900 mb-3">Sign in to Chat</h3>
                    <p className="text-slate-600 mb-6">Create an account or sign in to start a conversation with our support team</p>
                  </div>
                </div>
              ) : chatLoading ? (
                <div className="flex-1 flex items-center justify-center">
                  <div className="text-center">
                    <Loader2 className="w-12 h-12 animate-spin text-blue-600 mx-auto mb-4" />
                    <p className="text-slate-600">Connecting to support...</p>
                  </div>
                </div>
              ) : error ? (
                <div className="flex-1 flex items-center justify-center p-6">
                  <div className="text-center max-w-md">
                    <div className="w-20 h-20 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
                      <AlertCircle className="w-10 h-10 text-red-500" />
                    </div>
                    <h3 className="text-xl font-bold text-slate-900 mb-2">Connection Error</h3>
                    <p className="text-slate-600 mb-4">{error}</p>
                    <button onClick={initializeChat} className="px-6 py-2.5 bg-blue-600 text-white rounded-xl font-semibold hover:bg-blue-700 transition-colors flex items-center gap-2 mx-auto">
                      <RefreshCw className="w-5 h-5" /> Retry Connection
                    </button>
                  </div>
                </div>
              ) : (
                <>
                  {/* Product Context Banner */}
                  <div className="bg-gradient-to-r from-blue-600 to-indigo-600 text-white px-4 py-3">
                    <div className="flex items-center gap-4 max-w-4xl mx-auto">
                      <div className="w-12 h-12 bg-white/20 rounded-xl flex items-center justify-center flex-shrink-0">
                        {(product as any).image_url ? (
                          <img src={(product as any).image_url} alt="" className="w-10 h-10 object-contain rounded-lg" />
                        ) : (
                          <Package className="w-6 h-6" />
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm text-blue-100">Chatting about</p>
                        <p className="font-bold truncate">{product.name}</p>
                      </div>
                      <div className="text-right">
                        <p className="text-xl font-bold">৳{product.price.toLocaleString()}</p>
                      </div>
                    </div>
                  </div>

                  {/* Inquiry Info */}
                  {inquiry && (
                    <div className="bg-blue-50/80 backdrop-blur-sm border-b border-blue-100 px-4 py-2.5">
                      <div className="flex items-center justify-between text-sm max-w-4xl mx-auto">
                        <div className="flex items-center gap-3">
                          <span className="text-slate-500">Inquiry:</span>
                          <span className="font-mono font-semibold text-slate-700 bg-white px-2 py-0.5 rounded">#{inquiry.id.slice(0, 8)}</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <button onClick={() => setSoundEnabled(!soundEnabled)} className="p-1.5 hover:bg-blue-100 rounded-lg transition-colors" title={soundEnabled ? 'Mute notifications' : 'Enable notifications'}>
                            {soundEnabled ? <Volume2 className="w-4 h-4 text-blue-600" /> : <VolumeX className="w-4 h-4 text-slate-400" />}
                          </button>
                          <span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${inquiry.status === 'open' ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-600'}`}>
                            {inquiry.status === 'open' ? '● Active' : 'Closed'}
                          </span>
                        </div>
                      </div>
                    </div>
                  )}

                  {/* Messages */}
                  <div className="flex-1 overflow-y-auto px-4 py-6">
                    <div className="max-w-4xl mx-auto space-y-4">
                      {messages.length === 0 ? (
                        <div className="text-center py-12">
                          <div className="w-20 h-20 bg-gradient-to-br from-blue-100 to-indigo-100 rounded-full flex items-center justify-center mx-auto mb-4">
                            <MessageCircle className="w-10 h-10 text-blue-600" />
                          </div>
                          <h3 className="text-lg font-bold text-slate-900 mb-2">Start the Conversation</h3>
                          <p className="text-slate-500 max-w-sm mx-auto">Send a message to ask about {product.name}. Our support team typically responds within minutes.</p>
                        </div>
                      ) : (
                        <>
                          {messages.map((message) => {
                            const isSelf = isOwnMessage(message.sender_id);
                            const senderIsAdmin = (message.sender as any)?.role === 'admin';

                            return (
                              <MemoizedMessageBubble
                                key={message.id || message.tempId}
                                content={message.content}
                                timestamp={message.created_at}
                                isOwn={isSelf}
                                isAdmin={senderIsAdmin}
                                senderName={isSelf ? profile?.full_name || user?.email?.split('@')[0] || 'You' : senderIsAdmin ? 'Admin Support' : (message.sender as any)?.full_name || (message.sender as any)?.email?.split('@')[0] || 'User'}
                                senderAvatar={(message.sender as any)?.avatar_url}
                                imageUrl={message.image_url || undefined}
                                status={message.status}
                                onRetry={() => handleRetryMessage(message)}
                              />
                            );
                          })}
                          
                          {adminTyping && <TypingIndicator userName="Admin" isAdmin />}
                          <div ref={messagesEndRef} />
                        </>
                      )}
                    </div>
                  </div>

                  {/* Chat Input */}
                  <div className="border-t border-slate-200 bg-white px-4 py-3">
                    <form onSubmit={handleSendMessage} className="max-w-4xl mx-auto">
                      <div className="flex items-end gap-3">
                        <div className="flex-1 relative">
                          <textarea
                            ref={inputRef}
                            value={newMessage}
                            onChange={(e) => setNewMessage(e.target.value)}
                            onKeyDown={handleKeyDown}
                            placeholder={`Ask about ${product.name}...`}
                            disabled={sending || connectionStatus === 'disconnected'}
                            rows={1}
                            className="w-full px-4 py-3 bg-slate-100 border-0 rounded-2xl resize-none focus:ring-2 focus:ring-blue-500 focus:bg-white transition-all text-slate-900 placeholder:text-slate-400 disabled:opacity-50"
                            style={{ maxHeight: '120px' }}
                          />
                        </div>
                        <button
                          type="submit"
                          disabled={!newMessage.trim() || sending || connectionStatus === 'disconnected'}
                          className={`p-3.5 rounded-2xl transition-all transform ${
                            newMessage.trim() ? 'bg-gradient-to-r from-blue-600 to-indigo-600 text-white shadow-lg hover:shadow-xl hover:scale-105' : 'bg-slate-200 text-slate-400'
                          } disabled:opacity-50 disabled:transform-none disabled:hover:shadow-none`}
                        >
                          {sending ? <Loader2 className="w-5 h-5 animate-spin" /> : <Send className="w-5 h-5" />}
                        </button>
                      </div>
                    </form>
                  </div>
                </>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
