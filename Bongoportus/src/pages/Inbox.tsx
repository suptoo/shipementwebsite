import React, { useState, useEffect, useRef, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { supabase } from '../lib/supabase';
import { 
  MessageCircle, Send, Clock, CheckCircle2, User, Shield, 
  Search, Filter, Archive, Trash2, Star, MoreVertical,
  ChevronRight, Package, Loader2, RefreshCw, Bell, BellOff,
  Check, CheckCheck, AlertCircle, X, Sparkles
} from 'lucide-react';
import { ensureProfileRecord } from '../lib/profileUtils';

interface Message {
  id: string;
  inquiry_id: string;
  sender_id: string;
  content: string;
  created_at: string;
  is_read: boolean;
  status?: 'sending' | 'sent' | 'delivered' | 'read' | 'failed';
  tempId?: string;
  sender?: {
    email: string;
    role: string;
    full_name: string;
    avatar_url?: string;
  };
}

interface Inquiry {
  id: string;
  status: string;
  created_at: string;
  survey_amount: string;
  survey_address: string;
  survey_days: number;
  product_id?: string;
  product?: {
    name: string;
    image_url?: string;
    price: number;
  };
  last_message?: string;
  unread_count?: number;
}

export const Inbox: React.FC = () => {
  const { user, profile } = useAuth();
  const [inquiries, setInquiries] = useState<Inquiry[]>([]);
  const [selectedInquiry, setSelectedInquiry] = useState<string | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterStatus, setFilterStatus] = useState<'all' | 'open' | 'closed'>('all');
  const [showMobileChat, setShowMobileChat] = useState(false);
  const [connectionStatus, setConnectionStatus] = useState<'connected' | 'connecting' | 'disconnected'>('connecting');
  
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const channelRef = useRef<any>(null);

  useEffect(() => {
    if (user) {
      fetchInquiries();
    }
    return () => {
      if (channelRef.current) {
        supabase.removeChannel(channelRef.current);
      }
    };
  }, [user]);

  useEffect(() => {
    if (selectedInquiry) {
      fetchMessages(selectedInquiry);
      setupRealtimeSubscription(selectedInquiry);
      inputRef.current?.focus();
    }
  }, [selectedInquiry]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const scrollToBottom = useCallback(() => {
    setTimeout(() => {
      messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    }, 100);
  }, []);

  const fetchInquiries = async () => {
    try {
      // Single optimized query - fetch inquiries with product info
      const { data, error } = await supabase
        .from('inquiries')
        .select(`
          *,
          product:products(name, price)
        `)
        .eq('user_id', user?.id)
        .order('created_at', { ascending: false });

      if (error) throw error;
      
      const inquiryIds = (data || []).map(i => i.id);
      
      if (inquiryIds.length === 0) {
        setInquiries([]);
        setLoading(false);
        setConnectionStatus('connected');
        return;
      }

      // Batch fetch: Get last messages and unread counts in parallel
      const [lastMessagesResult, unreadCountsResult] = await Promise.all([
        // Fetch all last messages in one query using distinct on inquiry_id
        supabase
          .from('messages')
          .select('inquiry_id, content, created_at')
          .in('inquiry_id', inquiryIds)
          .order('inquiry_id')
          .order('created_at', { ascending: false }),
        // Fetch all unread counts
        supabase
          .from('messages')
          .select('inquiry_id')
          .in('inquiry_id', inquiryIds)
          .eq('is_read', false)
          .neq('sender_id', user?.id || '')
      ]);

      // Build lookup maps for O(1) access
      const lastMessageMap = new Map<string, string>();
      const seenInquiries = new Set<string>();
      (lastMessagesResult.data || []).forEach(msg => {
        if (!seenInquiries.has(msg.inquiry_id)) {
          lastMessageMap.set(msg.inquiry_id, msg.content);
          seenInquiries.add(msg.inquiry_id);
        }
      });

      const unreadCountMap = new Map<string, number>();
      (unreadCountsResult.data || []).forEach(msg => {
        unreadCountMap.set(msg.inquiry_id, (unreadCountMap.get(msg.inquiry_id) || 0) + 1);
      });

      // Enrich inquiries with pre-fetched data
      const enrichedInquiries = (data || []).map(inquiry => ({
        ...inquiry,
        last_message: lastMessageMap.get(inquiry.id),
        unread_count: unreadCountMap.get(inquiry.id) || 0
      }));

      setInquiries(enrichedInquiries);
      if (enrichedInquiries.length > 0 && !selectedInquiry) {
        setSelectedInquiry(enrichedInquiries[0].id);
      }
      setConnectionStatus('connected');
    } catch (error) {
      console.error('Error fetching inquiries:', error);
      setConnectionStatus('disconnected');
    } finally {
      setLoading(false);
    }
  };

  const fetchMessages = async (inquiryId: string) => {
    try {
      const { data, error } = await supabase
        .from('messages')
        .select(`
          *,
          sender:profiles!sender_id(email, role, full_name, avatar_url)
        `)
        .eq('inquiry_id', inquiryId)
        .order('created_at', { ascending: true });

      if (error) throw error;
      setMessages((data || []).map(m => ({ ...m, status: 'delivered' as const })));

      // Mark messages as read
      await supabase
        .from('messages')
        .update({ is_read: true })
        .eq('inquiry_id', inquiryId)
        .neq('sender_id', user?.id);

      // Update unread count in inquiries
      setInquiries(prev => prev.map(inq => 
        inq.id === inquiryId ? { ...inq, unread_count: 0 } : inq
      ));
    } catch (error) {
      console.error('Error fetching messages:', error);
    }
  };

  const setupRealtimeSubscription = (inquiryId: string) => {
    if (channelRef.current) {
      supabase.removeChannel(channelRef.current);
    }

    channelRef.current = supabase
      .channel(`inbox-messages:${inquiryId}`)
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'messages', filter: `inquiry_id=eq.${inquiryId}` },
        async (payload) => {
          const { data: fullMessage } = await supabase
            .from('messages')
            .select(`*, sender:profiles!sender_id(email, role, full_name, avatar_url)`)
            .eq('id', payload.new.id)
            .single();

          if (fullMessage) {
            setMessages(prev => {
              const exists = prev.some(m => m.id === fullMessage.id || m.tempId === fullMessage.id);
              if (exists) return prev.map(m => m.tempId === fullMessage.id ? { ...fullMessage, status: 'delivered' as const } : m);
              return [...prev, { ...fullMessage, status: 'delivered' as const }];
            });

            // Update last message in inquiries
            setInquiries(prev => prev.map(inq => 
              inq.id === inquiryId ? { ...inq, last_message: fullMessage.content } : inq
            ));

            // Mark as read if we're viewing this inquiry
            if (fullMessage.sender_id !== user?.id) {
              await supabase.from('messages').update({ is_read: true }).eq('id', fullMessage.id);
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
    if (!newMessage.trim() || !selectedInquiry || !user || sending) return;

    const tempId = `temp-${Date.now()}`;
    const messageContent = newMessage.trim();

    const optimisticMessage: Message = {
      id: tempId,
      tempId,
      inquiry_id: selectedInquiry,
      sender_id: user.id,
      content: messageContent,
      is_read: false,
      created_at: new Date().toISOString(),
      status: 'sending',
      sender: {
        email: user.email || '',
        role: profile?.role || 'user',
        full_name: profile?.full_name || '',
        avatar_url: profile?.avatar_url || undefined
      }
    };

    setMessages(prev => [...prev, optimisticMessage]);
    setNewMessage('');
    setSending(true);

    try {
      await ensureProfileRecord(user);
      
      const { data, error } = await supabase
        .from('messages')
        .insert({ inquiry_id: selectedInquiry, sender_id: user.id, content: messageContent })
        .select()
        .single();

      if (error) throw error;

      setMessages(prev => prev.map(m => m.tempId === tempId ? { ...m, id: data.id, status: 'sent' as const } : m));
      
      // Update last message in inquiries
      setInquiries(prev => prev.map(inq => 
        inq.id === selectedInquiry ? { ...inq, last_message: messageContent } : inq
      ));
    } catch (error: any) {
      console.error('Error sending message:', error);
      setMessages(prev => prev.map(m => m.tempId === tempId ? { ...m, status: 'failed' as const } : m));
    } finally {
      setSending(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  const handleRetryMessage = (message: Message) => {
    setMessages(prev => prev.filter(m => m.tempId !== message.tempId));
    setNewMessage(message.content);
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `${diffMins}m`;
    if (diffHours < 24) return `${diffHours}h`;
    if (diffDays < 7) return `${diffDays}d`;
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  const filteredInquiries = inquiries.filter(inquiry => {
    const matchesSearch = searchQuery === '' || 
      inquiry.survey_amount.toLowerCase().includes(searchQuery.toLowerCase()) ||
      inquiry.product?.name?.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesFilter = filterStatus === 'all' || inquiry.status === filterStatus;
    return matchesSearch && matchesFilter;
  });

  const currentInquiry = inquiries.find(i => i.id === selectedInquiry);
  const totalUnread = inquiries.reduce((sum, inq) => sum + (inq.unread_count || 0), 0);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-50 to-blue-50">
        <div className="text-center">
          <div className="relative">
            <div className="w-20 h-20 border-4 border-blue-200 rounded-full animate-pulse" />
            <div className="absolute inset-0 flex items-center justify-center">
              <Loader2 className="w-10 h-10 text-blue-600 animate-spin" />
            </div>
          </div>
          <p className="mt-4 text-slate-600 font-medium">Loading your messages...</p>
        </div>
      </div>
    );
  }

  if (inquiries.length === 0) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-50 to-blue-50 pt-20">
        <div className="text-center max-w-md px-6">
          <div className="w-32 h-32 bg-gradient-to-br from-blue-100 to-indigo-100 rounded-full flex items-center justify-center mx-auto mb-6">
            <MessageCircle className="w-16 h-16 text-blue-600" />
          </div>
          <h2 className="text-3xl font-bold text-slate-900 mb-3">No conversations yet</h2>
          <p className="text-slate-600 mb-6">
            Start a conversation by clicking on any product and chatting with our support team
          </p>
          <a href="/" className="inline-flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-blue-600 to-indigo-600 text-white font-semibold rounded-xl hover:shadow-lg transition-all">
            <Package className="w-5 h-5" />
            Browse Products
          </a>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-blue-50 pt-16">
      <div className="h-[calc(100vh-64px)] flex">
        {/* Sidebar - Inquiry List */}
        <div className={`${showMobileChat ? 'hidden' : 'flex'} lg:flex flex-col w-full lg:w-96 bg-white border-r border-slate-200 shadow-sm`}>
          {/* Header */}
          <div className="p-4 border-b border-slate-200 bg-gradient-to-r from-slate-900 to-blue-900 text-white">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-white/10 rounded-xl flex items-center justify-center">
                  <MessageCircle className="w-5 h-5" />
                </div>
                <div>
                  <h1 className="text-xl font-bold">Messages</h1>
                  <p className="text-xs text-blue-200">{inquiries.length} conversations</p>
                </div>
              </div>
              {totalUnread > 0 && (
                <span className="px-3 py-1 bg-red-500 text-white text-sm font-bold rounded-full animate-pulse">
                  {totalUnread}
                </span>
              )}
            </div>

            {/* Search */}
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search conversations..."
                className="w-full pl-10 pr-4 py-2.5 bg-white/10 border border-white/20 rounded-xl text-white placeholder:text-blue-200 focus:outline-none focus:ring-2 focus:ring-white/30"
              />
            </div>
          </div>

          {/* Filter Tabs */}
          <div className="flex border-b border-slate-200 bg-slate-50">
            {(['all', 'open', 'closed'] as const).map((status) => (
              <button
                key={status}
                onClick={() => setFilterStatus(status)}
                className={`flex-1 py-2.5 text-sm font-semibold transition-all ${
                  filterStatus === status 
                    ? 'text-blue-600 border-b-2 border-blue-600 bg-white' 
                    : 'text-slate-500 hover:text-slate-700'
                }`}
              >
                {status.charAt(0).toUpperCase() + status.slice(1)}
              </button>
            ))}
          </div>

          {/* Inquiry List */}
          <div className="flex-1 overflow-y-auto">
            {filteredInquiries.map((inquiry) => (
              <button
                key={inquiry.id}
                onClick={() => {
                  setSelectedInquiry(inquiry.id);
                  setShowMobileChat(true);
                }}
                className={`w-full text-left p-4 border-b border-slate-100 hover:bg-slate-50 transition-all ${
                  selectedInquiry === inquiry.id ? 'bg-blue-50 border-l-4 border-l-blue-500' : ''
                }`}
              >
                <div className="flex items-start gap-3">
                  {/* Product Image or Icon */}
                  <div className="w-12 h-12 bg-gradient-to-br from-blue-100 to-indigo-100 rounded-xl flex items-center justify-center flex-shrink-0">
                    <Package className="w-6 h-6 text-blue-600" />
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between mb-1">
                      <span className="font-semibold text-slate-900 truncate">
                        {inquiry.product?.name || `Inquiry #${inquiry.id.slice(0, 6)}`}
                      </span>
                      <span className="text-xs text-slate-500 flex-shrink-0 ml-2">
                        {formatDate(inquiry.created_at)}
                      </span>
                    </div>
                    
                    <p className="text-sm text-slate-600 truncate mb-1">
                      {inquiry.last_message || inquiry.survey_amount}
                    </p>

                    <div className="flex items-center justify-between">
                      <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${
                        inquiry.status === 'open' 
                          ? 'bg-green-100 text-green-700' 
                          : 'bg-slate-100 text-slate-600'
                      }`}>
                        {inquiry.status === 'open' ? '● Active' : 'Closed'}
                      </span>
                      {(inquiry.unread_count || 0) > 0 && (
                        <span className="w-5 h-5 bg-blue-600 text-white text-xs font-bold rounded-full flex items-center justify-center">
                          {inquiry.unread_count}
                        </span>
                      )}
                    </div>
                  </div>

                  <ChevronRight className="w-5 h-5 text-slate-400 flex-shrink-0 self-center" />
                </div>
              </button>
            ))}
          </div>
        </div>

        {/* Chat Area */}
        <div className={`${showMobileChat ? 'flex' : 'hidden'} lg:flex flex-1 flex-col bg-white`}>
          {currentInquiry ? (
            <>
              {/* Chat Header */}
              <div className="p-4 border-b border-slate-200 bg-gradient-to-r from-blue-600 to-indigo-600 text-white">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <button 
                      onClick={() => setShowMobileChat(false)}
                      className="lg:hidden p-2 hover:bg-white/10 rounded-lg"
                    >
                      <ChevronRight className="w-5 h-5 rotate-180" />
                    </button>
                    <div className="w-10 h-10 bg-white/20 rounded-xl flex items-center justify-center">
                      <Package className="w-5 h-5" />
                    </div>
                    <div>
                      <h3 className="font-bold">
                        {currentInquiry.product?.name || `Inquiry #${currentInquiry.id.slice(0, 8)}`}
                      </h3>
                      <p className="text-sm text-blue-100">
                        {currentInquiry.survey_amount}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className={`flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium ${
                      connectionStatus === 'connected' ? 'bg-green-500/20 text-green-100' 
                      : connectionStatus === 'connecting' ? 'bg-yellow-500/20 text-yellow-100'
                      : 'bg-red-500/20 text-red-100'
                    }`}>
                      <div className={`w-2 h-2 rounded-full ${
                        connectionStatus === 'connected' ? 'bg-green-400 animate-pulse' 
                        : connectionStatus === 'connecting' ? 'bg-yellow-400'
                        : 'bg-red-400'
                      }`} />
                      {connectionStatus === 'connected' ? 'Live' : connectionStatus === 'connecting' ? 'Connecting' : 'Offline'}
                    </div>
                    <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                      currentInquiry.status === 'open' 
                        ? 'bg-white/20 text-white' 
                        : 'bg-slate-500/30 text-slate-200'
                    }`}>
                      {currentInquiry.status === 'open' ? '● Active' : 'Closed'}
                    </span>
                  </div>
                </div>
              </div>

              {/* Messages */}
              <div className="flex-1 overflow-y-auto p-4 bg-gradient-to-b from-slate-50 to-white">
                <div className="max-w-3xl mx-auto space-y-4">
                  {messages.length === 0 ? (
                    <div className="text-center py-12">
                      <div className="w-20 h-20 bg-gradient-to-br from-blue-100 to-indigo-100 rounded-full flex items-center justify-center mx-auto mb-4">
                        <MessageCircle className="w-10 h-10 text-blue-600" />
                      </div>
                      <h3 className="text-lg font-bold text-slate-900 mb-2">Start the Conversation</h3>
                      <p className="text-slate-500">Send a message to get help from our support team</p>
                    </div>
                  ) : (
                    messages.map((message) => {
                      const isOwn = message.sender_id === user?.id;
                      const isAdmin = message.sender?.role === 'admin';
                      
                      return (
                        <div key={message.id || message.tempId} className={`flex gap-3 ${isOwn ? 'flex-row-reverse' : ''}`}>
                          {/* Avatar */}
                          <div className={`flex-shrink-0 ${isOwn ? 'hidden sm:block' : ''}`}>
                            {message.sender?.avatar_url ? (
                              <img src={message.sender.avatar_url} alt="" className="w-10 h-10 rounded-full object-cover ring-2 ring-white shadow-md" />
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
                          <div className={`max-w-[75%] ${isOwn ? 'items-end' : 'items-start'}`}>
                            <div className={`flex items-center gap-2 mb-1 ${isOwn ? 'flex-row-reverse' : ''}`}>
                              <span className={`text-xs font-semibold ${isAdmin ? 'text-purple-600' : 'text-slate-600'}`}>
                                {isOwn ? 'You' : isAdmin ? 'Admin Support' : message.sender?.full_name || 'User'}
                              </span>
                              {isAdmin && !isOwn && (
                                <span className="text-[10px] bg-purple-100 text-purple-700 px-1.5 py-0.5 rounded-full font-bold">ADMIN</span>
                              )}
                            </div>

                            <div className={`relative rounded-2xl px-4 py-3 shadow-sm ${
                              isOwn ? 'bg-gradient-to-br from-blue-600 to-blue-700 text-white rounded-tr-sm'
                              : isAdmin ? 'bg-gradient-to-br from-purple-50 to-indigo-50 text-slate-800 border border-purple-200 rounded-tl-sm'
                              : 'bg-white text-slate-800 border border-slate-200 rounded-tl-sm'
                            } ${message.status === 'failed' ? 'opacity-60' : ''}`}>
                              <p className="text-sm whitespace-pre-wrap break-words leading-relaxed">{message.content}</p>
                            </div>

                            <div className={`flex items-center gap-1.5 mt-1 ${isOwn ? 'justify-end' : 'justify-start'}`}>
                              <span className="text-[11px] text-slate-400">{formatDate(message.created_at)}</span>
                              {isOwn && (
                                <>
                                  {message.status === 'sending' && <Clock className="w-3.5 h-3.5 text-slate-400 animate-pulse" />}
                                  {message.status === 'sent' && <Check className="w-3.5 h-3.5 text-slate-400" />}
                                  {message.status === 'delivered' && <CheckCheck className="w-3.5 h-3.5 text-slate-400" />}
                                  {message.status === 'read' && <CheckCheck className="w-3.5 h-3.5 text-blue-400" />}
                                  {message.status === 'failed' && <AlertCircle className="w-3.5 h-3.5 text-red-500" />}
                                </>
                              )}
                            </div>

                            {message.status === 'failed' && (
                              <button onClick={() => handleRetryMessage(message)} className="mt-1 text-xs text-red-600 hover:text-red-700 font-medium flex items-center gap-1">
                                <AlertCircle className="w-3 h-3" /> Tap to retry
                              </button>
                            )}
                          </div>
                        </div>
                      );
                    })
                  )}
                  <div ref={messagesEndRef} />
                </div>
              </div>

              {/* Input */}
              <div className="border-t border-slate-200 bg-white px-4 py-3">
                <form onSubmit={handleSendMessage} className="max-w-3xl mx-auto">
                  <div className="flex items-end gap-3">
                    <div className="flex-1 relative">
                      <textarea
                        ref={inputRef}
                        value={newMessage}
                        onChange={(e) => setNewMessage(e.target.value)}
                        onKeyDown={handleKeyDown}
                        placeholder="Type your message..."
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
                      } disabled:opacity-50 disabled:transform-none`}
                    >
                      {sending ? <Loader2 className="w-5 h-5 animate-spin" /> : <Send className="w-5 h-5" />}
                    </button>
                  </div>
                </form>
              </div>
            </>
          ) : (
            <div className="flex-1 flex items-center justify-center">
              <div className="text-center">
                <div className="w-24 h-24 bg-gradient-to-br from-blue-100 to-indigo-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <MessageCircle className="w-12 h-12 text-blue-600" />
                </div>
                <h3 className="text-xl font-bold text-slate-900 mb-2">Select a conversation</h3>
                <p className="text-slate-500">Choose from your inquiries to start chatting</p>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
