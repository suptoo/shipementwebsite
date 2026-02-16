class Brand {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final bool isActive;

  Brand({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.isActive = true,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      logoUrl: json['logo_url'],
      isActive: json['is_active'] ?? true,
    );
  }
}
