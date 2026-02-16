import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../models/review.dart';
import '../../services/product_service.dart';
import '../../widgets/rating_stars.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;
  ProductVariant? _selectedVariant;
  int _quantity = 1;
  List<Review> _reviews = [];
  bool _loadingReviews = false;
  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    context.read<ProductProvider>().loadProduct(widget.productId);
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _loadingReviews = true);
    try {
      _reviews = await _productService.getProductReviews(widget.productId);
    } catch (_) {}
    if (mounted) setState(() => _loadingReviews = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final product = provider.selectedProduct;
        if (product == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Product not found')),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Image Gallery AppBar
              _buildImageGallery(product),
              // Product Info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.pagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price
                      _buildPriceSection(product),
                      const SizedBox(height: 14),
                      // Name
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.secondaryColor,
                          letterSpacing: -0.3,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Rating & sales
                      _buildRatingRow(product),
                      const SizedBox(height: 16),
                      // Shop info
                      if (product.shop != null) _buildShopCard(product),
                      const SizedBox(height: 16),
                      // Variants
                      if (product.variants.isNotEmpty) _buildVariants(product),
                      // Quantity
                      _buildQuantitySelector(),
                      const SizedBox(height: 16),
                      // Description
                      _buildDescription(product),
                      const SizedBox(height: 24),
                      // Reviews
                      _buildReviewsSection(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomSheet: _buildBottomBar(product),
        );
      },
    );
  }

  Widget _buildImageGallery(Product product) {
    final images = product.images;
    return SliverAppBar(
      expandedHeight: 360,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: AppTheme.secondaryColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: images.isEmpty
            ? Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, size: 80, color: Colors.grey),
              )
            : Stack(
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (i) =>
                        setState(() => _currentImageIndex = i),
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: images[i].imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 60),
                      ),
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (i) => Container(
                            width: _currentImageIndex == i ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: _currentImageIndex == i
                                  ? AppTheme.primaryColor
                                  : Colors.white.withAlpha(128),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Discount badge
                  if (product.hasDiscount)
                    Positioned(
                      top: 100,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${product.discountPercentage?.round() ?? ((1 - product.discountPrice! / product.price) * 100).round()}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildPriceSection(Product product) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '\u09F3${product.effectivePrice.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryColor,
            letterSpacing: -0.5,
          ),
        ),
        if (product.hasDiscount) ...[
          const SizedBox(width: 10),
          Text(
            '৳${product.price.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 18,
              decoration: TextDecoration.lineThrough,
              color: Colors.grey.shade500,
            ),
          ),
        ],
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: product.inStock
                ? AppTheme.successColor.withAlpha(25)
                : AppTheme.errorColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            product.inStock ? 'In Stock' : 'Out of Stock',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: product.inStock
                  ? AppTheme.successColor
                  : AppTheme.errorColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingRow(Product product) {
    return Row(
      children: [
        RatingStars(rating: product.rating, size: 18),
        const SizedBox(width: 8),
        Text(
          '${product.rating.toStringAsFixed(1)} (${product.totalReviews} reviews)',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        Icon(Icons.shopping_bag_outlined,
            size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          '${product.totalSales} sold',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildShopCard(Product product) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primaryColor.withAlpha(25),
            backgroundImage: product.shop?.logoUrl != null
                ? NetworkImage(product.shop!.logoUrl!)
                : null,
            child: product.shop?.logoUrl == null
                ? const Icon(Icons.store, color: AppTheme.primaryColor, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.shop!.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${product.shop!.totalProducts} products',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: const Text('Visit', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildVariants(Product product) {
    // Group variants by type
    final variantGroups = <String, List<ProductVariant>>{};
    for (final v in product.variants) {
      variantGroups.putIfAbsent(v.variantType, () => []).add(v);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: variantGroups.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.key,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entry.value.map((variant) {
                final isSelected = _selectedVariant?.id == variant.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedVariant = variant),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withAlpha(25)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      variant.variantValue,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.secondaryColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        const Text(
          'Quantity',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 18),
                onPressed:
                    _quantity > 1 ? () => setState(() => _quantity--) : null,
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$_quantity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: () => setState(() => _quantity++),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.description ?? 'No description available.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Reviews',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            if (_reviews.isNotEmpty)
              TextButton(
                onPressed: () {},
                child: Text('See All (${_reviews.length})'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loadingReviews)
          const Center(child: CircularProgressIndicator())
        else if (_reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                'No reviews yet',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ),
          )
        else
          ..._reviews.take(3).map((review) => _buildReviewCard(review)),
      ],
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryColor.withAlpha(25),
                child: Text(
                  (review.user?.displayName ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                review.user?.displayName ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              RatingStars(rating: review.rating, size: 14),
            ],
          ),
          if (review.comment != null) ...[
            const SizedBox(height: 8),
            Text(
              review.comment!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(Product product) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(240),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Chat button
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
              ),
              child: IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 12),
            // Add to cart
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: product.inStock ? () => _addToCart(product) : null,
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('Add to Cart'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Buy now — gradient
            Expanded(
              child: SizedBox(
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: product.inStock
                        ? const LinearGradient(
                            colors: [Color(0xFFFF6B35), Color(0xFFFF8A57)],
                          )
                        : null,
                    color: product.inStock ? null : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                    boxShadow: product.inStock
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryColor.withAlpha(50),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: ElevatedButton(
                    onPressed: product.inStock ? () => _buyNow(product) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                    ),
                    child: Text(
                      'Buy Now',
                      style: TextStyle(
                        color: product.inStock ? Colors.white : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart(Product product) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      context.push('/login');
      return;
    }

    try {
      await context.read<CartProvider>().addToCart(
            userId: auth.userId!,
            productId: product.id,
            quantity: _quantity,
            variantId: _selectedVariant?.id,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Added to cart!'),
            backgroundColor: AppTheme.successColor,
            action: SnackBarAction(
              label: 'View Cart',
              textColor: Colors.white,
              onPressed: () => context.go('/cart'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _buyNow(Product product) async {
    await _addToCart(product);
    if (mounted) {
      GoRouter.of(context).push('/checkout');
    }
  }
}
