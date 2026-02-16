import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shimmer_loading.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<ProductProvider>();
    if (provider.products.isEmpty) {
      provider.loadProducts();
    }

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<ProductProvider>().loadMoreProducts();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: _showSortSheet,
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.products.isEmpty) {
            return _buildShimmerGrid();
          }

          if (provider.error != null && provider.products.isEmpty) {
            return _buildError(provider.error!);
          }

          if (provider.products.isEmpty) {
            return _buildEmpty();
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadProducts(refresh: true),
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.62,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: provider.products.length + (provider.isLoadingMore ? 2 : 0),
              itemBuilder: (context, index) {
                if (index >= provider.products.length) {
                  return const ShimmerLoading(height: 240, width: double.infinity);
                }

                return ProductCard(
                  product: provider.products[index],
                  onTap: () => context.push(
                    '/product/${provider.products[index].id}',
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const ShimmerLoading(height: 240, width: double.infinity),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Something went wrong', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                context.read<ProductProvider>().loadProducts(refresh: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final options = [
          ('newest', 'Newest First', Icons.schedule),
          ('popular', 'Most Popular', Icons.trending_up),
          ('price_asc', 'Price: Low to High', Icons.arrow_upward),
          ('price_desc', 'Price: High to Low', Icons.arrow_downward),
          ('rating', 'Highest Rated', Icons.star_rounded),
        ];

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort By',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...options.map(
                (opt) => ListTile(
                  leading: Icon(opt.$3, color: AppTheme.primaryColor),
                  title: Text(opt.$2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    context
                        .read<ProductProvider>()
                        .updateFilters(ProductFilters(sortBy: opt.$1));
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          builder: (_, controller) {
            return Consumer<ProductProvider>(
              builder: (context, provider, _) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: ListView(
                    controller: controller,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filters',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              provider.clearFilters();
                              Navigator.pop(context);
                            },
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Categories',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: provider.categories.map((cat) {
                          final isSelected =
                              provider.filters.categoryId == cat.id;
                          return FilterChip(
                            label: Text(cat.name),
                            selected: isSelected,
                            selectedColor:
                                AppTheme.primaryColor.withAlpha(38),
                            checkmarkColor: AppTheme.primaryColor,
                            onSelected: (_) {
                              provider.updateFilters(provider.filters.copyWith(
                                categoryId: isSelected ? null : cat.id,
                              ));
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Price Range',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ('Under ৳500', 0.0, 500.0),
                          ('৳500 - ৳1000', 500.0, 1000.0),
                          ('৳1000 - ৳5000', 1000.0, 5000.0),
                          ('Over ৳5000', 5000.0, 999999.0),
                        ].map((range) {
                          return FilterChip(
                            label: Text(range.$1),
                            selected: provider.filters.minPrice == range.$2,
                            selectedColor:
                                AppTheme.primaryColor.withAlpha(38),
                            checkmarkColor: AppTheme.primaryColor,
                            onSelected: (_) {
                              provider.updateFilters(
                                provider.filters.copyWith(
                                  minPrice: range.$2,
                                  maxPrice: range.$3,
                                ),
                              );
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
