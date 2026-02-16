import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation.dart';

class MessagingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new conversation
  Future<Conversation> createConversation({
    required String type,
    String? buyerId,
    String? sellerId,
    String? productId,
    String? orderId,
    String? subject,
  }) async {
    final data = await _supabase
        .from('conversations')
        .insert({
          'type': type,
          'buyer_id': buyerId,
          'seller_id': sellerId,
          'product_id': productId,
          'order_id': orderId,
          'subject': subject,
          'status': 'active',
        })
        .select()
        .single();

    return Conversation.fromJson(data);
  }

  /// Get or create conversation
  Future<Conversation> getOrCreateConversation({
    required String type,
    String? buyerId,
    String? sellerId,
    String? productId,
    String? orderId,
  }) async {
    var query = _supabase
        .from('conversations')
        .select()
        .eq('type', type)
        .eq('status', 'active');

    if (buyerId != null) query = query.eq('buyer_id', buyerId);
    if (sellerId != null) query = query.eq('seller_id', sellerId);
    if (productId != null) query = query.eq('product_id', productId);
    if (orderId != null) query = query.eq('order_id', orderId);

    final existing = await query.maybeSingle();
    if (existing != null) return Conversation.fromJson(existing);

    return createConversation(
      type: type,
      buyerId: buyerId,
      sellerId: sellerId,
      productId: productId,
      orderId: orderId,
    );
  }

  /// Get user's conversations
  Future<List<Conversation>> getUserConversations(
    String userId,
    String userRole,
  ) async {
    var query = _supabase
        .from('conversations')
        .select('''
          *,
          buyer:buyer_id(id, full_name, avatar_url),
          seller:seller_id(id, business_name),
          product:product_id(id, name, slug),
          order:order_id(id, order_number)
        ''');

    if (userRole == 'buyer') {
      query = query.eq('buyer_id', userId);
    } else if (userRole == 'seller') {
      final sellerProfile = await _supabase
          .from('seller_profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (sellerProfile != null) {
        query = query.eq('seller_id', sellerProfile['id'] as String);
      }
    }

    final data = await query.order('last_message_at', ascending: false);
    return (data as List<dynamic>)
        .map((c) => Conversation.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  /// Send a message
  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderType,
    required String content,
    String? attachmentUrl,
  }) async {
    final data = await _supabase
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': senderId,
          'sender_type': senderType,
          'content': content,
          'attachment_url': attachmentUrl,
          'is_read': false,
        })
        .select()
        .single();

    // Update conversation last_message_at
    await _supabase
        .from('conversations')
        .update({'last_message_at': DateTime.now().toIso8601String()})
        .eq('id', conversationId);

    return Message.fromJson(data);
  }

  /// Get messages for a conversation
  Future<List<Message>> getMessages(String conversationId) async {
    final data = await _supabase
        .from('messages')
        .select('''
          *,
          sender:sender_id(id, full_name, avatar_url, role)
        ''')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (data as List<dynamic>)
        .map((m) => Message.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    // Get unread messages that aren't from this user
    final unread = await _supabase
        .from('messages')
        .select('id')
        .eq('conversation_id', conversationId)
        .neq('sender_id', userId)
        .eq('is_read', false);

    final ids = (unread as List).map((m) => m['id']).toList();
    if (ids.isNotEmpty) {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .inFilter('id', ids);
    }
  }

  /// Get unread count
  Future<int> getUnreadCount(String userId, String userRole) async {
    final conversations = await getUserConversations(userId, userRole);
    final ids = conversations.map((c) => c.id).toList();
    if (ids.isEmpty) return 0;

    final response = await _supabase
        .from('messages')
        .select('id')
        .inFilter('conversation_id', ids)
        .neq('sender_id', userId)
        .eq('is_read', false);

    return (response as List).length;
  }

  /// Subscribe to new messages (real-time)
  RealtimeChannel subscribeToMessages(
    String conversationId,
    void Function(Message) onMessage,
  ) {
    return _supabase
        .channel('conversation:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            onMessage(Message.fromJson(payload.newRecord));
          },
        )
        .subscribe();
  }
}
