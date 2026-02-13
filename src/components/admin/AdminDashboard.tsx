import React, { useState, useEffect } from 'react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../context/AuthContext';
import { messagingService } from '../../services/messagingService';
import { InquiryWithProfile, Conversation } from '../../types';
import {
  MessageSquare, Clock, User, Loader2,
  Users, DollarSign, TrendingUp, Mail,
  ChevronRight, Inbox, Send, CreditCard,
  CheckCircle, XCircle, Smartphone, Wallet,
  Package, Search
} from 'lucide-react';
import { ChatWindow } from '../chat/ChatWindow';
import { ConversationWindow } from '../messaging/ConversationWindow';

interface Order {
  id: string;
  order_number: string;
  user_id: string;
  delivery_full_name: string;
  delivery_phone: string;
  total_amount: number;
  payment_method: string;
  payment_status: string;
  order_status: string;
  stripe_payment_intent_id: string | null;
  payment_details: string | null;
  created_at: string;
}

export const AdminDashboard: React.FC = () => {
  const { profile, user } = useAuth();
  const [inquiries, setInquiries] = useState<InquiryWithProfile[]>([]);
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedInquiry, setSelectedInquiry] = useState<InquiryWithProfile | null>(null);
  const [selectedConversation, setSelectedConversation] = useState<Conversation | null>(null);
  const [activeTab, setActiveTab] = useState<'payments' | 'conversations' | 'inquiries'>('payments');
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    if (profile?.role === 'admin') {
      fetchInquiries();
      fetchConversations();
      fetchOrders();
      subscribeToInquiries();
    }
  }, [profile]);

  const fetchOrders = async () => {
    try {
      const { data, error } = await supabase
        .from('orders')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(50);

      if (error) throw error;
      setOrders(data || []);
    } catch (error) {
      console.error('Error fetching orders:', error);
    }
  };

  const fetchConversations = async () => {
    if (!user) return;
    try {
      const data = await messagingService.getUserConversations(user.id, 'admin');
      setConversations(data);
    } catch (error) {
      console.error('Error fetching conversations:', error);
    }
  };

  const fetchInquiries = async () => {
    try {
      const { data, error } = await supabase
        .from('inquiries')
        .select('*, profiles(*)')
        .eq('status', 'open')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setInquiries(data || []);
    } catch (error) {
      console.error('Error fetching inquiries:', error);
    } finally {
      setLoading(false);
    }
  };

  const subscribeToInquiries = () => {
    const channel = supabase
      .channel('admin-inquiries')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'inquiries',
        },
        () => {
          fetchInquiries();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  };

  const handleCloseInquiry = async (id: string) => {
    if (!confirm('Are you sure you want to close this inquiry?')) return;

    try {
      const { error } = await supabase
        .from('inquiries')
        .update({ status: 'closed' })
        .eq('id', id);

      if (error) throw error;
      setInquiries(inquiries.filter((i) => i.id !== id));
    } catch (error: any) {
      alert('Error closing inquiry: ' + error.message);
    }
  };

  if (profile?.role !== 'admin') {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg">
          Access denied. Admin privileges required.
        </div>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-blue-900" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-slate-50 py-8">
      <div className="container mx-auto px-4">
        {/* Admin Header */}
        <div className="mb-8 bg-gradient-to-r from-blue-900 via-blue-800 to-purple-900 rounded-3xl p-8 text-white shadow-2xl relative overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-white/10 to-transparent pointer-events-none"></div>
          <div className="absolute top-0 right-0 w-64 h-64 bg-purple-500/20 rounded-full -translate-y-1/2 translate-x-1/2 blur-3xl"></div>
          <div className="relative z-10">
            <div className="flex items-center gap-3 mb-3">
              <div className="w-14 h-14 bg-gradient-to-br from-yellow-400 to-orange-400 rounded-2xl flex items-center justify-center shadow-lg">
                <User className="w-8 h-8 text-blue-900" />
              </div>
              <div>
                <h1 className="text-4xl font-black tracking-tight">Admin Control Center</h1>
                <p className="text-blue-100 text-sm">Welcome back, {profile?.full_name || 'Administrator'}</p>
              </div>
            </div>
            <div className="mt-6 grid grid-cols-2 md:grid-cols-4 gap-4">
              <div className="bg-white/10 backdrop-blur-sm rounded-xl p-4 border border-white/20">
                <div className="flex items-center gap-2 mb-2">
                  <Users className="w-5 h-5 text-blue-300" />
                  <span className="text-sm text-blue-200">Active Chats</span>
                </div>
                <div className="text-3xl font-black">{conversations.length}</div>
              </div>
              <div className="bg-white/10 backdrop-blur-sm rounded-xl p-4 border border-white/20">
                <div className="flex items-center gap-2 mb-2">
                  <Mail className="w-5 h-5 text-purple-300" />
                  <span className="text-sm text-blue-200">Inquiries</span>
                </div>
                <div className="text-3xl font-black">{inquiries.length}</div>
              </div>
              <div className="bg-white/10 backdrop-blur-sm rounded-xl p-4 border border-white/20">
                <div className="flex items-center gap-2 mb-2">
                  <DollarSign className="w-5 h-5 text-green-300" />
                  <span className="text-sm text-blue-200">Today's Requests</span>
                </div>
                <div className="text-3xl font-black">
                  {conversations.filter(c => new Date(c.created_at).toDateString() === new Date().toDateString()).length}
                </div>
              </div>
              <div className="bg-white/10 backdrop-blur-sm rounded-xl p-4 border border-white/20">
                <div className="flex items-center gap-2 mb-2">
                  <TrendingUp className="w-5 h-5 text-yellow-300" />
                  <span className="text-sm text-blue-200">Response Rate</span>
                </div>
                <div className="text-3xl font-black">98%</div>
              </div>
            </div>
          </div>
        </div>

        {/* Tab Navigation */}
        <div className="flex gap-2 mb-6 flex-wrap">
          <button
            onClick={() => setActiveTab('payments')}
            className={`flex items-center gap-2 px-6 py-3 rounded-xl font-semibold transition-all ${activeTab === 'payments'
              ? 'bg-gradient-to-r from-green-600 to-emerald-600 text-white shadow-lg'
              : 'bg-white text-gray-600 hover:bg-gray-50 border border-gray-200'
              }`}
          >
            <CreditCard className="w-5 h-5" />
            Payment Tracking
            {orders.length > 0 && (
              <span className="ml-2 bg-white/20 px-2 py-0.5 rounded-full text-sm">
                {orders.length}
              </span>
            )}
          </button>
          <button
            onClick={() => setActiveTab('conversations')}
            className={`flex items-center gap-2 px-6 py-3 rounded-xl font-semibold transition-all ${activeTab === 'conversations'
              ? 'bg-gradient-to-r from-blue-600 to-purple-600 text-white shadow-lg'
              : 'bg-white text-gray-600 hover:bg-gray-50 border border-gray-200'
              }`}
          >
            <Inbox className="w-5 h-5" />
            Customer Chats
            {conversations.length > 0 && (
              <span className="ml-2 bg-white/20 px-2 py-0.5 rounded-full text-sm">
                {conversations.length}
              </span>
            )}
          </button>
          <button
            onClick={() => setActiveTab('inquiries')}
            className={`flex items-center gap-2 px-6 py-3 rounded-xl font-semibold transition-all ${activeTab === 'inquiries'
              ? 'bg-gradient-to-r from-blue-600 to-purple-600 text-white shadow-lg'
              : 'bg-white text-gray-600 hover:bg-gray-50 border border-gray-200'
              }`}
          >
            <MessageSquare className="w-5 h-5" />
            Support Tickets
            {inquiries.length > 0 && (
              <span className="ml-2 bg-white/20 px-2 py-0.5 rounded-full text-sm">
                {inquiries.length}
              </span>
            )}
          </button>
        </div>

        {/* Payments Tab */}
        {activeTab === 'payments' && (
          <>
            {/* Search Bar */}
            <div className="bg-white rounded-xl shadow-sm border p-4 mb-6">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
                <input
                  type="text"
                  placeholder="Search by order #, customer name, or phone..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                />
              </div>
            </div>

            {/* Demo orders when no real orders */}
            {(() => {
              const demoOrders: Order[] = orders.length > 0 ? orders : [
                {
                  id: 'demo-1',
                  order_number: 'ORD-20260101-001',
                  user_id: 'demo',
                  delivery_full_name: 'Umor Faruk',
                  delivery_phone: '01712345678',
                  total_amount: 15990,
                  payment_method: 'mobile',
                  payment_status: 'paid',
                  order_status: 'delivered',
                  stripe_payment_intent_id: null,
                  payment_details: JSON.stringify({ method: 'bkash', transactionId: 'TXN8K2M9P4Q1', accountNumber: '01712345678' }),
                  created_at: new Date().toISOString()
                },
                {
                  id: 'demo-2',
                  order_number: 'ORD-20260101-002',
                  user_id: 'demo',
                  delivery_full_name: 'Rafiq Ahmed',
                  delivery_phone: '01898765432',
                  total_amount: 25500,
                  payment_method: 'card',
                  payment_status: 'paid',
                  order_status: 'processing',
                  stripe_payment_intent_id: null,
                  payment_details: JSON.stringify({ method: 'visa', transactionId: 'TXN7V3N8K2L5', cardType: 'visa' }),
                  created_at: new Date(Date.now() - 3600000).toISOString()
                },
                {
                  id: 'demo-3',
                  order_number: 'ORD-20260101-003',
                  user_id: 'demo',
                  delivery_full_name: 'Fatima Begum',
                  delivery_phone: '01556789012',
                  total_amount: 8750,
                  payment_method: 'mobile',
                  payment_status: 'paid',
                  order_status: 'shipped',
                  stripe_payment_intent_id: null,
                  payment_details: JSON.stringify({ method: 'nagad', transactionId: 'TXN4N7M2P8Q3', accountNumber: '01556789012' }),
                  created_at: new Date(Date.now() - 7200000).toISOString()
                },
                {
                  id: 'demo-4',
                  order_number: 'ORD-20260101-004',
                  user_id: 'demo',
                  delivery_full_name: 'Karim Hossain',
                  delivery_phone: '01623456789',
                  total_amount: 42000,
                  payment_method: 'card',
                  payment_status: 'paid',
                  order_status: 'pending',
                  stripe_payment_intent_id: null,
                  payment_details: JSON.stringify({ method: 'mastercard', transactionId: 'TXN9M4C7K2L1', cardType: 'mastercard' }),
                  created_at: new Date(Date.now() - 10800000).toISOString()
                },
                {
                  id: 'demo-5',
                  order_number: 'ORD-20260101-005',
                  user_id: 'demo',
                  delivery_full_name: 'Nasrin Akter',
                  delivery_phone: '01934567890',
                  total_amount: 12500,
                  payment_method: 'cod',
                  payment_status: 'pending',
                  order_status: 'pending',
                  stripe_payment_intent_id: null,
                  payment_details: null,
                  created_at: new Date(Date.now() - 14400000).toISOString()
                }
              ];

              return (
                <div className="space-y-4">
                  {demoOrders
                    .filter(order =>
                      order.order_number.toLowerCase().includes(searchQuery.toLowerCase()) ||
                      order.delivery_full_name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
                      order.delivery_phone?.includes(searchQuery)
                    )
                    .map((order) => {
                      const paymentDetails = order.payment_details ? JSON.parse(order.payment_details) : null;

                      const getPaymentIcon = () => {
                        if (paymentDetails?.method === 'bkash') return <Smartphone className="w-5 h-5 text-pink-600" />;
                        if (paymentDetails?.method === 'nagad') return <Smartphone className="w-5 h-5 text-orange-600" />;
                        if (paymentDetails?.method === 'visa') return <CreditCard className="w-5 h-5 text-blue-600" />;
                        if (paymentDetails?.method === 'mastercard') return <CreditCard className="w-5 h-5 text-orange-600" />;
                        if (order.payment_method === 'cod') return <Wallet className="w-5 h-5 text-gray-600" />;
                        return <CreditCard className="w-5 h-5 text-gray-600" />;
                      };

                      const getPaymentLabel = () => {
                        if (paymentDetails?.method === 'bkash') return 'bKash';
                        if (paymentDetails?.method === 'nagad') return 'Nagad';
                        if (paymentDetails?.method === 'visa') return 'Visa Card';
                        if (paymentDetails?.method === 'mastercard') return 'Mastercard';
                        if (order.payment_method === 'cod') return 'Cash on Delivery';
                        return order.payment_method || 'Unknown';
                      };

                      return (
                        <div key={order.id} className="bg-white rounded-2xl shadow-lg border border-slate-200 overflow-hidden">
                          <div className="p-5">
                            <div className="flex flex-wrap items-center justify-between gap-4 mb-4">
                              <div className="flex items-center gap-3">
                                <div className="w-12 h-12 bg-gradient-to-br from-green-100 to-emerald-100 rounded-xl flex items-center justify-center">
                                  <Package className="w-6 h-6 text-green-600" />
                                </div>
                                <div>
                                  <p className="font-bold text-lg">{order.order_number}</p>
                                  <p className="text-sm text-gray-500">
                                    {new Date(order.created_at).toLocaleDateString('en-US', {
                                      year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'
                                    })}
                                  </p>
                                </div>
                              </div>
                              <div className="text-right">
                                <p className="text-2xl font-bold text-green-600">৳{order.total_amount?.toLocaleString()}</p>
                                <span className={`inline-flex items-center gap-1 px-3 py-1 rounded-full text-sm font-medium ${order.payment_status === 'paid'
                                  ? 'bg-green-100 text-green-700'
                                  : 'bg-yellow-100 text-yellow-700'
                                  }`}>
                                  {order.payment_status === 'paid' ? <CheckCircle className="w-4 h-4" /> : <Clock className="w-4 h-4" />}
                                  {order.payment_status === 'paid' ? 'Paid' : 'Pending'}
                                </span>
                              </div>
                            </div>

                            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 bg-slate-50 rounded-xl p-4">
                              {/* Customer Info */}
                              <div>
                                <p className="text-xs text-gray-500 uppercase font-semibold mb-1">Customer</p>
                                <p className="font-medium">{order.delivery_full_name}</p>
                                <p className="text-sm text-gray-600">{order.delivery_phone}</p>
                              </div>

                              {/* Payment Method */}
                              <div>
                                <p className="text-xs text-gray-500 uppercase font-semibold mb-1">Payment Method</p>
                                <div className="flex items-center gap-2">
                                  {getPaymentIcon()}
                                  <span className="font-medium">{getPaymentLabel()}</span>
                                </div>
                                {paymentDetails?.cardType && (
                                  <p className="text-sm text-gray-600 mt-1">Card: {paymentDetails.cardType}</p>
                                )}
                              </div>

                              {/* Transaction Details */}
                              <div>
                                <p className="text-xs text-gray-500 uppercase font-semibold mb-1">Transaction Details</p>
                                {paymentDetails?.transactionId ? (
                                  <>
                                    <p className="font-mono text-sm bg-white px-2 py-1 rounded border inline-block">
                                      {paymentDetails.transactionId}
                                    </p>
                                    {paymentDetails?.accountNumber && (
                                      <p className="text-sm text-gray-600 mt-1">Mobile: {paymentDetails.accountNumber}</p>
                                    )}
                                  </>
                                ) : order.stripe_payment_intent_id ? (
                                  <p className="font-mono text-xs">{order.stripe_payment_intent_id}</p>
                                ) : (
                                  <p className="text-gray-400 italic">No transaction ID</p>
                                )}
                              </div>
                            </div>

                            <div className="flex items-center justify-between mt-4 pt-4 border-t">
                              <span className={`inline-flex items-center gap-1 px-3 py-1 rounded-full text-sm font-medium ${order.order_status === 'delivered' ? 'bg-green-100 text-green-700' :
                                order.order_status === 'shipped' ? 'bg-blue-100 text-blue-700' :
                                  order.order_status === 'processing' ? 'bg-purple-100 text-purple-700' :
                                    order.order_status === 'cancelled' ? 'bg-red-100 text-red-700' :
                                      'bg-gray-100 text-gray-700'
                                }`}>
                                Order: {order.order_status}
                              </span>
                            </div>
                          </div>
                        </div>
                      );
                    })}
                </div>
              );
            })()}
          </>
        )}

        {/* Conversations Tab */}
        {activeTab === 'conversations' && (
          <>
            {conversations.length === 0 ? (
              <div className="text-center py-20 bg-white rounded-3xl border-2 border-dashed border-slate-300 shadow-lg">
                <div className="w-24 h-24 mx-auto mb-6 bg-gradient-to-br from-blue-100 to-purple-100 rounded-full flex items-center justify-center">
                  <Inbox className="w-12 h-12 text-blue-500" />
                </div>
                <p className="text-slate-700 text-xl font-semibold">No active conversations</p>
                <p className="text-slate-500 mt-2">Customer messages will appear here automatically</p>
              </div>
            ) : (
              <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
                {conversations.map((conv, index) => (
                  <div
                    key={conv.id}
                    className="group bg-white rounded-2xl shadow-lg border border-slate-200 overflow-hidden hover:shadow-2xl transition-all duration-500 hover:-translate-y-2 cursor-pointer"
                    style={{ animation: `fadeInUp 0.5s ease-out ${index * 0.1}s both` }}
                    onClick={() => setSelectedConversation(conv)}
                  >
                    <div className="bg-gradient-to-br from-blue-600 via-purple-600 to-pink-600 p-5 text-white relative overflow-hidden">
                      <div className="absolute inset-0 bg-gradient-to-tr from-white/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500"></div>
                      <div className="flex items-center gap-3 relative z-10">
                        <div className="w-12 h-12 bg-white/20 backdrop-blur-sm rounded-xl flex items-center justify-center">
                          <User className="w-6 h-6" />
                        </div>
                        <div>
                          <span className="font-bold text-lg block">
                            {conv.buyer?.full_name || 'Customer'}
                          </span>
                          <span className="text-sm text-white/80">
                            {conv.type === 'buyer_admin' ? 'Support Chat' : conv.type}
                          </span>
                        </div>
                      </div>
                    </div>

                    <div className="p-5">
                      {conv.product && (
                        <div className="bg-slate-50 rounded-xl p-3 mb-3">
                          <span className="text-xs text-slate-500 block mb-1">Product Inquiry</span>
                          <span className="font-semibold text-slate-800">{conv.product.name}</span>
                        </div>
                      )}

                      <div className="flex items-center justify-between text-sm text-slate-500">
                        <div className="flex items-center gap-1">
                          <Clock className="w-4 h-4" />
                          {new Date(conv.last_message_at || conv.created_at).toLocaleDateString()}
                        </div>
                        <div className="flex items-center gap-2">
                          <span className="text-blue-600 font-semibold group-hover:underline flex items-center gap-1">
                            Open Chat <ChevronRight className="w-4 h-4" />
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </>
        )}
        {/* Inquiries Tab */}
        {activeTab === 'inquiries' && (
          <>
            {inquiries.length === 0 ? (
              <div className="text-center py-20 bg-white rounded-3xl border-2 border-dashed border-slate-300 shadow-lg">
                <div className="w-24 h-24 mx-auto mb-6 bg-gradient-to-br from-blue-100 to-purple-100 rounded-full flex items-center justify-center">
                  <MessageSquare className="w-12 h-12 text-blue-500" />
                </div>
                <p className="text-slate-700 text-xl font-semibold">No open inquiries at the moment</p>
                <p className="text-slate-500 mt-2">New customer inquiries will appear here automatically</p>
              </div>
            ) : (
              <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
                {inquiries.map((inquiry, index) => (
                  <div
                    key={inquiry.id}
                    className="group bg-white rounded-2xl shadow-lg border border-slate-200 overflow-hidden hover:shadow-2xl transition-all duration-500 hover:-translate-y-2"
                    style={{ animation: `fadeInUp 0.5s ease-out ${index * 0.1}s both` }}
                  >
                    <div className="bg-gradient-to-br from-blue-600 via-purple-600 to-pink-600 p-5 text-white relative overflow-hidden">
                      <div className="absolute inset-0 bg-gradient-to-tr from-white/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500"></div>
                      <div className="absolute -top-10 -right-10 w-32 h-32 bg-white/10 rounded-full blur-2xl"></div>
                      <div className="flex items-center gap-2 mb-2 relative z-10">
                        <User className="w-5 h-5" />
                        <span className="font-semibold">
                          {inquiry.profiles.full_name || inquiry.profiles.email}
                        </span>
                      </div>
                      <div className="flex items-center gap-2 text-blue-100 text-sm relative z-10">
                        <Clock className="w-4 h-4" />
                        {new Date(inquiry.created_at).toLocaleString()}
                      </div>
                    </div>

                    <div className="p-5 space-y-4">
                      <div className="bg-gradient-to-br from-blue-50 to-purple-50 rounded-xl p-3 border border-blue-100">
                        <span className="text-xs text-blue-700 uppercase font-bold tracking-wider block mb-1">
                          💰 Amount
                        </span>
                        <p className="text-slate-900 font-bold text-lg">{inquiry.survey_amount}</p>
                      </div>

                      <div className="bg-slate-50 rounded-xl p-3">
                        <span className="text-xs text-slate-600 uppercase font-bold tracking-wider block mb-1">
                          📍 Shipping Address
                        </span>
                        <p className="text-slate-800 text-sm leading-relaxed">{inquiry.survey_address}</p>
                      </div>

                      <div className="bg-gradient-to-br from-emerald-50 to-teal-50 rounded-xl p-3 border border-emerald-100">
                        <span className="text-xs text-emerald-700 uppercase font-bold tracking-wider block mb-1">
                          ⚡ Delivery Time
                        </span>
                        <p className="text-slate-900 font-bold text-lg">{inquiry.survey_days} days</p>
                      </div>

                      <div className="flex gap-2 pt-3">
                        <button
                          onClick={() => setSelectedInquiry(inquiry)}
                          className="flex-1 bg-gradient-to-r from-blue-600 to-purple-600 text-white px-4 py-3 rounded-xl hover:from-blue-700 hover:to-purple-700 transition-all shadow-lg hover:shadow-xl transform hover:scale-105 flex items-center justify-center gap-2 font-semibold"
                        >
                          <MessageSquare className="w-5 h-5" />
                          Open Chat
                        </button>
                        <button
                          onClick={() => handleCloseInquiry(inquiry.id)}
                          className="px-4 py-3 bg-slate-100 text-slate-700 rounded-xl hover:bg-red-50 hover:text-red-600 transition-all font-semibold border border-slate-200 hover:border-red-200"
                        >
                          ✓ Close
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </>
        )}

        {selectedInquiry && (
          <ChatWindow
            inquiry={selectedInquiry}
            onClose={() => setSelectedInquiry(null)}
          />
        )}

        {selectedConversation && (
          <ConversationWindow
            conversation={selectedConversation}
            onClose={() => setSelectedConversation(null)}
          />
        )}
      </div>
    </div>
  );
};
