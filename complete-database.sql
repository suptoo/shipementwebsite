-- ==============================================================================
-- MULTI-VENDOR E-COMMERCE PLATFORM - DATABASE SCHEMA
-- ==============================================================================

-- ==============================================================================
-- 1. CLEANUP (DELETE EVERYTHING FIRST)
-- ==============================================================================
-- Drop all triggers first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS update_product_rating ON reviews;

-- Drop all functions with CASCADE
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.update_product_rating() CASCADE;

-- Drop all tables with CASCADE
DROP TABLE IF EXISTS ticket_messages CASCADE;
DROP TABLE IF EXISTS support_tickets CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS inquiries CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;
DROP TABLE IF EXISTS withdrawals CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS coupons CASCADE;
DROP TABLE IF EXISTS cart_items CASCADE;
DROP TABLE IF EXISTS wishlists CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS product_variants CASCADE;
DROP TABLE IF EXISTS product_images CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS brands CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS shops CASCADE;
DROP TABLE IF EXISTS seller_kyc CASCADE;
DROP TABLE IF EXISTS seller_profiles CASCADE;
DROP TABLE IF EXISTS user_addresses CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS cms_pages CASCADE;
DROP TABLE IF EXISTS cms_banners CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- ==============================================================================
-- 2. SETUP EXTENSIONS
-- ==============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 3. CREATE TABLES
-- ==============================================================================

-- A. User Profiles (Linked to Auth)
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'seller', 'user')),
    full_name TEXT,
    phone TEXT,
    avatar_url TEXT,
    is_verified BOOLEAN DEFAULT false,
    is_blocked BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- B. User Addresses
CREATE TABLE user_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    label TEXT NOT NULL, -- Home, Office, etc.
    full_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    postal_code TEXT NOT NULL,
    country TEXT DEFAULT 'Bangladesh',
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- C. Seller Profiles
CREATE TABLE seller_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    business_name TEXT NOT NULL,
    business_type TEXT, -- Individual, Company
    commission_rate NUMERIC DEFAULT 15.0, -- Platform commission %
    total_earnings NUMERIC DEFAULT 0,
    available_balance NUMERIC DEFAULT 0,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'suspended', 'rejected')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- D. Seller KYC Documents
CREATE TABLE seller_kyc (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID NOT NULL REFERENCES seller_profiles(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL, -- NID, Trade License, Tax Certificate
    document_number TEXT,
    document_url TEXT NOT NULL,
    verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected')),
    rejection_reason TEXT,
    submitted_at TIMESTAMPTZ DEFAULT NOW(),
    verified_at TIMESTAMPTZ
);

-- E. Shops
CREATE TABLE shops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID NOT NULL REFERENCES seller_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    description TEXT,
    logo_url TEXT,
    banner_url TEXT,
    address TEXT,
    rating NUMERIC DEFAULT 0,
    total_products INTEGER DEFAULT 0,
    total_orders INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(seller_id)
);

-- F. Categories
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    parent_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    icon_url TEXT,
    image_url TEXT,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- G. Brands
CREATE TABLE brands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    logo_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- H. Products
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID NOT NULL REFERENCES seller_profiles(id) ON DELETE CASCADE,
    shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE SET NULL,
    brand_id UUID REFERENCES brands(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    description TEXT,
    price NUMERIC NOT NULL,
    discount_price NUMERIC,
    discount_percentage NUMERIC,
    stock_quantity INTEGER DEFAULT 0,
    sku TEXT,
    weight NUMERIC, -- in kg
    dimensions TEXT, -- JSON or text like "10x20x5"
    video_url TEXT,
    rating NUMERIC DEFAULT 0,
    total_reviews INTEGER DEFAULT 0,
    total_sales INTEGER DEFAULT 0,
    is_featured BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    approval_status TEXT DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    rejection_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- I. Product Images
CREATE TABLE product_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    display_order INTEGER DEFAULT 0,
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- J. Product Variants (Size, Color, etc.)
CREATE TABLE product_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    variant_type TEXT NOT NULL, -- color, size, type
    variant_value TEXT NOT NULL,
    price_modifier NUMERIC DEFAULT 0,
    stock_quantity INTEGER DEFAULT 0,
    sku TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- K. Reviews & Ratings
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    order_id UUID, -- Link to order for verified purchases
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title TEXT,
    comment TEXT,
    image_urls TEXT[], -- Array of photo URLs
    is_verified_purchase BOOLEAN DEFAULT false,
    helpful_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- L. Wishlist
CREATE TABLE wishlists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, product_id)
);

-- M. Cart Items
CREATE TABLE cart_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    variant_id UUID REFERENCES product_variants(id) ON DELETE SET NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- N. Coupons
CREATE TABLE coupons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE,
    description TEXT,
    discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
    discount_value NUMERIC NOT NULL,
    min_purchase_amount NUMERIC DEFAULT 0,
    max_discount_amount NUMERIC,
    usage_limit INTEGER,
    used_count INTEGER DEFAULT 0,
    valid_from TIMESTAMPTZ DEFAULT NOW(),
    valid_until TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- O. Orders
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number TEXT NOT NULL UNIQUE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- Delivery Info
    delivery_full_name TEXT NOT NULL,
    delivery_phone TEXT NOT NULL,
    delivery_address_line1 TEXT NOT NULL,
    delivery_address_line2 TEXT,
    delivery_city TEXT NOT NULL,
    delivery_state TEXT NOT NULL,
    delivery_postal_code TEXT NOT NULL,
    delivery_country TEXT DEFAULT 'Bangladesh',
    
    -- Pricing
    subtotal NUMERIC NOT NULL,
    discount_amount NUMERIC DEFAULT 0,
    coupon_code TEXT,
    shipping_charge NUMERIC DEFAULT 0,
    tax_amount NUMERIC DEFAULT 0,
    total_amount NUMERIC NOT NULL,
    
    -- Payment
    payment_method TEXT NOT NULL, -- cod, card, mobile_banking, wallet
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
    stripe_payment_intent_id TEXT,
    stripe_charge_id TEXT,
    
    -- Order Status
    order_status TEXT DEFAULT 'pending' CHECK (order_status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'returned')),
    
    -- Tracking
    tracking_number TEXT,
    courier_name TEXT, -- Pathao, Steadfast, RedX
    estimated_delivery TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- P. Order Items
CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE SET NULL,
    seller_id UUID NOT NULL REFERENCES seller_profiles(id) ON DELETE CASCADE,
    shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    variant_id UUID REFERENCES product_variants(id) ON DELETE SET NULL,
    
    product_name TEXT NOT NULL,
    product_image_url TEXT,
    variant_details TEXT, -- JSON string
    
    quantity INTEGER NOT NULL,
    unit_price NUMERIC NOT NULL,
    total_price NUMERIC NOT NULL,
    
    commission_rate NUMERIC NOT NULL,
    commission_amount NUMERIC NOT NULL,
    seller_earnings NUMERIC NOT NULL,
    
    item_status TEXT DEFAULT 'pending' CHECK (item_status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'returned')),
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Q. Transactions (Financial Records)
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID REFERENCES seller_profiles(id) ON DELETE CASCADE,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    transaction_type TEXT NOT NULL, -- sale, withdrawal, refund, commission
    amount NUMERIC NOT NULL,
    balance_after NUMERIC NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- R. Withdrawals
CREATE TABLE withdrawals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID NOT NULL REFERENCES seller_profiles(id) ON DELETE CASCADE,
    amount NUMERIC NOT NULL,
    payment_method TEXT NOT NULL, -- bank_transfer, mobile_banking
    account_details JSONB NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed')),
    rejection_reason TEXT,
    requested_at TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ
);

