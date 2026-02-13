import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Search, TrendingUp, ArrowRight, Sparkles, Zap, Shield, Truck, Star, ChevronLeft, ChevronRight, ShoppingCart, Heart } from 'lucide-react';
import { useCartStore } from '../store/cartStore';

// Category data with icons
const categories = [
  { name: 'Electronics', icon: '💻', color: 'from-blue-500 to-cyan-500', slug: 'electronics' },
  { name: 'Fashion', icon: '👕', color: 'from-pink-500 to-rose-500', slug: 'fashion' },
  { name: 'Home & Living', icon: '🏠', color: 'from-amber-500 to-orange-500', slug: 'home-living' },
  { name: 'Beauty', icon: '💄', color: 'from-purple-500 to-violet-500', slug: 'beauty' },
  { name: 'Sports', icon: '⚽', color: 'from-green-500 to-emerald-500', slug: 'sports' },
  { name: 'Toys', icon: '🎮', color: 'from-indigo-500 to-blue-500', slug: 'toys' },
];

// Hero slides data with LOCAL images
const heroSlides = [
  {
    title: 'New Year Sale',
    subtitle: 'Up to 50% Off',
    description: 'Start 2026 with amazing deals on electronics, fashion, and more!',
    gradient: 'from-violet-600 via-purple-600 to-indigo-700',
    accent: 'text-yellow-300',
    image: '/images/products/laptops/macbook-pro-16.png',
  },
  {
    title: 'Fashion Week',
    subtitle: 'Trending Styles',
    description: 'Discover the latest collections from top brands',
    gradient: 'from-rose-500 via-pink-600 to-purple-600',
    accent: 'text-pink-200',
    image: '/images/products/womens-fashion/floral-summer-dress.png',
  },
  {
    title: 'Smart Home',
    subtitle: 'Tech Essentials',
    description: 'Transform your living space with cutting-edge technology',
    gradient: 'from-blue-600 via-cyan-600 to-teal-500',
    accent: 'text-cyan-200',
    image: '/images/products/home-living/modern-sofa.png',
  },
];

// Features data
const features = [
  { icon: <Truck className="w-6 h-6" />, title: 'Free Shipping', desc: 'On orders over ৳1000' },
  { icon: <Shield className="w-6 h-6" />, title: 'Secure Payment', desc: '100% secure checkout' },
  { icon: <Zap className="w-6 h-6" />, title: 'Fast Delivery', desc: '2-3 business days' },
  { icon: <Star className="w-6 h-6" />, title: 'Best Quality', desc: 'Top-rated products' },
];

// ========== STATIC PRODUCT DATA - NO DATABASE REQUIRED ==========

// Electronics Products (5 unique items with unique images)
const electronicsProducts = [
  { id: 'e1', name: 'iPhone 15 Pro', price: 149999, discountPrice: 139999, rating: 4.9, reviews: 342, image: '/images/products/smartphones/iphone-15-pro.png', category: 'Electronics' },
  { id: 'e2', name: 'Samsung Galaxy S24', price: 139900, discountPrice: 129900, rating: 4.8, reviews: 285, image: '/images/products/smartphones/samsung-galaxy-s24.png', category: 'Electronics' },
  { id: 'e3', name: 'Google Pixel 8', price: 79900, discountPrice: 74900, rating: 4.8, reviews: 450, image: '/images/products/smartphones/google-pixel-8.png', category: 'Electronics' },
  { id: 'e4', name: 'MacBook Pro 16"', price: 249900, discountPrice: 229900, rating: 4.9, reviews: 200, image: '/images/products/laptops/macbook-pro-16.png', category: 'Electronics' },
  { id: 'e5', name: 'Dell XPS 15', price: 189900, discountPrice: null, rating: 4.7, reviews: 156, image: '/images/products/laptops/dell-xps-15.png', category: 'Electronics' },
];

