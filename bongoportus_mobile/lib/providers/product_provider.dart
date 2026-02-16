import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/brand.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

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

  /// Load home page data
  Future<void> loadHomeData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _productService.getFeaturedProducts(limit: 10),
        _productService.getNewArrivals(limit: 10),
        _productService.getCategories(),
      ]);

      _featuredProducts = results[0] as List<Product>;
      _newArrivals = results[1] as List<Product>;
      _categories = results[2] as List<Category>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load products with filters
  Future<void> loadProducts({ProductFilters? filters, bool refresh = false}) async {
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
}
