import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item.dart';

class CartService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get user's cart
  Future<List<CartItem>> getCart(String userId) async {
    final data = await _supabase
        .from('cart_items')
        .select('*, products(*, product_images(*)), product_variants(*)')
        .eq('user_id', userId);

    return (data as List<dynamic>)
        .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Add item to cart
  Future<CartItem?> addToCart({
    required String userId,
    required String productId,
    int quantity = 1,
    String? variantId,
  }) async {
    // Check if item already exists
    try {
      final existing = await _supabase
          .from('cart_items')
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId)
          .eq('variant_id', variantId ?? '')
          .maybeSingle();

      if (existing != null) {
        // Update quantity
        final data = await _supabase
            .from('cart_items')
            .update({'quantity': existing['quantity'] + quantity})
            .eq('id', existing['id'])
            .select('*, products(*, product_images(*)), product_variants(*)')
            .single();
        return CartItem.fromJson(data);
      }
    } catch (_) {}

    // Insert new item
    final data = await _supabase
        .from('cart_items')
        .insert({
          'user_id': userId,
          'product_id': productId,
          'variant_id': variantId,
          'quantity': quantity,
        })
        .select('*, products(*, product_images(*)), product_variants(*)')
        .single();

    return CartItem.fromJson(data);
  }

  /// Update cart item quantity
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(cartItemId);
      return;
    }

    await _supabase
        .from('cart_items')
        .update({'quantity': quantity})
        .eq('id', cartItemId);
  }

  /// Remove item from cart
  Future<void> removeFromCart(String cartItemId) async {
    await _supabase.from('cart_items').delete().eq('id', cartItemId);
  }

  /// Clear user's cart
  Future<void> clearCart(String userId) async {
    await _supabase.from('cart_items').delete().eq('user_id', userId);
  }
}
