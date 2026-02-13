import { supabase } from '../lib/supabase';
import { Product, ProductFilters, PaginatedResponse, Category, Brand } from '../types';

export const productService = {
  // Get all products with filters and pagination
  async getProducts(
    filters: ProductFilters = {},
    page: number = 1,
    limit: number = 20
  ): Promise<PaginatedResponse<Product>> {
    let query = supabase
      .from('products')
      .select('*, product_images(*), categories(*), brands(*), shops(*)', { count: 'exact' })
      .eq('is_active', true)
      .eq('approval_status', 'approved');

    // Apply filters
    if (filters.categoryId) {
      query = query.eq('category_id', filters.categoryId);
    }
    if (filters.brandId) {
      query = query.eq('brand_id', filters.brandId);
    }
    if (filters.minPrice !== undefined) {
      query = query.gte('price', filters.minPrice);
    }
    if (filters.maxPrice !== undefined) {
      query = query.lte('price', filters.maxPrice);
    }
    if (filters.rating !== undefined) {
      query = query.gte('rating', filters.rating);
    }
    if (filters.searchQuery) {
      query = query.ilike('name', `%${filters.searchQuery}%`);
    }

    // Apply sorting
    switch (filters.sortBy) {
      case 'price_asc':
        query = query.order('price', { ascending: true });
        break;
      case 'price_desc':
        query = query.order('price', { ascending: false });
        break;
      case 'rating':
        query = query.order('rating', { ascending: false });
        break;
      case 'newest':
        query = query.order('created_at', { ascending: false });
        break;
      case 'popular':
        query = query.order('total_sales', { ascending: false });
        break;
      default:
        query = query.order('created_at', { ascending: false });
    }

    // Apply pagination
    const from = (page - 1) * limit;
    const to = from + limit - 1;
    query = query.range(from, to);

    const { data, error, count } = await query;

    if (error) throw error;

    return {
      data: (data || []).map((p: any) => ({
        ...p,
        images: p.product_images || [],
        category: p.categories,
        brand: p.brands,
        shop: p.shops,
      })),
      total: count || 0,
      page,
      limit,
      totalPages: Math.ceil((count || 0) / limit),
    };
  },

  // Get single product by ID or slug
  async getProduct(idOrSlug: string): Promise<Product | null> {
    const isUUID = idOrSlug.match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);

    const query = supabase
      .from('products')
      .select('*, product_images(*), product_variants(*), categories(*), brands(*), shops(*)')
      .eq('is_active', true)
      .eq('approval_status', 'approved');

    const { data, error } = await (isUUID
      ? query.eq('id', idOrSlug).single()
      : query.eq('slug', idOrSlug).single());

    if (error) throw error;

    return data
      ? {
          ...data,
          images: data.product_images || [],
          variants: data.product_variants || [],
          category: data.categories,
          brand: data.brands,
          shop: data.shops,
        }
      : null;
  },

  // Get featured products
  async getFeaturedProducts(limit: number = 10): Promise<Product[]> {
    const { data, error } = await supabase
      .from('products')
      .select('*, product_images(*), categories(*), brands(*)')
      .eq('is_active', true)
      .eq('is_featured', true)
      .eq('approval_status', 'approved')
      .order('total_sales', { ascending: false })
      .limit(limit);

    if (error) throw error;

    return (data || []).map((p: any) => ({
      ...p,
      images: p.product_images || [],
      category: p.categories,
      brand: p.brands,
    }));
  },

  // Get categories
  async getCategories(): Promise<Category[]> {
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .eq('is_active', true)
      .is('parent_id', null)
      .order('display_order');

    if (error) throw error;

    // Get subcategories for each category
    const categoriesWithSubs = await Promise.all(
      (data || []).map(async (cat) => {
        const { data: subs } = await supabase
          .from('categories')
          .select('*')
          .eq('parent_id', cat.id)
          .eq('is_active', true)
          .order('display_order');

        return { ...cat, subcategories: subs || [] };
      })
    );

    return categoriesWithSubs;
  },

  // Get brands
  async getBrands(): Promise<Brand[]> {
    const { data, error } = await supabase
      .from('brands')
      .select('*')
      .eq('is_active', true)
      .order('name');

    if (error) throw error;
    return data || [];
  },

  // Get product reviews
  async getProductReviews(productId: string) {
    const { data, error } = await supabase
      .from('reviews')
      .select('*, profiles(*)')
      .eq('product_id', productId)
      .order('created_at', { ascending: false });

    if (error) throw error;

    return (data || []).map((r: any) => ({
      ...r,
      user: r.profiles,
    }));
  },

  // Add product review
  async addReview(
    productId: string,
    userId: string,
    rating: number,
    title: string,
    comment: string,
    imageUrls?: string[]
  ) {
    const { data, error } = await supabase
      .from('reviews')
      .insert({
        product_id: productId,
        user_id: userId,
        rating,
        title,
        comment,
        image_urls: imageUrls || null,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  },
};
