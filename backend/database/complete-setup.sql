-- =====================================================
-- BongoPortus - Complete Database Setup (Fully Idempotent)
-- Columns aligned with frontend types & Edge Functions
-- Safe to run multiple times in Supabase SQL Editor
-- =====================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLES
-- =====================================================

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  phone TEXT,
  role TEXT DEFAULT 'customer' CHECK (role IN ('customer', 'seller', 'admin')),
  is_verified BOOLEAN DEFAULT false,
  is_blocked BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_addresses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  address_line1 TEXT NOT NULL,
  address_line2 TEXT,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  postal_code TEXT NOT NULL,
  country TEXT DEFAULT 'Bangladesh',
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS seller_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  business_name TEXT NOT NULL,
  business_type TEXT CHECK (business_type IN ('Individual', 'Company', 'Marketplace')),
  business_address TEXT,
  tax_id TEXT,
  bank_account_name TEXT,
  bank_account_number TEXT,
  bank_name TEXT,
  bank_routing_number TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'suspended')),
  commission_rate DECIMAL(5, 2) DEFAULT 10.00,
  available_balance DECIMAL(10, 2) DEFAULT 0,
  total_earnings DECIMAL(10, 2) DEFAULT 0,
  total_products INTEGER DEFAULT 0,
  rating DECIMAL(3, 2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS shops (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  seller_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  description TEXT,
  logo_url TEXT,
  banner_url TEXT,
  rating DECIMAL(3, 2) DEFAULT 0,
  total_products INTEGER DEFAULT 0,
  total_orders INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  description TEXT,
  icon_url TEXT,
  image_url TEXT,
  parent_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS brands (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  description TEXT,
  logo_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  seller_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  shop_id UUID REFERENCES shops(id) ON DELETE SET NULL,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  brand_id UUID REFERENCES brands(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,
  discount_price DECIMAL(10, 2),
  discount_percentage INTEGER,
  stock_quantity INTEGER DEFAULT 0,
  sku TEXT,
  weight DECIMAL(10, 2),
  dimensions TEXT,
  is_featured BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  approval_status TEXT DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  rejection_reason TEXT,
  views INTEGER DEFAULT 0,
  rating DECIMAL(3, 2) DEFAULT 0,
  total_reviews INTEGER DEFAULT 0,
  total_sales INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS product_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  display_order INTEGER DEFAULT 0,
  is_primary BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS product_variants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  variant_type TEXT NOT NULL,
  variant_value TEXT NOT NULL,
  price_adjustment DECIMAL(10, 2) DEFAULT 0,
  stock_quantity INTEGER DEFAULT 0,
  sku TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS cart_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  variant_id UUID REFERENCES product_variants(id) ON DELETE SET NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, product_id, variant_id)
);

CREATE TABLE IF NOT EXISTS coupons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT UNIQUE NOT NULL,
  description TEXT,
  discount_type TEXT CHECK (discount_type IN ('percentage', 'fixed')),
  discount_value DECIMAL(10, 2) NOT NULL,
  min_purchase_amount DECIMAL(10, 2) DEFAULT 0,
  max_discount_amount DECIMAL(10, 2),
  usage_limit INTEGER,
  used_count INTEGER DEFAULT 0,
  valid_from TIMESTAMPTZ DEFAULT NOW(),
  valid_until TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Orders: columns match Edge Function create-order + frontend Order type
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  order_number TEXT UNIQUE NOT NULL,
  order_status TEXT DEFAULT 'pending' CHECK (order_status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'returned', 'refunded')),
  payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
  payment_method TEXT,
  delivery_full_name TEXT,
  delivery_phone TEXT,
  delivery_address_line1 TEXT,
  delivery_address_line2 TEXT,
  delivery_city TEXT,
  delivery_state TEXT,
  delivery_postal_code TEXT,
  delivery_country TEXT DEFAULT 'Bangladesh',
  subtotal DECIMAL(10, 2) NOT NULL,
  discount_amount DECIMAL(10, 2) DEFAULT 0,
  coupon_code TEXT,
  shipping_charge DECIMAL(10, 2) DEFAULT 0,
  tax_amount DECIMAL(10, 2) DEFAULT 0,
  total_amount DECIMAL(10, 2) NOT NULL,
  stripe_payment_intent_id TEXT,
  tracking_number TEXT,
  courier_name TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Order items: columns match Edge Function create-order + frontend OrderItem type
CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  variant_id UUID REFERENCES product_variants(id),
  seller_id UUID NOT NULL REFERENCES profiles(id),
  shop_id UUID REFERENCES shops(id),
  product_name TEXT,
  product_image_url TEXT,
  variant_details TEXT,
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(10, 2) NOT NULL,
  total_price DECIMAL(10, 2) NOT NULL,
  commission_rate DECIMAL(5, 2) DEFAULT 0,
  commission_amount DECIMAL(10, 2) DEFAULT 0,
  seller_earnings DECIMAL(10, 2) DEFAULT 0,
  item_status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  title TEXT,
  comment TEXT,
  image_urls TEXT[],
  is_verified_purchase BOOLEAN DEFAULT false,
  helpful_count INTEGER DEFAULT 0,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Conversations: columns match frontend Conversation type + messagingService
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type TEXT DEFAULT 'buyer_seller' CHECK (type IN ('buyer_seller', 'buyer_admin', 'seller_admin')),
  buyer_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  seller_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE SET NULL,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  subject TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'closed', 'archived')),
  last_message TEXT,
  last_message_at TIMESTAMPTZ,
  unread_count_buyer INTEGER DEFAULT 0,
  unread_count_seller INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Messages: columns match frontend Message type + messagingService
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  sender_type TEXT DEFAULT 'buyer' CHECK (sender_type IN ('buyer', 'seller', 'admin')),
  content TEXT NOT NULL,
  attachment_url TEXT,
  image_url TEXT,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS inquiries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  product_id UUID REFERENCES products(id) ON DELETE SET NULL,
  subject TEXT NOT NULL,
  message TEXT,
  survey_amount TEXT,
  survey_address TEXT,
  survey_days INTEGER,
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS inquiry_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  inquiry_id UUID NOT NULL REFERENCES inquiries(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  is_staff BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Support tickets: columns match frontend SupportTicket type + supportService
CREATE TABLE IF NOT EXISTS support_tickets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  category TEXT DEFAULT 'other',
  subject TEXT NOT NULL,
  description TEXT NOT NULL,
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  assigned_to UUID REFERENCES profiles(id),
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ticket messages: columns match frontend TicketMessage type + supportService
CREATE TABLE IF NOT EXISTS ticket_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  attachment_url TEXT,
  is_internal BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL,
  link TEXT,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS banners (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  image_url TEXT NOT NULL,
  link TEXT,
  position TEXT DEFAULT 'home',
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payment_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  amount DECIMAL(10, 2) NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'paid')),
  payment_method TEXT,
  transaction_id TEXT,
  admin_id UUID REFERENCES profiles(id),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- ADD MISSING COLUMNS (safe for re-runs on existing tables)
