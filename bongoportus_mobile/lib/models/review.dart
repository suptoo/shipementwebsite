import 'user_profile.dart';

class Review {
  final String id;
  final String productId;
  final String userId;
  final String? orderId;
  final double rating;
  final String? title;
  final String? comment;
  final List<String>? imageUrls;
  final bool isVerifiedPurchase;
  final int helpfulCount;
  final String createdAt;
  final UserProfile? user;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    this.orderId,
    required this.rating,
    this.title,
    this.comment,
    this.imageUrls,
    this.isVerifiedPurchase = false,
    this.helpfulCount = 0,
    required this.createdAt,
    this.user,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      userId: json['user_id'] ?? '',
      orderId: json['order_id'],
      rating: (json['rating'] ?? 0).toDouble(),
      title: json['title'],
      comment: json['comment'],
      imageUrls: (json['image_urls'] as List<dynamic>?)?.cast<String>(),
      isVerifiedPurchase: json['is_verified_purchase'] ?? false,
      helpfulCount: json['helpful_count'] ?? 0,
      createdAt: json['created_at'] ?? '',
      user: json['profiles'] != null
          ? UserProfile.fromJson(json['profiles'])
          : null,
    );
  }
}
