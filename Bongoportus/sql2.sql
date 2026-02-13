-- ==============================================================================
-- SQL2: FUNCTIONS, TRIGGERS, RLS POLICIES, STORAGE, BASE DATA
-- Run this SECOND (after sql1.sql)
-- ==============================================================================

-- 1. FUNCTIONS

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

-- Trigger for new user
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Update product rating function
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

-- Get or create support conversation (for chat system)
CREATE OR REPLACE FUNCTION public.get_or_create_support_conversation(p_user_id UUID)
RETURNS UUID AS $$
DECLARE
    conv_id UUID;
BEGIN
    SELECT id INTO conv_id
    FROM conversations
    WHERE type = 'buyer_admin' 
      AND buyer_id = p_user_id 
      AND status = 'active'
    LIMIT 1;

    IF conv_id IS NOT NULL THEN
        RETURN conv_id;
    END IF;

    INSERT INTO conversations (type, buyer_id, subject, status)
    VALUES ('buyer_admin', p_user_id, 'Support Chat', 'active')
    RETURNING id INTO conv_id;

    RETURN conv_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. RLS ENABLE
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

-- 3. RLS POLICIES

-- Profiles
CREATE POLICY "Public profiles viewable" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users create own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Products
CREATE POLICY "Products viewable" ON products FOR SELECT USING (true);
CREATE POLICY "Admins insert products" ON products FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Admins update products" ON products FOR UPDATE USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Admins delete products" ON products FOR DELETE USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Sellers insert own products" ON products FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM seller_profiles sp WHERE sp.id = seller_id AND sp.user_id = auth.uid()));
CREATE POLICY "Sellers update own products" ON products FOR UPDATE USING (EXISTS (SELECT 1 FROM seller_profiles sp WHERE sp.id = seller_id AND sp.user_id = auth.uid()));
CREATE POLICY "Sellers delete own products" ON products FOR DELETE USING (EXISTS (SELECT 1 FROM seller_profiles sp WHERE sp.id = seller_id AND sp.user_id = auth.uid()));

-- Conversations
CREATE POLICY "Users view conversations" ON conversations FOR SELECT USING (
    buyer_id = auth.uid() OR
    EXISTS (SELECT 1 FROM seller_profiles sp WHERE sp.id = seller_id AND sp.user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Users create conversations" ON conversations FOR INSERT WITH CHECK (
    buyer_id = auth.uid() OR
    EXISTS (SELECT 1 FROM seller_profiles sp WHERE sp.id = seller_id AND sp.user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Users update conversations" ON conversations FOR UPDATE USING (
    buyer_id = auth.uid() OR
    EXISTS (SELECT 1 FROM seller_profiles sp WHERE sp.id = seller_id AND sp.user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Messages (FIXED for chat system)
CREATE POLICY "Users view messages" ON messages FOR SELECT USING (
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
);

CREATE POLICY "Users send messages" ON messages FOR INSERT WITH CHECK (
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

-- Inquiries
CREATE POLICY "Users view own inquiries" ON inquiries FOR SELECT USING (
    user_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Users create inquiries" ON inquiries FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Admins update inquiries" ON inquiries FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Orders
CREATE POLICY "Users view own orders" ON orders FOR SELECT USING (user_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Users create orders" ON orders FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Admins update orders" ON orders FOR UPDATE USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- Order Items
CREATE POLICY "Users view own order items" ON order_items FOR SELECT USING (
    EXISTS (SELECT 1 FROM orders WHERE id = order_id AND user_id = auth.uid()) OR 
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Users create order items" ON order_items FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM orders WHERE id = order_id AND user_id = auth.uid())
);

-- User Addresses
CREATE POLICY "Users view own addresses" ON user_addresses FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users insert own addresses" ON user_addresses FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users update own addresses" ON user_addresses FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users delete own addresses" ON user_addresses FOR DELETE USING (user_id = auth.uid());

-- Cart Items
CREATE POLICY "Users view own cart" ON cart_items FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users add to cart" ON cart_items FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users update cart" ON cart_items FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users delete from cart" ON cart_items FOR DELETE USING (user_id = auth.uid());

-- Support Tickets
CREATE POLICY "Users view own tickets" ON support_tickets FOR SELECT USING (
    user_id = auth.uid() OR assigned_to = auth.uid() OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Users create tickets" ON support_tickets FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Admins update tickets" ON support_tickets FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Ticket Messages
CREATE POLICY "View ticket messages" ON ticket_messages FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM support_tickets st WHERE st.id = ticket_id AND (
            st.user_id = auth.uid() OR st.assigned_to = auth.uid() OR
            EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
        )
    ) AND (NOT is_internal OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'))
);
CREATE POLICY "Send ticket messages" ON ticket_messages FOR INSERT WITH CHECK (
    sender_id = auth.uid() AND EXISTS (
        SELECT 1 FROM support_tickets st WHERE st.id = ticket_id AND (
            st.user_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
        )
    )
);

-- 4. STORAGE BUCKETS
INSERT INTO storage.buckets (id, name, public) VALUES 
('product-images', 'product-images', true),
('chat-attachments', 'chat-attachments', true),
('seller-documents', 'seller-documents', false)
ON CONFLICT (id) DO NOTHING;

-- Storage Policies
DROP POLICY IF EXISTS "Anyone view product images" ON storage.objects;
CREATE POLICY "Anyone view product images" ON storage.objects FOR SELECT USING (bucket_id = 'product-images');
DROP POLICY IF EXISTS "Auth upload product images" ON storage.objects;
CREATE POLICY "Auth upload product images" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'product-images' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Anyone view chat images" ON storage.objects;
CREATE POLICY "Anyone view chat images" ON storage.objects FOR SELECT USING (bucket_id = 'chat-attachments');
DROP POLICY IF EXISTS "Auth upload chat images" ON storage.objects;
CREATE POLICY "Auth upload chat images" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'chat-attachments' AND auth.uid() IS NOT NULL);

-- 5. SEED BASE DATA (Categories, Brands, Coupons, CMS)

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

-- Coupons
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

-- Banners
INSERT INTO cms_banners (title, image_url, link, position, display_order) VALUES
('Winter Sale 2025', 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=1200&h=400&fit=crop', '/category/fashion', 'home_hero', 1),
('Electronics Mega Sale', 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=1200&h=400&fit=crop', '/category/electronics', 'home_hero', 2);

-- SQL2 COMPLETE
-- Now sign up your admin user (umorfaruksupto@gmail.com) in the app
-- Then run SQL3.sql to seed products