-- S. Inquiries (Product inquiries and chat sessions with admin)
CREATE TABLE inquiries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    message TEXT,
    survey_amount TEXT,
    survey_address TEXT,
    survey_days INTEGER DEFAULT 7,
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'closed')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- T. Messages (All message types - for inquiries and support)
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inquiry_id UUID REFERENCES inquiries(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    image_url TEXT,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- U. Conversations (Direct messaging between users, sellers, and support)
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type TEXT NOT NULL CHECK (type IN ('buyer_seller', 'buyer_admin', 'seller_admin')),
    buyer_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    seller_id UUID REFERENCES seller_profiles(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    subject TEXT,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'closed', 'archived')),
    last_message_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- V. Support Tickets (Admin-level help system)
CREATE TABLE support_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    category TEXT NOT NULL CHECK (category IN ('order_issue', 'payment_issue', 'product_issue', 'account_issue', 'technical_issue', 'other')),
    subject TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    assigned_to UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

-- S2. Ticket Messages (Support ticket conversation)
CREATE TABLE ticket_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    attachment_url TEXT,
    is_internal BOOLEAN DEFAULT false, -- Internal notes visible only to admins
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- U. Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL, -- order, payment, product, promotion, system
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    link TEXT,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- V. CMS Banners
CREATE TABLE cms_banners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    image_url TEXT NOT NULL,
    link TEXT,
    position TEXT DEFAULT 'home_hero', -- home_hero, home_middle, category_top
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    valid_from TIMESTAMPTZ DEFAULT NOW(),
    valid_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- W. CMS Pages (Terms, Privacy, etc.)
CREATE TABLE cms_pages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    meta_description TEXT,
    is_published BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 4. PERFORMANCE INDEXES
-- ==============================================================================
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_user_addresses_user_id ON user_addresses(user_id);
CREATE INDEX idx_seller_profiles_user_id ON seller_profiles(user_id);
CREATE INDEX idx_seller_profiles_status ON seller_profiles(status);
CREATE INDEX idx_products_seller_id ON products(seller_id);
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_brand_id ON products(brand_id);
CREATE INDEX idx_products_slug ON products(slug);
CREATE INDEX idx_products_is_active ON products(is_active);
CREATE INDEX idx_products_approval_status ON products(approval_status);
CREATE INDEX idx_product_images_product_id ON product_images(product_id);
CREATE INDEX idx_reviews_product_id ON reviews(product_id);
CREATE INDEX idx_reviews_user_id ON reviews(user_id);
CREATE INDEX idx_cart_items_user_id ON cart_items(user_id);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_order_number ON orders(order_number);
CREATE INDEX idx_orders_order_status ON orders(order_status);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_seller_id ON order_items(seller_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_inquiries_user_id ON inquiries(user_id);
CREATE INDEX idx_inquiries_product_id ON inquiries(product_id);
CREATE INDEX idx_inquiries_status ON inquiries(status);
CREATE INDEX idx_messages_inquiry_id ON messages(inquiry_id);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_conversations_buyer_id ON conversations(buyer_id);
CREATE INDEX idx_conversations_seller_id ON conversations(seller_id);
CREATE INDEX idx_conversations_type ON conversations(type);
CREATE INDEX idx_support_tickets_user_id ON support_tickets(user_id);
CREATE INDEX idx_support_tickets_status ON support_tickets(status);
CREATE INDEX idx_ticket_messages_ticket_id ON ticket_messages(ticket_id);

-- ==============================================================================
-- 5. AUTOMATION (Triggers & Functions)
-- ==============================================================================

-- Function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if email is admin email
    IF NEW.email = 'umorfaruksupto@gmail.com' THEN
        INSERT INTO public.profiles (id, email, full_name, role, is_verified)
        VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name', 'admin', true);
    ELSE
        INSERT INTO public.profiles (id, email, full_name, role)
        VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name', 'user');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update product rating
CREATE OR REPLACE FUNCTION public.update_product_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE products
    SET 
        rating = (SELECT AVG(rating) FROM reviews WHERE product_id = NEW.product_id),
        total_reviews = (SELECT COUNT(*) FROM reviews WHERE product_id = NEW.product_id)
    WHERE id = NEW.product_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update product rating after review
CREATE TRIGGER update_product_rating
    AFTER INSERT OR UPDATE ON reviews
    FOR EACH ROW EXECUTE FUNCTION public.update_product_rating();

-- Force update existing user to admin (if needed)
UPDATE public.profiles 
SET role = 'admin', is_verified = true
WHERE email = 'umorfaruksupto@gmail.com';

-- ==============================================================================
-- 6. SEED DATA
-- ==============================================================================

-- Categories
INSERT INTO categories (name, slug, parent_id, display_order) VALUES
('Electronics', 'electronics', NULL, 1),
('Fashion', 'fashion', NULL, 2),
('Home & Living', 'home-living', NULL, 3),
('Health & Beauty', 'health-beauty', NULL, 4),
('Sports & Outdoors', 'sports-outdoors', NULL, 5),
('Books', 'books', NULL, 6),
('Groceries', 'groceries', NULL, 7);

-- Sub-categories
INSERT INTO categories (name, slug, parent_id, display_order) VALUES
('Smartphones', 'smartphones', (SELECT id FROM categories WHERE slug = 'electronics'), 1),
('Laptops', 'laptops', (SELECT id FROM categories WHERE slug = 'electronics'), 2),
('Mens Fashion', 'mens-fashion', (SELECT id FROM categories WHERE slug = 'fashion'), 1),
('Womens Fashion', 'womens-fashion', (SELECT id FROM categories WHERE slug = 'fashion'), 2);

-- Brands
INSERT INTO brands (name, slug) VALUES
('Samsung', 'samsung'),
('Apple', 'apple'),
('Nike', 'nike'),
('Adidas', 'adidas'),
('Sony', 'sony'),
('LG', 'lg'),
('Uniqlo', 'uniqlo'),
('Zara', 'zara');

-- Sample Coupons
INSERT INTO coupons (code, description, discount_type, discount_value, min_purchase_amount, usage_limit, valid_until) VALUES
('WELCOME10', '10% off on first order', 'percentage', 10, 500, 1000, NOW() + INTERVAL '30 days'),
('SAVE50', '50 Taka off on orders above 1000', 'fixed', 50, 1000, NULL, NOW() + INTERVAL '60 days'),
('FLASH20', 'Flash Sale - 20% Off', 'percentage', 20, 0, 500, NOW() + INTERVAL '7 days');

-- CMS Pages
INSERT INTO cms_pages (slug, title, content) VALUES
('terms-and-conditions', 'Terms and Conditions', '<h1>Terms and Conditions</h1><p>Welcome to our multi-vendor e-commerce platform...</p>'),
('privacy-policy', 'Privacy Policy', '<h1>Privacy Policy</h1><p>Your privacy is important to us...</p>'),
('return-policy', 'Return & Refund Policy', '<h1>Return & Refund Policy</h1><p>We accept returns within 7 days...</p>'),
('about-us', 'About Us', '<h1>About Us</h1><p>We are a leading multi-vendor marketplace...</p>');

-- Sample Banner
INSERT INTO cms_banners (title, image_url, link, position, display_order) VALUES
('Winter Sale 2025', '/images/products/home-living/modern-sofa.png', '/category/fashion', 'home_hero', 1),
('Electronics Mega Sale', '/images/products/laptops/macbook-pro-16.png', '/category/electronics', 'home_hero', 2);

-- If profile doesn't exist, create it as admin
INSERT INTO public.profiles (id, email, full_name, role)
SELECT 
    id, 
    email,
    raw_user_meta_data->>'full_name' as full_name,
    'admin' as role
FROM auth.users 
WHERE email = 'umorfaruksupto@gmail.com'
ON CONFLICT (id) DO UPDATE SET role = 'admin';

-- ==============================================================================
-- 6. SECURITY (Row Level Security)
-- ==============================================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE seller_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE inquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_messages ENABLE ROW LEVEL SECURITY;

-- --- Profiles Policies ---
CREATE POLICY "Public profiles are viewable by everyone" 
ON profiles FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" 
ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can create own profile"
ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- --- Products Policies ---
CREATE POLICY "Products are viewable by everyone" 
ON products FOR SELECT USING (true);

-- Admins can manage all products
CREATE POLICY "Admins can insert products" 
ON products FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

CREATE POLICY "Admins can update all products" 
ON products FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

CREATE POLICY "Admins can delete products" 
ON products FOR DELETE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Sellers can manage their own products
CREATE POLICY "Sellers can insert own products" 
ON products FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM seller_profiles sp
        JOIN profiles p ON p.id = sp.user_id
        WHERE sp.id = seller_id AND p.id = auth.uid() AND p.role = 'seller'
    )
);

