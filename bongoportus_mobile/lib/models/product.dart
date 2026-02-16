import 'category.dart';
import 'brand.dart';
import 'shop.dart';

class ProductImage {
  final String id;
  final String productId;
  final String imageUrl;
  final int displayOrder;
  final bool isPrimary;

  ProductImage({
    required this.id,
    required this.productId,
    required this.imageUrl,
    this.displayOrder = 0,
    this.isPrimary = false,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      imageUrl: json['image_url'] ?? '',
      displayOrder: json['display_order'] ?? 0,
      isPrimary: json['is_primary'] ?? false,
    );
  }
}

class ProductVariant {
  final String id;
  final String productId;
  final String variantType;
  final String variantValue;
  final double priceAdjustment;
  final int stockQuantity;
  final String? sku;

  ProductVariant({
    required this.id,
    required this.productId,
    required this.variantType,
    required this.variantValue,
    this.priceAdjustment = 0,
    this.stockQuantity = 0,
    this.sku,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      variantType: json['variant_type'] ?? '',
      variantValue: json['variant_value'] ?? '',
      priceAdjustment: (json['price_adjustment'] ?? 0).toDouble(),
      stockQuantity: json['stock_quantity'] ?? 0,
      sku: json['sku'],
    );
  }
}

class Product {
  final String id;
  final String sellerId;
  final String shopId;
  final String categoryId;
  final String? brandId;
  final String name;
  final String slug;
  final String? description;
  final double price;
  final double? discountPrice;
  final double? discountPercentage;
  final int stockQuantity;
  final String? sku;
  final double rating;
  final int totalReviews;
  final int totalSales;
  final bool isFeatured;
  final bool isActive;
  final String approvalStatus;
  final List<ProductImage> images;
  final List<ProductVariant> variants;
  final Category? category;
  final Brand? brand;
  final Shop? shop;

  Product({
    required this.id,
    required this.sellerId,
    required this.shopId,
    required this.categoryId,
    this.brandId,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    this.discountPrice,
    this.discountPercentage,
    this.stockQuantity = 0,
    this.sku,
    this.rating = 0,
    this.totalReviews = 0,
    this.totalSales = 0,
    this.isFeatured = false,
    this.isActive = true,
    this.approvalStatus = 'pending',
    this.images = const [],
    this.variants = const [],
    this.category,
    this.brand,
    this.shop,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      sellerId: json['seller_id'] ?? '',
      shopId: json['shop_id'] ?? '',
      categoryId: json['category_id'] ?? '',
      brandId: json['brand_id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      discountPrice: json['discount_price'] != null
          ? (json['discount_price']).toDouble()
          : null,
      discountPercentage: json['discount_percentage'] != null
          ? (json['discount_percentage']).toDouble()
          : null,
      stockQuantity: json['stock_quantity'] ?? 0,
      sku: json['sku'],
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      totalSales: json['total_sales'] ?? 0,
      isFeatured: json['is_featured'] ?? false,
      isActive: json['is_active'] ?? true,
      approvalStatus: json['approval_status'] ?? 'pending',
      images: (json['product_images'] as List<dynamic>?)
              ?.map((i) => ProductImage.fromJson(i))
              .toList() ??
          [],
      variants: (json['product_variants'] as List<dynamic>?)
              ?.map((v) => ProductVariant.fromJson(v))
              .toList() ??
          [],
      category: json['categories'] != null
          ? Category.fromJson(json['categories'])
          : null,
      brand: json['brands'] != null ? Brand.fromJson(json['brands']) : null,
      shop: json['shops'] != null ? Shop.fromJson(json['shops']) : null,
    );
  }

  /// Get the primary image URL or first image
  String? get primaryImageUrl {
    if (images.isEmpty) return null;
    final primary = images.where((i) => i.isPrimary).toList();
    if (primary.isNotEmpty) return primary.first.imageUrl;
    return images.first.imageUrl;
  }

  /// Get the effective/display price (considers discount)
  double get effectivePrice => discountPrice ?? price;

  /// Check if product has a discount
  bool get hasDiscount => discountPrice != null && discountPrice! < price;

  /// In stock?
  bool get inStock => stockQuantity > 0;
}

class ProductFilters {
  final String? categoryId;
  final String? brandId;
  final double? minPrice;
  final double? maxPrice;
  final double? rating;
  final String? searchQuery;
  final String? sortBy;

  ProductFilters({
    this.categoryId,
    this.brandId,
    this.minPrice,
    this.maxPrice,
    this.rating,
    this.searchQuery,
    this.sortBy,
  });

  ProductFilters copyWith({
    String? categoryId,
    String? brandId,
    double? minPrice,
    double? maxPrice,
    double? rating,
    String? searchQuery,
    String? sortBy,
  }) {
    return ProductFilters(
      categoryId: categoryId ?? this.categoryId,
      brandId: brandId ?? this.brandId,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      rating: rating ?? this.rating,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class PaginatedResponse<T> {
  final List<T> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PaginatedResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });
}
