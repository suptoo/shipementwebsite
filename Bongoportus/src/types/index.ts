export interface User {
  id: string;
  email: string;
  role: 'admin' | 'seller' | 'user';
  full_name: string | null;
  phone: string | null;
  avatar_url: string | null;
  is_verified: boolean;
  is_blocked: boolean;
}

export interface Product {
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
  rating: number;
  total_reviews: number;
  total_sales: number;
  is_featured: boolean;
  is_active: boolean;
  approval_status: 'pending' | 'approved' | 'rejected';
  images?: ProductImage[];
  variants?: ProductVariant[];
  category?: Category;
  brand?: Brand;
  shop?: Shop;
}

export interface ProductImage {
  id: string;
  product_id: string;
  image_url: string;
  display_order: number;
  is_primary: boolean;
}

export interface ProductVariant {
  id: string;
  product_id: string;
  variant_type: string;
  variant_value: string;
  price_modifier: number;
  stock_quantity: number;
  sku: string | null;
}

export interface Category {
  id: string;
  name: string;
  slug: string;
  parent_id: string | null;
  icon_url: string | null;
  image_url: string | null;
  display_order: number;
  is_active: boolean;
  subcategories?: Category[];
}

export interface Brand {
  id: string;
  name: string;
  slug: string;
  logo_url: string | null;
  is_active: boolean;
}

export interface Shop {
  id: string;
  seller_id: string;
  name: string;
  slug: string;
  description: string | null;
  logo_url: string | null;
  banner_url: string | null;
  rating: number;
  total_products: number;
  total_orders: number;
}

export interface CartItem {
  id: string;
  user_id: string;
  product_id: string;
  variant_id: string | null;
  quantity: number;
  product?: Product;
  variant?: ProductVariant;
}

export interface Order {
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
  order_status: 'pending' | 'confirmed' | 'processing' | 'shipped' | 'delivered' | 'cancelled' | 'returned';
  tracking_number: string | null;
  courier_name: string | null;
  created_at: string;
  items?: OrderItem[];
}

export interface OrderItem {
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
}

export interface Review {
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
  user?: User;
}

export interface Address {
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
}

export interface Coupon {
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
}

export interface SellerProfile {
  id: string;
  user_id: string;
  business_name: string;
  business_type: string | null;
  commission_rate: number;
  total_earnings: number;
  available_balance: number;
  status: 'pending' | 'approved' | 'suspended' | 'rejected';
  created_at: string;
  shop?: Shop;
}

export interface Notification {
  id: string;
  user_id: string;
  type: string;
  title: string;
  message: string;
  link: string | null;
  is_read: boolean;
  created_at: string;
}

export interface Banner {
  id: string;
  title: string;
  image_url: string;
  link: string | null;
  position: string;
  display_order: number;
  is_active: boolean;
}

// Messaging Types
export interface Conversation {
  id: string;
  type: 'buyer_seller' | 'buyer_admin' | 'seller_admin';
  buyer_id: string | null;
  seller_id: string | null;
  product_id: string | null;
  order_id: string | null;
  subject: string | null;
  status: 'active' | 'closed' | 'archived';
  last_message_at: string;
  created_at: string;
  buyer?: User;
  seller?: SellerProfile;
  product?: Product;
  order?: Order;
  unread_count?: number;
}

export interface Message {
  id: string;
  conversation_id: string;
  sender_id: string;
  sender_type: 'buyer' | 'seller' | 'admin';
  content: string;
  attachment_url: string | null;
  image_url?: string | null;
  inquiry_id?: string;
  is_read: boolean;
  created_at: string;
  sender?: User;
}

export interface SupportTicket {
  id: string;
  user_id: string;
  category: 'order_issue' | 'payment_issue' | 'product_issue' | 'account_issue' | 'technical_issue' | 'other';
  subject: string;
  description: string;
  status: 'open' | 'in_progress' | 'resolved' | 'closed';
  priority: 'low' | 'medium' | 'high' | 'urgent';
  assigned_to: string | null;
  created_at: string;
  updated_at: string;
  resolved_at: string | null;
  user?: User;
  assigned_admin?: User;
}

export interface TicketMessage {
  id: string;
  ticket_id: string;
  sender_id: string;
  content: string;
  attachment_url: string | null;
  is_internal: boolean;
  created_at: string;
  sender?: User;
}

// Filter & Search Types
export interface ProductFilters {
  categoryId?: string;
  category?: string; // Category slug for filtering
  brandId?: string;
  minPrice?: number;
  maxPrice?: number;
  rating?: number;
  searchQuery?: string;
  sortBy?: 'price_asc' | 'price_desc' | 'rating' | 'newest' | 'popular';
}

export interface PaginationParams {
  page: number;
  limit: number;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

// Profile for AuthContext
export interface Profile {
  id: string;
  email: string;
  full_name: string | null;
  phone: string | null;
  avatar_url: string | null;
  role: 'admin' | 'seller' | 'user';
  is_verified: boolean;
  is_blocked: boolean;
  created_at: string;
}

// Inquiry types for admin dashboard
export interface Inquiry {
  id: string;
  user_id: string;
  product_id?: string;
  message: string;
  survey_amount: string;
  survey_address: string;
  survey_days: number;
  status: 'open' | 'closed';
  created_at: string;
}

export interface InquiryWithProfile extends Inquiry {
  profiles: {
    email: string;
    full_name: string | null;
  };
}