// Fashion Products (5 unique items with unique images)
const fashionProducts = [
  { id: 'f1', name: 'Nike Air Max 270', price: 15000, discountPrice: 12999, rating: 4.8, reviews: 567, image: '/images/products/mens-fashion/nike-air-max.png', category: 'Fashion' },
  { id: 'f2', name: 'Adidas Ultraboost', price: 19000, discountPrice: 16900, rating: 4.7, reviews: 423, image: '/images/products/mens-fashion/adidas-ultraboost.png', category: 'Fashion' },
  { id: 'f3', name: 'Tech Fleece Hoodie', price: 11000, discountPrice: 9900, rating: 4.6, reviews: 289, image: '/images/products/mens-fashion/tech-fleece-hoodie.png', category: 'Fashion' },
  { id: 'f4', name: 'Floral Summer Dress', price: 4500, discountPrice: 3999, rating: 4.7, reviews: 150, image: '/images/products/womens-fashion/floral-summer-dress.png', category: 'Fashion' },
  { id: 'f5', name: 'High-Waisted Jeans', price: 5500, discountPrice: null, rating: 4.6, reviews: 130, image: '/images/products/womens-fashion/high-waisted-jeans.png', category: 'Fashion' },
];

// Home & Living Products (5 unique items with unique images)
const homeProducts = [
  { id: 'h1', name: 'Modern L-Shape Sofa', price: 59900, discountPrice: 54900, rating: 4.8, reviews: 45, image: '/images/products/home-living/modern-sofa.png', category: 'Home & Living' },
  { id: 'h2', name: 'Wooden Coffee Table', price: 15000, discountPrice: null, rating: 4.7, reviews: 67, image: '/images/products/home-living/wooden-coffee-table.png', category: 'Home & Living' },
  { id: 'h3', name: 'HP Spectre Laptop', price: 149900, discountPrice: 134900, rating: 4.6, reviews: 89, image: '/images/products/laptops/hp-spectre.png', category: 'Electronics' },
  { id: 'h4', name: 'Lenovo ThinkPad X1', price: 169900, discountPrice: null, rating: 4.8, reviews: 90, image: '/images/products/laptops/lenovo-thinkpad.png', category: 'Electronics' },
  { id: 'h5', name: 'Gaming Laptop ROG', price: 159900, discountPrice: 149900, rating: 4.7, reviews: 75, image: '/images/products/laptops/gaming-laptop.png', category: 'Electronics' },
];

// Trending Products (8 mixed unique items)
const trendingProducts = [
  { id: 't1', name: 'iPhone 15 Pro', price: 149999, discountPrice: 139999, rating: 4.9, reviews: 342, image: '/images/products/smartphones/iphone-15-pro.png', category: 'Electronics', featured: true },
  { id: 't2', name: 'Samsung Z Fold', price: 179900, discountPrice: 159900, rating: 4.6, reviews: 40, image: '/images/products/smartphones/samsung-z-fold.png', category: 'Electronics', featured: true },
  { id: 't3', name: 'OnePlus 12', price: 65000, discountPrice: null, rating: 4.7, reviews: 120, image: '/images/products/smartphones/oneplus-12.png', category: 'Electronics', featured: false },
  { id: 't4', name: 'Sony Xperia 1 V', price: 119900, discountPrice: null, rating: 4.5, reviews: 25, image: '/images/products/smartphones/sony-xperia.png', category: 'Electronics', featured: false },
  { id: 't5', name: 'Xiaomi 14 Ultra', price: 109900, discountPrice: 99900, rating: 4.6, reviews: 30, image: '/images/products/smartphones/xiaomi-14-ultra.png', category: 'Electronics', featured: true },
  { id: 't6', name: 'Nothing Phone 2', price: 59900, discountPrice: null, rating: 4.4, reviews: 45, image: '/images/products/smartphones/nothing-phone-2.png', category: 'Electronics', featured: false },
  { id: 't7', name: 'Leather Handbag', price: 12000, discountPrice: 9999, rating: 4.9, reviews: 90, image: '/images/products/womens-fashion/leather-handbag.png', category: 'Fashion', featured: true },
  { id: 't8', name: 'iPhone 14', price: 99900, discountPrice: 89900, rating: 4.7, reviews: 200, image: '/images/products/smartphones/iphone-14.png', category: 'Electronics', featured: true },
];

// ========== STATIC PRODUCT CARD COMPONENT ==========
interface StaticProduct {
  id: string;
  name: string;
  price: number;
  discountPrice: number | null;
  rating: number;
  reviews: number;
  image: string;
  category: string;
  featured?: boolean;
}