-- =====================================================
DO $$ BEGIN
  -- profiles
  ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_blocked BOOLEAN DEFAULT false;
  -- shops
  ALTER TABLE shops ADD COLUMN IF NOT EXISTS rating DECIMAL(3,2) DEFAULT 0;
  ALTER TABLE shops ADD COLUMN IF NOT EXISTS total_products INTEGER DEFAULT 0;
  ALTER TABLE shops ADD COLUMN IF NOT EXISTS total_orders INTEGER DEFAULT 0;
  -- categories
  ALTER TABLE categories ADD COLUMN IF NOT EXISTS icon_url TEXT;
  -- products
  ALTER TABLE products ADD COLUMN IF NOT EXISTS total_sales INTEGER DEFAULT 0;
  -- orders (if table was created with old schema)
  ALTER TABLE orders ADD COLUMN IF NOT EXISTS order_status TEXT DEFAULT 'pending';
  ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_full_name TEXT;
  ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_phone TEXT;
  ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_address_line1 TEXT;
  ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_address_line2 TEXT;
  ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_city TEXT;
  ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_state TEXT;
  ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_postal_code TEXT;
  ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_country TEXT DEFAULT 'Bangladesh';
  ALTER TABLE orders ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(10,2) DEFAULT 0;
  ALTER TABLE orders ADD COLUMN IF NOT EXISTS coupon_code TEXT;
  ALTER TABLE orders ADD COLUMN IF NOT EXISTS shipping_charge DECIMAL(10,2) DEFAULT 0;
  ALTER TABLE orders ADD COLUMN IF NOT EXISTS tax_amount DECIMAL(10,2) DEFAULT 0;
  ALTER TABLE orders ADD COLUMN IF NOT EXISTS stripe_payment_intent_id TEXT;
  ALTER TABLE orders ADD COLUMN IF NOT EXISTS courier_name TEXT;
  -- order_items
  ALTER TABLE order_items ADD COLUMN IF NOT EXISTS shop_id UUID;
  ALTER TABLE order_items ADD COLUMN IF NOT EXISTS product_name TEXT;
  ALTER TABLE order_items ADD COLUMN IF NOT EXISTS product_image_url TEXT;
  ALTER TABLE order_items ADD COLUMN IF NOT EXISTS variant_details TEXT;
  ALTER TABLE order_items ADD COLUMN IF NOT EXISTS unit_price DECIMAL(10,2);
  ALTER TABLE order_items ADD COLUMN IF NOT EXISTS total_price DECIMAL(10,2);
  ALTER TABLE order_items ADD COLUMN IF NOT EXISTS commission_rate DECIMAL(5,2) DEFAULT 0;
  ALTER TABLE order_items ADD COLUMN IF NOT EXISTS commission_amount DECIMAL(10,2) DEFAULT 0;
  ALTER TABLE order_items ADD COLUMN IF NOT EXISTS seller_earnings DECIMAL(10,2) DEFAULT 0;
  ALTER TABLE order_items ADD COLUMN IF NOT EXISTS item_status TEXT DEFAULT 'pending';
  -- reviews
  ALTER TABLE reviews ADD COLUMN IF NOT EXISTS image_urls TEXT[];
  -- conversations
  ALTER TABLE conversations ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'buyer_seller';
  ALTER TABLE conversations ADD COLUMN IF NOT EXISTS order_id UUID;
  ALTER TABLE conversations ADD COLUMN IF NOT EXISTS subject TEXT;
  ALTER TABLE conversations ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active';
  -- messages
  ALTER TABLE messages ADD COLUMN IF NOT EXISTS sender_type TEXT DEFAULT 'buyer';
  ALTER TABLE messages ADD COLUMN IF NOT EXISTS attachment_url TEXT;
  ALTER TABLE messages ADD COLUMN IF NOT EXISTS image_url TEXT;
  -- support_tickets
  ALTER TABLE support_tickets ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'other';
  ALTER TABLE support_tickets ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMPTZ;
  -- ticket_messages
  ALTER TABLE ticket_messages ADD COLUMN IF NOT EXISTS content TEXT;
  ALTER TABLE ticket_messages ADD COLUMN IF NOT EXISTS attachment_url TEXT;
  ALTER TABLE ticket_messages ADD COLUMN IF NOT EXISTS is_internal BOOLEAN DEFAULT false;
  -- seller_profiles (rename old columns if they exist)
  ALTER TABLE seller_profiles ADD COLUMN IF NOT EXISTS available_balance DECIMAL(10,2) DEFAULT 0;
  ALTER TABLE seller_profiles ADD COLUMN IF NOT EXISTS total_earnings DECIMAL(10,2) DEFAULT 0;
  -- banners
  ALTER TABLE banners ADD COLUMN IF NOT EXISTS position TEXT DEFAULT 'home';
END $$;

-- =====================================================
-- FUNCTIONS (CASCADE drops dependent policies + triggers)
-- =====================================================

DROP FUNCTION IF EXISTS is_admin() CASCADE;
CREATE FUNCTION is_admin() RETURNS BOOLEAN AS $$
  SELECT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin');