CREATE POLICY "Sellers can update own products" 
ON products FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM seller_profiles sp
        JOIN profiles p ON p.id = sp.user_id
        WHERE sp.id = seller_id AND p.id = auth.uid() AND p.role = 'seller'
    )
);

CREATE POLICY "Sellers can delete own products" 
ON products FOR DELETE USING (
    EXISTS (
        SELECT 1 FROM seller_profiles sp
        JOIN profiles p ON p.id = sp.user_id
        WHERE sp.id = seller_id AND p.id = auth.uid() AND p.role = 'seller'
    )
);

-- --- Inquiries Policies ---
CREATE POLICY "Users can view own inquiries" 
ON inquiries FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

CREATE POLICY "Users can create inquiries" 
ON inquiries FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can update inquiries" 
ON inquiries FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- --- Messages Policies ---
CREATE POLICY "Users can view messages in own inquiries" 
ON messages FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM inquiries i
        WHERE i.id = inquiry_id AND (
            i.user_id = auth.uid() OR
            EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
        )
    )
);

CREATE POLICY "Users can send messages in own inquiries" 
ON messages FOR INSERT WITH CHECK (
    sender_id = auth.uid() AND
    EXISTS (
        SELECT 1 FROM inquiries i
        WHERE i.id = inquiry_id AND (
            i.user_id = auth.uid() OR
            EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
        )
    )
);

-- --- User Addresses Policies ---
CREATE POLICY "Users can view own addresses" 
ON user_addresses FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert own addresses" 
ON user_addresses FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own addresses" 
ON user_addresses FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete own addresses" 
ON user_addresses FOR DELETE USING (user_id = auth.uid());

-- --- Cart Items Policies ---
CREATE POLICY "Users can view own cart" 
ON cart_items FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can add to cart" 
ON cart_items FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own cart" 
ON cart_items FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete from cart" 
ON cart_items FOR DELETE USING (user_id = auth.uid());

-- --- Orders Policies ---
CREATE POLICY "Users can view own orders" 
ON orders FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

CREATE POLICY "Users can create orders" 
ON orders FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can update orders" 
ON orders FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- --- Order Items Policies ---
CREATE POLICY "Users can view own order items" 
ON order_items FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM orders o
        WHERE o.id = order_id AND (
            o.user_id = auth.uid() OR
            EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
        )
    )
);

CREATE POLICY "Users can create order items" 
ON order_items FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM orders o
        WHERE o.id = order_id AND o.user_id = auth.uid()
    )
);

-- --- Conversations Policies ---
CREATE POLICY "Users can view their conversations" 
ON conversations FOR SELECT USING (
    -- Buyer can see their conversations
    buyer_id = auth.uid() OR
    -- Seller can see their conversations
    EXISTS (
        SELECT 1 FROM seller_profiles sp
        WHERE sp.id = seller_id AND sp.user_id = auth.uid()
    ) OR
    -- Admin can see all conversations
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

CREATE POLICY "Users can create conversations" 
ON conversations FOR INSERT WITH CHECK (
    buyer_id = auth.uid() OR
    EXISTS (
        SELECT 1 FROM seller_profiles sp
        WHERE sp.id = seller_id AND sp.user_id = auth.uid()
    )
);

-- --- Support Tickets Policies ---
CREATE POLICY "Users view own tickets, Admins view all" 
ON support_tickets FOR SELECT USING (
    auth.uid() = user_id OR 
    auth.uid() = assigned_to OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

CREATE POLICY "Users can create support tickets" 
ON support_tickets FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can update support tickets" 
ON support_tickets FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- --- Ticket Messages Policies ---
CREATE POLICY "View ticket messages if authorized" 
ON ticket_messages FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM support_tickets st
        WHERE st.id = ticket_id AND (
            st.user_id = auth.uid() OR
            st.assigned_to = auth.uid() OR
            EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
        )
    ) AND (
        -- Hide internal notes from non-admins
        NOT is_internal OR 
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    )
);

CREATE POLICY "Send ticket messages if authorized" 
ON ticket_messages FOR INSERT WITH CHECK (
    sender_id = auth.uid() AND
    EXISTS (
        SELECT 1 FROM support_tickets st
        WHERE st.id = ticket_id AND (
            st.user_id = auth.uid() OR
            EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
        )
    )
);

-- ==============================================================================
-- 7. STORAGE SETUP (Buckets)
-- ==============================================================================
-- Note: You usually run this once. If it fails because it exists, that is fine.
INSERT INTO storage.buckets (id, name, public)
VALUES 
('product-images', 'product-images', true),
('chat-attachments', 'chat-attachments', true),
('seller-documents', 'seller-documents', false)
ON CONFLICT (id) DO NOTHING;

-- Storage Policies
-- Product Images - Anyone can view
DROP POLICY IF EXISTS "Anyone can view product images" ON storage.objects;
CREATE POLICY "Anyone can view product images" ON storage.objects
FOR SELECT USING (bucket_id = 'product-images');

-- Product Images - Sellers and Admins can upload
DROP POLICY IF EXISTS "Sellers and Admins can upload product images" ON storage.objects;
CREATE POLICY "Sellers and Admins can upload product images" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'product-images' AND 
    auth.uid() IS NOT NULL AND (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'seller'))
    )
);

-- Chat Attachments - Authenticated users can upload
DROP POLICY IF EXISTS "Authenticated users can upload chat images" ON storage.objects;
CREATE POLICY "Authenticated users can upload chat images" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'chat-attachments' AND auth.uid() IS NOT NULL
);

-- Allow Public to view images
DROP POLICY IF EXISTS "Anyone can view chat images" ON storage.objects;
CREATE POLICY "Anyone can view chat images" ON storage.objects
FOR SELECT USING (bucket_id = 'chat-attachments');

-- ==============================================================================
-- 8. SAMPLE DATA (Optional - for testing)
-- ==============================================================================

-- Note: Run the schema first, then optionally add sample products through the admin panel
-- The platform is ready for sellers and admins to add products

-- SEED DATA FOR PRODUCTS (60 ITEMS)
DO $$
DECLARE
    v_admin_id UUID;
    v_seller_id UUID;
    v_shop_id UUID;
    v_cat_smartphones UUID;
    v_cat_laptops UUID;
    v_cat_mens_fashion UUID;
    v_cat_womens_fashion UUID;
    v_cat_home UUID;
    v_brand_apple UUID;
    v_brand_samsung UUID;
    v_brand_nike UUID;
    v_brand_adidas UUID;
    v_brand_sony UUID;
