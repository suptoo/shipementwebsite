import React, { useState, useEffect, useRef } from 'react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../context/AuthContext';
import { Message, Inquiry } from '../../types';
import { Send, Paperclip, X, Loader2, Info } from 'lucide-react';
import { ensureProfileRecord } from '../../lib/profileUtils';

interface ChatWindowProps {
  inquiry: Inquiry;
  onClose: () => void;
}

export const ChatWindow: React.FC<ChatWindowProps> = ({ inquiry, onClose }) => {
  const { user, profile } = useAuth();
  const [messages, setMessages] = useState<Message[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [showSurvey, setShowSurvey] = useState(true);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    fetchMessages();
    subscribeToMessages();
  }, [inquiry.id]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const fetchMessages = async () => {
    try {
      const { data, error } = await supabase
        .from('messages')
        .select('*')
        .eq('inquiry_id', inquiry.id)
        .order('created_at', { ascending: true });

      if (error) throw error;
      setMessages(data || []);
    } catch (error) {
      console.error('Error fetching messages:', error);
    } finally {
      setLoading(false);
    }
  };

  const subscribeToMessages = () => {
    const channel = supabase
      .channel(`inquiry:${inquiry.id}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
          filter: `inquiry_id=eq.${inquiry.id}`,
        },
        (payload) => {
          setMessages((prev) => [...prev, payload.new as Message]);
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  };

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newMessage.trim() || !user) return;

    setSending(true);
    try {
      await ensureProfileRecord(user);
      const { error } = await supabase.from('messages').insert({
        inquiry_id: inquiry.id,
        sender_id: user.id,
        content: newMessage.trim(),
      });

      if (error) throw error;
      setNewMessage('');
    } catch (error: any) {
      alert('Error sending message: ' + error.message);
    } finally {
      setSending(false);
    }
  };

  const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !user) return;

    // Check file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      alert('File size must be less than 5MB');
      return;
    }

    // Check file type
    if (!file.type.startsWith('image/')) {
      alert('Only image files are allowed');
      return;
    }

    setUploading(true);
    try {
      await ensureProfileRecord(user);
      const fileExt = file.name.split('.').pop();
      const fileName = `${user.id}/${Date.now()}.${fileExt}`;

      // Upload to Supabase Storage
      const { error: uploadError } = await supabase.storage
        .from('chat-attachments')
        .upload(fileName, file);

      if (uploadError) throw uploadError;

      // Get public URL
      const { data: urlData } = supabase.storage
        .from('chat-attachments')
        .getPublicUrl(fileName);

      // Insert message with image
      const { error: messageError } = await supabase.from('messages').insert({
        inquiry_id: inquiry.id,
        sender_id: user.id,
        content: 'Sent an image',
        image_url: urlData.publicUrl,
      });

      if (messageError) throw messageError;
    } catch (error: any) {
      alert('Error uploading image: ' + error.message);
    } finally {
      setUploading(false);
      if (fileInputRef.current) fileInputRef.current.value = '';
    }
  };

  const isAdmin = profile?.role === 'admin';
  const isOwnMessage = (senderId: string) => senderId === user?.id;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-60 backdrop-blur-sm flex items-center justify-center p-4 z-50 animate-in fade-in duration-200">
      <div className="bg-white rounded-2xl max-w-4xl w-full h-[85vh] flex flex-col shadow-2xl transform transition-all">
        {/* Header */}
        <div className="bg-blue-900 text-white p-4 rounded-t-lg flex justify-between items-center">
          <div>
            <h2 className="text-xl font-bold">Support Chat</h2>
            <p className="text-blue-100 text-sm">Inquiry #{inquiry.id.slice(0, 8)}</p>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setShowSurvey(!showSurvey)}
              className="p-2 hover:bg-blue-800 rounded-lg transition-colors"
              title="Toggle Survey Info"
            >
              <Info className="w-5 h-5" />
            </button>
            <button
              onClick={onClose}
              className="p-2 hover:bg-blue-800 rounded-lg transition-colors"
            >
              <X className="w-6 h-6" />
            </button>
          </div>
        </div>

        {/* Survey Context (for Admins) */}
        {isAdmin && showSurvey && (
          <div className="bg-blue-50 border-b border-blue-200 p-4">
            <h3 className="font-semibold text-blue-900 mb-2">Customer Requirements:</h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-3 text-sm">
              <div>
                <span className="text-slate-600">Amount:</span>
                <span className="ml-2 font-medium">{inquiry.survey_amount}</span>
              </div>
              <div>
                <span className="text-slate-600">Address:</span>
                <span className="ml-2 font-medium">{inquiry.survey_address}</span>
              </div>
              <div>
                <span className="text-slate-600">Days:</span>
                <span className="ml-2 font-medium">{inquiry.survey_days} days</span>
              </div>
            </div>
          </div>
        )}

        {/* Messages */}
        <div className="flex-1 overflow-y-auto p-4 bg-slate-50">
          {loading ? (
            <div className="flex items-center justify-center h-full">
              <Loader2 className="w-8 h-8 animate-spin text-blue-900" />
            </div>
          ) : messages.length === 0 ? (
            <div className="text-center text-slate-500 mt-8">
              No messages yet. Start the conversation!
            </div>
          ) : (
            <div className="space-y-4">
              {messages.map((message) => {
                const isSelf = isOwnMessage(message.sender_id);
                return (
                  <div
                    key={message.id}
                    className={`flex ${isSelf ? 'justify-end' : 'justify-start'}`}
                  >
                    <div
                      className={`max-w-[70%] ${
                        isSelf
                          ? 'bg-blue-900 text-white'
                          : 'bg-white text-slate-800 border border-slate-200'
                      } rounded-lg p-3 shadow-sm`}
                    >
                      {message.image_url && (
                        <img
                          src={message.image_url}
                          alt="Attachment"
                          className="rounded-lg mb-2 max-w-full"
                        />
                      )}
                      <p className="whitespace-pre-wrap break-words">{message.content}</p>
                      <p
                        className={`text-xs mt-1 ${
                          isSelf ? 'text-blue-200' : 'text-slate-500'
                        }`}
                      >
                        {new Date(message.created_at).toLocaleTimeString()}
                      </p>
                    </div>
                  </div>
                );
              })}
              <div ref={messagesEndRef} />
            </div>
          )}
        </div>

        {/* Input */}
        <div className="border-t border-slate-200 p-4 bg-white rounded-b-lg">
          <form onSubmit={handleSendMessage} className="flex gap-2">
            <input
              type="file"
              ref={fileInputRef}
              onChange={handleFileSelect}
              accept="image/*"
              className="hidden"
            />
            <button
              type="button"
              onClick={() => fileInputRef.current?.click()}
              disabled={uploading}
              className="p-3 text-slate-600 hover:bg-slate-100 rounded-lg transition-colors disabled:opacity-50"
              title="Attach Image"
            >
              {uploading ? (
                <Loader2 className="w-5 h-5 animate-spin" />
              ) : (
                <Paperclip className="w-5 h-5" />
              )}
            </button>
            <input
              type="text"
              value={newMessage}
              onChange={(e) => setNewMessage(e.target.value)}
              placeholder="Type your message..."
              className="flex-1 px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
            <button
              type="submit"
              disabled={sending || !newMessage.trim()}
              className="bg-blue-900 text-white px-6 py-2 rounded-lg hover:bg-blue-800 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
            >
              {sending ? (
                <Loader2 className="w-5 h-5 animate-spin" />
              ) : (
                <>
                  <Send className="w-5 h-5" />
                  Send
                </>
              )}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};