$$ LANGUAGE sql SECURITY DEFINER;

DROP FUNCTION IF EXISTS is_seller() CASCADE;
CREATE FUNCTION is_seller() RETURNS BOOLEAN AS $$
  SELECT EXISTS (SELECT 1 FROM seller_profiles WHERE user_id = auth.uid() AND status = 'approved');
$$ LANGUAGE sql SECURITY DEFINER;

DROP FUNCTION IF EXISTS owns_product(UUID) CASCADE;
CREATE FUNCTION owns_product(product_id UUID) RETURNS BOOLEAN AS $$
  SELECT EXISTS (SELECT 1 FROM products WHERE id = product_id AND seller_id = auth.uid());
$$ LANGUAGE sql SECURITY DEFINER;

DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
CREATE FUNCTION handle_new_user() RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email, full_name, avatar_url)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'avatar_url');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
CREATE FUNCTION update_updated_at_column() RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS decrement_stock() CASCADE;
CREATE FUNCTION decrement_stock() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.variant_id IS NOT NULL THEN
    UPDATE product_variants SET stock_quantity = stock_quantity - NEW.quantity WHERE id = NEW.variant_id;
  ELSE
    UPDATE products SET stock_quantity = stock_quantity - NEW.quantity WHERE id = NEW.product_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP FUNCTION IF EXISTS increment_stock() CASCADE;
CREATE FUNCTION increment_stock() RETURNS TRIGGER AS $$
BEGIN
  IF OLD.order_status != 'cancelled' AND NEW.order_status = 'cancelled' THEN
    UPDATE products p SET stock_quantity = p.stock_quantity + oi.quantity
    FROM order_items oi WHERE oi.order_id = NEW.id AND oi.product_id = p.id AND oi.variant_id IS NULL;
    
    UPDATE product_variants pv SET stock_quantity = pv.stock_quantity + oi.quantity
    FROM order_items oi WHERE oi.order_id = NEW.id AND oi.variant_id = pv.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP FUNCTION IF EXISTS increment_seller_balance() CASCADE;
CREATE FUNCTION increment_seller_balance() RETURNS TRIGGER AS $$
DECLARE
  v_commission_rate DECIMAL(5,2);
  v_seller_amount DECIMAL(10,2);
  v_seller_id UUID;
BEGIN
  IF OLD.order_status != 'delivered' AND NEW.order_status = 'delivered' THEN
    SELECT oi.seller_id INTO v_seller_id FROM order_items oi WHERE oi.order_id = NEW.id LIMIT 1;
    SELECT COALESCE(sp.commission_rate, 10) INTO v_commission_rate FROM seller_profiles sp WHERE sp.user_id = v_seller_id;
    v_seller_amount := NEW.total_amount * (1 - COALESCE(v_commission_rate, 10) / 100);
    UPDATE seller_profiles SET available_balance = available_balance + v_seller_amount, total_earnings = total_earnings + v_seller_amount WHERE user_id = v_seller_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- ENABLE ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE seller_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE inquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE inquiry_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_requests ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- RLS POLICIES (DROP IF EXISTS + CREATE)
-- =====================================================

-- PROFILES
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;
CREATE POLICY "Profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
DROP POLICY IF EXISTS "Admins can update any profile" ON profiles;
CREATE POLICY "Admins can update any profile" ON profiles FOR UPDATE USING (is_admin());

-- USER ADDRESSES
DROP POLICY IF EXISTS "Users can view own addresses" ON user_addresses;
CREATE POLICY "Users can view own addresses" ON user_addresses FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own addresses" ON user_addresses;
CREATE POLICY "Users can insert own addresses" ON user_addresses FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own addresses" ON user_addresses;
CREATE POLICY "Users can update own addresses" ON user_addresses FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete own addresses" ON user_addresses;
CREATE POLICY "Users can delete own addresses" ON user_addresses FOR DELETE USING (auth.uid() = user_id);

-- SELLER PROFILES
DROP POLICY IF EXISTS "Seller profiles are viewable by everyone" ON seller_profiles;
CREATE POLICY "Seller profiles are viewable by everyone" ON seller_profiles FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can create seller profile" ON seller_profiles;
CREATE POLICY "Users can create seller profile" ON seller_profiles FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Sellers can update own profile" ON seller_profiles;
CREATE POLICY "Sellers can update own profile" ON seller_profiles FOR UPDATE USING (auth.uid() = user_id OR is_admin());

-- SHOPS
DROP POLICY IF EXISTS "Shops are viewable by everyone" ON shops;
CREATE POLICY "Shops are viewable by everyone" ON shops FOR SELECT USING (true);
DROP POLICY IF EXISTS "Sellers can create shops" ON shops;
CREATE POLICY "Sellers can create shops" ON shops FOR INSERT WITH CHECK (auth.uid() = seller_id);
DROP POLICY IF EXISTS "Sellers can update own shops" ON shops;
CREATE POLICY "Sellers can update own shops" ON shops FOR UPDATE USING (auth.uid() = seller_id OR is_admin());

-- CATEGORIES
DROP POLICY IF EXISTS "Categories are viewable by everyone" ON categories;
CREATE POLICY "Categories are viewable by everyone" ON categories FOR SELECT USING (true);
DROP POLICY IF EXISTS "Admins can manage categories" ON categories;
CREATE POLICY "Admins can manage categories" ON categories FOR ALL USING (is_admin());

-- BRANDS
DROP POLICY IF EXISTS "Brands are viewable by everyone" ON brands;
CREATE POLICY "Brands are viewable by everyone" ON brands FOR SELECT USING (true);
DROP POLICY IF EXISTS "Admins can manage brands" ON brands;
CREATE POLICY "Admins can manage brands" ON brands FOR ALL USING (is_admin());

