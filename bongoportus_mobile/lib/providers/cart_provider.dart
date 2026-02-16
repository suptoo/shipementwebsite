import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();

  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  
  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);
  double get shippingCharge => subtotal > 0 ? 50 : 0;
  double get total => subtotal + shippingCharge;
  bool get isEmpty => _items.isEmpty;

  /// Load cart items from server
  Future<void> loadCart(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _cartService.getCart(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add item to cart
  Future<void> addToCart({
    required String userId,
    required String productId,
    int quantity = 1,
    String? variantId,
  }) async {
    try {
      await _cartService.addToCart(
        userId: userId,
        productId: productId,
        quantity: quantity,
        variantId: variantId,
      );

      // Reload cart to get fresh data
      await loadCart(userId);
    } catch (e) {
      _error = 'Failed to add item to cart. Please try again.';
      notifyListeners();
    }
  }

  /// Update item quantity (optimistic UI — updates instantly, reverts on error)
  Future<void> updateQuantity(String cartItemId, int quantity, String userId) async {
    // Optimistic: update local state immediately
    final index = _items.indexWhere((i) => i.id == cartItemId);
    final oldQuantity = index != -1 ? _items[index].quantity : quantity;
    if (index != -1) {
      _items[index].quantity = quantity;
      notifyListeners();
    }

    try {
      await _cartService.updateQuantity(cartItemId, quantity);
      // Reload to sync with server state
      await loadCart(userId);
    } catch (e) {
      // Revert on error
      if (index != -1 && index < _items.length) {
        _items[index].quantity = oldQuantity;
      }
      _error = 'Failed to update quantity. Please try again.';
      notifyListeners();
    }
  }

  /// Remove item from cart
  Future<void> removeItem(String cartItemId, String userId) async {
    try {
      // Optimistic: remove from local state immediately
      _items.removeWhere((item) => item.id == cartItemId);
      notifyListeners();

      await _cartService.removeFromCart(cartItemId);
    } catch (e) {
      // Revert — reload from server
      _error = 'Failed to remove item. Please try again.';
      await loadCart(userId);
    }
  }

  /// Clear cart
  Future<void> clearCart(String userId) async {
    try {
      await _cartService.clearCart(userId);
      _items = [];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
