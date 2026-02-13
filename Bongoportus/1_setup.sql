-- ==============================================================================
-- 1. SETUP SCHEMA (RUN THIS FIRST)
-- ==============================================================================

-- ==============================================================================
-- CLEANUP
-- ==============================================================================
-- Drop all triggers first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS update_product_rating ON reviews;

-- Drop all functions with CASCADE
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.update_product_rating() CASCADE;
DROP FUNCTION IF EXISTS public.get_or_create_support_conversation(UUID) CASCADE;

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
-- SETUP EXTENSIONS
-- ==============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- CREATE TABLES
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
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- C. Seller Profiles
CREATE TABLE seller_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    business_name TEXT NOT NULL,
    business_type TEXT,
    commission_rate NUMERIC DEFAULT 15.0,
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
    document_type TEXT NOT NULL,
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
    weight NUMERIC,
    dimensions TEXT,
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

-- J. Product Variants
CREATE TABLE product_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    variant_type TEXT NOT NULL,
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
    order_id UUID,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title TEXT,
    comment TEXT,
    image_urls TEXT[],
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
    delivery_full_name TEXT NOT NULL,
    delivery_phone TEXT NOT NULL,
    delivery_address_line1 TEXT NOT NULL,
    delivery_address_line2 TEXT,
    delivery_city TEXT NOT NULL,
    delivery_state TEXT NOT NULL,
    delivery_postal_code TEXT NOT NULL,
    delivery_country TEXT DEFAULT 'Bangladesh',
    subtotal NUMERIC NOT NULL,
    discount_amount NUMERIC DEFAULT 0,
    coupon_code TEXT,
    shipping_charge NUMERIC DEFAULT 0,
    tax_amount NUMERIC DEFAULT 0,
    total_amount NUMERIC NOT NULL,
    payment_method TEXT NOT NULL,
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
    stripe_payment_intent_id TEXT,
    stripe_charge_id TEXT,
    order_status TEXT DEFAULT 'pending' CHECK (order_status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'returned')),
    tracking_number TEXT,
    courier_name TEXT,
    estimated_delivery TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
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
    variant_details TEXT,
    quantity INTEGER NOT NULL,
    unit_price NUMERIC NOT NULL,
    total_price NUMERIC NOT NULL,
    commission_rate NUMERIC NOT NULL,
    commission_amount NUMERIC NOT NULL,
    seller_earnings NUMERIC NOT NULL,
    item_status TEXT DEFAULT 'pending' CHECK (item_status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'returned')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Q. Transactions
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID REFERENCES seller_profiles(id) ON DELETE CASCADE,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    transaction_type TEXT NOT NULL,
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
    payment_method TEXT NOT NULL,
    account_details JSONB NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed')),
    rejection_reason TEXT,
    requested_at TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ
);

-- S. Inquiries
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

-- U. Conversations (Moved up because Messages references it)
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

-- T. Messages
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inquiry_id UUID REFERENCES inquiries(id) ON DELETE CASCADE,
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE, -- ADDED
    sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    attachment_url TEXT, -- ADDED/RENAMED from image_url (better name, standardizing)
    image_url TEXT, -- Keeping old likely for compat or just use attachment_url
    sender_type TEXT CHECK (sender_type IN ('buyer', 'seller', 'admin')), -- ADDED for clarity
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- V. Support Tickets
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

-- S2. Ticket Messages
CREATE TABLE ticket_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    attachment_url TEXT,
    is_internal BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- U. Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
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
    position TEXT DEFAULT 'home_hero',
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    valid_from TIMESTAMPTZ DEFAULT NOW(),
    valid_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- W. CMS Pages
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
-- INDEXES
-- ==============================================================================
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_user_addresses_user_id ON user_addresses(user_id);
CREATE INDEX idx_seller_profiles_user_id ON seller_profiles(user_id);
CREATE INDEX idx_products_seller_id ON products(seller_id);
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_slug ON products(slug);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_inquiry_id ON messages(inquiry_id);
CREATE INDEX idx_conversations_buyer_id ON conversations(buyer_id);
CREATE INDEX idx_conversations_seller_id ON conversations(seller_id);

-- ==============================================================================
-- FUNCTIONS & TRIGGERS
-- ==============================================================================

-- Handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
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

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Update product rating
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

CREATE TRIGGER update_product_rating
    AFTER INSERT OR UPDATE ON reviews
    FOR EACH ROW EXECUTE FUNCTION public.update_product_rating();

-- Get or create support conversation
CREATE OR REPLACE FUNCTION public.get_or_create_support_conversation(user_id UUID)
RETURNS UUID AS $$
DECLARE
    conv_id UUID;
