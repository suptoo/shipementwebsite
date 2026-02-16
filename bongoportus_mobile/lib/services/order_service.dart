import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../models/address.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Generate unique order number
  String _generateOrderNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final random = (DateTime.now().microsecond * 97).toRadixString(36);
    return 'ORD-$timestamp-$random'.toUpperCase();
  }

  /// Create order
  Future<Order> createOrder({
    required String userId,
    required List<Map<String, dynamic>> cartItems,
    required Address address,
    String paymentMethod = 'cod',
    String? couponCode,
    double shippingCharge = 50,
    double taxRate = 0,
  }) async {
    // Calculate totals
    double subtotal = 0;
    for (final item in cartItems) {
      subtotal += (item['price'] as double) * (item['quantity'] as int);
    }

    double discountAmount = 0;
    Map<String, dynamic>? appliedCoupon;

    // Try to apply coupon
    if (couponCode != null && couponCode.isNotEmpty) {
      try {
        final couponData = await _supabase
            .from('coupons')
            .select()
            .eq('code', couponCode.toUpperCase())
            .eq('is_active', true)
            .maybeSingle();

        if (couponData != null) {
          appliedCoupon = couponData;
          if (couponData['discount_type'] == 'percentage') {
            discountAmount = subtotal * (couponData['discount_value'] / 100);
          } else {
            discountAmount = (couponData['discount_value'] as num).toDouble();
          }
          if (couponData['max_discount_amount'] != null &&
              discountAmount > couponData['max_discount_amount']) {
            discountAmount = (couponData['max_discount_amount'] as num).toDouble();
          }
        }
      } catch (e) {
        print('Coupon error ignored: $e');
      }
    }

    final taxAmount = (subtotal - discountAmount + shippingCharge) * taxRate;
    final totalAmount = subtotal - discountAmount + shippingCharge + taxAmount;
    final orderNumber = _generateOrderNumber();

    // Create order
    final orderData = await _supabase
        .from('orders')
        .insert({
          'order_number': orderNumber,
          'user_id': userId,
          'delivery_full_name': address.fullName,
          'delivery_phone': address.phone,
          'delivery_address_line1': address.addressLine1,
          'delivery_address_line2': address.addressLine2,
          'delivery_city': address.city,
          'delivery_state': address.state,
          'delivery_postal_code': address.postalCode,
          'delivery_country': address.country,
          'subtotal': subtotal,
          'discount_amount': discountAmount,
          'coupon_code': appliedCoupon?['code'],
          'shipping_charge': shippingCharge,
          'tax_amount': taxAmount,
          'total_amount': totalAmount,
          'payment_method': paymentMethod,
          'payment_status': 'pending',
          'order_status': 'pending',
        })
        .select()
        .single();

    // Create order items
    try {
      final orderItems = cartItems.map((item) {
        final commissionRate = (item['commissionRate'] as num?) ?? 0;
        final itemTotal = (item['price'] as double) * (item['quantity'] as int);
        final commissionAmount = itemTotal * (commissionRate / 100);

        return {
          'order_id': orderData['id'],
          'product_id': item['productId'],
          'seller_id': item['sellerId'],
          'shop_id': item['shopId'],
          'variant_id': item['variantId'],
          'product_name': item['productName'] ?? 'Product',
          'product_image_url': item['productImageUrl'],
          'quantity': item['quantity'],
          'unit_price': item['price'],
          'total_price': itemTotal,
          'commission_rate': commissionRate,
          'commission_amount': commissionAmount,
          'seller_earnings': itemTotal - commissionAmount,
          'item_status': 'pending',
        };
      }).toList();

      await _supabase.from('order_items').insert(orderItems);
    } catch (e) {
      print('Order items insert skipped: $e');
    }

    // Update coupon usage
    if (appliedCoupon != null) {
      try {
        await _supabase
            .from('coupons')
            .update({'used_count': (appliedCoupon['used_count'] ?? 0) + 1})
            .eq('id', appliedCoupon['id']);
      } catch (_) {}
    }

    return Order.fromJson(orderData);
  }

  /// Get user orders
  Future<List<Order>> getUserOrders(String userId) async {
    final data = await _supabase
        .from('orders')
        .select('*, order_items(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((o) => Order.fromJson(o as Map<String, dynamic>))
        .toList();
  }

  /// Get single order
  Future<Order?> getOrder(String orderId) async {
    final data = await _supabase
        .from('orders')
        .select('*, order_items(*)')
        .eq('id', orderId)
        .single();

    return Order.fromJson(data);
  }

  /// Cancel order
  Future<void> cancelOrder(String orderId) async {
    await _supabase
        .from('orders')
        .update({'order_status': 'cancelled'})
        .eq('id', orderId);
  }

  /// Get user addresses
  Future<List<Address>> getUserAddresses(String userId) async {
    final data = await _supabase
        .from('user_addresses')
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false);

    return (data as List<dynamic>)
        .map((a) => Address.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  /// Add address
  Future<Address> addAddress(Address address) async {
    final data = await _supabase
        .from('user_addresses')
        .insert(address.toJson())
        .select()
        .single();

    return Address.fromJson(data);
  }

  /// Update address
  Future<void> updateAddress(String addressId, Map<String, dynamic> updates) async {
    await _supabase
        .from('user_addresses')
        .update(updates)
        .eq('id', addressId);
  }

  /// Delete address
  Future<void> deleteAddress(String addressId) async {
    await _supabase.from('user_addresses').delete().eq('id', addressId);
  }
}
