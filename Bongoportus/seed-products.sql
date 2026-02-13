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
