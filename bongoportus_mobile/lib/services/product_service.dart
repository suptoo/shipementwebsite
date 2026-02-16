import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/brand.dart';
import '../models/review.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Cache-first: try cache → if expired/missing, fetch from Supabase → cache result.
  /// On network failure, always fall back to cached data (even if expired).
  Future<T> _withCache<T>({
    required String cacheKey,
    required Duration ttl,
    required Future<List<Map<String, dynamic>>> Function() fetcher,
    required T Function(List<Map<String, dynamic>>) parser,
  }) async {
    final cache = await CacheService.getInstance();
    final isOnline = ConnectivityService.instance.isOnline.value;

    // Try fresh cache first
    final cached = cache.getCachedData(cacheKey);
    if (cached != null) {
      // If online, also fetch in background to refresh
      if (isOnline) {
        _refreshCache(cacheKey, ttl, fetcher);
      }
      return parser((cached as List).cast<Map<String, dynamic>>());
    }

    // No valid cache — try network
    if (isOnline) {
      try {
        final data = await fetcher();
        await cache.cacheData(cacheKey, data, ttl);
        return parser(data);
      } catch (_) {
        // Network error — try expired cache
        final stale = cache.getCachedDataForce(cacheKey);
        if (stale != null) {
          return parser((stale as List).cast<Map<String, dynamic>>());
        }
        rethrow;
      }
    }

    // Offline — try expired cache
    final stale = cache.getCachedDataForce(cacheKey);
    if (stale != null) {
      return parser((stale as List).cast<Map<String, dynamic>>());
    }

    throw Exception('No cached data available offline');
  }

  /// Background cache refresh (fire-and-forget)
  Future<void> _refreshCache(
    String cacheKey,
    Duration ttl,
    Future<List<Map<String, dynamic>>> Function() fetcher,
  ) async {
    try {
      final data = await fetcher();
      final cache = await CacheService.getInstance();
      await cache.cacheData(cacheKey, data, ttl);
    } catch (_) {
      // Silently fail — stale cache is fine
    }
  }

  /// Get products with filters and pagination
  Future<PaginatedResponse<Product>> getProducts({
    ProductFilters? filters,
    int page = 1,
    int limit = 20,
  }) async {
    // First get count
    final countQuery = _supabase
        .from('products')
        .select('id')
        .eq('is_active', true)
        .eq('approval_status', 'approved');
    final countData = await countQuery;
    final totalCount = (countData as List).length;

    // Build main query
    var query = _supabase
        .from('products')
        .select('*, product_images(*), categories(*), brands(*), shops(*)')
        .eq('is_active', true)
        .eq('approval_status', 'approved');

    if (filters != null) {
      if (filters.categoryId != null) {
        query = query.eq('category_id', filters.categoryId!);
      }
      if (filters.brandId != null) {
        query = query.eq('brand_id', filters.brandId!);
      }
      if (filters.minPrice != null) {
        query = query.gte('price', filters.minPrice!);
      }
      if (filters.maxPrice != null) {
        query = query.lte('price', filters.maxPrice!);
      }
      if (filters.rating != null) {
        query = query.gte('rating', filters.rating!);
      }
      if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
        query = query.ilike('name', '%${filters.searchQuery}%');
      }
    }

    // Determine sort column and direction
    String orderColumn = 'created_at';
    bool ascending = false;
    final sortBy = filters?.sortBy;
    switch (sortBy) {
      case 'price_asc':
        orderColumn = 'price';
        ascending = true;
        break;
      case 'price_desc':
        orderColumn = 'price';
        ascending = false;
        break;
      case 'rating':
        orderColumn = 'rating';
        ascending = false;
        break;
      case 'newest':
        orderColumn = 'created_at';
        ascending = false;
        break;
      case 'popular':
        orderColumn = 'total_sales';
        ascending = false;
        break;
    }

    // Pagination
    final from = (page - 1) * limit;
    final to = from + limit - 1;
    final response = await query
        .order(orderColumn, ascending: ascending)
        .range(from, to);

    final products = (response as List<dynamic>)
        .map((p) => Product.fromJson(p as Map<String, dynamic>))
        .toList();

    return PaginatedResponse(
      data: products,
      total: totalCount,
      page: page,
      limit: limit,
      totalPages: (totalCount / limit).ceil(),
    );
  }

  /// Get single product by ID or slug
  Future<Product?> getProduct(String idOrSlug) async {
    final isUUID = RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
            caseSensitive: false)
        .hasMatch(idOrSlug);

    final query = _supabase
        .from('products')
        .select(
            '*, product_images(*), product_variants(*), categories(*), brands(*), shops(*)')
        .eq('is_active', true)
        .eq('approval_status', 'approved');

    final data = isUUID
        ? await query.eq('id', idOrSlug).single()
        : await query.eq('slug', idOrSlug).single();

    return Product.fromJson(data);
  }

  /// Get featured products (cache-first)
  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    return _withCache(
      cacheKey: 'home_featured',
      ttl: CacheService.homeTTL,
      fetcher: () async {
        final data = await _supabase
            .from('products')
            .select('*, product_images(*), categories(*), brands(*)')
            .eq('is_active', true)
            .eq('is_featured', true)
            .eq('approval_status', 'approved')
            .order('total_sales', ascending: false)
            .limit(limit);
        return (data as List<dynamic>).cast<Map<String, dynamic>>();
      },
      parser: (data) =>
          data.map((p) => Product.fromJson(p)).toList(),
    );
  }

  /// Get new arrivals (cache-first)
  Future<List<Product>> getNewArrivals({int limit = 10}) async {
    return _withCache(
      cacheKey: 'home_new_arrivals',
      ttl: CacheService.homeTTL,
      fetcher: () async {
        final data = await _supabase
            .from('products')
            .select('*, product_images(*), categories(*), brands(*)')
            .eq('is_active', true)
            .eq('approval_status', 'approved')
            .order('created_at', ascending: false)
            .limit(limit);
        return (data as List<dynamic>).cast<Map<String, dynamic>>();
      },
      parser: (data) =>
          data.map((p) => Product.fromJson(p)).toList(),
    );
  }

  /// Get categories (cache-first)
  Future<List<Category>> getCategories() async {
    return _withCache(
      cacheKey: 'categories',
      ttl: CacheService.categoriesTTL,
      fetcher: () async {
        final data = await _supabase
            .from('categories')
            .select()
            .eq('is_active', true)
            .isFilter('parent_id', null)
            .order('display_order');

        final categories = <Map<String, dynamic>>[];
        for (final cat in (data as List<dynamic>)) {
          final subs = await _supabase
              .from('categories')
              .select()
              .eq('parent_id', cat['id'])
              .eq('is_active', true)
              .order('display_order');

          final catMap = Map<String, dynamic>.from(cat as Map);
          catMap['subcategories'] = subs;
          categories.add(catMap);
        }
        return categories;
      },
      parser: (data) =>
          data.map((c) => Category.fromJson(c)).toList(),
    );
  }

  /// Get brands
  Future<List<Brand>> getBrands() async {
    final data = await _supabase
        .from('brands')
        .select()
        .eq('is_active', true)
        .order('name');

    return (data as List<dynamic>)
        .map((b) => Brand.fromJson(b as Map<String, dynamic>))
        .toList();
  }

  /// Get product reviews
  Future<List<Review>> getProductReviews(String productId) async {
    final data = await _supabase
        .from('reviews')
        .select('*, profiles(*)')
        .eq('product_id', productId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((r) => Review.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Add product review
  Future<void> addReview({
    required String productId,
    required String userId,
    required double rating,
    String? title,
    String? comment,
    List<String>? imageUrls,
  }) async {
    await _supabase.from('reviews').insert({
      'product_id': productId,
      'user_id': userId,
      'rating': rating,
      'title': title,
      'comment': comment,
      'image_urls': imageUrls,
      'is_verified_purchase': true,
    });
  }

  /// Search products
  Future<List<Product>> searchProducts(String query, {int limit = 20}) async {
    final data = await _supabase
        .from('products')
        .select('*, product_images(*), categories(*), brands(*)')
        .eq('is_active', true)
        .eq('approval_status', 'approved')
        .ilike('name', '%$query%')
        .order('total_sales', ascending: false)
        .limit(limit);

    return (data as List<dynamic>)
        .map((p) => Product.fromJson(p as Map<String, dynamic>))
        .toList();
  }
}
