export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string;
          email: string;
          role: 'admin' | 'seller' | 'user';
          full_name: string | null;
          phone: string | null;
          avatar_url: string | null;
          is_verified: boolean;
          is_blocked: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['profiles']['Row'], 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['profiles']['Insert']>;
      };
      user_addresses: {
        Row: {
          id: string;
          user_id: string;
          label: string;
          full_name: string;
          phone: string;
          address_line1: string;
          address_line2: string | null;
          city: string;
          state: string;
          postal_code: string;
          country: string;
          is_default: boolean;
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['user_addresses']['Row'], 'id' | 'created_at'>;
        Update: Partial<Database['public']['Tables']['user_addresses']['Insert']>;
      };
      seller_profiles: {
        Row: {
          id: string;
          user_id: string;
          business_name: string;
          business_type: string | null;
          commission_rate: number;
          total_earnings: number;
          available_balance: number;
          status: 'pending' | 'approved' | 'suspended' | 'rejected';
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['seller_profiles']['Row'], 'id' | 'created_at'>;
        Update: Partial<Database['public']['Tables']['seller_profiles']['Insert']>;
      };
      shops: {
        Row: {
          id: string;
          seller_id: string;
          name: string;
          slug: string;
          description: string | null;
          logo_url: string | null;
          banner_url: string | null;
          address: string | null;
          rating: number;
          total_products: number;
          total_orders: number;
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['shops']['Row'], 'id' | 'created_at' | 'rating' | 'total_products' | 'total_orders'>;
        Update: Partial<Database['public']['Tables']['shops']['Insert']>;
      };
      categories: {
        Row: {
          id: string;
          name: string;
          slug: string;
          parent_id: string | null;
          icon_url: string | null;
          image_url: string | null;
          display_order: number;
          is_active: boolean;
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['categories']['Row'], 'id' | 'created_at'>;
        Update: Partial<Database['public']['Tables']['categories']['Insert']>;
      };
      brands: {
        Row: {
          id: string;
          name: string;
          slug: string;
          logo_url: string | null;
          is_active: boolean;
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['brands']['Row'], 'id' | 'created_at'>;
        Update: Partial<Database['public']['Tables']['brands']['Insert']>;
      };
      products: {
        Row: {
          id: string;
          seller_id: string;
          shop_id: string;
          category_id: string;
          brand_id: string | null;
          name: string;
          slug: string;
          description: string | null;
          price: number;
          discount_price: number | null;
          discount_percentage: number | null;
          stock_quantity: number;
          sku: string | null;
          weight: number | null;
          dimensions: string | null;
          video_url: string | null;
          rating: number;
          total_reviews: number;
          total_sales: number;
          is_featured: boolean;
          is_active: boolean;
          approval_status: 'pending' | 'approved' | 'rejected';
          rejection_reason: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['products']['Row'], 'id' | 'created_at' | 'updated_at' | 'rating' | 'total_reviews' | 'total_sales'>;
        Update: Partial<Database['public']['Tables']['products']['Insert']>;
      };
      product_images: {
        Row: {
          id: string;
          product_id: string;
          image_url: string;
          display_order: number;
          is_primary: boolean;
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['product_images']['Row'], 'id' | 'created_at'>;
        Update: Partial<Database['public']['Tables']['product_images']['Insert']>;
      };
      product_variants: {
        Row: {
          id: string;
          product_id: string;
          variant_type: string;
          variant_value: string;
          price_modifier: number;
          stock_quantity: number;
          sku: string | null;
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['product_variants']['Row'], 'id' | 'created_at'>;
        Update: Partial<Database['public']['Tables']['product_variants']['Insert']>;
      };
      reviews: {
        Row: {
          id: string;
          product_id: string;
          user_id: string;
          order_id: string | null;
          rating: number;
          title: string | null;
          comment: string | null;
          image_urls: string[] | null;
          is_verified_purchase: boolean;
          helpful_count: number;
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['reviews']['Row'], 'id' | 'created_at' | 'helpful_count'>;
        Update: Partial<Database['public']['Tables']['reviews']['Insert']>;
      };
      wishlists: {
        Row: {
          id: string;
          user_id: string;
          product_id: string;
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['wishlists']['Row'], 'id' | 'created_at'>;
        Update: Partial<Database['public']['Tables']['wishlists']['Insert']>;
      };
      cart_items: {
        Row: {
          id: string;
          user_id: string;
          product_id: string;
          variant_id: string | null;
          quantity: number;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['cart_items']['Row'], 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['cart_items']['Insert']>;
      };
      coupons: {
        Row: {
          id: string;
          code: string;
          description: string | null;
          discount_type: 'percentage' | 'fixed';
          discount_value: number;
          min_purchase_amount: number;
          max_discount_amount: number | null;
          usage_limit: number | null;
          used_count: number;
          valid_from: string;
          valid_until: string | null;
          is_active: boolean;
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['coupons']['Row'], 'id' | 'created_at' | 'used_count'>;
        Update: Partial<Database['public']['Tables']['coupons']['Insert']>;
      };
      orders: {
        Row: {
          id: string;
          order_number: string;
          user_id: string;
          delivery_full_name: string;
          delivery_phone: string;
          delivery_address_line1: string;
          delivery_address_line2: string | null;
          delivery_city: string;
          delivery_state: string;
          delivery_postal_code: string;
          delivery_country: string;
          subtotal: number;
          discount_amount: number;
          coupon_code: string | null;
          shipping_charge: number;
          tax_amount: number;
          total_amount: number;
          payment_method: string;
          payment_status: 'pending' | 'paid' | 'failed' | 'refunded';
          stripe_payment_intent_id: string | null;
          stripe_charge_id: string | null;
          order_status: 'pending' | 'confirmed' | 'processing' | 'shipped' | 'delivered' | 'cancelled' | 'returned';
          tracking_number: string | null;
          courier_name: string | null;
          estimated_delivery: string | null;
          delivered_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['orders']['Row'], 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['orders']['Insert']>;
      };
      order_items: {
        Row: {
          id: string;
          order_id: string;
          product_id: string;
          seller_id: string;
          shop_id: string;
          variant_id: string | null;
          product_name: string;
          product_image_url: string | null;
          variant_details: string | null;
          quantity: number;
          unit_price: number;
          total_price: number;
          commission_rate: number;
          commission_amount: number;
          seller_earnings: number;
          item_status: 'pending' | 'confirmed' | 'processing' | 'shipped' | 'delivered' | 'cancelled' | 'returned';
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['order_items']['Row'], 'id' | 'created_at'>;
        Update: Partial<Database['public']['Tables']['order_items']['Insert']>;
      };
      notifications: {
        Row: {
          id: string;
          user_id: string;
          type: string;
          title: string;
          message: string;
          link: string | null;
          is_read: boolean;
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['notifications']['Row'], 'id' | 'created_at'>;
        Update: Partial<Database['public']['Tables']['notifications']['Insert']>;
      };
      cms_banners: {
        Row: {
          id: string;
          title: string;
          image_url: string;
          link: string | null;
          position: string;
          display_order: number;
          is_active: boolean;
          valid_from: string;
          valid_until: string | null;
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['cms_banners']['Row'], 'id' | 'created_at'>;
        Update: Partial<Database['public']['Tables']['cms_banners']['Insert']>;
      };
      cms_pages: {
        Row: {
          id: string;
          slug: string;
          title: string;
          content: string;
          meta_description: string | null;
          is_published: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['cms_pages']['Row'], 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['cms_pages']['Insert']>;
      };
    };
  };
}
