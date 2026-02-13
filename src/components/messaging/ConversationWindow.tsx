import React, { useState, useEffect, useRef } from 'react';
import { Send, X, MessageCircle, CreditCard, Loader2, Bot, DollarSign } from 'lucide-react';
import { messagingService } from '../../services/messagingService';
import { useAuth } from '../../context/AuthContext';
import { Message, Conversation } from '../../types';
import { useNavigate } from 'react-router-dom';

interface ConversationWindowProps {
  conversation: Conversation;
  onClose: () => void;
}

export const ConversationWindow: React.FC<ConversationWindowProps> = ({ conversation, onClose }) => {
  const { user, profile } = useAuth();
  const navigate = useNavigate();
  const [messages, setMessages] = useState<Message[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [showPaymentModal, setShowPaymentModal] = useState(false);
  const [paymentAmount, setPaymentAmount] = useState('');
  const [paymentDescription, setPaymentDescription] = useState('');
  const [sendingPayment, setSendingPayment] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    loadMessages();
    markAsRead();

    // Subscribe to new messages
    const subscription = messagingService.subscribeToMessages(conversation.id, (message) => {
      setMessages(prev => [...prev, message]);
      scrollToBottom();
    });

    return () => {
      subscription.unsubscribe();
    };
  }, [conversation.id]);

  const loadMessages = async () => {
    try {
      const data = await messagingService.getMessages(conversation.id);
      setMessages(data);
      scrollToBottom();
    } catch (error) {
      console.error('Error loading messages:', error);
    } finally {
      setLoading(false);
    }
  };

  const markAsRead = async () => {
    if (!user) return;
    try {
      await messagingService.markMessagesAsRead(conversation.id, user.id);
    } catch (error) {
      console.error('Error marking messages as read:', error);
    }
  };

  const scrollToBottom = () => {
    setTimeout(() => {
      messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    }, 100);
  };

  const handleSend = async () => {
    if (!newMessage.trim() || !user || sending) return;

    setSending(true);
    try {
      const senderType = profile?.role === 'admin' ? 'admin' : 
                        conversation.type === 'buyer_seller' && conversation.seller_id ? 'seller' : 'buyer';

      await messagingService.sendMessage({
        conversationId: conversation.id,
        senderId: user.id,
        senderType,
        content: newMessage.trim()
      });

      setNewMessage('');
    } catch (error) {
      console.error('Error sending message:', error);
      alert('Failed to send message');
    } finally {
      setSending(false);
    }
  };

  const getOtherPartyName = () => {
    if (conversation.type === 'buyer_seller') {
      return profile?.role === 'seller' 
        ? conversation.buyer?.full_name || 'Customer'
        : conversation.seller?.business_name || 'Seller';
    } else if (conversation.type === 'buyer_admin') {
      return profile?.role === 'admin' ? conversation.buyer?.full_name : 'Support Team';
    }
    return 'Support';
  };

  const handleSendPaymentRequest = async () => {
    if (!paymentAmount || !user || sendingPayment) return;
    
    setSendingPayment(true);
    try {
      await messagingService.sendPaymentRequest({
        conversationId: conversation.id,
        senderId: user.id,
        amount: parseFloat(paymentAmount),
        description: paymentDescription || 'Payment Request',
      });
      setPaymentAmount('');
      setPaymentDescription('');
      setShowPaymentModal(false);
    } catch (error) {
      console.error('Error sending payment request:', error);
      alert('Failed to send payment request');
    } finally {
      setSendingPayment(false);
    }
  };

  const renderMessage = (message: Message) => {
    const isOwn = message.sender_id === user?.id;
    const paymentRequest = messagingService.parsePaymentRequest(message.content);

    if (paymentRequest) {
      return (
        <div key={message.id} className="flex justify-center my-4">
          <div className="w-full max-w-[90%] bg-gradient-to-br from-emerald-50 via-teal-50 to-cyan-50 border-2 border-emerald-200 rounded-2xl p-5 shadow-lg">
            <div className="flex items-center gap-3 mb-3">
              <div className="w-12 h-12 bg-gradient-to-br from-emerald-500 to-teal-500 rounded-xl flex items-center justify-center shadow-lg">
                <CreditCard className="w-6 h-6 text-white" />
              </div>
              <div>
                <span className="font-bold text-emerald-800 text-lg">Payment Request</span>
                <p className="text-sm text-emerald-600">From Support Team</p>
              </div>
            </div>
            
            <div className="bg-white/80 rounded-xl p-4 mb-4">
              <p className="text-4xl font-black text-gray-900 mb-1">৳{paymentRequest.amount.toLocaleString()}</p>
              <p className="text-gray-600">{paymentRequest.description}</p>
            </div>
            
            {!isOwn && paymentRequest.status === 'pending' && (
              <button
                onClick={() => navigate(`/checkout?payment_request=${paymentRequest.id}&amount=${paymentRequest.amount}&desc=${encodeURIComponent(paymentRequest.description)}`)}
                className="w-full bg-gradient-to-r from-emerald-500 via-teal-500 to-cyan-500 text-white px-6 py-3 rounded-xl font-bold text-lg hover:shadow-xl hover:shadow-emerald-500/30 transition-all transform hover:scale-[1.02]"
              >
                💳 Pay Now
              </button>
            )}
            
            {paymentRequest.status === 'paid' && (
              <div className="w-full bg-green-100 text-green-700 px-6 py-3 rounded-xl font-bold text-center">
                ✓ Payment Completed
              </div>
            )}
            
            <p className="text-xs text-gray-500 text-center mt-3">
              {new Date(message.created_at).toLocaleString()}
            </p>
          </div>
        </div>
      );
    }

    return (
      <div key={message.id} className={`flex ${isOwn ? 'justify-end' : 'justify-start'}`}>
        <div className={`max-w-[80%] rounded-2xl p-3 shadow-sm ${
          isOwn 
            ? 'bg-gradient-to-br from-blue-600 to-purple-600 text-white' 
            : 'bg-white text-slate-800 border border-slate-200'
        }`}>
          {!isOwn && (
            <div className="flex items-center gap-2 mb-1">
              <Bot className="w-4 h-4 text-purple-500" />
              <span className="text-xs font-semibold text-purple-600">
                {message.sender?.full_name || 'Support'}
              </span>
            </div>
          )}
          <p className="text-sm whitespace-pre-wrap leading-relaxed">{message.content}</p>
          <p className={`text-xs mt-2 ${isOwn ? 'text-blue-200' : 'text-slate-500'}`}>
            {new Date(message.created_at).toLocaleTimeString([], { 
              hour: '2-digit', 
              minute: '2-digit' 
            })}
          </p>
        </div>
      </div>
    );
  };

  return (
    <div className="fixed bottom-4 right-4 w-[420px] h-[600px] bg-white rounded-2xl shadow-2xl flex flex-col z-50 border border-gray-200 overflow-hidden">
      {/* Header */}
      <div className="bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 text-white p-4 flex items-center justify-between relative overflow-hidden flex-shrink-0">
        <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-full -translate-y-1/2 translate-x-1/2 blur-xl"></div>
        <div className="flex items-center gap-3 relative z-10">
          <div className="w-10 h-10 bg-white/20 backdrop-blur-sm rounded-xl flex items-center justify-center">
            <MessageCircle className="w-5 h-5" />
          </div>
          <div>
            <h3 className="font-bold">{getOtherPartyName()}</h3>
            {conversation.product && (
              <p className="text-xs text-white/80">About: {conversation.product.name}</p>
            )}
          </div>
        </div>
        <div className="flex items-center gap-2 relative z-10">
          {profile?.role === 'admin' && (
            <button 
              onClick={() => setShowPaymentModal(true)}
              className="p-2 hover:bg-white/10 rounded-lg transition-colors"
              title="Send Payment Request"
            >
              <DollarSign className="w-5 h-5" />
            </button>
          )}
          <button onClick={onClose} className="p-2 hover:bg-white/10 rounded-lg transition-colors">
            <X className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-3 bg-gradient-to-b from-slate-50 to-white">
        {loading ? (
          <div className="text-center text-slate-500 py-8">
            <Loader2 className="w-8 h-8 animate-spin mx-auto mb-2" />
            Loading messages...
          </div>
        ) : messages.length === 0 ? (
          <div className="text-center py-8">
            <div className="w-16 h-16 bg-gradient-to-br from-blue-100 to-purple-100 rounded-2xl flex items-center justify-center mx-auto mb-3">
              <MessageCircle className="w-8 h-8 text-blue-500" />
            </div>
            <p className="text-slate-500">No messages yet. Start the conversation!</p>
          </div>
        ) : (
          messages.map(renderMessage)
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Input */}
      <div className="border-t p-4 bg-white flex-shrink-0">
        <div className="flex gap-2">
          <input
            type="text"
            value={newMessage}
            onChange={(e) => setNewMessage(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && !e.shiftKey && handleSend()}
            placeholder="Type a message..."
            className="flex-1 px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-purple-500 focus:border-transparent text-sm transition-all"
            disabled={sending}
          />
          <button
            onClick={handleSend}
            disabled={!newMessage.trim() || sending}
            className="bg-gradient-to-r from-blue-600 to-purple-600 text-white px-5 py-3 rounded-xl hover:shadow-lg hover:shadow-purple-500/30 disabled:bg-slate-300 disabled:cursor-not-allowed disabled:shadow-none transition-all"
          >
            {sending ? <Loader2 className="w-5 h-5 animate-spin" /> : <Send className="w-5 h-5" />}
          </button>
        </div>
      </div>

      {/* Payment Request Modal */}
      {showPaymentModal && (
        <div className="absolute inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 z-10">
          <div className="bg-white rounded-2xl p-6 w-full max-w-sm shadow-2xl">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-12 h-12 bg-gradient-to-br from-emerald-500 to-teal-500 rounded-xl flex items-center justify-center">
                <CreditCard className="w-6 h-6 text-white" />
              </div>
              <div>
                <h3 className="font-bold text-lg text-gray-800">Send Payment Request</h3>
                <p className="text-sm text-gray-500">Request payment from customer</p>
              </div>
            </div>
            
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">Amount (৳)</label>
                <input
                  type="number"
                  value={paymentAmount}
                  onChange={(e) => setPaymentAmount(e.target.value)}
                  placeholder="0.00"
                  className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500 focus:border-transparent text-lg font-bold"
                />
              </div>
              
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">Description</label>
                <input
                  type="text"
                  value={paymentDescription}
                  onChange={(e) => setPaymentDescription(e.target.value)}
                  placeholder="e.g., Product payment, Service fee..."
                  className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500 focus:border-transparent"
                />
              </div>
            </div>
            
            <div className="flex gap-3 mt-6">
              <button
                onClick={() => setShowPaymentModal(false)}
                className="flex-1 px-4 py-3 bg-slate-100 text-slate-700 rounded-xl font-semibold hover:bg-slate-200 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleSendPaymentRequest}
                disabled={!paymentAmount || sendingPayment}
                className="flex-1 bg-gradient-to-r from-emerald-500 to-teal-500 text-white px-4 py-3 rounded-xl font-semibold hover:shadow-lg hover:shadow-emerald-500/30 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
              >
                {sendingPayment ? <Loader2 className="w-5 h-5 animate-spin mx-auto" /> : 'Send Request'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
