import { supabase } from '../lib/supabase';
import { SupportTicket, TicketMessage } from '../types';

export const supportService = {
  // Create a new support ticket
  async createTicket(data: {
    userId: string;
    category: 'order_issue' | 'payment_issue' | 'product_issue' | 'account_issue' | 'technical_issue' | 'other';
    subject: string;
    description: string;
    priority?: 'low' | 'medium' | 'high' | 'urgent';
  }): Promise<SupportTicket> {
    const { data: ticket, error } = await supabase
      .from('support_tickets')
      .insert({
        user_id: data.userId,
        category: data.category,
        subject: data.subject,
        description: data.description,
        priority: data.priority || 'medium',
        status: 'open'
      })
      .select()
      .single();

    if (error) throw error;
    return ticket;
  },

  // Get user's support tickets
  async getUserTickets(userId: string): Promise<SupportTicket[]> {
    const { data, error } = await supabase
      .from('support_tickets')
      .select(`
        *,
        user:user_id(id, full_name, email),
        assigned_admin:assigned_to(id, full_name)
      `)
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  },

  // Get all support tickets (admin)
  async getAllTickets(filters?: {
    status?: string;
    priority?: string;
    category?: string;
  }): Promise<SupportTicket[]> {
    let query = supabase
      .from('support_tickets')
      .select(`
        *,
        user:user_id(id, full_name, email),
        assigned_admin:assigned_to(id, full_name)
      `)
      .order('created_at', { ascending: false });

    if (filters?.status) {
      query = query.eq('status', filters.status);
    }
    if (filters?.priority) {
      query = query.eq('priority', filters.priority);
    }
    if (filters?.category) {
      query = query.eq('category', filters.category);
    }

    const { data, error } = await query;

    if (error) throw error;
    return data || [];
  },

  // Get single ticket
  async getTicket(ticketId: string): Promise<SupportTicket | null> {
    const { data, error } = await supabase
      .from('support_tickets')
      .select(`
        *,
        user:user_id(id, full_name, email, avatar_url),
        assigned_admin:assigned_to(id, full_name)
      `)
      .eq('id', ticketId)
      .single();

    if (error) throw error;
    return data;
  },

  // Update ticket status
  async updateTicketStatus(
    ticketId: string,
    status: 'open' | 'in_progress' | 'resolved' | 'closed'
  ): Promise<void> {
    const updateData: any = {
      status,
      updated_at: new Date().toISOString()
    };

    if (status === 'resolved' || status === 'closed') {
      updateData.resolved_at = new Date().toISOString();
    }

    const { error } = await supabase
      .from('support_tickets')
      .update(updateData)
      .eq('id', ticketId);

    if (error) throw error;
  },

  // Assign ticket to admin
  async assignTicket(ticketId: string, adminId: string): Promise<void> {
    const { error } = await supabase
      .from('support_tickets')
      .update({
        assigned_to: adminId,
        status: 'in_progress',
        updated_at: new Date().toISOString()
      })
      .eq('id', ticketId);

    if (error) throw error;
  },

  // Update ticket priority
  async updatePriority(
    ticketId: string,
    priority: 'low' | 'medium' | 'high' | 'urgent'
  ): Promise<void> {
    const { error } = await supabase
      .from('support_tickets')
      .update({
        priority,
        updated_at: new Date().toISOString()
      })
      .eq('id', ticketId);

    if (error) throw error;
  },

  // Send message in ticket
  async sendTicketMessage(data: {
    ticketId: string;
    senderId: string;
    content: string;
    attachmentUrl?: string;
    isInternal?: boolean;
  }): Promise<TicketMessage> {
    const { data: message, error } = await supabase
      .from('ticket_messages')
      .insert({
        ticket_id: data.ticketId,
        sender_id: data.senderId,
        content: data.content,
        attachment_url: data.attachmentUrl,
        is_internal: data.isInternal || false
      })
      .select()
      .single();

    if (error) throw error;

    // Update ticket updated_at
    await supabase
      .from('support_tickets')
      .update({ updated_at: new Date().toISOString() })
      .eq('id', data.ticketId);

    return message;
  },

  // Get ticket messages
  async getTicketMessages(ticketId: string, isAdmin: boolean = false): Promise<TicketMessage[]> {
    let query = supabase
      .from('ticket_messages')
      .select(`
        *,
        sender:sender_id(id, full_name, avatar_url, role)
      `)
      .eq('ticket_id', ticketId)
      .order('created_at', { ascending: true });

    // Hide internal notes from non-admins
    if (!isAdmin) {
      query = query.eq('is_internal', false);
    }

    const { data, error } = await query;

    if (error) throw error;
    return data || [];
  },

  // Get ticket statistics (admin)
  async getTicketStats(): Promise<{
    total: number;
    open: number;
    in_progress: number;
    resolved: number;
    closed: number;
    by_category: Record<string, number>;
    by_priority: Record<string, number>;
  }> {
    const { data: tickets, error } = await supabase
      .from('support_tickets')
      .select('status, category, priority');

    if (error) throw error;

    const stats = {
      total: tickets?.length || 0,
      open: 0,
      in_progress: 0,
      resolved: 0,
      closed: 0,
      by_category: {} as Record<string, number>,
      by_priority: {} as Record<string, number>
    };

    tickets?.forEach(ticket => {
      // Count by status
      if (ticket.status === 'open') stats.open++;
      else if (ticket.status === 'in_progress') stats.in_progress++;
      else if (ticket.status === 'resolved') stats.resolved++;
      else if (ticket.status === 'closed') stats.closed++;

      // Count by category
      stats.by_category[ticket.category] = (stats.by_category[ticket.category] || 0) + 1;

      // Count by priority
      stats.by_priority[ticket.priority] = (stats.by_priority[ticket.priority] || 0) + 1;
    });

    return stats;
  },

  // Subscribe to ticket updates
  subscribeToTicket(ticketId: string, callback: (message: TicketMessage) => void) {
    return supabase
      .channel(`ticket:${ticketId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'ticket_messages',
          filter: `ticket_id=eq.${ticketId}`
        },
        (payload) => {
          callback(payload.new as TicketMessage);
        }
      )
      .subscribe();
  }
};