-- PRODUCTS
DROP POLICY IF EXISTS "Active products are viewable by everyone" ON products;
CREATE POLICY "Active products are viewable by everyone" ON products FOR SELECT USING (true);
DROP POLICY IF EXISTS "Sellers can insert products" ON products;
CREATE POLICY "Sellers can insert products" ON products FOR INSERT WITH CHECK (auth.uid() = seller_id);
DROP POLICY IF EXISTS "Sellers can update own products" ON products;
CREATE POLICY "Sellers can update own products" ON products FOR UPDATE USING (auth.uid() = seller_id OR is_admin());
DROP POLICY IF EXISTS "Sellers can delete own products" ON products;
CREATE POLICY "Sellers can delete own products" ON products FOR DELETE USING (auth.uid() = seller_id OR is_admin());

-- PRODUCT IMAGES
DROP POLICY IF EXISTS "Product images are viewable by everyone" ON product_images;
CREATE POLICY "Product images are viewable by everyone" ON product_images FOR SELECT USING (true);
DROP POLICY IF EXISTS "Product owners can manage images" ON product_images;
CREATE POLICY "Product owners can manage images" ON product_images FOR ALL USING (
  EXISTS (SELECT 1 FROM products WHERE products.id = product_images.product_id AND products.seller_id = auth.uid()) OR is_admin()
);

-- PRODUCT VARIANTS
DROP POLICY IF EXISTS "Product variants are viewable by everyone" ON product_variants;
CREATE POLICY "Product variants are viewable by everyone" ON product_variants FOR SELECT USING (true);
DROP POLICY IF EXISTS "Product owners can manage variants" ON product_variants;
CREATE POLICY "Product owners can manage variants" ON product_variants FOR ALL USING (
  EXISTS (SELECT 1 FROM products WHERE products.id = product_variants.product_id AND products.seller_id = auth.uid()) OR is_admin()
);

-- CART ITEMS
DROP POLICY IF EXISTS "Users can view own cart" ON cart_items;
CREATE POLICY "Users can view own cart" ON cart_items FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can manage own cart" ON cart_items;
CREATE POLICY "Users can manage own cart" ON cart_items FOR ALL USING (auth.uid() = user_id);

-- COUPONS
DROP POLICY IF EXISTS "Coupons are viewable by everyone" ON coupons;
CREATE POLICY "Coupons are viewable by everyone" ON coupons FOR SELECT USING (true);
DROP POLICY IF EXISTS "Admins can manage coupons" ON coupons;
CREATE POLICY "Admins can manage coupons" ON coupons FOR ALL USING (is_admin());

-- ORDERS
DROP POLICY IF EXISTS "Users can view own orders" ON orders;
CREATE POLICY "Users can view own orders" ON orders FOR SELECT USING (auth.uid() = user_id OR is_admin());
DROP POLICY IF EXISTS "Users can create orders" ON orders;
CREATE POLICY "Users can create orders" ON orders FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users and admins can update orders" ON orders;
CREATE POLICY "Users and admins can update orders" ON orders FOR UPDATE USING (auth.uid() = user_id OR is_admin());

-- ORDER ITEMS
DROP POLICY IF EXISTS "Order items viewable by order owner" ON order_items;
CREATE POLICY "Order items viewable by order owner" ON order_items FOR SELECT USING (
  EXISTS (SELECT 1 FROM orders WHERE orders.id = order_items.order_id AND (orders.user_id = auth.uid() OR auth.uid() = order_items.seller_id)) OR is_admin()
);
DROP POLICY IF EXISTS "System can create order items" ON order_items;
CREATE POLICY "System can create order items" ON order_items FOR INSERT WITH CHECK (true);

-- REVIEWS
DROP POLICY IF EXISTS "Reviews are viewable by everyone" ON reviews;
CREATE POLICY "Reviews are viewable by everyone" ON reviews FOR SELECT USING (status = 'approved');
DROP POLICY IF EXISTS "Users can create reviews" ON reviews;
CREATE POLICY "Users can create reviews" ON reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own reviews" ON reviews;
CREATE POLICY "Users can update own reviews" ON reviews FOR UPDATE USING (auth.uid() = user_id OR is_admin());

-- CONVERSATIONS
DROP POLICY IF EXISTS "Users can view own conversations" ON conversations;
CREATE POLICY "Users can view own conversations" ON conversations FOR SELECT USING (
  auth.uid() = buyer_id OR auth.uid() = seller_id OR is_admin()
);
DROP POLICY IF EXISTS "Users can create conversations" ON conversations;
CREATE POLICY "Users can create conversations" ON conversations FOR INSERT WITH CHECK (
  auth.uid() = buyer_id OR is_admin()
);
DROP POLICY IF EXISTS "Participants can update conversations" ON conversations;
CREATE POLICY "Participants can update conversations" ON conversations FOR UPDATE USING (
  auth.uid() = buyer_id OR auth.uid() = seller_id OR is_admin()
);

-- MESSAGES
DROP POLICY IF EXISTS "Conversation participants can view messages" ON messages;
CREATE POLICY "Conversation participants can view messages" ON messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM conversations c WHERE c.id = messages.conversation_id AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid() OR is_admin()))
);
DROP POLICY IF EXISTS "Users can send messages" ON messages;
CREATE POLICY "Users can send messages" ON messages FOR INSERT WITH CHECK (auth.uid() = sender_id);
DROP POLICY IF EXISTS "Users can update own messages" ON messages;
CREATE POLICY "Users can update own messages" ON messages FOR UPDATE USING (auth.uid() = sender_id OR is_admin());

-- INQUIRIES
DROP POLICY IF EXISTS "Users can view own inquiries" ON inquiries;
CREATE POLICY "Users can view own inquiries" ON inquiries FOR SELECT USING (auth.uid() = user_id OR is_admin());
DROP POLICY IF EXISTS "Users can create inquiries" ON inquiries;
CREATE POLICY "Users can create inquiries" ON inquiries FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users and admins can update inquiries" ON inquiries;
CREATE POLICY "Users and admins can update inquiries" ON inquiries FOR UPDATE USING (auth.uid() = user_id OR is_admin());