BEGIN
    -- Try to find existing active support conversation
    SELECT id INTO conv_id
    FROM conversations
    WHERE type = 'buyer_admin' 
      AND buyer_id = user_id 
      AND status = 'active'
    LIMIT 1;

    -- If found, return it
    IF conv_id IS NOT NULL THEN
        RETURN conv_id;
    END IF;

    -- Create new conversation
    INSERT INTO conversations (type, buyer_id, subject, status)
    VALUES ('buyer_admin', user_id, 'Support Chat', 'active')
    RETURNING id INTO conv_id;

    RETURN conv_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==============================================================================
-- RLS POLICIES
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

-- Profiles
CREATE POLICY "Public profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can create own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Products
CREATE POLICY "Products are viewable by everyone" ON products FOR SELECT USING (true);
CREATE POLICY "Admins can insert products" ON products FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Admins can update all products" ON products FOR UPDATE USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Admins can delete products" ON products FOR DELETE USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Sellers can insert own products" ON products FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM seller_profiles sp WHERE sp.id = seller_id AND sp.user_id = auth.uid()));
CREATE POLICY "Sellers can update own products" ON products FOR UPDATE USING (EXISTS (SELECT 1 FROM seller_profiles sp WHERE sp.id = seller_id AND sp.user_id = auth.uid()));
CREATE POLICY "Sellers can delete own products" ON products FOR DELETE USING (EXISTS (SELECT 1 FROM seller_profiles sp WHERE sp.id = seller_id AND sp.user_id = auth.uid()));

-- Conversations
CREATE POLICY "Users can view their conversations" ON conversations FOR SELECT USING (
    buyer_id = auth.uid() OR
    EXISTS (SELECT 1 FROM seller_profiles sp WHERE sp.id = seller_id AND sp.user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Users can create conversations" ON conversations FOR INSERT WITH CHECK (
    buyer_id = auth.uid() OR
    EXISTS (SELECT 1 FROM seller_profiles sp WHERE sp.id = seller_id AND sp.user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Users can update conversations" ON conversations FOR UPDATE USING (
    buyer_id = auth.uid() OR
    EXISTS (SELECT 1 FROM seller_profiles sp WHERE sp.id = seller_id AND sp.user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Messages (UPDATED)
CREATE POLICY "Users can view their messages" ON messages FOR SELECT USING (
    -- Linked to an inquiry they own
    (inquiry_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM inquiries i WHERE i.id = inquiry_id AND (
            i.user_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
        )
    )) 
    OR
    -- Linked to a conversation they are part of
    (conversation_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM conversations c WHERE c.id = conversation_id AND (
            c.buyer_id = auth.uid() OR
            c.seller_id IN (SELECT id FROM seller_profiles WHERE user_id = auth.uid()) OR
            EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
        )
    ))
);

CREATE POLICY "Users can send messages" ON messages FOR INSERT WITH CHECK (
    sender_id = auth.uid() AND (
        (inquiry_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM inquiries i WHERE i.id = inquiry_id AND (
                i.user_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
            )
        )) 
        OR
        (conversation_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM conversations c WHERE c.id = conversation_id AND (
                c.buyer_id = auth.uid() OR
                c.seller_id IN (SELECT id FROM seller_profiles WHERE user_id = auth.uid()) OR
                EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
            )
        ))
    )
);

-- Basic Policies for other tables (Add more if needed, keeping basic user ownership)
CREATE POLICY "Users view own orders" ON orders FOR SELECT USING (user_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Users create orders" ON orders FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users view own order items" ON order_items FOR SELECT USING (EXISTS (SELECT 1 FROM orders WHERE id = order_id AND user_id = auth.uid()) OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Users view own addresses" ON user_addresses FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users manage addresses" ON user_addresses FOR ALL USING (user_id = auth.uid());
CREATE POLICY "Users view own cart" ON cart_items FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users manage cart" ON cart_items FOR ALL USING (user_id = auth.uid());

-- Storage
INSERT INTO storage.buckets (id, name, public) VALUES 
('product-images', 'product-images', true),
('chat-attachments', 'chat-attachments', true),
('seller-documents', 'seller-documents', false)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public view product images" ON storage.objects;
CREATE POLICY "Public view product images" ON storage.objects FOR SELECT USING (bucket_id = 'product-images');
DROP POLICY IF EXISTS "Auth upload product images" ON storage.objects;
CREATE POLICY "Auth upload product images" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'product-images' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Public view chat images" ON storage.objects;
CREATE POLICY "Public view chat images" ON storage.objects FOR SELECT USING (bucket_id = 'chat-attachments');
DROP POLICY IF EXISTS "Auth upload chat images" ON storage.objects;
CREATE POLICY "Auth upload chat images" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'chat-attachments' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Public view chat images" ON storage.objects;
CREATE POLICY "Public view chat images" ON storage.objects FOR SELECT USING (bucket_id = 'chat-attachments');

-- ==============================================================================
-- 7. SUPPORT TICKETS POLICIES
-- ==============================================================================
CREATE POLICY "Users can create support tickets" 
ON support_tickets FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can update support tickets" 
ON support_tickets FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

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

