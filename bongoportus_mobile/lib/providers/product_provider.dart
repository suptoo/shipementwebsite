import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/brand.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _productChannel;

  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  List<Product> _newArrivals = [];
  List<Category> _categories = [];
  List<Brand> _brands = [];
  Product? _selectedProduct;
  ProductFilters _filters = ProductFilters();
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  List<Product> get newArrivals => _newArrivals;
  List<Category> get categories => _categories;
  List<Brand> get brands => _brands;
  Product? get selectedProduct => _selectedProduct;
  ProductFilters get filters => _filters;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMorePages => _currentPage < _totalPages;
  String? get error => _error;

  /// Load home page data with retry logic
  Future<void> loadHomeData({int retries = 3}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        final results = await Future.wait([
          _productService.getFeaturedProducts(limit: 10),
          _productService.getNewArrivals(limit: 10),
          _productService.getCategories(),
        ]);

        _featuredProducts = results[0] as List<Product>;
        _newArrivals = results[1] as List<Product>;
        _categories = results[2] as List<Category>;
        _error = null;
        break; // success
      } catch (e) {
        _error = e.toString();
        if (attempt < retries - 1) {
          // Exponential backoff: 500ms, 1500ms
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Pull-to-refresh home data
  Future<void> refreshHomeData() async {
    await loadHomeData(retries: 1);
  }

  /// Load products with filters
  Future<void> loadProducts(
      {ProductFilters? filters, bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _products = [];
    }
    if (filters != null) {
      _filters = filters;
      _currentPage = 1;
      _products = [];
    }

    _isLoading = _products.isEmpty;
    _error = null;
    notifyListeners();

    try {
      final response = await _productService.getProducts(
        filters: _filters,
        page: _currentPage,
      );

      _products = response.data;
      _totalPages = response.totalPages;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more products (pagination)
  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !hasMorePages) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final response = await _productService.getProducts(
        filters: _filters,
        page: _currentPage,
      );

      _products.addAll(response.data);
      _totalPages = response.totalPages;
    } catch (e) {
      _currentPage--;
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Load single product
  Future<void> loadProduct(String idOrSlug) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedProduct = await _productService.getProduct(idOrSlug);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load categories
  Future<void> loadCategories() async {
    if (_categories.isNotEmpty) return;

    try {
      _categories = await _productService.getCategories();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Load brands
  Future<void> loadBrands() async {
    if (_brands.isNotEmpty) return;

    try {
      _brands = await _productService.getBrands();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Search products
  Future<List<Product>> searchProducts(String query) async {
    return _productService.searchProducts(query);
  }

  /// Update filters
  void updateFilters(ProductFilters newFilters) {
    _filters = newFilters;
    loadProducts();
  }

  /// Clear filters
  void clearFilters() {
    _filters = ProductFilters();
    loadProducts();
  }

  void clearSelectedProduct() {
    _selectedProduct = null;
  }

  // ─── Real-time product sync ───────────────────────────────
  /// Subscribe to real-time product changes so both app and website stay in sync.
  void subscribeToProductChanges() {
    _productChannel?.unsubscribe();
    _productChannel = _supabase
        .channel('products-realtime-mobile')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'products',
          callback: (payload) {
            _handleProductUpdate(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'products',
          callback: (payload) {
            // A new product was added — refresh lists on next load
            _refreshNeeded = true;
            notifyListeners();
          },
        )
        .subscribe();
  }

  bool _refreshNeeded = false;
  bool get refreshNeeded => _refreshNeeded;
  void clearRefreshNeeded() => _refreshNeeded = false;

  void _handleProductUpdate(Map<String, dynamic> updatedData) {
    final id = updatedData['id'];
    if (id == null) return;

    // Update in featured products
    _updateProductInList(_featuredProducts, id, updatedData);
    // Update in new arrivals
    _updateProductInList(_newArrivals, id, updatedData);
    // Update in main product list
    _updateProductInList(_products, id, updatedData);
    // Update selected product if it matches
    if (_selectedProduct?.id == id) {
      _selectedProduct = Product.fromJson({
        ..._selectedProductToMap(),
        ...updatedData,
      });
    }

    notifyListeners();
  }

  void _updateProductInList(
      List<Product> list, String id, Map<String, dynamic> updatedData) {
    final idx = list.indexWhere((p) => p.id == id);
    if (idx != -1) {
      // Merge updated fields into existing product JSON
      final existing = _productToBasicMap(list[idx]);
      existing.addAll(updatedData);
      list[idx] = Product.fromJson(existing);
    }
  }

  Map<String, dynamic> _productToBasicMap(Product p) => {
        'id': p.id,
        'seller_id': p.sellerId,
        'shop_id': p.shopId,
        'category_id': p.categoryId,
        'brand_id': p.brandId,
        'name': p.name,
        'slug': p.slug,
        'description': p.description,
        'price': p.price,
        'discount_price': p.discountPrice,
        'discount_percentage': p.discountPercentage,
        'stock_quantity': p.stockQuantity,
        'sku': p.sku,
        'rating': p.rating,
        'total_reviews': p.totalReviews,
        'total_sales': p.totalSales,
        'is_featured': p.isFeatured,
        'is_active': p.isActive,
        'approval_status': p.approvalStatus,
      };

  Map<String, dynamic> _selectedProductToMap() {
    if (_selectedProduct == null) return {};
    return _productToBasicMap(_selectedProduct!);
  }

  /// Atomically increment view count via server RPC.
  /// The update propagates via Realtime to all connected clients.
  Future<void> incrementViews(String productId) async {
    try {
      await _supabase.rpc('increment_product_views', params: {
        'p_product_id': productId,
      });
    } catch (e) {
      debugPrint('Failed to increment product views: $e');
    }
  }

  /// Unsubscribe from realtime (call in dispose)
  void disposeRealtime() {
    _productChannel?.unsubscribe();
    _productChannel = null;
  }

  @override
  void dispose() {
    disposeRealtime();
    super.dispose();
  }
}