BEGIN
    -- 1. Get Admin User ID (assuming the one from setup exists, or pick any user)
    SELECT id INTO v_admin_id FROM auth.users LIMIT 1;
    
    -- If no user exists, we can't proceed easily without creating one, 
    -- but let's assume the setup script ran and created 'umorfaruksupto@gmail.com' or similar.
    -- If v_admin_id is null, we might fail.
    
    -- 2. Ensure Seller Profile Exists for this user
    INSERT INTO seller_profiles (user_id, business_name, business_type, status)
    VALUES (v_admin_id, 'Bongo Tech Store', 'Company', 'approved')
    ON CONFLICT (user_id) DO UPDATE SET status = 'approved'
    RETURNING id INTO v_seller_id;

    -- 3. Ensure Shop Exists
    INSERT INTO shops (seller_id, name, slug, description)
    VALUES (v_seller_id, 'Bongo Official Store', 'bongo-official', 'The official store for BongoPortus products.')
    ON CONFLICT (seller_id) DO UPDATE SET name = 'Bongo Official Store'
    RETURNING id INTO v_shop_id;

    -- 4. Get Category IDs
    SELECT id INTO v_cat_smartphones FROM categories WHERE slug = 'smartphones';
    SELECT id INTO v_cat_laptops FROM categories WHERE slug = 'laptops';
    SELECT id INTO v_cat_mens_fashion FROM categories WHERE slug = 'mens-fashion';
    SELECT id INTO v_cat_womens_fashion FROM categories WHERE slug = 'womens-fashion';
    -- Create Home category if not exists (it was 'Home & Living' in setup, let's get that)
    SELECT id INTO v_cat_home FROM categories WHERE slug = 'home-living';

    -- 5. Get Brand IDs
    SELECT id INTO v_brand_apple FROM brands WHERE slug = 'apple';
    SELECT id INTO v_brand_samsung FROM brands WHERE slug = 'samsung';
    SELECT id INTO v_brand_nike FROM brands WHERE slug = 'nike';
    SELECT id INTO v_brand_adidas FROM brands WHERE slug = 'adidas';
    SELECT id INTO v_brand_sony FROM brands WHERE slug = 'sony';

    -- 6. Insert Products (Batch 1: Smartphones - 12 items)
    INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, stock_quantity, is_active, approval_status, rating, total_reviews) VALUES
    (v_seller_id, v_shop_id, v_cat_smartphones, v_brand_apple, 'iPhone 15 Pro Max', 'iphone-15-pro-max-titanium', 'The ultimate iPhone with titanium design.', 1499.00, 50, true, 'approved', 4.9, 120),
    (v_seller_id, v_shop_id, v_cat_smartphones, v_brand_apple, 'iPhone 15 Pro', 'iphone-15-pro-blue', 'Pro camera system, pro performance.', 1299.00, 45, true, 'approved', 4.8, 95),
    (v_seller_id, v_shop_id, v_cat_smartphones, v_brand_apple, 'iPhone 14', 'iphone-14-midnight', 'Full of fantastic features.', 999.00, 100, true, 'approved', 4.7, 200),
    (v_seller_id, v_shop_id, v_cat_smartphones, v_brand_samsung, 'Samsung Galaxy S24 Ultra', 'samsung-s24-ultra', 'Galaxy AI is here.', 1399.00, 60, true, 'approved', 4.9, 80),
    (v_seller_id, v_shop_id, v_cat_smartphones, v_brand_samsung, 'Samsung Galaxy S24+', 'samsung-s24-plus', 'Epic moments, now accessible.', 1199.00, 55, true, 'approved', 4.7, 60),
    (v_seller_id, v_shop_id, v_cat_smartphones, v_brand_samsung, 'Samsung Galaxy Z Fold 5', 'samsung-z-fold-5', 'Unfold your world.', 1799.00, 30, true, 'approved', 4.6, 40),
    (v_seller_id, v_shop_id, v_cat_smartphones, v_brand_sony, 'Sony Xperia 1 V', 'sony-xperia-1-v', 'Next-gen sensor. Next-gen imaging.', 1199.00, 20, true, 'approved', 4.5, 25),
    (v_seller_id, v_shop_id, v_cat_smartphones, NULL, 'Google Pixel 8 Pro', 'google-pixel-8-pro', 'The AI-first phone from Google.', 999.00, 40, true, 'approved', 4.7, 150),
    (v_seller_id, v_shop_id, v_cat_smartphones, NULL, 'Google Pixel 8', 'google-pixel-8', 'Powerful, helpful, and personal.', 699.00, 50, true, 'approved', 4.6, 110),
    (v_seller_id, v_shop_id, v_cat_smartphones, NULL, 'OnePlus 12', 'oneplus-12', 'Smooth beyond belief.', 799.00, 35, true, 'approved', 4.5, 70),
    (v_seller_id, v_shop_id, v_cat_smartphones, NULL, 'Nothing Phone (2)', 'nothing-phone-2', 'Come to the bright side.', 599.00, 25, true, 'approved', 4.4, 45),
    (v_seller_id, v_shop_id, v_cat_smartphones, NULL, 'Xiaomi 14 Ultra', 'xiaomi-14-ultra', 'Lens to legend.', 1099.00, 15, true, 'approved', 4.6, 30);

    -- Insert Images for Smartphones (using local assets)
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/iphone-15-pro.png', true FROM products WHERE slug = 'iphone-15-pro-max-titanium';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/iphone-15-pro.png', true FROM products WHERE slug = 'iphone-15-pro-blue';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/iphone-15-pro.png', true FROM products WHERE slug = 'iphone-14-midnight';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/samsung-galaxy-s24.png', true FROM products WHERE slug = 'samsung-s24-ultra';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/samsung-galaxy-s24.png', true FROM products WHERE slug = 'samsung-s24-plus';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/samsung-galaxy-s24.png', true FROM products WHERE slug = 'samsung-z-fold-5';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/google-pixel-8.png', true FROM products WHERE slug = 'sony-xperia-1-v';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/google-pixel-8.png', true FROM products WHERE slug = 'google-pixel-8-pro';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/google-pixel-8.png', true FROM products WHERE slug = 'google-pixel-8';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/oneplus-12.png', true FROM products WHERE slug = 'oneplus-12';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/oneplus-12.png', true FROM products WHERE slug = 'nothing-phone-2';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/oneplus-12.png', true FROM products WHERE slug = 'xiaomi-14-ultra';


    -- 7. Insert Products (Batch 2: Laptops - 12 items)
    INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, stock_quantity, is_active, approval_status, rating, total_reviews) VALUES
    (v_seller_id, v_shop_id, v_cat_laptops, v_brand_apple, 'MacBook Pro 16 M3 Max', 'macbook-pro-16-m3', 'Mind-blowing. Head-turning.', 3499.00, 20, true, 'approved', 4.9, 50),
    (v_seller_id, v_shop_id, v_cat_laptops, v_brand_apple, 'MacBook Air 15 M2', 'macbook-air-15-m2', 'Impressively big. Impossibly thin.', 1299.00, 60, true, 'approved', 4.8, 120),
    (v_seller_id, v_shop_id, v_cat_laptops, v_brand_apple, 'MacBook Pro 14 M3', 'macbook-pro-14-m3', 'Serious power.', 1599.00, 40, true, 'approved', 4.8, 80),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'Dell XPS 15', 'dell-xps-15', 'Immersive display. Premium design.', 1899.00, 30, true, 'approved', 4.6, 60),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'Dell XPS 13 Plus', 'dell-xps-13-plus', 'Twice as powerful as before.', 1399.00, 35, true, 'approved', 4.5, 45),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'HP Spectre x360', 'hp-spectre-x360', 'Craftsmanship meets power.', 1499.00, 25, true, 'approved', 4.7, 55),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'Lenovo ThinkPad X1 Carbon', 'lenovo-thinkpad-x1', 'Ultralight. Ultra-powerful.', 1699.00, 40, true, 'approved', 4.8, 90),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'Asus ROG Zephyrus G14', 'asus-rog-zephyrus-g14', 'World''s most powerful 14-inch gaming laptop.', 1599.00, 30, true, 'approved', 4.7, 75),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'Razer Blade 16', 'razer-blade-16', 'Fastest display. Most powerful graphics.', 2999.00, 15, true, 'approved', 4.6, 35),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'Microsoft Surface Laptop 5', 'surface-laptop-5', 'Style and speed.', 999.00, 50, true, 'approved', 4.5, 65),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'Acer Swift Go 14', 'acer-swift-go-14', 'Ready to go.', 799.00, 45, true, 'approved', 4.4, 40),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'MSI Raider GE78', 'msi-raider-ge78', 'Light ''em up.', 2499.00, 10, true, 'approved', 4.5, 20);

    -- Insert Images for Laptops (using local assets)
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/macbook-pro-16.png', true FROM products WHERE slug = 'macbook-pro-16-m3';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/macbook-pro-16.png', true FROM products WHERE slug = 'macbook-air-15-m2';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/macbook-pro-16.png', true FROM products WHERE slug = 'macbook-pro-14-m3';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/dell-xps-15.png', true FROM products WHERE slug = 'dell-xps-15';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/dell-xps-15.png', true FROM products WHERE slug = 'dell-xps-13-plus';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/dell-xps-15.png', true FROM products WHERE slug = 'hp-spectre-x360';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/dell-xps-15.png', true FROM products WHERE slug = 'lenovo-thinkpad-x1';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/gaming-laptop.png', true FROM products WHERE slug = 'asus-rog-zephyrus-g14';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/gaming-laptop.png', true FROM products WHERE slug = 'razer-blade-16';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/dell-xps-15.png', true FROM products WHERE slug = 'surface-laptop-5';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/dell-xps-15.png', true FROM products WHERE slug = 'acer-swift-go-14';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/gaming-laptop.png', true FROM products WHERE slug = 'msi-raider-ge78';


    -- 8. Insert Products (Batch 3: Mens Fashion - 12 items)
    INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, stock_quantity, is_active, approval_status, rating, total_reviews) VALUES
    (v_seller_id, v_shop_id, v_cat_mens_fashion, v_brand_nike, 'Nike Air Max 270', 'nike-air-max-270', 'Big air. Bold look.', 150.00, 100, true, 'approved', 4.8, 300),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, v_brand_nike, 'Nike Tech Fleece Hoodie', 'nike-tech-fleece', 'Warmth without weight.', 110.00, 80, true, 'approved', 4.7, 150),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, v_brand_adidas, 'Adidas Ultraboost Light', 'adidas-ultraboost', 'Epic energy.', 190.00, 60, true, 'approved', 4.8, 200),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, v_brand_adidas, 'Adidas Essentials Tracksuit', 'adidas-tracksuit', 'Classic comfort.', 80.00, 90, true, 'approved', 4.6, 120),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Classic Denim Jacket', 'classic-denim-jacket', 'Timeless style.', 60.00, 70, true, 'approved', 4.5, 80),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Slim Fit Chinos', 'slim-fit-chinos', 'Versatile and comfortable.', 45.00, 120, true, 'approved', 4.4, 90),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Oxford Cotton Shirt', 'oxford-cotton-shirt', 'Sharp and professional.', 55.00, 100, true, 'approved', 4.6, 110),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Leather Chelsea Boots', 'leather-chelsea-boots', 'Sleek and durable.', 120.00, 40, true, 'approved', 4.7, 60),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Casual White Sneakers', 'casual-white-sneakers', 'Everyday essential.', 70.00, 150, true, 'approved', 4.5, 180),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Puffer Jacket', 'mens-puffer-jacket', 'Winter ready.', 130.00, 50, true, 'approved', 4.8, 70),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Graphic Print T-Shirt', 'graphic-print-tshirt', 'Express yourself.', 25.00, 200, true, 'approved', 4.3, 140),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Cargo Pants', 'mens-cargo-pants', 'Utility meets style.', 50.00, 85, true, 'approved', 4.4, 95);

    -- Insert Images for Mens Fashion (using local assets)
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/nike-air-max.png', true FROM products WHERE slug = 'nike-air-max-270';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/tech-fleece-hoodie.png', true FROM products WHERE slug = 'nike-tech-fleece';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/adidas-ultraboost.png', true FROM products WHERE slug = 'adidas-ultraboost';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/tech-fleece-hoodie.png', true FROM products WHERE slug = 'adidas-tracksuit';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/nike-air-max.png', true FROM products WHERE slug = 'classic-denim-jacket';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/adidas-ultraboost.png', true FROM products WHERE slug = 'slim-fit-chinos';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/tech-fleece-hoodie.png', true FROM products WHERE slug = 'oxford-cotton-shirt';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/nike-air-max.png', true FROM products WHERE slug = 'leather-chelsea-boots';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/adidas-ultraboost.png', true FROM products WHERE slug = 'casual-white-sneakers';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/tech-fleece-hoodie.png', true FROM products WHERE slug = 'mens-puffer-jacket';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/tech-fleece-hoodie.png', true FROM products WHERE slug = 'graphic-print-tshirt';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/adidas-ultraboost.png', true FROM products WHERE slug = 'mens-cargo-pants';


    -- 9. Insert Products (Batch 4: Womens Fashion - 12 items)
    INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, stock_quantity, is_active, approval_status, rating, total_reviews) VALUES
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Floral Summer Dress', 'floral-summer-dress', 'Breezy and beautiful.', 45.00, 80, true, 'approved', 4.7, 110),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'High-Waisted Jeans', 'high-waisted-jeans', 'Flattering fit.', 55.00, 100, true, 'approved', 4.6, 130),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Oversized Blazer', 'oversized-blazer', 'Chic and professional.', 85.00, 40, true, 'approved', 4.8, 60),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Silk Blouse', 'silk-blouse', 'Luxurious feel.', 70.00, 50, true, 'approved', 4.7, 45),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Pleated Midi Skirt', 'pleated-midi-skirt', 'Elegant movement.', 50.00, 60, true, 'approved', 4.5, 75),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Leather Handbag', 'leather-handbag', 'Everyday essential.', 120.00, 30, true, 'approved', 4.9, 90),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Ankle Boots', 'ankle-boots', 'Stylish and sturdy.', 90.00, 55, true, 'approved', 4.6, 85),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Knitted Sweater', 'knitted-sweater', 'Cozy comfort.', 60.00, 70, true, 'approved', 4.8, 100),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Statement Earrings', 'statement-earrings', 'Bold accessory.', 20.00, 150, true, 'approved', 4.4, 50),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Trench Coat', 'womens-trench-coat', 'Classic outerwear.', 140.00, 35, true, 'approved', 4.8, 65),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Yoga Leggings', 'yoga-leggings', 'Stretch and support.', 35.00, 120, true, 'approved', 4.7, 140),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Evening Gown', 'evening-gown', 'For special occasions.', 180.00, 20, true, 'approved', 4.9, 30);

    -- Insert Images for Womens Fashion (using local assets)
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/floral-summer-dress.png', true FROM products WHERE slug = 'floral-summer-dress';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/high-waisted-jeans.png', true FROM products WHERE slug = 'high-waisted-jeans';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/floral-summer-dress.png', true FROM products WHERE slug = 'oversized-blazer';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/floral-summer-dress.png', true FROM products WHERE slug = 'silk-blouse';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/high-waisted-jeans.png', true FROM products WHERE slug = 'pleated-midi-skirt';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/leather-handbag.png', true FROM products WHERE slug = 'leather-handbag';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/leather-handbag.png', true FROM products WHERE slug = 'ankle-boots';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/floral-summer-dress.png', true FROM products WHERE slug = 'knitted-sweater';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/leather-handbag.png', true FROM products WHERE slug = 'statement-earrings';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/floral-summer-dress.png', true FROM products WHERE slug = 'womens-trench-coat';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/high-waisted-jeans.png', true FROM products WHERE slug = 'yoga-leggings';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/floral-summer-dress.png', true FROM products WHERE slug = 'evening-gown';


    -- 10. Insert Products (Batch 5: Home & Living - 12 items)
    INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, stock_quantity, is_active, approval_status, rating, total_reviews) VALUES
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Modern Sofa', 'modern-sofa', 'Comfortable and stylish.', 599.00, 10, true, 'approved', 4.8, 40),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Wooden Coffee Table', 'wooden-coffee-table', 'Solid oak wood.', 150.00, 20, true, 'approved', 4.7, 35),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Floor Lamp', 'floor-lamp', 'Warm ambient lighting.', 80.00, 40, true, 'approved', 4.6, 50),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Ceramic Vase', 'ceramic-vase', 'Handcrafted beauty.', 30.00, 60, true, 'approved', 4.8, 25),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Cotton Bed Sheets', 'cotton-bed-sheets', 'Soft and breathable.', 45.00, 80, true, 'approved', 4.5, 90),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Wall Art Print', 'wall-art-print', 'Abstract design.', 25.00, 100, true, 'approved', 4.4, 30),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Indoor Plant Pot', 'indoor-plant-pot', 'Minimalist design.', 15.00, 120, true, 'approved', 4.7, 60),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Kitchen Knife Set', 'kitchen-knife-set', 'Professional grade.', 90.00, 30, true, 'approved', 4.8, 45),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Non-Stick Frying Pan', 'non-stick-frying-pan', 'Easy cooking.', 35.00, 70, true, 'approved', 4.6, 80),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Bath Towel Set', 'bath-towel-set', 'Plush and absorbent.', 40.00, 60, true, 'approved', 4.5, 55),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Scented Candle', 'scented-candle', 'Relaxing lavender.', 18.00, 150, true, 'approved', 4.8, 100),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Throw Pillow', 'throw-pillow', 'Decorative accent.', 22.00, 90, true, 'approved', 4.6, 40);

    -- Insert Images for Home & Living (using local assets)
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/modern-sofa.png', true FROM products WHERE slug = 'modern-sofa';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/wooden-coffee-table.png', true FROM products WHERE slug = 'wooden-coffee-table';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/wooden-coffee-table.png', true FROM products WHERE slug = 'floor-lamp';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/wooden-coffee-table.png', true FROM products WHERE slug = 'ceramic-vase';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/modern-sofa.png', true FROM products WHERE slug = 'cotton-bed-sheets';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/wooden-coffee-table.png', true FROM products WHERE slug = 'wall-art-print';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/wooden-coffee-table.png', true FROM products WHERE slug = 'indoor-plant-pot';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/wooden-coffee-table.png', true FROM products WHERE slug = 'kitchen-knife-set';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/wooden-coffee-table.png', true FROM products WHERE slug = 'non-stick-frying-pan';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/modern-sofa.png', true FROM products WHERE slug = 'bath-towel-set';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/wooden-coffee-table.png', true FROM products WHERE slug = 'scented-candle';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/modern-sofa.png', true FROM products WHERE slug = 'throw-pillow';

