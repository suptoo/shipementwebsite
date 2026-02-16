class Category {
  final String id;
  final String name;
  final String slug;
  final String? parentId;
  final String? iconUrl;
  final String? imageUrl;
  final int displayOrder;
  final bool isActive;
  final List<Category> subcategories;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
    this.iconUrl,
    this.imageUrl,
    this.displayOrder = 0,
    this.isActive = true,
    this.subcategories = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      parentId: json['parent_id'],
      iconUrl: json['icon_url'],
      imageUrl: json['image_url'],
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      subcategories: (json['subcategories'] as List<dynamic>?)
              ?.map((s) => Category.fromJson(s))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'parent_id': parentId,
      'icon_url': iconUrl,
      'image_url': imageUrl,
      'display_order': displayOrder,
      'is_active': isActive,
    };
  }
}
