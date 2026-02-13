import React, { useEffect, useState } from 'react';
import { Product, ProductFilters } from '../../types';
import { productService } from '../../services/productService';
import { ProductCard } from './ProductCard';
import { Loader2 } from 'lucide-react';

interface ProductListProps {
  filters?: ProductFilters;
  featured?: boolean;
  limit?: number;
}

// Demo products with placeholder images
const demoProducts: Omit<Product, 'id'>[] = [
  // Electronics (5 products)
  {
    seller_id: 'demo', shop_id: 'demo', category_id: 'cat-1', brand_id: null,
    name: 'iPhone 15 Pro',
    slug: 'iphone-15-pro',
    description: 'The ultimate iPhone with titanium design, A17 Pro chip.',
    price: 149999,
    discount_price: 139999,
    discount_percentage: 7,
    stock_quantity: 45,
    rating: 4.9,
    total_reviews: 342,
    total_sales: 1520,
    is_featured: true,
    is_active: true,
    approval_status: 'approved',
    category: { id: 'cat-1', name: 'Electronics', slug: 'electronics' },
    images: [{ id: '1', product_id: '1', image_url: 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=600&h=600&fit=crop', display_order: 0, is_primary: true }],
  },
  {
    seller_id: 'demo', shop_id: 'demo', category_id: 'cat-1', brand_id: null,
    name: 'Samsung Galaxy S24',
    slug: 'samsung-galaxy-s24',
    description: 'Galaxy AI is here. Experience the next generation.',
    price: 139900,
    discount_price: 129900,
    discount_percentage: 7,
    stock_quantity: 60,
    rating: 4.8,
    total_reviews: 285,
    total_sales: 980,
    is_featured: true,
    is_active: true,
    approval_status: 'approved',
    category: { id: 'cat-1', name: 'Electronics', slug: 'electronics' },
    images: [{ id: '2', product_id: '2', image_url: 'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=600&h=600&fit=crop', display_order: 0, is_primary: true }],
  },
  {
    seller_id: 'demo', shop_id: 'demo', category_id: 'cat-1', brand_id: null,
    name: 'Google Pixel 8',
    slug: 'google-pixel-8',
    description: 'The best of Google. AI-powered photography.',
    price: 79900,
    discount_price: 74900,
    discount_percentage: 6,
    stock_quantity: 100,
    rating: 4.8,
    total_reviews: 450,
    total_sales: 1200,
    is_featured: true,
    is_active: true,
    approval_status: 'approved',
    category: { id: 'cat-1', name: 'Electronics', slug: 'electronics' },
    images: [{ id: '3', product_id: '3', image_url: 'https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=600&h=600&fit=crop', display_order: 0, is_primary: true }],
  },
  {
    seller_id: 'demo', shop_id: 'demo', category_id: 'cat-1', brand_id: null,
    name: 'OnePlus 12',
    slug: 'oneplus-12',
    description: 'Flagship killer. Hasselblad camera system.',
    price: 65000,
    discount_price: null,
    discount_percentage: null,
    stock_quantity: 40,
    rating: 4.7,
    total_reviews: 120,
    total_sales: 500,
    is_featured: false,
    is_active: true,
    approval_status: 'approved',
    category: { id: 'cat-1', name: 'Electronics', slug: 'electronics' },
    images: [{ id: '4', product_id: '4', image_url: 'https://images.unsplash.com/photo-1605236453806-6ff36851218e?w=600&h=600&fit=crop', display_order: 0, is_primary: true }],
  },
  {
    seller_id: 'demo', shop_id: 'demo', category_id: 'cat-1', brand_id: null,
    name: 'MacBook Pro 16"',
    slug: 'macbook-pro-16',
    description: 'Strikingly powerful. M3 Pro chip for professionals.',
    price: 249900,
    discount_price: 229900,
    discount_percentage: 8,
    stock_quantity: 30,
    rating: 4.9,
    total_reviews: 200,
    total_sales: 800,
    is_featured: true,
    is_active: true,
    approval_status: 'approved',
    category: { id: 'cat-1', name: 'Electronics', slug: 'electronics' },
    images: [{ id: '5', product_id: '5', image_url: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=600&h=600&fit=crop', display_order: 0, is_primary: true }],
  },

  // Fashion (5 products)
  {
    seller_id: 'demo', shop_id: 'demo', category_id: 'cat-3', brand_id: null,
    name: 'Nike Air Max',
    slug: 'nike-air-max',
    description: 'Big air. Bold look. Maximum comfort.',
    price: 15000,
    discount_price: 12999,
    discount_percentage: 13,
    stock_quantity: 95,
    rating: 4.8,
    total_reviews: 567,
    total_sales: 2340,
    is_featured: true,
    is_active: true,
    approval_status: 'approved',
    category: { id: 'cat-3', name: 'Fashion', slug: 'fashion' },
    images: [{ id: '6', product_id: '6', image_url: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&h=600&fit=crop', display_order: 0, is_primary: true }],
  },
  {
    seller_id: 'demo', shop_id: 'demo', category_id: 'cat-3', brand_id: null,
    name: 'Adidas Ultraboost',
    slug: 'adidas-ultraboost',
    description: 'Epic energy return. Premium running experience.',
    price: 19000,
    discount_price: 16900,
    discount_percentage: 11,
    stock_quantity: 72,
    rating: 4.7,
    total_reviews: 423,
    total_sales: 1890,
    is_featured: false,
    is_active: true,
    approval_status: 'approved',
    category: { id: 'cat-3', name: 'Fashion', slug: 'fashion' },
    images: [{ id: '7', product_id: '7', image_url: 'https://images.unsplash.com/photo-1608231387042-66d1773070a5?w=600&h=600&fit=crop', display_order: 0, is_primary: true }],
  },
  {
    seller_id: 'demo', shop_id: 'demo', category_id: 'cat-3', brand_id: null,
    name: 'Tech Fleece Hoodie',
    slug: 'tech-fleece-hoodie',
    description: 'Warmth without weight. Premium streetwear.',
    price: 11000,
    discount_price: 9900,
    discount_percentage: 10,
    stock_quantity: 85,
    rating: 4.6,
    total_reviews: 289,
    total_sales: 1450,
    is_featured: false,
    is_active: true,
    approval_status: 'approved',
    category: { id: 'cat-3', name: 'Fashion', slug: 'fashion' },
    images: [{ id: '8', product_id: '8', image_url: 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=600&h=600&fit=crop', display_order: 0, is_primary: true }],
  },
  {
    seller_id: 'demo', shop_id: 'demo', category_id: 'cat-3', brand_id: null,
    name: 'Denim Jacket',
    slug: 'denim-jacket',
    description: 'Timeless style. Premium denim craftsmanship.',
    price: 6000,
    discount_price: null,
    discount_percentage: null,
    stock_quantity: 68,
    rating: 4.5,
    total_reviews: 178,
    total_sales: 890,
    is_featured: false,
    is_active: true,
    approval_status: 'approved',
    category: { id: 'cat-3', name: 'Fashion', slug: 'fashion' },
    images: [{ id: '9', product_id: '9', image_url: 'https://images.unsplash.com/photo-1576995853123-5a10305d93c0?w=600&h=600&fit=crop', display_order: 0, is_primary: true }],
  },
  {
    seller_id: 'demo', shop_id: 'demo', category_id: 'cat-3', brand_id: null,
    name: 'Floral Summer Dress',
    slug: 'floral-summer-dress',
    description: 'Light and breezy. Perfect for summer days.',
    price: 4500,
    discount_price: 3999,
    discount_percentage: 11,
    stock_quantity: 50,
    rating: 4.7,
    total_reviews: 150,
    total_sales: 600,
    is_featured: true,
    is_active: true,
    approval_status: 'approved',
    category: { id: 'cat-3', name: 'Fashion', slug: 'fashion' },
    images: [{ id: '10', product_id: '10', image_url: 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=600&h=600&fit=crop', display_order: 0, is_primary: true }],
  },

  // Home & Living (5 products)
  {
    seller_id: 'demo', shop_id: 'demo', category_id: 'cat-5', brand_id: null,
    name: 'Modern L-Shape Sofa',
    slug: 'modern-sofa',
    description: 'Comfortable and stylish. Contemporary design.',
    price: 59900,
    discount_price: 54900,
    discount_percentage: 8,
    stock_quantity: 8,
    rating: 4.8,
    total_reviews: 45,
    total_sales: 120,
    is_featured: true,
    is_active: true,
    approval_status: 'approved',
    category: { id: 'cat-5', name: 'Home & Living', slug: 'home-living' },
    images: [{ id: '11', product_id: '11', image_url: 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=600&h=600&fit=crop', display_order: 0, is_primary: true }],
  },
  {
    seller_id: 'demo', shop_id: 'demo', category_id: 'cat-5', brand_id: null,
    name: 'Wooden Coffee Table',
    slug: 'wooden-coffee-table',
    description: 'Solid oak wood. Natural wood grain.',
    price: 15000,
    discount_price: null,
    discount_percentage: null,
    stock_quantity: 22,
    rating: 4.7,
    total_reviews: 67,
    total_sales: 245,
    is_featured: false,
    is_active: true,
    approval_status: 'approved',
    category: { id: 'cat-5', name: 'Home & Living', slug: 'home-living' },
    images: [{ id: '12', product_id: '12', image_url: 'https://images.unsplash.com/photo-1533090481720-856c6e3c1fdc?w=600&h=600&fit=crop', display_order: 0, is_primary: true }],
  },
  {
    seller_id: 'demo', shop_id: 'demo', category_id: 'cat-5', brand_id: null,
    name: 'Ceramic Decorative Vase',
    slug: 'ceramic-vase',
    description: 'Minimalist design. Perfect for any room.',
    price: 2500,
    discount_price: null,
    discount_percentage: null,
    stock_quantity: 50,
    rating: 4.6,
    total_reviews: 89,
    total_sales: 300,
    is_featured: false,
    is_active: true,
    approval_status: 'approved',
    category: { id: 'cat-5', name: 'Home & Living', slug: 'home-living' },
    images: [{ id: '13', product_id: '13', image_url: 'https://images.unsplash.com/photo-1578500494198-246f612d3b3d?w=600&h=600&fit=crop', display_order: 0, is_primary: true }],
  },
  {
    seller_id: 'demo', shop_id: 'demo', category_id: 'cat-5', brand_id: null,
    name: 'Luxury Cotton Bed Sheets',
    slug: 'bed-sheets',
    description: 'Luxury feel. 100% organic cotton.',
    price: 4500,
    discount_price: 3999,
    discount_percentage: 11,
    stock_quantity: 80,
    rating: 4.9,
    total_reviews: 210,
    total_sales: 800,
    is_featured: true,
    is_active: true,
    approval_status: 'approved',
    category: { id: 'cat-5', name: 'Home & Living', slug: 'home-living' },
    images: [{ id: '14', product_id: '14', image_url: 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=600&h=600&fit=crop', display_order: 0, is_primary: true }],
  },
  {
    seller_id: 'demo', shop_id: 'demo', category_id: 'cat-5', brand_id: null,
    name: 'Modern LED Floor Lamp',
    slug: 'floor-lamp',
    description: 'Adjustable brightness. Modern aesthetic.',
    price: 8500,
    discount_price: 7500,
    discount_percentage: 12,
    stock_quantity: 35,
    rating: 4.5,
    total_reviews: 76,
    total_sales: 250,
    is_featured: false,
    is_active: true,
    approval_status: 'approved',
    category: { id: 'cat-5', name: 'Home & Living', slug: 'home-living' },
    images: [{ id: '15', product_id: '15', image_url: 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=600&h=600&fit=crop', display_order: 0, is_primary: true }],
  },

  // Beauty (5 products)
  {
    seller_id: 'demo', shop_id: 'demo', category_id: 'cat-6', brand_id: null,
    name: 'Hydrating Face Serum',
    slug: 'face-serum',
    description: 'Deep hydration with hyaluronic acid.',
    price: 1500,
    discount_price: 1200,
    discount_percentage: 20,
    stock_quantity: 150,
    rating: 4.8,
    total_reviews: 320,
    total_sales: 1500,
    is_featured: true,
    is_active: true,
    approval_status: 'approved',
    category: { id: 'cat-6', name: 'Beauty', slug: 'beauty' },
    images: [{ id: '16', product_id: '16', image_url: 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=600&h=600&fit=crop', display_order: 0, is_primary: true }],
  },
  {
    seller_id: 'demo', shop_id: 'demo', category_id: 'cat-6', brand_id: null,
    name: 'Matte Lipstick Collection',
    slug: 'lipstick-set',
    description: 'Long-lasting color. Velvet finish.',
    price: 2500,
    discount_price: null,
    discount_percentage: null,
    stock_quantity: 100,
    rating: 4.7,
    total_reviews: 250,
    total_sales: 900,
    is_featured: false,
    is_active: true,
    approval_status: 'approved',
    category: { id: 'cat-6', name: 'Beauty', slug: 'beauty' },
    images: [{ id: '17', product_id: '17', image_url: 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=600&h=600&fit=crop', display_order: 0, is_primary: true }],
  },
  {
    seller_id: 'demo', shop_id: 'demo', category_id: 'cat-6', brand_id: null,
    name: 'Vitamin C Moisturizer',
    slug: 'moisturizer',
    description: 'Brightens skin tone. Daily protection.',
    price: 1800,
    discount_price: 1500,
    discount_percentage: 17,
    stock_quantity: 80,
    rating: 4.6,
    total_reviews: 180,
    total_sales: 700,
    is_featured: true,
    is_active: true,
    approval_status: 'approved',
    category: { id: 'cat-6', name: 'Beauty', slug: 'beauty' },
    images: [{ id: '18', product_id: '18', image_url: 'https://images.unsplash.com/photo-1608248597279-f99d160bfbc8?w=600&h=600&fit=crop', display_order: 0, is_primary: true }],
  },
  {
    seller_id: 'demo', shop_id: 'demo', category_id: 'cat-6', brand_id: null,
    name: 'Organic Hair Shampoo',
    slug: 'shampoo',
    description: 'Sulfate-free. Natural ingredients.',
    price: 900,
    discount_price: null,
    discount_percentage: null,
    stock_quantity: 200,
    rating: 4.5,
    total_reviews: 150,
    total_sales: 600,
    is_featured: false,
    is_active: true,
    approval_status: 'approved',
    category: { id: 'cat-6', name: 'Beauty', slug: 'beauty' },
    images: [{ id: '19', product_id: '19', image_url: 'https://images.unsplash.com/photo-1631729371254-42c2892f0e6e?w=600&h=600&fit=crop', display_order: 0, is_primary: true }],
  },
  {
    seller_id: 'demo', shop_id: 'demo', category_id: 'cat-6', brand_id: null,
    name: 'Luxury Perfume Gift Set',
    slug: 'perfume-set',
    description: 'Elegant fragrances. Perfect gift.',
    price: 5500,
    discount_price: 4999,
    discount_percentage: 9,
    stock_quantity: 40,
    rating: 4.9,
    total_reviews: 90,
    total_sales: 350,
    is_featured: true,
    is_active: true,
    approval_status: 'approved',
    category: { id: 'cat-6', name: 'Beauty', slug: 'beauty' },
    images: [{ id: '20', product_id: '20', image_url: 'https://images.unsplash.com/photo-1594035910387-fea4779426e9?w=600&h=600&fit=crop', display_order: 0, is_primary: true }],
  },
];

export const ProductList: React.FC<ProductListProps> = ({
  filters = {},
  featured = false,
  limit,
}) => {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [useDemoMode, setUseDemoMode] = useState(false);

  useEffect(() => {
    loadProducts();
  }, [filters, page, featured]);

  const loadProducts = async () => {
    setLoading(true);
    setError(null);

    try {
      if (featured) {
        const data = await productService.getFeaturedProducts(limit || 10);
        setProducts(data);
        setUseDemoMode(data.length === 0);
      } else {
        const result = await productService.getProducts(filters, page, limit || 20);
        setProducts(result.data);
        setTotalPages(result.totalPages);
        setUseDemoMode(result.data.length === 0);
      }
    } catch (err) {
      console.error('Error loading products:', err);
      setError('Using demo products - database connection unavailable');
      setUseDemoMode(true);
    } finally {
      setLoading(false);
    }
  };

  // Generate demo products with unique IDs and filter by category
  const getDemoProducts = (): Product[] => {
    let filtered = [...demoProducts];

    // Filter by category if specified
    if (filters?.category) {
      filtered = filtered.filter(p =>
        p.category?.slug === filters.category ||
        p.category?.slug?.includes(filters.category as string) ||
        (filters.category as string).includes(p.category?.slug || '')
      );
    }

    // Filter by search query if specified
    if (filters?.searchQuery) {
      const query = (filters.searchQuery as string).toLowerCase();
      filtered = filtered.filter(p =>
        p.name.toLowerCase().includes(query) ||
        p.description?.toLowerCase().includes(query)
      );
    }

    const count = limit || filtered.length;
    return filtered.slice(0, count).map((p, i) => ({
      ...p,
      id: `demo-${p.slug}-${i}`,
    })) as Product[];
  };

  const displayProducts = useDemoMode || products.length === 0 ? getDemoProducts() : products;

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center py-16">
        <div className="relative">
          <div className="absolute inset-0 rounded-full bg-gradient-to-r from-blue-500 to-purple-600 blur-xl opacity-30 animate-pulse"></div>
          <Loader2 className="relative animate-spin text-blue-600 w-12 h-12" />
        </div>
        <p className="mt-4 text-gray-500 font-medium">Loading products...</p>
      </div>
    );
  }

  return (
    <div>
      {/* Products Grid */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-5">
        {displayProducts.map((product, index) => (
          <div
            key={product.id}
            className="animate-in"
            style={{ animationDelay: `${index * 50}ms` }}
          >
            <ProductCard product={product} />
          </div>
        ))}
      </div>

      {/* Pagination */}
      {!featured && !useDemoMode && totalPages > 1 && (
        <div className="flex justify-center items-center gap-3 mt-10">
          <button
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            disabled={page === 1}
            className="px-5 py-2.5 bg-white border border-gray-200 rounded-xl hover:bg-gray-50 hover:border-gray-300 disabled:opacity-50 disabled:cursor-not-allowed transition-all font-medium text-gray-700"
          >
            Previous
          </button>

          <div className="flex items-center gap-2">
            {Array.from({ length: Math.min(5, totalPages) }).map((_, i) => {
              const pageNum = i + 1;
              return (
                <button
                  key={pageNum}
                  onClick={() => setPage(pageNum)}
                  className={`w-10 h-10 rounded-xl font-semibold transition-all ${page === pageNum
                    ? 'bg-gradient-to-r from-blue-600 to-indigo-600 text-white shadow-lg'
                    : 'bg-white border border-gray-200 text-gray-700 hover:bg-gray-50'
                    }`}
                >
                  {pageNum}
                </button>
              );
            })}
          </div>

          <button
            onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
            disabled={page === totalPages}
            className="px-5 py-2.5 bg-white border border-gray-200 rounded-xl hover:bg-gray-50 hover:border-gray-300 disabled:opacity-50 disabled:cursor-not-allowed transition-all font-medium text-gray-700"
          >
            Next
          </button>
        </div>
      )}
    </div>
  );
};
