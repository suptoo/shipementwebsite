import 'user_profile.dart';

class Conversation {
  final String id;
  final String type; // 'buyer_seller' | 'buyer_admin' | 'seller_admin'
  final String? buyerId;
  final String? sellerId;
  final String? productId;
  final String? orderId;
  final String? subject;
  final String status; // 'active' | 'closed' | 'archived'
  final String lastMessageAt;
  final String createdAt;
  final UserProfile? buyer;
  final Map<String, dynamic>? seller;
  final Map<String, dynamic>? product;
  final Map<String, dynamic>? order;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.type,
    this.buyerId,
    this.sellerId,
    this.productId,
    this.orderId,
    this.subject,
    this.status = 'active',
    required this.lastMessageAt,
    required this.createdAt,
    this.buyer,
    this.seller,
    this.product,
    this.order,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? '',
      type: json['type'] ?? 'buyer_seller',
      buyerId: json['buyer_id'],
      sellerId: json['seller_id'],
      productId: json['product_id'],
      orderId: json['order_id'],
      subject: json['subject'],
      status: json['status'] ?? 'active',
      lastMessageAt: json['last_message_at'] ?? '',
      createdAt: json['created_at'] ?? '',
      buyer: json['buyer'] != null ? UserProfile.fromJson(json['buyer']) : null,
      seller: json['seller'] as Map<String, dynamic>?,
      product: json['product'] as Map<String, dynamic>?,
      order: json['order'] as Map<String, dynamic>?,
    );
  }

  String get displayTitle {
    if (subject != null && subject!.isNotEmpty) return subject!;
    if (product != null) return product!['name'] ?? 'Product Inquiry';
    if (order != null) return 'Order #${order!['order_number'] ?? ''}';
    return 'Conversation';
  }
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderType; // 'buyer' | 'seller' | 'admin'
  final String content;
  final String? attachmentUrl;
  final bool isRead;
  final String createdAt;
  final UserProfile? sender;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderType,
    required this.content,
    this.attachmentUrl,
    this.isRead = false,
    required this.createdAt,
    this.sender,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderType: json['sender_type'] ?? 'buyer',
      content: json['content'] ?? '',
      attachmentUrl: json['attachment_url'],
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] ?? '',
      sender: json['sender'] != null
          ? UserProfile.fromJson(json['sender'])
          : null,
    );
  }
}
