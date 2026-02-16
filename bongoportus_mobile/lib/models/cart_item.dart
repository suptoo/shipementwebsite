import 'product.dart';

class CartItem {
  final String id;
  final String userId;
  final String productId;
  final String? variantId;
  int quantity;
  final Product? product;
  final ProductVariant? variant;

  CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    this.variantId,
    this.quantity = 1,
    this.product,
    this.variant,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      productId: json['product_id'] ?? '',
      variantId: json['variant_id'],
      quantity: json['quantity'] ?? 1,
      product:
          json['products'] != null ? Product.fromJson(json['products']) : null,
      variant: json['product_variants'] != null
          ? ProductVariant.fromJson(json['product_variants'])
          : null,
    );
  }

  double get totalPrice {
    if (product == null) return 0;
    final basePrice = product!.effectivePrice;
    final modifier = variant?.priceAdjustment ?? 0;
    return (basePrice + modifier) * quantity;
  }

  String get displayName {
    final name = product?.name ?? 'Product';
    if (variant != null) {
      return '$name - ${variant!.variantValue}';
    }
    return name;
  }
}
