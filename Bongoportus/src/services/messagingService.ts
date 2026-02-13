import { supabase } from '../lib/supabase';
import { Conversation, Message } from '../types';

export interface PaymentRequest {
  id: string;
  amount: number;
  description: string;
  status: 'pending' | 'paid' | 'cancelled';
  createdAt: string;
}

export const messagingService = {
  // Create a payment request message
  async sendPaymentRequest(data: {
    conversationId: string;
    senderId: string;
    amount: number;
    description: string;
  }): Promise<Message> {
    const paymentData: PaymentRequest = {
      id: `pay_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      amount: data.amount,
      description: data.description,
      status: 'pending',
      createdAt: new Date().toISOString(),
    };

    const content = `[PAYMENT_REQUEST]${JSON.stringify(paymentData)}`;

    return this.sendMessage({
      conversationId: data.conversationId,
      senderId: data.senderId,
      senderType: 'admin',
      content,
    });
  },

  // Parse payment request from message content
  parsePaymentRequest(content: string): PaymentRequest | null {
    if (!content.startsWith('[PAYMENT_REQUEST]')) return null;
    try {
      return JSON.parse(content.replace('[PAYMENT_REQUEST]', ''));
    } catch {
      return null;
    }
  },
  // Create a new conversation
  async createConversation(data: {
    type: 'buyer_seller' | 'buyer_admin' | 'seller_admin';
    buyerId?: string;
    sellerId?: string;
    productId?: string;
    orderId?: string;
    subject?: string;
  }): Promise<Conversation> {
    const { data: conversation, error } = await supabase
      .from('conversations')
      .insert({
        type: data.type,
        buyer_id: data.buyerId,
        seller_id: data.sellerId,
        product_id: data.productId,
        order_id: data.orderId,
        subject: data.subject,
        status: 'active'
      })
      .select()
      .single();

    if (error) throw error;
    return conversation;
  },

  // Get or create conversation
  async getOrCreateConversation(data: {
    type: 'buyer_seller' | 'buyer_admin' | 'seller_admin';
    buyerId?: string;
    sellerId?: string;
    productId?: string;
    orderId?: string;
  }): Promise<Conversation> {
    // Try to find existing conversation
    let query = supabase
      .from('conversations')
      .select('*')
      .eq('type', data.type)
      .eq('status', 'active');

    if (data.buyerId) query = query.eq('buyer_id', data.buyerId);
    if (data.sellerId) query = query.eq('seller_id', data.sellerId);
    if (data.productId) query = query.eq('product_id', data.productId);
    if (data.orderId) query = query.eq('order_id', data.orderId);

    const { data: existing } = await query.single();

    if (existing) return existing;

    // Create new conversation
    return this.createConversation(data);
  },

  // Get user's conversations
  async getUserConversations(userId: string, userRole: 'buyer' | 'seller' | 'admin'): Promise<Conversation[]> {
    let query = supabase
      .from('conversations')
      .select(`
        *,
        buyer:buyer_id(id, full_name, avatar_url),
        seller:seller_id(id, business_name),
        product:product_id(id, name, slug),
        order:order_id(id, order_number)
      `)
      .order('last_message_at', { ascending: false });

    if (userRole === 'buyer') {
      query = query.eq('buyer_id', userId);
    } else if (userRole === 'seller') {
      // Get seller profile first
      const { data: sellerProfile } = await supabase
        .from('seller_profiles')
        .select('id')
        .eq('user_id', userId)
        .single();
      
      if (sellerProfile) {
        query = query.eq('seller_id', sellerProfile.id);
      }
    }
    // Admin sees all conversations

    const { data, error } = await query;

    if (error) throw error;
    return data || [];
  },

  // Get conversation by ID
  async getConversation(conversationId: string): Promise<Conversation | null> {
    const { data, error } = await supabase
      .from('conversations')
      .select(`
        *,
        buyer:buyer_id(id, full_name, avatar_url),
        seller:seller_id(id, business_name),
        product:product_id(id, name, slug),
        order:order_id(id, order_number)
      `)
      .eq('id', conversationId)
      .single();

    if (error) throw error;
    return data;
  },

  // Send a message
  async sendMessage(data: {
    conversationId: string;
    senderId: string;
    senderType: 'buyer' | 'seller' | 'admin';
    content: string;
    attachmentUrl?: string;
  }): Promise<Message> {
    const { data: message, error } = await supabase
      .from('messages')
      .insert({
        conversation_id: data.conversationId,
        sender_id: data.senderId,
        sender_type: data.senderType,
        content: data.content,
        attachment_url: data.attachmentUrl,
        is_read: false
      })
      .select()
      .single();

    if (error) throw error;

    // Update conversation last_message_at
    await supabase
      .from('conversations')
      .update({ last_message_at: new Date().toISOString() })
      .eq('id', data.conversationId);

    return message;
  },

  // Get messages for a conversation
  async getMessages(conversationId: string): Promise<Message[]> {
    const { data, error } = await supabase
      .from('messages')
      .select(`
        *,
        sender:sender_id(id, full_name, avatar_url, role)
      `)
      .eq('conversation_id', conversationId)
      .order('created_at', { ascending: true });

    if (error) throw error;
    return data || [];
  },

  // Mark messages as read
  async markMessagesAsRead(conversationId: string, userId: string): Promise<void> {
    const { error } = await supabase
      .from('messages')
      .update({ is_read: true })
      .eq('conversation_id', conversationId)
      .neq('sender_id', userId)
      .eq('is_read', false);

    if (error) throw error;
  },

  // Get unread message count
  async getUnreadCount(userId: string, userRole: 'buyer' | 'seller' | 'admin'): Promise<number> {
    const conversations = await this.getUserConversations(userId, userRole);
    const conversationIds = conversations.map(c => c.id);

    if (conversationIds.length === 0) return 0;

    const { count, error } = await supabase
      .from('messages')
      .select('*', { count: 'exact', head: true })
      .in('conversation_id', conversationIds)
      .neq('sender_id', userId)
      .eq('is_read', false);

    if (error) throw error;
    return count || 0;
  },

  // Close conversation
  async closeConversation(conversationId: string): Promise<void> {
    const { error } = await supabase
      .from('conversations')
      .update({ status: 'closed' })
      .eq('id', conversationId);

    if (error) throw error;
  },

  // Subscribe to new messages
  subscribeToMessages(conversationId: string, callback: (message: Message) => void) {
    return supabase
      .channel(`conversation:${conversationId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
          filter: `conversation_id=eq.${conversationId}`
        },
        (payload) => {
          callback(payload.new as Message);
        }
      )
      .subscribe();
  }
};