-- INQUIRY MESSAGES
DROP POLICY IF EXISTS "Inquiry participants can view messages" ON inquiry_messages;
CREATE POLICY "Inquiry participants can view messages" ON inquiry_messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM inquiries WHERE inquiries.id = inquiry_messages.inquiry_id AND (inquiries.user_id = auth.uid() OR is_admin()))
);
DROP POLICY IF EXISTS "Users can send inquiry messages" ON inquiry_messages;
CREATE POLICY "Users can send inquiry messages" ON inquiry_messages FOR INSERT WITH CHECK (auth.uid() = sender_id);
DROP POLICY IF EXISTS "Users can update own inquiry messages" ON inquiry_messages;
CREATE POLICY "Users can update own inquiry messages" ON inquiry_messages FOR UPDATE USING (auth.uid() = sender_id OR is_admin());

-- SUPPORT TICKETS
DROP POLICY IF EXISTS "Users can view own tickets" ON support_tickets;
CREATE POLICY "Users can view own tickets" ON support_tickets FOR SELECT USING (auth.uid() = user_id OR is_admin());
DROP POLICY IF EXISTS "Users can create tickets" ON support_tickets;
CREATE POLICY "Users can create tickets" ON support_tickets FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Admins can update tickets" ON support_tickets;
CREATE POLICY "Admins can update tickets" ON support_tickets FOR UPDATE USING (is_admin() OR auth.uid() = user_id);

-- TICKET MESSAGES
DROP POLICY IF EXISTS "Ticket participants can view messages" ON ticket_messages;
CREATE POLICY "Ticket participants can view messages" ON ticket_messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM support_tickets WHERE support_tickets.id = ticket_messages.ticket_id AND (support_tickets.user_id = auth.uid() OR is_admin()))
);
DROP POLICY IF EXISTS "Users can send ticket messages" ON ticket_messages;
CREATE POLICY "Users can send ticket messages" ON ticket_messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- NOTIFICATIONS
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "System can create notifications" ON notifications;
CREATE POLICY "System can create notifications" ON notifications FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);

-- BANNERS
DROP POLICY IF EXISTS "Banners are viewable by everyone" ON banners;
CREATE POLICY "Banners are viewable by everyone" ON banners FOR SELECT USING (true);
DROP POLICY IF EXISTS "Admins can manage banners" ON banners;
CREATE POLICY "Admins can manage banners" ON banners FOR ALL USING (is_admin());

-- PAYMENT REQUESTS
DROP POLICY IF EXISTS "Users can view own payment requests" ON payment_requests;
CREATE POLICY "Users can view own payment requests" ON payment_requests FOR SELECT USING (auth.uid() = user_id OR auth.uid() = admin_id OR is_admin());
DROP POLICY IF EXISTS "Admins can create payment requests" ON payment_requests;
CREATE POLICY "Admins can create payment requests" ON payment_requests FOR INSERT WITH CHECK (is_admin());
DROP POLICY IF EXISTS "Payment requests can be updated" ON payment_requests;
CREATE POLICY "Payment requests can be updated" ON payment_requests FOR UPDATE USING (auth.uid() = user_id OR is_admin());

-- =====================================================
-- STORAGE
-- =====================================================

INSERT INTO storage.buckets (id, name, public) VALUES ('product-images', 'product-images', true) ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public product images read" ON storage.objects;
CREATE POLICY "Public product images read" ON storage.objects FOR SELECT USING (bucket_id = 'product-images');