const StaticProductCard: React.FC<{ product: StaticProduct }> = ({ product }) => {
  const addItem = useCartStore((state) => state.addItem);
  const hasDiscount = product.discountPrice && product.discountPrice < product.price;
  const displayPrice = product.discountPrice || product.price;
  const discountPercent = hasDiscount ? Math.round((1 - product.discountPrice! / product.price) * 100) : 0;

  const handleAddToCart = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    // Create a compatible product object for cart
    addItem({
      id: product.id,
      name: product.name,
      price: product.price,
      discount_price: product.discountPrice,
      images: [{ id: '1', product_id: product.id, image_url: product.image, display_order: 0, is_primary: true }],
      rating: product.rating,
      total_reviews: product.reviews,
      stock_quantity: 100,
      is_featured: product.featured || false,
      is_active: true,
      approval_status: 'approved',
      seller_id: 'demo',
      shop_id: 'demo',
      category_id: 'demo',
      brand_id: null,
      slug: product.id,
    } as any);
  };

  return (
    <div className="group bg-white rounded-2xl shadow-sm hover:shadow-2xl transition-all duration-300 overflow-hidden border border-gray-100 hover:border-blue-200 hover:-translate-y-2 cursor-pointer">
      <div className="relative aspect-square overflow-hidden bg-gradient-to-br from-gray-100 to-gray-50">
        <img
          src={product.image}
          alt={product.name}
          className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500"
          loading="eager"
        />

        {/* Badges */}
        <div className="absolute top-3 left-3 flex flex-col gap-2">
          {hasDiscount && (
            <div className="bg-gradient-to-r from-red-500 to-pink-600 text-white px-3 py-1.5 rounded-lg text-xs font-bold shadow-lg flex items-center gap-1">
              <TrendingUp size={12} />
              {discountPercent}% OFF
            </div>
          )}
          {product.featured && (
            <div className="bg-gradient-to-r from-yellow-400 to-orange-500 text-white px-3 py-1.5 rounded-lg text-xs font-bold shadow-lg">
              ⭐ Featured
            </div>
          )}
        </div>

        {/* Action Buttons */}
        <div className="absolute top-3 right-3 flex flex-col gap-2 opacity-0 group-hover:opacity-100 transition-all duration-300">
          <button className="p-2.5 bg-white/95 backdrop-blur-sm rounded-xl shadow-lg hover:bg-white hover:scale-110 transition-all duration-200">
            <Heart size={18} className="text-gray-700" />
          </button>
        </div>

        {/* Quick View Overlay */}
        <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/60 to-transparent p-4 opacity-0 group-hover:opacity-100 transition-all duration-300 translate-y-2 group-hover:translate-y-0">
          <button
            onClick={handleAddToCart}
            className="w-full flex items-center justify-center gap-2 bg-white text-blue-600 hover:bg-blue-50 py-2.5 px-4 rounded-xl transition-all duration-200 font-bold text-sm shadow-lg"
          >
            <ShoppingCart size={18} />
            Quick Add
          </button>
        </div>
      </div>

      <div className="p-5">
        <div className="text-xs text-blue-600 font-semibold mb-1 uppercase tracking-wider">
          {product.category}
        </div>
        <h3 className="text-sm font-semibold text-gray-900 line-clamp-2 mb-3 min-h-[40px] group-hover:text-blue-600 transition-colors">
          {product.name}
        </h3>

        <div className="flex items-center gap-2 mb-3">
          <div className="flex items-center gap-0.5">
            {[1, 2, 3, 4, 5].map((star) => (
              <Star
                key={star}
                size={14}
                className={star <= product.rating ? 'fill-yellow-400 text-yellow-400' : 'fill-gray-200 text-gray-200'}
              />
            ))}
          </div>
          <span className="text-xs text-gray-500 font-medium">
            {product.rating.toFixed(1)} ({product.reviews})
          </span>
        </div>

        <div className="flex items-center justify-between mb-4">
          <div className="flex items-baseline gap-2">
            <span className="text-xl font-bold text-blue-600">
              ৳{displayPrice.toLocaleString()}
            </span>
            {hasDiscount && (
              <span className="text-sm text-gray-400 line-through">
                ৳{product.price.toLocaleString()}
              </span>
            )}
          </div>
        </div>

        <button
          onClick={handleAddToCart}
          className="w-full flex items-center justify-center gap-2 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white py-3 px-4 rounded-xl transition-all duration-200 text-sm font-bold shadow-md hover:shadow-lg transform hover:scale-[1.02]"
        >
          <ShoppingCart size={16} />
          Add to Cart
        </button>
      </div>
    </div>
  );
};

