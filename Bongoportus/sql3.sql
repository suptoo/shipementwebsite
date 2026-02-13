-- ==============================================================================
-- SQL3: SEED PRODUCTS - Run this THIRD (after sql2.sql)
-- ==============================================================================
-- IMPORTANT: You must sign up a user (umorfaruksupto@gmail.com) before running this!
-- This script requires at least one user to exist in auth.users.
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
    -- 1. Get Admin User ID
    SELECT id INTO v_admin_id FROM auth.users WHERE email = 'umorfaruksupto@gmail.com' LIMIT 1;
    IF v_admin_id IS NULL THEN
        SELECT id INTO v_admin_id FROM auth.users LIMIT 1;
    END IF;

    IF v_admin_id IS NULL THEN
        RAISE EXCEPTION 'No users found. Please sign up (e.g., umorfaruksupto@gmail.com) before running sql3.sql';
    END IF;

    -- 2. Ensure Profile exists (in case trigger didn't fire)
    INSERT INTO profiles (id, email, role, is_verified)
    SELECT id, email, 'admin', true
    FROM auth.users WHERE id = v_admin_id
    ON CONFLICT (id) DO UPDATE SET role = 'admin', is_verified = true;
    
    -- 3. Ensure Seller Profile
    INSERT INTO seller_profiles (user_id, business_name, business_type, status)
    VALUES (v_admin_id, 'Bongo Tech Store', 'Company', 'approved')
    ON CONFLICT (user_id) DO UPDATE SET status = 'approved'
    RETURNING id INTO v_seller_id;

    -- 3. Ensure Shop
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

    -- 6. Smartphones (12 items)
    INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, stock_quantity, is_active, approval_status, rating, total_reviews) VALUES
    (v_seller_id, v_shop_id, v_cat_smartphones, v_brand_apple, 'iPhone 15 Pro Max', 'iphone-15-pro-max-titanium', 'The ultimate iPhone with titanium design.', 1499.00, 50, true, 'approved', 4.9, 120),
    (v_seller_id, v_shop_id, v_cat_smartphones, v_brand_apple, 'iPhone 15 Pro', 'iphone-15-pro-blue', 'Pro camera system, pro performance.', 1299.00, 45, true, 'approved', 4.8, 95),
    (v_seller_id, v_shop_id, v_cat_smartphones, v_brand_apple, 'iPhone 14', 'iphone-14-midnight', 'Full of fantastic features.', 999.00, 100, true, 'approved', 4.7, 200),
    (v_seller_id, v_shop_id, v_cat_smartphones, v_brand_samsung, 'Samsung Galaxy S24 Ultra', 'samsung-s24-ultra', 'Galaxy AI is here.', 1399.00, 60, true, 'approved', 4.9, 80),
    (v_seller_id, v_shop_id, v_cat_smartphones, v_brand_samsung, 'Samsung Galaxy S24+', 'samsung-s24-plus', 'Epic moments, now accessible.', 1199.00, 55, true, 'approved', 4.7, 60),
    (v_seller_id, v_shop_id, v_cat_smartphones, v_brand_samsung, 'Samsung Galaxy Z Fold 5', 'samsung-z-fold-5', 'Unfold your world.', 1799.00, 30, true, 'approved', 4.6, 40),
    (v_seller_id, v_shop_id, v_cat_smartphones, v_brand_sony, 'Sony Xperia 1 V', 'sony-xperia-1-v', 'Next-gen sensor.', 1199.00, 20, true, 'approved', 4.5, 25),
    (v_seller_id, v_shop_id, v_cat_smartphones, NULL, 'Google Pixel 8 Pro', 'google-pixel-8-pro', 'The AI-first phone.', 999.00, 40, true, 'approved', 4.7, 150),
    (v_seller_id, v_shop_id, v_cat_smartphones, NULL, 'Google Pixel 8', 'google-pixel-8', 'Powerful and personal.', 699.00, 50, true, 'approved', 4.6, 110),
    (v_seller_id, v_shop_id, v_cat_smartphones, NULL, 'OnePlus 12', 'oneplus-12', 'Smooth beyond belief.', 799.00, 35, true, 'approved', 4.5, 70),
    (v_seller_id, v_shop_id, v_cat_smartphones, NULL, 'Nothing Phone (2)', 'nothing-phone-2', 'Come to the bright side.', 599.00, 25, true, 'approved', 4.4, 45),
    (v_seller_id, v_shop_id, v_cat_smartphones, NULL, 'Xiaomi 14 Ultra', 'xiaomi-14-ultra', 'Lens to legend.', 1099.00, 15, true, 'approved', 4.6, 30);

    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=600&h=600&fit=crop', true FROM products WHERE slug = 'iphone-15-pro-max-titanium';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=600&h=600&fit=crop', true FROM products WHERE slug = 'iphone-15-pro-blue';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1678685888221-cda773a3dcdb?w=600&h=600&fit=crop', true FROM products WHERE slug = 'iphone-14-midnight';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=600&h=600&fit=crop', true FROM products WHERE slug = 'samsung-s24-ultra';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=600&h=600&fit=crop', true FROM products WHERE slug = 'samsung-s24-plus';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=600&h=600&fit=crop', true FROM products WHERE slug = 'samsung-z-fold-5';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=600&h=600&fit=crop', true FROM products WHERE slug = 'sony-xperia-1-v';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=600&h=600&fit=crop', true FROM products WHERE slug = 'google-pixel-8-pro';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=600&h=600&fit=crop', true FROM products WHERE slug = 'google-pixel-8';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1605236453806-6ff36851218e?w=600&h=600&fit=crop', true FROM products WHERE slug = 'oneplus-12';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1592899677977-9c10ca588bbd?w=600&h=600&fit=crop', true FROM products WHERE slug = 'nothing-phone-2';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1574944985070-8f3ebc6b79d2?w=600&h=600&fit=crop', true FROM products WHERE slug = 'xiaomi-14-ultra';

    -- 7. Laptops (12 items)
    INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, stock_quantity, is_active, approval_status, rating, total_reviews) VALUES
    (v_seller_id, v_shop_id, v_cat_laptops, v_brand_apple, 'MacBook Pro 16 M3 Max', 'macbook-pro-16-m3', 'Mind-blowing.', 3499.00, 20, true, 'approved', 4.9, 50),
    (v_seller_id, v_shop_id, v_cat_laptops, v_brand_apple, 'MacBook Air 15 M2', 'macbook-air-15-m2', 'Impossibly thin.', 1299.00, 60, true, 'approved', 4.8, 120),
    (v_seller_id, v_shop_id, v_cat_laptops, v_brand_apple, 'MacBook Pro 14 M3', 'macbook-pro-14-m3', 'Serious power.', 1599.00, 40, true, 'approved', 4.8, 80),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'Dell XPS 15', 'dell-xps-15', 'Premium design.', 1899.00, 30, true, 'approved', 4.6, 60),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'Dell XPS 13 Plus', 'dell-xps-13-plus', 'Twice as powerful.', 1399.00, 35, true, 'approved', 4.5, 45),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'HP Spectre x360', 'hp-spectre-x360', 'Craftsmanship.', 1499.00, 25, true, 'approved', 4.7, 55),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'Lenovo ThinkPad X1', 'lenovo-thinkpad-x1', 'Ultra-powerful.', 1699.00, 40, true, 'approved', 4.8, 90),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'Asus ROG Zephyrus G14', 'asus-rog-zephyrus-g14', 'Gaming beast.', 1599.00, 30, true, 'approved', 4.7, 75),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'Razer Blade 16', 'razer-blade-16', 'Most powerful.', 2999.00, 15, true, 'approved', 4.6, 35),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'Surface Laptop 5', 'surface-laptop-5', 'Style and speed.', 999.00, 50, true, 'approved', 4.5, 65),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'Acer Swift Go 14', 'acer-swift-go-14', 'Ready to go.', 799.00, 45, true, 'approved', 4.4, 40),
    (v_seller_id, v_shop_id, v_cat_laptops, NULL, 'MSI Raider GE78', 'msi-raider-ge78', 'Light em up.', 2499.00, 10, true, 'approved', 4.5, 20);

    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=600&h=600&fit=crop', true FROM products WHERE slug = 'macbook-pro-16-m3';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=600&h=600&fit=crop', true FROM products WHERE slug = 'macbook-air-15-m2';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=600&h=600&fit=crop', true FROM products WHERE slug = 'macbook-pro-14-m3';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1593642632559-0c6d3fc62b89?w=600&h=600&fit=crop', true FROM products WHERE slug = 'dell-xps-15';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1593642632559-0c6d3fc62b89?w=600&h=600&fit=crop', true FROM products WHERE slug = 'dell-xps-13-plus';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=600&h=600&fit=crop', true FROM products WHERE slug = 'hp-spectre-x360';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=600&h=600&fit=crop', true FROM products WHERE slug = 'lenovo-thinkpad-x1';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1603302576837-37561b2e2302?w=600&h=600&fit=crop', true FROM products WHERE slug = 'asus-rog-zephyrus-g14';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1603302576837-37561b2e2302?w=600&h=600&fit=crop', true FROM products WHERE slug = 'razer-blade-16';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1587614382346-4ec70e388b28?w=600&h=600&fit=crop', true FROM products WHERE slug = 'surface-laptop-5';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1525547719571-a2d4ac8945e2?w=600&h=600&fit=crop', true FROM products WHERE slug = 'acer-swift-go-14';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1603302576837-37561b2e2302?w=600&h=600&fit=crop', true FROM products WHERE slug = 'msi-raider-ge78';

    -- 8. Mens Fashion (12 items)
    INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, stock_quantity, is_active, approval_status, rating, total_reviews) VALUES
    (v_seller_id, v_shop_id, v_cat_mens_fashion, v_brand_nike, 'Nike Air Max 270', 'nike-air-max-270', 'Big air. Bold look.', 150.00, 100, true, 'approved', 4.8, 300),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, v_brand_nike, 'Nike Tech Fleece Hoodie', 'nike-tech-fleece', 'Warmth without weight.', 110.00, 80, true, 'approved', 4.7, 150),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, v_brand_adidas, 'Adidas Ultraboost Light', 'adidas-ultraboost', 'Epic energy.', 190.00, 60, true, 'approved', 4.8, 200),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, v_brand_adidas, 'Adidas Tracksuit', 'adidas-tracksuit', 'Classic comfort.', 80.00, 90, true, 'approved', 4.6, 120),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Classic Denim Jacket', 'classic-denim-jacket', 'Timeless style.', 60.00, 70, true, 'approved', 4.5, 80),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Slim Fit Chinos', 'slim-fit-chinos', 'Versatile.', 45.00, 120, true, 'approved', 4.4, 90),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Oxford Cotton Shirt', 'oxford-cotton-shirt', 'Sharp.', 55.00, 100, true, 'approved', 4.6, 110),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Leather Chelsea Boots', 'leather-chelsea-boots', 'Sleek.', 120.00, 40, true, 'approved', 4.7, 60),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Casual White Sneakers', 'casual-white-sneakers', 'Essential.', 70.00, 150, true, 'approved', 4.5, 180),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Puffer Jacket', 'mens-puffer-jacket', 'Winter ready.', 130.00, 50, true, 'approved', 4.8, 70),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Graphic T-Shirt', 'graphic-print-tshirt', 'Express yourself.', 25.00, 200, true, 'approved', 4.3, 140),
    (v_seller_id, v_shop_id, v_cat_mens_fashion, NULL, 'Cargo Pants', 'mens-cargo-pants', 'Utility style.', 50.00, 85, true, 'approved', 4.4, 95);

    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&h=600&fit=crop', true FROM products WHERE slug = 'nike-air-max-270';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=600&h=600&fit=crop', true FROM products WHERE slug = 'nike-tech-fleece';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1608231387042-66d1773070a5?w=600&h=600&fit=crop', true FROM products WHERE slug = 'adidas-ultraboost';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=600&h=600&fit=crop', true FROM products WHERE slug = 'adidas-tracksuit';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1576995853123-5a10305d93c0?w=600&h=600&fit=crop', true FROM products WHERE slug = 'classic-denim-jacket';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=600&h=600&fit=crop', true FROM products WHERE slug = 'slim-fit-chinos';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600&h=600&fit=crop', true FROM products WHERE slug = 'oxford-cotton-shirt';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1638247025967-b4e38f787b76?w=600&h=600&fit=crop', true FROM products WHERE slug = 'leather-chelsea-boots';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=600&h=600&fit=crop', true FROM products WHERE slug = 'casual-white-sneakers';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=600&h=600&fit=crop', true FROM products WHERE slug = 'mens-puffer-jacket';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=600&h=600&fit=crop', true FROM products WHERE slug = 'graphic-print-tshirt';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1517438476312-10d79c077509?w=600&h=600&fit=crop', true FROM products WHERE slug = 'mens-cargo-pants';

    -- 9. Womens Fashion (12 items)
    INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, stock_quantity, is_active, approval_status, rating, total_reviews) VALUES
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Floral Summer Dress', 'floral-summer-dress', 'Breezy.', 45.00, 80, true, 'approved', 4.7, 110),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'High-Waisted Jeans', 'high-waisted-jeans', 'Flattering.', 55.00, 100, true, 'approved', 4.6, 130),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Oversized Blazer', 'oversized-blazer', 'Chic.', 85.00, 40, true, 'approved', 4.8, 60),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Silk Blouse', 'silk-blouse', 'Luxurious.', 70.00, 50, true, 'approved', 4.7, 45),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Pleated Midi Skirt', 'pleated-midi-skirt', 'Elegant.', 50.00, 60, true, 'approved', 4.5, 75),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Leather Handbag', 'leather-handbag', 'Essential.', 120.00, 30, true, 'approved', 4.9, 90),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Ankle Boots', 'ankle-boots', 'Stylish.', 90.00, 55, true, 'approved', 4.6, 85),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Knitted Sweater', 'knitted-sweater', 'Cozy.', 60.00, 70, true, 'approved', 4.8, 100),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Statement Earrings', 'statement-earrings', 'Bold.', 20.00, 150, true, 'approved', 4.4, 50),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Trench Coat', 'womens-trench-coat', 'Classic.', 140.00, 35, true, 'approved', 4.8, 65),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Yoga Leggings', 'yoga-leggings', 'Support.', 35.00, 120, true, 'approved', 4.7, 140),
    (v_seller_id, v_shop_id, v_cat_womens_fashion, NULL, 'Evening Gown', 'evening-gown', 'Special.', 180.00, 20, true, 'approved', 4.9, 30);

    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=600&h=600&fit=crop', true FROM products WHERE slug = 'floral-summer-dress';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=600&h=600&fit=crop', true FROM products WHERE slug = 'high-waisted-jeans';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=600&h=600&fit=crop', true FROM products WHERE slug = 'oversized-blazer';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1604575396020-3c6a0b7d7a84?w=600&h=600&fit=crop', true FROM products WHERE slug = 'silk-blouse';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1583496661160-fb5886a0afe1?w=600&h=600&fit=crop', true FROM products WHERE slug = 'pleated-midi-skirt';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600&h=600&fit=crop', true FROM products WHERE slug = 'leather-handbag';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=600&h=600&fit=crop', true FROM products WHERE slug = 'ankle-boots';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1620799140188-3b2a02fd9a77?w=600&h=600&fit=crop', true FROM products WHERE slug = 'knitted-sweater';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=600&h=600&fit=crop', true FROM products WHERE slug = 'statement-earrings';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=600&h=600&fit=crop', true FROM products WHERE slug = 'womens-trench-coat';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=600&h=600&fit=crop', true FROM products WHERE slug = 'yoga-leggings';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=600&h=600&fit=crop', true FROM products WHERE slug = 'evening-gown';

    -- 10. Home & Living (12 items)
    INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, stock_quantity, is_active, approval_status, rating, total_reviews) VALUES
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Modern Sofa', 'modern-sofa', 'Comfortable.', 599.00, 10, true, 'approved', 4.8, 40),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Wooden Coffee Table', 'wooden-coffee-table', 'Solid oak.', 150.00, 20, true, 'approved', 4.7, 35),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Floor Lamp', 'floor-lamp', 'Ambient.', 80.00, 40, true, 'approved', 4.6, 50),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Ceramic Vase', 'ceramic-vase', 'Handcrafted.', 30.00, 60, true, 'approved', 4.8, 25),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Cotton Bed Sheets', 'cotton-bed-sheets', 'Soft.', 45.00, 80, true, 'approved', 4.5, 90),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Wall Art Print', 'wall-art-print', 'Abstract.', 25.00, 100, true, 'approved', 4.4, 30),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Indoor Plant Pot', 'indoor-plant-pot', 'Minimalist.', 15.00, 120, true, 'approved', 4.7, 60),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Kitchen Knife Set', 'kitchen-knife-set', 'Professional.', 90.00, 30, true, 'approved', 4.8, 45),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Non-Stick Frying Pan', 'non-stick-frying-pan', 'Easy cooking.', 35.00, 70, true, 'approved', 4.6, 80),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Bath Towel Set', 'bath-towel-set', 'Plush.', 40.00, 60, true, 'approved', 4.5, 55),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Scented Candle', 'scented-candle', 'Lavender.', 18.00, 150, true, 'approved', 4.8, 100),
    (v_seller_id, v_shop_id, v_cat_home, NULL, 'Throw Pillow', 'throw-pillow', 'Decorative.', 22.00, 90, true, 'approved', 4.6, 40);

    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=600&h=600&fit=crop', true FROM products WHERE slug = 'modern-sofa';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1533090481720-856c6e3c1fdc?w=600&h=600&fit=crop', true FROM products WHERE slug = 'wooden-coffee-table';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=600&h=600&fit=crop', true FROM products WHERE slug = 'floor-lamp';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1578500494198-246f612d3b3d?w=600&h=600&fit=crop', true FROM products WHERE slug = 'ceramic-vase';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=600&h=600&fit=crop', true FROM products WHERE slug = 'cotton-bed-sheets';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?w=600&h=600&fit=crop', true FROM products WHERE slug = 'wall-art-print';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1485955900006-10f4d324d411?w=600&h=600&fit=crop', true FROM products WHERE slug = 'indoor-plant-pot';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1593618998160-e34014e67546?w=600&h=600&fit=crop', true FROM products WHERE slug = 'kitchen-knife-set';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1592154395799-5a7c2db3b4a6?w=600&h=600&fit=crop', true FROM products WHERE slug = 'non-stick-frying-pan';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1583845112239-97ef1341b271?w=600&h=600&fit=crop', true FROM products WHERE slug = 'bath-towel-set';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1602028915047-37269d1a73f7?w=600&h=600&fit=crop', true FROM products WHERE slug = 'scented-candle';
    INSERT INTO product_images (product_id, image_url, is_primary) SELECT id, 'https://images.unsplash.com/photo-1579656381254-5d0f5e956b7b?w=600&h=600&fit=crop', true FROM products WHERE slug = 'throw-pillow';

END $$;

-- SQL3 COMPLETE - Database is now fully seeded!
