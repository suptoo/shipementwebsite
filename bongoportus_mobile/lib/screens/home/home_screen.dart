import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/product.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shimmer_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _heroAnimCtrl;
  late AnimationController _sectionAnimCtrl;
  late AnimationController _promoAnimCtrl;
  final PageController _promoPageCtrl = PageController();

  // Staggered section animations
  late Animation<double> _quickActionsAnim;
  late Animation<double> _categoriesAnim;
  late Animation<double> _featuredAnim;
  late Animation<double> _newArrivalsAnim;

  int _currentPromoPage = 0;

  static const List<Map<String, dynamic>> _promoBanners = [
    {
      'title': 'Flash Sale \u26A1',
      'subtitle': 'Up to 50% off electronics',
      'gradient': [Color(0xFFFF6B35), Color(0xFFFF9A6C)],
    },
    {
      'title': 'New Arrivals \u2728',
      'subtitle': 'Fresh styles just dropped',
      'gradient': [Color(0xFF667eea), Color(0xFF764ba2)],
    },
    {
      'title': 'Free Shipping \uD83D\uDE9A',
      'subtitle': 'On orders above \u09F3500',
      'gradient': [Color(0xFF43e97b), Color(0xFF38f9d7)],
    },
  ];

  @override
  void initState() {
    super.initState();

    // Hero entrance
    _heroAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Staggered sections cascade (1200ms total, each section gets an interval)
    _sectionAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _quickActionsAnim = CurvedAnimation(
      parent: _sectionAnimCtrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    );
    _categoriesAnim = CurvedAnimation(
      parent: _sectionAnimCtrl,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
    );
    _featuredAnim = CurvedAnimation(
      parent: _sectionAnimCtrl,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
    );
    _newArrivalsAnim = CurvedAnimation(
      parent: _sectionAnimCtrl,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
    );

    // Promo banner auto-scroll
    _promoAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _currentPromoPage = (_currentPromoPage + 1) % _promoBanners.length;
          if (_promoPageCtrl.hasClients) {
            _promoPageCtrl.animateToPage(
              _currentPromoPage,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
          _promoAnimCtrl.forward(from: 0);
        }
      });

    _heroAnimCtrl.forward();
    _sectionAnimCtrl.forward();
    _promoAnimCtrl.forward();
    _loadData();
  }

  void _loadData() {
    final productProvider = context.read<ProductProvider>();
    productProvider.loadHomeData();

    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      context.read<CartProvider>().loadCart(auth.userId!);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _heroAnimCtrl.dispose();
    _sectionAnimCtrl.dispose();
    _promoAnimCtrl.dispose();
    _promoPageCtrl.dispose();
    super.dispose();
  }

  // ── Category helpers ──
  static const List<Map<String, dynamic>> _defaultCategories = [
    {
      'emoji': '📱',
      'name': 'Electronics',
      'gradient': [Color(0xFF667eea), Color(0xFF764ba2)]
    },
    {
      'emoji': '👗',
      'name': 'Fashion',
      'gradient': [Color(0xFFf093fb), Color(0xFFf5576c)]
    },
    {
      'emoji': '🏠',
      'name': 'Home & Living',
      'gradient': [Color(0xFF4facfe), Color(0xFF00f2fe)]
    },
    {
      'emoji': '🧴',
      'name': 'Beauty',
      'gradient': [Color(0xFFa18cd1), Color(0xFFfbc2eb)]
    },
    {
      'emoji': '⚽',
      'name': 'Sports',
      'gradient': [Color(0xFF43e97b), Color(0xFF38f9d7)]
    },
    {
      'emoji': '📚',
      'name': 'Books',
      'gradient': [Color(0xFFfa709a), Color(0xFFfee140)]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              _buildHeroSection(),
              _buildPromoBanner(),
              _buildQuickActions(),
              _buildCategoriesGrid(),
              _buildFeaturedSection(),
              _buildNewArrivalsSection(),
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // HERO SECTION — "What do you want to buy?"
  // ══════════════════════════════════════════════
  Widget _buildHeroSection() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _heroAnimCtrl,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: const Offset(0, 0),
          ).animate(CurvedAnimation(
            parent: _heroAnimCtrl,
            curve: Curves.easeOut,
          )),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  AppTheme.pagePadding, 16, AppTheme.pagePadding, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App bar row
                  Row(
                    children: [
                      Expanded(
                        child: Consumer<AuthProvider>(
                          builder: (_, auth, __) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.isAuthenticated
                                    ? 'Hello, ${auth.profile?.displayName.split(' ').first ?? 'there'} \u{1F44B}'
                                    : 'Welcome \u{1F44B}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.secondaryColor,
                                  letterSpacing: -0.5,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Find exactly what you need',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Consumer<AuthProvider>(
                        builder: (_, auth, __) => GestureDetector(
                          onTap: () => context.go('/profile'),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme.primaryGradient,
                            ),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white,
                              backgroundImage: auth.profile?.avatarUrl != null
                                  ? NetworkImage(auth.profile!.avatarUrl!)
                                  : null,
                              child: auth.profile?.avatarUrl == null
                                  ? const Icon(Icons.person_rounded,
                                      color: AppTheme.primaryColor, size: 22)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ── "What do you want to buy?" search/inquiry ──
                  GestureDetector(
                    onTap: () => context.push('/inquiry'),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withAlpha(12),
                            AppTheme.primaryColor.withAlpha(6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryColor.withAlpha(30),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_rounded,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'What do you want to buy?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.secondaryColor,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Type or snap a photo — we\'ll find it for you',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 16, color: AppTheme.primaryColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Regular search bar ──
                  GestureDetector(
                    onTap: () => context.push('/search'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 15),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded,
                              color: Colors.grey.shade400, size: 22),
                          const SizedBox(width: 12),
                          Text(
                            'Search products, brands & more...',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.tune_rounded,
                                color: AppTheme.primaryColor, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // PROMO BANNER — auto-scrolling
  // ══════════════════════════════════════════════
  Widget _buildPromoBanner() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _quickActionsAnim,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppTheme.pagePadding, 16, AppTheme.pagePadding, 0),
          child: SizedBox(
            height: 100,
            child: PageView.builder(
              controller: _promoPageCtrl,
              itemCount: _promoBanners.length,
              onPageChanged: (i) => _currentPromoPage = i,
              itemBuilder: (_, i) {
                final banner = _promoBanners[i];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: banner['gradient'] as List<Color>,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: (banner['gradient'] as List<Color>).first.withAlpha(40),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              banner['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              banner['subtitle'] as String,
                              style: TextStyle(
                                color: Colors.white.withAlpha(210),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // QUICK ACTIONS — staggered elastic entrance
  // ══════════════════════════════════════════════
  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.grid_view_rounded,
        'label': 'Browse All',
        'color': AppTheme.infoColor,
        'route': '/products',
      },
      {
        'icon': Icons.chat_bubble_rounded,
        'label': 'Chat',
        'color': AppTheme.successColor,
        'route': '/inquiry',
      },
      {
        'icon': Icons.local_fire_department_rounded,
        'label': 'Deals',
        'color': AppTheme.warningColor,
        'route': '/products',
      },
      {
        'icon': Icons.storefront_rounded,
        'label': 'Sellers',
        'color': const Color(0xFF8B5CF6),
        'route': '/products',
      },
    ];

    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _quickActionsAnim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(_quickActionsAnim),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppTheme.pagePadding, 20, AppTheme.pagePadding, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: actions.asMap().entries.map((entry) {
                final i = entry.key;
                final a = entry.value;
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 400 + (i * 100)),
                  curve: Curves.elasticOut,
                  builder: (_, val, child) => Transform.scale(
                    scale: val.clamp(0.0, 1.0),
                    child: child,
                  ),
                  child: GestureDetector(
                    onTap: () => context.push(a['route'] as String),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: (a['color'] as Color).withAlpha(18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            a['icon'] as IconData,
                            color: a['color'] as Color,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          a['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // CATEGORIES GRID — staggered fade-in
  // ══════════════════════════════════════════════
  Widget _buildCategoriesGrid() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        return SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _categoriesAnim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(_categoriesAnim),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    title: 'Shop by Category',
                    icon: Icons.grid_view_rounded,
                    iconColor: AppTheme.primaryColor,
                    onViewAll: () => context.push('/categories'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.pagePadding),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.95,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: provider.categories.isNotEmpty
                          ? provider.categories.length.clamp(0, 6)
                          : _defaultCategories.length,
                      itemBuilder: (context, index) {
                        if (provider.categories.isNotEmpty) {
                          final cat = provider.categories[index];
                          final colors = index < _defaultCategories.length
                              ? _defaultCategories[index]['gradient'] as List<Color>
                              : [AppTheme.primaryColor, AppTheme.primaryLight];
                          final emoji = index < _defaultCategories.length
                              ? _defaultCategories[index]['emoji'] as String
                              : '\uD83D\uDCE6';

                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 400 + (index * 80)),
                            curve: Curves.easeOutCubic,
                            builder: (_, val, child) => Opacity(
                              opacity: val,
                              child: Transform.translate(
                                offset: Offset(0, 12 * (1 - val)),
                                child: child,
                              ),
                            ),
                            child: _CategoryCard(
                              emoji: emoji,
                              name: cat.name,
                              gradient: colors,
                              onTap: () {
                                provider.updateFilters(
                                  ProductFilters(categoryId: cat.id),
                                );
                                context.push('/products');
                              },
                            ),
                          );
                        }

                        // Default categories fallback
                        final def = _defaultCategories[index];
                        return _CategoryCard(
                          emoji: def['emoji'] as String,
                          name: def['name'] as String,
                          gradient: def['gradient'] as List<Color>,
                          onTap: () => context.push('/products'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════
  // SECTION HEADER
  // ══════════════════════════════════════════════
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onViewAll,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.pagePadding, 28, AppTheme.pagePadding, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.secondaryColor,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: AppTheme.primaryColor, size: 12),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // FEATURED PRODUCTS
  // ══════════════════════════════════════════════
  Widget _buildFeaturedSection() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.featuredProducts.isEmpty) {
          return SliverToBoxAdapter(child: _buildShimmerGrid());
        }

        if (provider.featuredProducts.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _featuredAnim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(_featuredAnim),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    title: 'Featured',
                    icon: Icons.star_rounded,
                    iconColor: AppTheme.primaryColor,
                    onViewAll: () {
                      provider.updateFilters(ProductFilters(sortBy: 'popular'));
                      context.push('/products');
                    },
                  ),
                  SizedBox(
                    height: 285,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.pagePadding),
                      scrollDirection: Axis.horizontal,
                      itemCount: provider.featuredProducts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 175,
                          child: ProductCard(
                            product: provider.featuredProducts[index],
                            onTap: () => context.push(
                              '/product/${provider.featuredProducts[index].id}',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════
  // NEW ARRIVALS
  // ══════════════════════════════════════════════
  Widget _buildNewArrivalsSection() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.newArrivals.isEmpty) {
          return SliverToBoxAdapter(child: _buildShimmerGrid());
        }

        if (provider.newArrivals.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _newArrivalsAnim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(_newArrivalsAnim),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    title: 'New Arrivals',
                    icon: Icons.new_releases_rounded,
                    iconColor: AppTheme.successColor,
                    onViewAll: () {
                      provider.updateFilters(ProductFilters(sortBy: 'newest'));
                      context.push('/products');
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.pagePadding),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.62,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: provider.newArrivals.length.clamp(0, 6),
                      itemBuilder: (context, index) {
                        return ProductCard(
                          product: provider.newArrivals[index],
                          onTap: () => context.push(
                            '/product/${provider.newArrivals[index].id}',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════
  // SHIMMER LOADING
  // ══════════════════════════════════════════════
  Widget _buildShimmerGrid() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.pagePadding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: 4,
        itemBuilder: (_, __) =>
            const ShimmerLoading(height: 240, width: double.infinity),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// CATEGORY CARD WIDGET
// ══════════════════════════════════════════════
class _CategoryCard extends StatelessWidget {
  final String emoji;
  final String name;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.emoji,
    required this.name,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient.map((c) => c.withAlpha(25)).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: gradient.first.withAlpha(20),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
