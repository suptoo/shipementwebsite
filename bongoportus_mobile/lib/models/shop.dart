class Shop {
  final String id;
  final String sellerId;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final double rating;
  final int totalProducts;
  final int totalOrders;

  Shop({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    this.rating = 0,
    this.totalProducts = 0,
    this.totalOrders = 0,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] ?? '',
      sellerId: json['seller_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      logoUrl: json['logo_url'],
      bannerUrl: json['banner_url'],
      rating: (json['rating'] ?? 0).toDouble(),
      totalProducts: json['total_products'] ?? 0,
      totalOrders: json['total_orders'] ?? 0,
    );
  }
}