DROP POLICY IF EXISTS "Authenticated users can upload" ON storage.objects;
CREATE POLICY "Authenticated users can upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'product-images' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can update own images" ON storage.objects;
CREATE POLICY "Users can update own images" ON storage.objects FOR UPDATE USING (bucket_id = 'product-images' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Users can delete own images" ON storage.objects;
CREATE POLICY "Users can delete own images" ON storage.objects FOR DELETE USING (bucket_id = 'product-images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- =====================================================
-- TRIGGERS (DROP IF EXISTS + CREATE)
-- =====================================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_addresses_updated_at ON user_addresses;
CREATE TRIGGER update_user_addresses_updated_at BEFORE UPDATE ON user_addresses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_seller_profiles_updated_at ON seller_profiles;
CREATE TRIGGER update_seller_profiles_updated_at BEFORE UPDATE ON seller_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_shops_updated_at ON shops;
CREATE TRIGGER update_shops_updated_at BEFORE UPDATE ON shops
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_categories_updated_at ON categories;
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_brands_updated_at ON brands;
CREATE TRIGGER update_brands_updated_at BEFORE UPDATE ON brands
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_products_updated_at ON products;
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS after_order_item_insert ON order_items;
CREATE TRIGGER after_order_item_insert AFTER INSERT ON order_items
  FOR EACH ROW EXECUTE FUNCTION decrement_stock();

DROP TRIGGER IF EXISTS after_order_cancelled ON orders;
CREATE TRIGGER after_order_cancelled AFTER UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION increment_stock();

DROP TRIGGER IF EXISTS after_order_delivered ON orders;
CREATE TRIGGER after_order_delivered AFTER UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION increment_seller_balance();

-- =====================================================
-- REALTIME
-- =====================================================

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE messages;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE orders;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- =====================================================
-- SEED DATA
-- =====================================================

DO $$
DECLARE
  v_admin_id UUID;
  v_shop_id UUID;
  v_cat_electronics UUID; v_cat_fashion UUID; v_cat_home UUID; v_cat_beauty UUID;
  v_cat_sports UUID; v_cat_books UUID; v_cat_phones UUID; v_cat_laptops UUID;
  v_brand_samsung UUID; v_brand_apple UUID; v_brand_nike UUID;
  v_brand_adidas UUID; v_brand_sony UUID; v_brand_local UUID;
BEGIN
  SELECT id INTO v_admin_id FROM auth.users WHERE email = 'umorfaruksupto@gmail.com';
  IF v_admin_id IS NULL THEN
    RAISE NOTICE 'Admin user not found. Sign up with umorfaruksupto@gmail.com first, then re-run.';
    RETURN;
  END IF;

  UPDATE profiles SET role = 'admin' WHERE id = v_admin_id;

  INSERT INTO seller_profiles (user_id, business_name, business_type, status, commission_rate)
  VALUES (v_admin_id, 'BongoPortus Official Store', 'Marketplace', 'approved', 0)
  ON CONFLICT (user_id) DO UPDATE SET status = 'approved';

  INSERT INTO shops (id, seller_id, name, slug, description)
  VALUES (uuid_generate_v4(), v_admin_id, 'BongoPortus Official', 'bongoportus-official', 'The official BongoPortus marketplace store with curated products')
  ON CONFLICT (slug) DO NOTHING;
  SELECT id INTO v_shop_id FROM shops WHERE seller_id = v_admin_id LIMIT 1;

  INSERT INTO categories (id, name, slug, display_order, is_active) VALUES
    (uuid_generate_v4(), 'Electronics', 'electronics', 1, true),
    (uuid_generate_v4(), 'Fashion', 'fashion', 2, true),
    (uuid_generate_v4(), 'Home & Living', 'home-living', 3, true),
    (uuid_generate_v4(), 'Beauty & Health', 'beauty-health', 4, true),
    (uuid_generate_v4(), 'Sports & Outdoors', 'sports-outdoors', 5, true),
    (uuid_generate_v4(), 'Books & Stationery', 'books-stationery', 6, true),
    (uuid_generate_v4(), 'Smartphones', 'smartphones', 7, true),
    (uuid_generate_v4(), 'Laptops & Computers', 'laptops-computers', 8, true)
  ON CONFLICT (slug) DO NOTHING;

  SELECT id INTO v_cat_electronics FROM categories WHERE slug = 'electronics';
  SELECT id INTO v_cat_fashion FROM categories WHERE slug = 'fashion';
  SELECT id INTO v_cat_home FROM categories WHERE slug = 'home-living';
  SELECT id INTO v_cat_beauty FROM categories WHERE slug = 'beauty-health';
  SELECT id INTO v_cat_sports FROM categories WHERE slug = 'sports-outdoors';
  SELECT id INTO v_cat_books FROM categories WHERE slug = 'books-stationery';
  SELECT id INTO v_cat_phones FROM categories WHERE slug = 'smartphones';
  SELECT id INTO v_cat_laptops FROM categories WHERE slug = 'laptops-computers';

  INSERT INTO brands (id, name, slug, is_active) VALUES
    (uuid_generate_v4(), 'Samsung', 'samsung', true),
    (uuid_generate_v4(), 'Apple', 'apple', true),
    (uuid_generate_v4(), 'Nike', 'nike', true),
    (uuid_generate_v4(), 'Adidas', 'adidas', true),
    (uuid_generate_v4(), 'Sony', 'sony', true),
    (uuid_generate_v4(), 'BongoLocal', 'bongolocal', true)
  ON CONFLICT (slug) DO NOTHING;

  SELECT id INTO v_brand_samsung FROM brands WHERE slug = 'samsung';
  SELECT id INTO v_brand_apple FROM brands WHERE slug = 'apple';
  SELECT id INTO v_brand_nike FROM brands WHERE slug = 'nike';
  SELECT id INTO v_brand_adidas FROM brands WHERE slug = 'adidas';
  SELECT id INTO v_brand_sony FROM brands WHERE slug = 'sony';
  SELECT id INTO v_brand_local FROM brands WHERE slug = 'bongolocal';

  DELETE FROM products WHERE seller_id = v_admin_id AND slug LIKE '%-demo-%';

  INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, discount_price, discount_percentage, stock_quantity, is_featured, is_active, approval_status, rating, total_reviews, total_sales) VALUES
    (v_admin_id, v_shop_id, v_cat_phones, v_brand_samsung, 'Samsung Galaxy S24 Ultra', 'samsung-galaxy-s24-ultra-demo-1', 'The ultimate Galaxy experience with S Pen, 200MP camera, titanium frame, and Galaxy AI. 12GB RAM, 256GB storage.', 134999, 124999, 7, 50, true, true, 'approved', 4.8, 245, 180),
    (v_admin_id, v_shop_id, v_cat_phones, v_brand_apple, 'iPhone 15 Pro Max', 'iphone-15-pro-max-demo-2', 'Forged in titanium with A17 Pro chip, 48MP camera system, Action button, and USB-C. 256GB storage.', 179999, 169999, 6, 35, true, true, 'approved', 4.9, 312, 250),
    (v_admin_id, v_shop_id, v_cat_electronics, v_brand_sony, 'Sony WH-1000XM5 Wireless Headphones', 'sony-wh1000xm5-demo-3', 'Industry-leading noise cancellation with 30-hour battery, multipoint connection.', 34999, 29999, 14, 100, true, true, 'approved', 4.7, 189, 320),
    (v_admin_id, v_shop_id, v_cat_fashion, v_brand_nike, 'Nike Air Max 270 Running Shoes', 'nike-air-max-270-demo-4', 'Featuring the largest Max Air unit yet for a soft comfortable ride. Mesh upper.', 12999, 9999, 23, 200, true, true, 'approved', 4.5, 156, 410),
    (v_admin_id, v_shop_id, v_cat_fashion, v_brand_adidas, 'Adidas Ultraboost Light 23', 'adidas-ultraboost-23-demo-5', 'The lightest Ultraboost ever. BOOST midsole, Primeknit+ upper, Continental rubber outsole.', 14999, 11999, 20, 150, false, true, 'approved', 4.6, 98, 200),
    (v_admin_id, v_shop_id, v_cat_electronics, v_brand_samsung, 'Samsung 55" Crystal UHD 4K Smart TV', 'samsung-55-4k-tv-demo-6', 'Crystal Processor 4K, HDR10+, Smart Hub, AirSlim design. Model: CU7000.', 52999, 44999, 15, 30, true, true, 'approved', 4.4, 87, 75),
    (v_admin_id, v_shop_id, v_cat_fashion, v_brand_local, 'Premium Dhakai Jamdani Saree', 'dhakai-jamdani-saree-demo-7', 'Authentic handwoven Dhakai Jamdani saree. Traditional Bangladeshi craftsmanship, cotton-silk blend.', 8500, 6999, 18, 25, true, true, 'approved', 4.9, 67, 55),
    (v_admin_id, v_shop_id, v_cat_home, v_brand_local, 'Nakshi Kantha Cushion Cover Set (4pcs)', 'nakshi-kantha-cushion-set-demo-8', 'Hand-embroidered Nakshi Kantha cushion covers. Set of 4, 18x18 inch.', 2499, 1899, 24, 80, false, true, 'approved', 4.6, 43, 90),
    (v_admin_id, v_shop_id, v_cat_laptops, v_brand_apple, 'MacBook Air M3 (2024) 15"', 'macbook-air-m3-15-demo-9', 'Apple M3 chip, 8-core CPU, 10-core GPU, 8GB RAM, 256GB SSD, Liquid Retina display.', 159999, 149999, 6, 20, true, true, 'approved', 4.8, 134, 95),
    (v_admin_id, v_shop_id, v_cat_electronics, v_brand_samsung, 'Samsung Galaxy Tab S9 FE', 'samsung-tab-s9-fe-demo-10', 'S Pen included, 10.9" TFT display, Exynos 1380, 6GB RAM, 128GB, IP68.', 39999, 34999, 13, 45, false, true, 'approved', 4.5, 76, 60),
    (v_admin_id, v_shop_id, v_cat_beauty, v_brand_local, 'Vitamin C Brightening Face Serum 30ml', 'vitamin-c-face-serum-demo-11', 'Advanced 20% Vitamin C serum with Hyaluronic Acid and Vitamin E.', 1299, 999, 23, 300, false, true, 'approved', 4.3, 210, 500),
    (v_admin_id, v_shop_id, v_cat_sports, v_brand_local, 'English Willow Cricket Bat - Pro Edition', 'english-willow-bat-demo-12', 'Grade 1 English Willow cricket bat. Full size SH. 8-12 grains.', 7999, 6499, 19, 40, false, true, 'approved', 4.4, 55, 35),
    (v_admin_id, v_shop_id, v_cat_books, v_brand_local, 'Bangla Ranna: Traditional Bengali Cookbook', 'bangla-ranna-cookbook-demo-13', '500+ authentic Bengali recipes with step-by-step instructions.', 599, 449, 25, 500, false, true, 'approved', 4.7, 89, 350),
    (v_admin_id, v_shop_id, v_cat_electronics, v_brand_samsung, 'Samsung Galaxy Buds3 Pro', 'galaxy-buds3-pro-demo-14', 'Blade lights design, 2-way speaker, Intelligent ANC, 360 Audio, 30hr battery.', 18999, 15999, 16, 120, true, true, 'approved', 4.6, 167, 280),
    (v_admin_id, v_shop_id, v_cat_fashion, v_brand_local, 'Premium Cotton Panjabi - Eid Collection', 'premium-panjabi-eid-demo-15', 'Handcrafted premium cotton panjabi with intricate embroidery. Multiple sizes.', 3499, 2799, 20, 100, true, true, 'approved', 4.5, 78, 120),
    (v_admin_id, v_shop_id, v_cat_beauty, v_brand_local, 'Complete Skincare Routine Set (5 products)', 'skincare-routine-set-demo-16', 'Cleanser, Toner, Serum, Moisturizer, and Sunscreen. All skin types.', 3999, 2999, 25, 150, false, true, 'approved', 4.4, 132, 220),
    (v_admin_id, v_shop_id, v_cat_electronics, v_brand_apple, 'Apple Watch Series 9 (45mm GPS)', 'apple-watch-series9-demo-17', 'S9 SiP chip, Double Tap gesture, always-on Retina display, blood oxygen, ECG.', 54999, 49999, 9, 40, true, true, 'approved', 4.7, 198, 150),
    (v_admin_id, v_shop_id, v_cat_home, v_brand_local, 'King Size Cotton Bedsheet Set (3pcs)', 'king-bedsheet-set-demo-18', 'Premium 300TC Egyptian cotton bedsheet with 2 pillow covers. 100x100 inch.', 2999, 2199, 27, 200, false, true, 'approved', 4.3, 95, 180),
    (v_admin_id, v_shop_id, v_cat_sports, v_brand_adidas, 'Adidas UCL Pro Match Football', 'adidas-ucl-football-demo-19', 'Official UEFA Champions League match ball. FIFA Quality Pro certified. Size 5.', 5999, 4999, 17, 60, false, true, 'approved', 4.6, 44, 40),
    (v_admin_id, v_shop_id, v_cat_laptops, v_brand_samsung, 'Samsung Galaxy Book4 Pro 14"', 'samsung-galaxy-book4-pro-demo-20', 'Intel Core Ultra 7, 16GB RAM, 512GB SSD, Dynamic AMOLED 2X, Intel Arc GPU.', 129999, 114999, 12, 25, true, true, 'approved', 4.5, 67, 45);

  INSERT INTO product_images (product_id, image_url, display_order, is_primary) VALUES
    ((SELECT id FROM products WHERE slug = 'samsung-galaxy-s24-ultra-demo-1'), 'https://picsum.photos/seed/galaxy-s24/600/600', 1, true),
    ((SELECT id FROM products WHERE slug = 'samsung-galaxy-s24-ultra-demo-1'), 'https://picsum.photos/seed/galaxy-s24-2/600/600', 2, false),
    ((SELECT id FROM products WHERE slug = 'iphone-15-pro-max-demo-2'), 'https://picsum.photos/seed/iphone15/600/600', 1, true),
    ((SELECT id FROM products WHERE slug = 'iphone-15-pro-max-demo-2'), 'https://picsum.photos/seed/iphone15-2/600/600', 2, false),
    ((SELECT id FROM products WHERE slug = 'sony-wh1000xm5-demo-3'), 'https://picsum.photos/seed/sony-xm5/600/600', 1, true),
    ((SELECT id FROM products WHERE slug = 'nike-air-max-270-demo-4'), 'https://picsum.photos/seed/nike-airmax/600/600', 1, true),
    ((SELECT id FROM products WHERE slug = 'adidas-ultraboost-23-demo-5'), 'https://picsum.photos/seed/adidas-ultra/600/600', 1, true),
    ((SELECT id FROM products WHERE slug = 'samsung-55-4k-tv-demo-6'), 'https://picsum.photos/seed/samsung-tv/600/600', 1, true),
    ((SELECT id FROM products WHERE slug = 'dhakai-jamdani-saree-demo-7'), 'https://picsum.photos/seed/jamdani/600/600', 1, true),
    ((SELECT id FROM products WHERE slug = 'nakshi-kantha-cushion-set-demo-8'), 'https://picsum.photos/seed/nakshi-kantha/600/600', 1, true),
    ((SELECT id FROM products WHERE slug = 'macbook-air-m3-15-demo-9'), 'https://picsum.photos/seed/macbook-m3/600/600', 1, true),
    ((SELECT id FROM products WHERE slug = 'samsung-tab-s9-fe-demo-10'), 'https://picsum.photos/seed/tab-s9/600/600', 1, true),
    ((SELECT id FROM products WHERE slug = 'vitamin-c-face-serum-demo-11'), 'https://picsum.photos/seed/vitaminc/600/600', 1, true),
    ((SELECT id FROM products WHERE slug = 'english-willow-bat-demo-12'), 'https://picsum.photos/seed/cricket-bat/600/600', 1, true),
    ((SELECT id FROM products WHERE slug = 'bangla-ranna-cookbook-demo-13'), 'https://picsum.photos/seed/cookbook/600/600', 1, true),
    ((SELECT id FROM products WHERE slug = 'galaxy-buds3-pro-demo-14'), 'https://picsum.photos/seed/galaxy-buds/600/600', 1, true),
    ((SELECT id FROM products WHERE slug = 'premium-panjabi-eid-demo-15'), 'https://picsum.photos/seed/panjabi/600/600', 1, true),
    ((SELECT id FROM products WHERE slug = 'skincare-routine-set-demo-16'), 'https://picsum.photos/seed/skincare/600/600', 1, true),
    ((SELECT id FROM products WHERE slug = 'apple-watch-series9-demo-17'), 'https://picsum.photos/seed/apple-watch/600/600', 1, true),
    ((SELECT id FROM products WHERE slug = 'king-bedsheet-set-demo-18'), 'https://picsum.photos/seed/bedsheet/600/600', 1, true),
    ((SELECT id FROM products WHERE slug = 'adidas-ucl-football-demo-19'), 'https://picsum.photos/seed/football/600/600', 1, true),
    ((SELECT id FROM products WHERE slug = 'samsung-galaxy-book4-pro-demo-20'), 'https://picsum.photos/seed/galaxy-book/600/600', 1, true);

  INSERT INTO coupons (code, description, discount_type, discount_value, min_purchase_amount, max_discount_amount, usage_limit, valid_from, valid_until, is_active) VALUES
    ('WELCOME10', 'Welcome discount - 10% off your first order', 'percentage', 10, 500, 2000, 1000, NOW(), NOW() + INTERVAL '1 year', true),
    ('BONGO20', 'BongoPortus special - 20% off', 'percentage', 20, 2000, 5000, 500, NOW(), NOW() + INTERVAL '6 months', true),
    ('FLAT500', 'Flat 500 off on orders above 5000', 'fixed', 500, 5000, NULL, 200, NOW(), NOW() + INTERVAL '3 months', true),
    ('EID25', 'Eid special - 25% off fashion', 'percentage', 25, 1000, 3000, 300, NOW(), NOW() + INTERVAL '2 months', true),
    ('FREESHIP', 'Free shipping on all orders', 'fixed', 50, 0, NULL, NULL, NOW(), NOW() + INTERVAL '1 year', true)
  ON CONFLICT (code) DO NOTHING;

  INSERT INTO product_variants (product_id, variant_type, variant_value, stock_quantity)
  SELECT p.id, 'Size', s.size, 30 FROM products p, (VALUES ('7'),('8'),('9'),('10'),('11')) AS s(size) WHERE p.slug = 'nike-air-max-270-demo-4';

  INSERT INTO product_variants (product_id, variant_type, variant_value, stock_quantity)
  SELECT p.id, 'Size', s.size, 25 FROM products p, (VALUES ('7'),('8'),('9'),('10'),('11')) AS s(size) WHERE p.slug = 'adidas-ultraboost-23-demo-5';

  INSERT INTO product_variants (product_id, variant_type, variant_value, stock_quantity)
  SELECT p.id, 'Size', s.size, 20 FROM products p, (VALUES ('S'),('M'),('L'),('XL'),('XXL')) AS s(size) WHERE p.slug = 'premium-panjabi-eid-demo-15';

  INSERT INTO product_variants (product_id, variant_type, variant_value, stock_quantity)
  SELECT p.id, 'Color', c.color, 10 FROM products p, (VALUES ('Titanium Black'),('Titanium Gray'),('Titanium Violet'),('Titanium Yellow')) AS c(color) WHERE p.slug = 'samsung-galaxy-s24-ultra-demo-1';

  INSERT INTO product_variants (product_id, variant_type, variant_value, stock_quantity)
  SELECT p.id, 'Color', c.color, 8 FROM products p, (VALUES ('Natural Titanium'),('Blue Titanium'),('White Titanium'),('Black Titanium')) AS c(color) WHERE p.slug = 'iphone-15-pro-max-demo-2';

  RAISE NOTICE 'Seed complete: 20 products, 8 categories, 6 brands, 5 coupons.';
END;
$$;

-- =====================================================
-- VERIFY
-- =====================================================
SELECT 'Products' AS entity, COUNT(*) AS total FROM products WHERE approval_status = 'approved'
UNION ALL SELECT 'Categories', COUNT(*) FROM categories WHERE is_active = true
UNION ALL SELECT 'Brands', COUNT(*) FROM brands WHERE is_active = true
UNION ALL SELECT 'Coupons', COUNT(*) FROM coupons WHERE is_active = true
UNION ALL SELECT 'Product Images', COUNT(*) FROM product_images
UNION ALL SELECT 'Product Variants', COUNT(*) FROM product_variants
ORDER BY entity;