// ========== STATIC PRODUCT GRID COMPONENT ==========
const StaticProductGrid: React.FC<{ products: StaticProduct[] }> = ({ products }) => {
  return (
    <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-5">
      {products.map((product, index) => (
        <div key={product.id} className="animate-in" style={{ animationDelay: `${index * 50}ms` }}>
          <StaticProductCard product={product} />
        </div>
      ))}
    </div>
  );
};

// ========== MAIN HOME COMPONENT ==========
export const Home: React.FC = () => {
  const [searchQuery, setSearchQuery] = useState('');
  const [currentSlide, setCurrentSlide] = useState(0);

  // Auto-rotate hero slides
  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentSlide((prev) => (prev + 1) % heroSlides.length);
    }, 5000);
    return () => clearInterval(timer);
  }, []);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    if (searchQuery.trim()) {
      window.location.href = `/products?search=${encodeURIComponent(searchQuery)}`;
    }
  };

  const nextSlide = () => setCurrentSlide((prev) => (prev + 1) % heroSlides.length);
  const prevSlide = () => setCurrentSlide((prev) => (prev - 1 + heroSlides.length) % heroSlides.length);

  return (
    <div className="min-h-screen bg-slate-50">

      {/* Hero Section */}
      <section className="relative overflow-hidden">
        {heroSlides.map((slide, index) => (
          <div
            key={index}
            className={`absolute inset-0 transition-all duration-700 ease-in-out ${index === currentSlide ? 'opacity-100 translate-x-0' : 'opacity-0 translate-x-full'
              }`}
          >
            <div className={`bg-gradient-to-br ${slide.gradient} min-h-[400px] md:min-h-[500px]`}>
              {/* Decorative elements */}
              <div className="absolute inset-0 overflow-hidden">
                <div className="absolute top-10 left-10 w-72 h-72 bg-white/10 rounded-full blur-3xl animate-pulse"></div>
                <div className="absolute bottom-10 right-10 w-96 h-96 bg-white/5 rounded-full blur-3xl"></div>
                <div className="absolute top-1/2 left-1/4 w-2 h-2 bg-white/40 rounded-full animate-ping"></div>
                <div className="absolute top-1/3 right-1/3 w-3 h-3 bg-white/30 rounded-full animate-bounce"></div>
              </div>

              <div className="relative max-w-7xl mx-auto px-4 py-16 md:py-24 flex items-center">
                <div className="flex-1 text-white z-10">
                  <div className={`inline-flex items-center gap-2 ${slide.accent} bg-white/10 backdrop-blur-sm px-4 py-2 rounded-full text-sm font-semibold mb-4 animate-pulse`}>
                    <Sparkles className="w-4 h-4" />
                    {slide.subtitle}
                  </div>
                  <h1 className="text-4xl md:text-6xl font-extrabold mb-4 tracking-tight">
                    {slide.title}
                  </h1>
                  <p className="text-lg md:text-xl text-white/80 mb-8 max-w-lg">
                    {slide.description}
                  </p>
                  <div className="flex gap-4">
                    <Link
                      to="/products"
                      className="bg-white text-gray-900 px-8 py-4 rounded-xl font-bold hover:bg-gray-100 transition-all transform hover:scale-105 shadow-xl"
                    >
                      Shop Now
                    </Link>
                    <button className="border-2 border-white/30 text-white px-8 py-4 rounded-xl font-semibold hover:bg-white/10 transition-all backdrop-blur-sm">
                      Learn More
                    </button>
                  </div>
                </div>
                <div className="hidden lg:block flex-1 relative">
                  <div className="absolute inset-0 bg-gradient-to-r from-transparent to-white/10 rounded-3xl"></div>
                  <img
                    src={slide.image}
                    alt={slide.title}
                    className="w-full max-w-md mx-auto drop-shadow-2xl transform hover:scale-105 transition-transform duration-500"
                    loading="eager"
                  />
                </div>
              </div>
            </div>
          </div>
        ))}

        {/* Static container for height */}
        <div className="bg-gradient-to-br from-violet-600 to-indigo-700 min-h-[400px] md:min-h-[500px] opacity-0 pointer-events-none"></div>

        {/* Slide navigation */}
        <div className="absolute bottom-8 left-1/2 -translate-x-1/2 flex items-center gap-4 z-20">
          <button
            onClick={prevSlide}
            className="p-2 bg-white/20 backdrop-blur-sm rounded-full text-white hover:bg-white/30 transition-all"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>
          <div className="flex gap-2">
            {heroSlides.map((_, idx) => (
              <button
                key={idx}
                onClick={() => setCurrentSlide(idx)}
                className={`w-3 h-3 rounded-full transition-all ${idx === currentSlide ? 'bg-white w-8' : 'bg-white/40 hover:bg-white/60'
                  }`}
              />
            ))}
          </div>
          <button
            onClick={nextSlide}
            className="p-2 bg-white/20 backdrop-blur-sm rounded-full text-white hover:bg-white/30 transition-all"
          >
            <ChevronRight className="w-5 h-5" />
          </button>
        </div>
      </section>

      {/* Search Bar */}
      <section className="max-w-5xl mx-auto px-4 -mt-8 relative z-30">
        <form onSubmit={handleSearch}>
          <div className="flex bg-white rounded-2xl overflow-hidden shadow-2xl border border-gray-100">
            <div className="flex-1 flex items-center gap-3 px-6 py-4">
              <Search className="text-gray-400 w-6 h-6" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search for products, brands, and more..."
                className="flex-1 text-gray-900 focus:outline-none bg-transparent text-lg"
              />
            </div>
            <button
              type="submit"
              className="px-8 py-4 bg-gradient-to-r from-blue-600 to-indigo-600 text-white font-bold hover:from-blue-700 hover:to-indigo-700 transition-all text-lg"
            >
              Search
            </button>
          </div>
        </form>
      </section>

      {/* Features Bar */}
      <section className="max-w-7xl mx-auto px-4 py-8">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {features.map((feature, idx) => (
            <div
              key={idx}
              className="flex items-center gap-4 bg-white rounded-xl p-4 shadow-sm border border-gray-100 hover:shadow-md transition-shadow"
            >
              <div className="w-12 h-12 bg-gradient-to-br from-blue-50 to-indigo-100 rounded-xl flex items-center justify-center text-blue-600">
                {feature.icon}
              </div>
              <div>
                <h4 className="font-semibold text-gray-900">{feature.title}</h4>
                <p className="text-sm text-gray-500">{feature.desc}</p>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Categories Section */}
      <section className="max-w-7xl mx-auto px-4 py-6">
        <h2 className="text-2xl font-bold text-gray-900 mb-6">Shop by Category</h2>
        <div className="grid grid-cols-3 md:grid-cols-6 gap-4">
          {categories.map((cat) => (
            <button
              key={cat.name}
              onClick={() => window.location.href = `/products?category=${encodeURIComponent(cat.slug)}`}
              className="group bg-white rounded-2xl p-4 shadow-sm hover:shadow-lg transition-all border border-gray-100 hover:-translate-y-1"
            >
              <div className={`w-14 h-14 mx-auto mb-3 rounded-2xl bg-gradient-to-br ${cat.color} flex items-center justify-center text-2xl shadow-lg group-hover:scale-110 transition-transform`}>
                {cat.icon}
              </div>
              <span className="text-sm font-semibold text-gray-700 group-hover:text-blue-600 transition-colors">
                {cat.name}
              </span>
            </button>
          ))}
        </div>
      </section>

      {/* Trending Products - STATIC, NO DATABASE */}
      <section className="max-w-7xl mx-auto px-4 py-8">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-gray-900 flex items-center gap-3">
            <div className="w-10 h-10 bg-gradient-to-br from-orange-400 to-red-500 rounded-xl flex items-center justify-center">
              <TrendingUp className="w-5 h-5 text-white" />
            </div>
            Trending Products
          </h2>
          <Link
            to="/products"
            className="flex items-center gap-2 text-blue-600 font-semibold hover:text-indigo-600 transition-colors bg-blue-50 hover:bg-blue-100 px-4 py-2 rounded-lg"
          >
            View All
            <ArrowRight className="w-4 h-4" />
          </Link>
        </div>
        <StaticProductGrid products={trendingProducts} />
      </section>

      {/* Promotional Banner */}
      <section className="max-w-7xl mx-auto px-4 py-6">
        <div className="relative overflow-hidden rounded-3xl bg-gradient-to-r from-purple-600 via-pink-600 to-red-500 p-8 md:p-12">
          <div className="absolute inset-0 bg-black/10"></div>
          <div className="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full -translate-y-1/2 translate-x-1/2 blur-3xl"></div>
          <div className="relative z-10 flex flex-col md:flex-row items-center justify-between gap-6">
            <div className="text-white text-center md:text-left">
              <h3 className="text-3xl md:text-4xl font-extrabold mb-2">Become a Seller</h3>
              <p className="text-white/80 text-lg">Start selling on BongoPortus and reach millions of customers</p>
            </div>
            <Link
              to="/become-seller"
              className="bg-white text-purple-600 px-8 py-4 rounded-xl font-bold hover:bg-gray-100 transition-all transform hover:scale-105 shadow-xl whitespace-nowrap"
            >
              Start Selling Today
            </Link>
          </div>
        </div>
      </section>

      {/* Electronics Section - STATIC, NO DATABASE */}
      <section className="max-w-7xl mx-auto px-4 py-8">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="text-3xl">💻</span>
            Electronics
          </h2>
          <Link
            to="/products?category=electronics"
            className="flex items-center gap-2 text-blue-600 font-semibold hover:text-indigo-600 transition-colors"
          >
            View All
            <ArrowRight className="w-4 h-4" />
          </Link>
        </div>
        <StaticProductGrid products={electronicsProducts} />
      </section>

      {/* Fashion Section - STATIC, NO DATABASE */}
      <section className="bg-gradient-to-br from-pink-50 to-purple-50 py-8 my-8">
        <div className="max-w-7xl mx-auto px-4">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-2xl font-bold text-gray-900 flex items-center gap-3">
              <span className="text-3xl">👕</span>
              Fashion
            </h2>
            <Link
              to="/products?category=fashion"
              className="flex items-center gap-2 text-pink-600 font-semibold hover:text-purple-600 transition-colors"
            >
              View All
              <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
          <StaticProductGrid products={fashionProducts} />
        </div>
      </section>

      {/* Home & Living Section - STATIC, NO DATABASE */}
      <section className="max-w-7xl mx-auto px-4 py-8">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-gray-900 flex items-center gap-3">
            <span className="text-3xl">🏠</span>
            Home & Living
          </h2>
          <Link
            to="/products?category=home-living"
            className="flex items-center gap-2 text-amber-600 font-semibold hover:text-orange-600 transition-colors"
          >
            View All
            <ArrowRight className="w-4 h-4" />
          </Link>
        </div>
        <StaticProductGrid products={homeProducts} />
      </section>

      {/* Newsletter Section */}
      <section className="bg-gradient-to-br from-gray-900 to-gray-800 py-16 mt-8">
        <div className="max-w-4xl mx-auto px-4 text-center">
          <h3 className="text-3xl font-bold text-white mb-4">Stay Updated</h3>
          <p className="text-gray-400 mb-8">Subscribe to our newsletter for exclusive deals and updates</p>
          <form className="flex flex-col sm:flex-row gap-4 justify-center">
            <input
              type="email"
              placeholder="Enter your email"
              className="px-6 py-4 rounded-xl bg-white/10 border border-white/20 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 flex-1 max-w-md backdrop-blur-sm"
            />
            <button
              type="submit"
              className="px-8 py-4 bg-gradient-to-r from-blue-500 to-indigo-600 text-white font-bold rounded-xl hover:from-blue-600 hover:to-indigo-700 transition-all shadow-lg"
            >
              Subscribe
            </button>
          </form>
        </div>
      </section>
    </div>
  );
};
