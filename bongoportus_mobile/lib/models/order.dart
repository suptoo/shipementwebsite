class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String sellerId;
  final String shopId;
  final String? variantId;
  final String productName;
  final String? productImageUrl;
  final String? variantDetails;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final double commissionRate;
  final double commissionAmount;
  final double sellerEarnings;
  final String itemStatus;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.sellerId,
    required this.shopId,
    this.variantId,
    required this.productName,
    this.productImageUrl,
    this.variantDetails,
    this.quantity = 1,
    this.unitPrice = 0,
    this.totalPrice = 0,
    this.commissionRate = 0,
    this.commissionAmount = 0,
    this.sellerEarnings = 0,
    this.itemStatus = 'pending',
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      productId: json['product_id'] ?? '',
      sellerId: json['seller_id'] ?? '',
      shopId: json['shop_id'] ?? '',
      variantId: json['variant_id'],
      productName: json['product_name'] ?? '',
      productImageUrl: json['product_image_url'],
      variantDetails: json['variant_details'],
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      commissionRate: (json['commission_rate'] ?? 0).toDouble(),
      commissionAmount: (json['commission_amount'] ?? 0).toDouble(),
      sellerEarnings: (json['seller_earnings'] ?? 0).toDouble(),
      itemStatus: json['item_status'] ?? 'pending',
    );
  }
}

class Order {
  final String id;
  final String orderNumber;
  final String userId;
  final String deliveryFullName;
  final String deliveryPhone;
  final String deliveryAddressLine1;
  final String? deliveryAddressLine2;
  final String deliveryCity;
  final String deliveryState;
  final String deliveryPostalCode;
  final String deliveryCountry;
  final double subtotal;
  final double discountAmount;
  final String? couponCode;
  final double shippingCharge;
  final double taxAmount;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String? stripePaymentIntentId;
  final String orderStatus;
  final String? trackingNumber;
  final String? courierName;
  final String createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.deliveryFullName,
    required this.deliveryPhone,
    required this.deliveryAddressLine1,
    this.deliveryAddressLine2,
    required this.deliveryCity,
    required this.deliveryState,
    required this.deliveryPostalCode,
    this.deliveryCountry = 'Bangladesh',
    this.subtotal = 0,
    this.discountAmount = 0,
    this.couponCode,
    this.shippingCharge = 0,
    this.taxAmount = 0,
    this.totalAmount = 0,
    this.paymentMethod = 'cod',
    this.paymentStatus = 'pending',
    this.stripePaymentIntentId,
    this.orderStatus = 'pending',
    this.trackingNumber,
    this.courierName,
    required this.createdAt,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      orderNumber: json['order_number'] ?? '',
      userId: json['user_id'] ?? '',
      deliveryFullName: json['delivery_full_name'] ?? '',
      deliveryPhone: json['delivery_phone'] ?? '',
      deliveryAddressLine1: json['delivery_address_line1'] ?? '',
      deliveryAddressLine2: json['delivery_address_line2'],
      deliveryCity: json['delivery_city'] ?? '',
      deliveryState: json['delivery_state'] ?? '',
      deliveryPostalCode: json['delivery_postal_code'] ?? '',
      deliveryCountry: json['delivery_country'] ?? 'Bangladesh',
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      couponCode: json['coupon_code'],
      shippingCharge: (json['shipping_charge'] ?? 0).toDouble(),
      taxAmount: (json['tax_amount'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? 'cod',
      paymentStatus: json['payment_status'] ?? 'pending',
      stripePaymentIntentId: json['stripe_payment_intent_id'],
      orderStatus: json['order_status'] ?? 'pending',
      trackingNumber: json['tracking_number'],
      courierName: json['courier_name'],
      createdAt: json['created_at'] ?? '',
      items: (json['order_items'] as List<dynamic>?)
              ?.map((i) => OrderItem.fromJson(i))
              .toList() ??
          [],
    );
  }

  String get formattedAddress {
    final parts = [
      deliveryAddressLine1,
      if (deliveryAddressLine2 != null) deliveryAddressLine2,
      deliveryCity,
      deliveryState,
      deliveryPostalCode,
      deliveryCountry,
    ];
    return parts.join(', ');
  }
}