END $$;

-- ==============================================================================
-- SETUP COMPLETE!
-- ==============================================================================
-- Next Steps:
-- 1. Create your first admin account by signing up with email: umorfaruksupto@gmail.com
-- 2. Log in to the admin panel
-- 3. Approve seller registrations
-- 4. Add/approve products
-- 5. Configure payment gateway settings
-- 6. Customize CMS banners and pages
-- ==============================================================================
-- ==============================================================================
-- SEED DATA FOR PRODUCTS WITH LOCAL IMAGES (60 ITEMS)
-- ==============================================================================

DO $$
DECLARE
    v_admin_id UUID;
    v_seller_id UUID;
    v_shop_id UUID;
    v_cat_smartphones UUID;
    v_cat_laptops UUID;
    v_cat_mens_fashion UUID;
    v_cat_womens_fashion UUID;
    v_cat_home UUID;
    v_brand_apple UUID;
    v_brand_samsung UUID;
    v_brand_nike UUID;
    v_brand_adidas UUID;
    v_brand_sony UUID;
BEGIN
    -- 1. Get Admin User ID (prefer the known admin email, otherwise any existing user)
    SELECT id INTO v_admin_id FROM auth.users WHERE email = 'umorfaruksupto@gmail.com' LIMIT 1;
    IF v_admin_id IS NULL THEN
        SELECT id INTO v_admin_id FROM auth.users LIMIT 1;
    END IF;

    -- If still null, abort with a clear message so we do not insert a NULL user_id
    IF v_admin_id IS NULL THEN
        RAISE EXCEPTION 'No users found. Please create an auth user (e.g., sign up admin umorfaruksupto@gmail.com) before running seed-products.sql';
    END IF;
    
    -- 2. Ensure Seller Profile Exists for this user
    INSERT INTO seller_profiles (user_id, business_name, business_type, status)
    VALUES (v_admin_id, 'Bongo Tech Store', 'Company', 'approved')
    ON CONFLICT (user_id) DO UPDATE SET status = 'approved'
    RETURNING id INTO v_seller_id;

    -- 3. Ensure Shop Exists
    INSERT INTO shops (seller_id, name, slug, description)
    VALUES (v_seller_id, 'Bongo Official Store', 'bongo-official', 'The official store for BongoPortus products.')
    ON CONFLICT (seller_id) DO UPDATE SET name = 'Bongo Official Store'
    RETURNING id INTO v_shop_id;

    -- 4. Get Category IDs
    SELECT id INTO v_cat_smartphones FROM categories WHERE slug = 'smartphones';
    SELECT id INTO v_cat_laptops FROM categories WHERE slug = 'laptops';
    SELECT id INTO v_cat_mens_fashion FROM categories WHERE slug = 'mens-fashion';
    SELECT id INTO v_cat_womens_fashion FROM categories WHERE slug = 'womens-fashion';
    SELECT id INTO v_cat_home FROM categories WHERE slug = 'home-living';

    -- 5. Get Brand IDs
    SELECT id INTO v_brand_apple FROM brands WHERE slug = 'apple';
    SELECT id INTO v_brand_samsung FROM brands WHERE slug = 'samsung';
    SELECT id INTO v_brand_nike FROM brands WHERE slug = 'nike';
    SELECT id INTO v_brand_adidas FROM brands WHERE slug = 'adidas';
    SELECT id INTO v_brand_sony FROM brands WHERE slug = 'sony';

    -- 6. Insert Products (Batch 1: Smartphones - 12 items)
    INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, stock_quantity, is_active, approval_status, rating, total_reviews) VALUES
    (v_seller_id, v_shop_id, v_cat_smartphones, v_brand_apple, 'iPhone 15 Pro Max', 'iphone-15-pro-max-titanium', 'The ultimate iPhone with titanium design.', 1499.00, 50, true, 'approved', 4.9, 120),
    (v_seller_id, v_shop_id, v_cat_smartphones, v_brand_apple, 'iPhone 15 Pro', 'iphone-15-pro-blue', 'Pro camera system, pro performance.', 1299.00, 45, true, 'approved', 4.8, 95),
    (v_seller_id, v_shop_id, v_cat_smartphones, v_brand_apple, 'iPhone 14', 'iphone-14-midnight', 'Full of fantastic features.', 999.00, 100, true, 'approved', 4.7, 200),
    (v_seller_id, v_shop_id, v_cat_smartphones, v_brand_samsung, 'Samsung Galaxy S24 Ultra', 'samsung-s24-ultra', 'Galaxy AI is here.', 1399.00, 60, true, 'approved', 4.9, 80),
    (v_seller_id, v_shop_id, v_cat_smartphones, v_brand_samsung, 'Samsung Galaxy S24+', 'samsung-s24-plus', 'Epic moments, now accessible.', 1199.00, 55, true, 'approved', 4.7, 60),
    (v_seller_id, v_shop_id, v_cat_smartphones, v_brand_samsung, 'Samsung Galaxy Z Fold 5', 'samsung-z-fold-5', 'Unfold your world.', 1799.00, 30, true, 'approved', 4.6, 40),
    (v_seller_id, v_shop_id, v_cat_smartphones, v_brand_sony, 'Sony Xperia 1 V', 'sony-xperia-1-v', 'Next-gen sensor. Next-gen imaging.', 1199.00, 20, true, 'approved', 4.5, 25),
    (v_seller_id, v_shop_id, v_cat_smartphones, NULL, 'Google Pixel 8 Pro', 'google-pixel-8-pro', 'The AI-first phone from Google.', 999.00, 40, true, 'approved', 4.7, 150),
    (v_seller_id, v_shop_id, v_cat_smartphones, NULL, 'Google Pixel 8', 'google-pixel-8', 'Powerful, helpful, and personal.', 699.00, 50, true, 'approved', 4.6, 110),
    (v_seller_id, v_shop_id, v_cat_smartphones, NULL, 'OnePlus 12', 'oneplus-12', 'Smooth beyond belief.', 799.00, 35, true, 'approved', 4.5, 70),
    (v_seller_id, v_shop_id, v_cat_smartphones, NULL, 'Nothing Phone (2)', 'nothing-phone-2', 'Come to the bright side.', 599.00, 25, true, 'approved', 4.4, 45),
    (v_seller_id, v_shop_id, v_cat_smartphones, NULL, 'Xiaomi 14 Ultra', 'xiaomi-14-ultra', 'Lens to legend.', 1099.00, 15, true, 'approved', 4.6, 30);

    -- Insert Images for Smartphones (using LOCAL images)
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/iphone-15-pro.png', true FROM products WHERE slug = 'iphone-15-pro-max-titanium';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/iphone-15-pro.png', true FROM products WHERE slug = 'iphone-15-pro-blue';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/iphone-15-pro.png', true FROM products WHERE slug = 'iphone-14-midnight';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/samsung-galaxy-s24.png', true FROM products WHERE slug = 'samsung-s24-ultra';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/samsung-galaxy-s24.png', true FROM products WHERE slug = 'samsung-s24-plus';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/samsung-galaxy-s24.png', true FROM products WHERE slug = 'samsung-z-fold-5';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/google-pixel-8.png', true FROM products WHERE slug = 'sony-xperia-1-v';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/google-pixel-8.png', true FROM products WHERE slug = 'google-pixel-8-pro';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/google-pixel-8.png', true FROM products WHERE slug = 'google-pixel-8';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/oneplus-12.png', true FROM products WHERE slug = 'oneplus-12';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/oneplus-12.png', true FROM products WHERE slug = 'nothing-phone-2';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/smartphones/oneplus-12.png', true FROM products WHERE slug = 'xiaomi-14-ultra';


    -- 7. Insert Products (Batch 2: Laptops - 12 items)
    INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, stock_quantity, is_active, approval_status, rating, total_reviews) VALUES
    (v_seller_id, v_shop_id, v_cat_laptops, v_brand_apple, 'MacBook Pro 16 M3 Max', 'macbook-pro-16-m3', 'Mind-blowing. Head-turning.', 3499.00, 20, true, 'approved', 4.9, 50),
    (v_seller_id, v_shop_id, v_cat_laptops, v_brand_apple, 'MacBook Air 15 M2', 'macbook-air-15-m2', 'Impressively big. Impossibly thin.', 1299.00, 60, true, 'approved', 4.8, 120),
    (v_seller_id, v_shop_id, v_cat_laptops, v_brand_apple, 'MacBook Pro 14 M3', 'macbook-pro-14-m3', 'Serious power.', 1599.00, 40, true, 'approved', 4.8, 80),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'Dell XPS 15', 'dell-xps-15', 'Immersive display. Premium design.', 1899.00, 30, true, 'approved', 4.6, 60),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'Dell XPS 13 Plus', 'dell-xps-13-plus', 'Twice as powerful as before.', 1399.00, 35, true, 'approved', 4.5, 45),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'HP Spectre x360', 'hp-spectre-x360', 'Craftsmanship meets power.', 1499.00, 25, true, 'approved', 4.7, 55),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'Lenovo ThinkPad X1 Carbon', 'lenovo-thinkpad-x1', 'Ultralight. Ultra-powerful.', 1699.00, 40, true, 'approved', 4.8, 90),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'Asus ROG Zephyrus G14', 'asus-rog-zephyrus-g14', 'World''s most powerful 14-inch gaming laptop.', 1599.00, 30, true, 'approved', 4.7, 75),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'Razer Blade 16', 'razer-blade-16', 'Fastest display. Most powerful graphics.', 2999.00, 15, true, 'approved', 4.6, 35),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'Microsoft Surface Laptop 5', 'surface-laptop-5', 'Style and speed.', 999.00, 50, true, 'approved', 4.5, 65),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'Acer Swift Go 14', 'acer-swift-go-14', 'Ready to go.', 799.00, 45, true, 'approved', 4.4, 40),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'MSI Raider GE78', 'msi-raider-ge78', 'Light ''em up.', 2499.00, 10, true, 'approved', 4.5, 20);

    -- Insert Images for Laptops (using LOCAL images)
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/macbook-pro-16.png', true FROM products WHERE slug = 'macbook-pro-16-m3';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/macbook-pro-16.png', true FROM products WHERE slug = 'macbook-air-15-m2';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/macbook-pro-16.png', true FROM products WHERE slug = 'macbook-pro-14-m3';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/dell-xps-15.png', true FROM products WHERE slug = 'dell-xps-15';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/dell-xps-15.png', true FROM products WHERE slug = 'dell-xps-13-plus';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/dell-xps-15.png', true FROM products WHERE slug = 'hp-spectre-x360';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/dell-xps-15.png', true FROM products WHERE slug = 'lenovo-thinkpad-x1';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/gaming-laptop.png', true FROM products WHERE slug = 'asus-rog-zephyrus-g14';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/gaming-laptop.png', true FROM products WHERE slug = 'razer-blade-16';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/dell-xps-15.png', true FROM products WHERE slug = 'surface-laptop-5';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/dell-xps-15.png', true FROM products WHERE slug = 'acer-swift-go-14';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/laptops/gaming-laptop.png', true FROM products WHERE slug = 'msi-raider-ge78';


    -- 8. Insert Products (Batch 3: Mens Fashion - 12 items)
    INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, stock_quantity, is_active, approval_status, rating, total_reviews) VALUES
    (v_seller_id, v_shop_id, v_cat_mens_fashion, v_brand_nike, 'Nike Air Max 270', 'nike-air-max-270', 'Big air. Bold look.', 150.00, 100, true, 'approved', 4.8, 300),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, v_brand_nike, 'Nike Tech Fleece Hoodie', 'nike-tech-fleece', 'Warmth without weight.', 110.00, 80, true, 'approved', 4.7, 150),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, v_brand_adidas, 'Adidas Ultraboost Light', 'adidas-ultraboost', 'Epic energy.', 190.00, 60, true, 'approved', 4.8, 200),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, v_brand_adidas, 'Adidas Essentials Tracksuit', 'adidas-tracksuit', 'Classic comfort.', 80.00, 90, true, 'approved', 4.6, 120),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Classic Denim Jacket', 'classic-denim-jacket', 'Timeless style.', 60.00, 70, true, 'approved', 4.5, 80),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Slim Fit Chinos', 'slim-fit-chinos', 'Versatile and comfortable.', 45.00, 120, true, 'approved', 4.4, 90),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Oxford Cotton Shirt', 'oxford-cotton-shirt', 'Sharp and professional.', 55.00, 100, true, 'approved', 4.6, 110),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Leather Chelsea Boots', 'leather-chelsea-boots', 'Sleek and durable.', 120.00, 40, true, 'approved', 4.7, 60),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Casual White Sneakers', 'casual-white-sneakers', 'Everyday essential.', 70.00, 150, true, 'approved', 4.5, 180),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Puffer Jacket', 'mens-puffer-jacket', 'Winter ready.', 130.00, 50, true, 'approved', 4.8, 70),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Graphic Print T-Shirt', 'graphic-print-tshirt', 'Express yourself.', 25.00, 200, true, 'approved', 4.3, 140),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Cargo Pants', 'mens-cargo-pants', 'Utility meets style.', 50.00, 85, true, 'approved', 4.4, 95);

    -- Insert Images for Mens Fashion (using LOCAL images)
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/nike-air-max.png', true FROM products WHERE slug = 'nike-air-max-270';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/tech-fleece-hoodie.png', true FROM products WHERE slug = 'nike-tech-fleece';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/adidas-ultraboost.png', true FROM products WHERE slug = 'adidas-ultraboost';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/tech-fleece-hoodie.png', true FROM products WHERE slug = 'adidas-tracksuit';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/nike-air-max.png', true FROM products WHERE slug = 'classic-denim-jacket';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/adidas-ultraboost.png', true FROM products WHERE slug = 'slim-fit-chinos';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/tech-fleece-hoodie.png', true FROM products WHERE slug = 'oxford-cotton-shirt';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/nike-air-max.png', true FROM products WHERE slug = 'leather-chelsea-boots';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/adidas-ultraboost.png', true FROM products WHERE slug = 'casual-white-sneakers';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/tech-fleece-hoodie.png', true FROM products WHERE slug = 'mens-puffer-jacket';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/tech-fleece-hoodie.png', true FROM products WHERE slug = 'graphic-print-tshirt';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/mens-fashion/adidas-ultraboost.png', true FROM products WHERE slug = 'mens-cargo-pants';


    -- 9. Insert Products (Batch 4: Womens Fashion - 12 items)
    INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, stock_quantity, is_active, approval_status, rating, total_reviews) VALUES
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Floral Summer Dress', 'floral-summer-dress', 'Breezy and beautiful.', 45.00, 80, true, 'approved', 4.7, 110),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'High-Waisted Jeans', 'high-waisted-jeans', 'Flattering fit.', 55.00, 100, true, 'approved', 4.6, 130),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Oversized Blazer', 'oversized-blazer', 'Chic and professional.', 85.00, 40, true, 'approved', 4.8, 60),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Silk Blouse', 'silk-blouse', 'Luxurious feel.', 70.00, 50, true, 'approved', 4.7, 45),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Pleated Midi Skirt', 'pleated-midi-skirt', 'Elegant movement.', 50.00, 60, true, 'approved', 4.5, 75),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Leather Handbag', 'leather-handbag', 'Everyday essential.', 120.00, 30, true, 'approved', 4.9, 90),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Ankle Boots', 'ankle-boots', 'Stylish and sturdy.', 90.00, 55, true, 'approved', 4.6, 85),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Knitted Sweater', 'knitted-sweater', 'Cozy comfort.', 60.00, 70, true, 'approved', 4.8, 100),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Statement Earrings', 'statement-earrings', 'Bold accessory.', 20.00, 150, true, 'approved', 4.4, 50),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Trench Coat', 'womens-trench-coat', 'Classic outerwear.', 140.00, 35, true, 'approved', 4.8, 65),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Yoga Leggings', 'yoga-leggings', 'Stretch and support.', 35.00, 120, true, 'approved', 4.7, 140),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Evening Gown', 'evening-gown', 'For special occasions.', 180.00, 20, true, 'approved', 4.9, 30);

    -- Insert Images for Womens Fashion (using LOCAL images)
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/floral-summer-dress.png', true FROM products WHERE slug = 'floral-summer-dress';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/high-waisted-jeans.png', true FROM products WHERE slug = 'high-waisted-jeans';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/floral-summer-dress.png', true FROM products WHERE slug = 'oversized-blazer';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/floral-summer-dress.png', true FROM products WHERE slug = 'silk-blouse';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/high-waisted-jeans.png', true FROM products WHERE slug = 'pleated-midi-skirt';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/leather-handbag.png', true FROM products WHERE slug = 'leather-handbag';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/leather-handbag.png', true FROM products WHERE slug = 'ankle-boots';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/floral-summer-dress.png', true FROM products WHERE slug = 'knitted-sweater';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/leather-handbag.png', true FROM products WHERE slug = 'statement-earrings';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/floral-summer-dress.png', true FROM products WHERE slug = 'womens-trench-coat';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/high-waisted-jeans.png', true FROM products WHERE slug = 'yoga-leggings';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/womens-fashion/floral-summer-dress.png', true FROM products WHERE slug = 'evening-gown';


    -- 10. Insert Products (Batch 5: Home & Living - 12 items)
    INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, stock_quantity, is_active, approval_status, rating, total_reviews) VALUES
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Modern Sofa', 'modern-sofa', 'Comfortable and stylish.', 599.00, 10, true, 'approved', 4.8, 40),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Wooden Coffee Table', 'wooden-coffee-table', 'Solid oak wood.', 150.00, 20, true, 'approved', 4.7, 35),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Floor Lamp', 'floor-lamp', 'Warm ambient lighting.', 80.00, 40, true, 'approved', 4.6, 50),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Ceramic Vase', 'ceramic-vase', 'Handcrafted beauty.', 30.00, 60, true, 'approved', 4.8, 25),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Cotton Bed Sheets', 'cotton-bed-sheets', 'Soft and breathable.', 45.00, 80, true, 'approved', 4.5, 90),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Wall Art Print', 'wall-art-print', 'Abstract design.', 25.00, 100, true, 'approved', 4.4, 30),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Indoor Plant Pot', 'indoor-plant-pot', 'Minimalist design.', 15.00, 120, true, 'approved', 4.7, 60),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Kitchen Knife Set', 'kitchen-knife-set', 'Professional grade.', 90.00, 30, true, 'approved', 4.8, 45),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Non-Stick Frying Pan', 'non-stick-frying-pan', 'Easy cooking.', 35.00, 70, true, 'approved', 4.6, 80),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Bath Towel Set', 'bath-towel-set', 'Plush and absorbent.', 40.00, 60, true, 'approved', 4.5, 55),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Scented Candle', 'scented-candle', 'Relaxing lavender.', 18.00, 150, true, 'approved', 4.8, 100),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Throw Pillow', 'throw-pillow', 'Decorative accent.', 22.00, 90, true, 'approved', 4.6, 40);

    -- Insert Images for Home & Living (using LOCAL images)
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/modern-sofa.png', true FROM products WHERE slug = 'modern-sofa';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/wooden-coffee-table.png', true FROM products WHERE slug = 'wooden-coffee-table';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/wooden-coffee-table.png', true FROM products WHERE slug = 'floor-lamp';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/wooden-coffee-table.png', true FROM products WHERE slug = 'ceramic-vase';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/modern-sofa.png', true FROM products WHERE slug = 'cotton-bed-sheets';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/wooden-coffee-table.png', true FROM products WHERE slug = 'wall-art-print';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/wooden-coffee-table.png', true FROM products WHERE slug = 'indoor-plant-pot';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/wooden-coffee-table.png', true FROM products WHERE slug = 'kitchen-knife-set';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/wooden-coffee-table.png', true FROM products WHERE slug = 'non-stick-frying-pan';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/modern-sofa.png', true FROM products WHERE slug = 'bath-towel-set';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/wooden-coffee-table.png', true FROM products WHERE slug = 'scented-candle';
    INSERT INTO product_images (product_id, image_url, is_primary) 
    SELECT id, '/images/products/home-living/modern-sofa.png', true FROM products WHERE slug = 'throw-pillow';

END $$;
