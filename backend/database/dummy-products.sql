-- =====================================================
-- BongoPortus - Dummy Products Seed Data
-- Run this in the Supabase SQL Editor AFTER schema.sql
-- Uses the admin user (umorfaruksupto@gmail.com) as seller
-- =====================================================

-- Step 1: Make sure the admin user also has a seller profile
-- (We use a DO block to safely get the admin user's ID)
DO $$
DECLARE
  v_admin_id UUID;
  v_shop_id UUID;
  v_cat_electronics UUID;
  v_cat_fashion UUID;
  v_cat_home UUID;
  v_cat_beauty UUID;
  v_cat_sports UUID;
  v_cat_books UUID;
  v_cat_phones UUID;
  v_cat_laptops UUID;
  v_brand_samsung UUID;
  v_brand_apple UUID;
  v_brand_nike UUID;
  v_brand_adidas UUID;
  v_brand_sony UUID;
  v_brand_local UUID;
BEGIN
  -- Get admin user ID
  SELECT id INTO v_admin_id FROM auth.users WHERE email = 'umorfaruksupto@gmail.com';

  IF v_admin_id IS NULL THEN
    RAISE NOTICE 'Admin user not found. Please sign up with umorfaruksupto@gmail.com first, then re-run this script.';
    RETURN;
  END IF;

  -- Ensure admin has 'admin' role
  UPDATE profiles SET role = 'admin' WHERE id = v_admin_id;

  -- Create seller profile for admin (if not exists)
  INSERT INTO seller_profiles (user_id, business_name, business_type, status, commission_rate)
  VALUES (v_admin_id, 'BongoPortus Official Store', 'Marketplace', 'approved', 0)
  ON CONFLICT (user_id) DO UPDATE SET status = 'approved';

  -- Create the official shop
  INSERT INTO shops (id, seller_id, name, slug, description)
  VALUES (
    uuid_generate_v4(), v_admin_id,
    'BongoPortus Official', 'bongoportus-official',
    'The official BongoPortus marketplace store with curated products'
  )
  ON CONFLICT (slug) DO NOTHING;

  SELECT id INTO v_shop_id FROM shops WHERE seller_id = v_admin_id LIMIT 1;

  -- ─── CATEGORIES ────────────────────────────────────
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

  -- ─── BRANDS ─────────────────────────────────────────
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

  -- ─── PRODUCTS (20 dummy products across categories) ─
  -- Clear old dummy products if re-running
  DELETE FROM products WHERE seller_id = v_admin_id AND slug LIKE '%-demo-%';

  -- 1. Samsung Galaxy S24 Ultra
  INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, discount_price, discount_percentage, stock_quantity, is_featured, is_active, approval_status, rating, total_reviews)
  VALUES (v_admin_id, v_shop_id, v_cat_phones, v_brand_samsung,
    'Samsung Galaxy S24 Ultra', 'samsung-galaxy-s24-ultra-demo-1',
    'The ultimate Galaxy experience with S Pen, 200MP camera, titanium frame, and Galaxy AI. 12GB RAM, 256GB storage, Dynamic AMOLED 2X display.',
    134999, 124999, 7, 50, true, true, 'approved', 4.8, 245);

  -- 2. iPhone 15 Pro Max
  INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, discount_price, discount_percentage, stock_quantity, is_featured, is_active, approval_status, rating, total_reviews)
  VALUES (v_admin_id, v_shop_id, v_cat_phones, v_brand_apple,
    'iPhone 15 Pro Max', 'iphone-15-pro-max-demo-2',
    'Forged in titanium with A17 Pro chip, 48MP camera system, Action button, and USB-C. 256GB storage, Super Retina XDR display.',
    179999, 169999, 6, 35, true, true, 'approved', 4.9, 312);

  -- 3. Sony WH-1000XM5 Headphones
  INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, discount_price, discount_percentage, stock_quantity, is_featured, is_active, approval_status, rating, total_reviews)
  VALUES (v_admin_id, v_shop_id, v_cat_electronics, v_brand_sony,
    'Sony WH-1000XM5 Wireless Headphones', 'sony-wh1000xm5-demo-3',
    'Industry-leading noise cancellation with 30-hour battery, multipoint connection, and crystal-clear call quality.',
    34999, 29999, 14, 100, true, true, 'approved', 4.7, 189);

  -- 4. Nike Air Max 270
  INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, discount_price, discount_percentage, stock_quantity, is_featured, is_active, approval_status, rating, total_reviews)
  VALUES (v_admin_id, v_shop_id, v_cat_fashion, v_brand_nike,
    'Nike Air Max 270 Running Shoes', 'nike-air-max-270-demo-4',
    'Featuring the largest Max Air unit yet for a soft comfortable ride. Mesh upper for breathability, foam midsole.',
    12999, 9999, 23, 200, true, true, 'approved', 4.5, 156);

  -- 5. Adidas Ultraboost 23
  INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, discount_price, discount_percentage, stock_quantity, is_featured, is_active, approval_status, rating, total_reviews)
  VALUES (v_admin_id, v_shop_id, v_cat_fashion, v_brand_adidas,
    'Adidas Ultraboost Light 23', 'adidas-ultraboost-23-demo-5',
    'The lightest Ultraboost ever. BOOST midsole, Primeknit+ upper, Continental rubber outsole for all-day comfort.',
    14999, 11999, 20, 150, false, true, 'approved', 4.6, 98);

  -- 6. Samsung 55" 4K Smart TV
  INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, discount_price, discount_percentage, stock_quantity, is_featured, is_active, approval_status, rating, total_reviews)
  VALUES (v_admin_id, v_shop_id, v_cat_electronics, v_brand_samsung,
    'Samsung 55" Crystal UHD 4K Smart TV', 'samsung-55-4k-tv-demo-6',
    'Crystal Processor 4K, HDR10+, Smart Hub, AirSlim design, built-in voice assistants. Model: CU7000.',
    52999, 44999, 15, 30, true, true, 'approved', 4.4, 87);

  -- 7. Jamdani Saree
  INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, discount_price, discount_percentage, stock_quantity, is_featured, is_active, approval_status, rating, total_reviews)
  VALUES (v_admin_id, v_shop_id, v_cat_fashion, v_brand_local,
    'Premium Dhakai Jamdani Saree', 'dhakai-jamdani-saree-demo-7',
    'Authentic handwoven Dhakai Jamdani saree with intricate muslin weave. Traditional Bangladeshi craftsmanship, cotton-silk blend.',
    8500, 6999, 18, 25, true, true, 'approved', 4.9, 67);

  -- 8. Home Decor Set
  INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, discount_price, discount_percentage, stock_quantity, is_featured, is_active, approval_status, rating, total_reviews)
  VALUES (v_admin_id, v_shop_id, v_cat_home, v_brand_local,
    'Nakshi Kantha Cushion Cover Set (4pcs)', 'nakshi-kantha-cushion-set-demo-8',
    'Hand-embroidered Nakshi Kantha cushion covers. Set of 4, 18x18 inch. Traditional Bengali folk art motifs.',
    2499, 1899, 24, 80, false, true, 'approved', 4.6, 43);

  -- 9. MacBook Air M3
  INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, discount_price, discount_percentage, stock_quantity, is_featured, is_active, approval_status, rating, total_reviews)
  VALUES (v_admin_id, v_shop_id, v_cat_laptops, v_brand_apple,
    'MacBook Air M3 (2024) 15"', 'macbook-air-m3-15-demo-9',
    'Apple M3 chip, 8-core CPU, 10-core GPU, 8GB RAM, 256GB SSD, Liquid Retina display, 18-hr battery, MagSafe.',
    159999, 149999, 6, 20, true, true, 'approved', 4.8, 134);

  -- 10. Samsung Galaxy Tab S9
  INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, discount_price, discount_percentage, stock_quantity, is_featured, is_active, approval_status, rating, total_reviews)
  VALUES (v_admin_id, v_shop_id, v_cat_electronics, v_brand_samsung,
    'Samsung Galaxy Tab S9 FE', 'samsung-tab-s9-fe-demo-10',
    'S Pen included, 10.9" TFT display, Exynos 1380, 6GB RAM, 128GB, IP68 water resistance.',
    39999, 34999, 13, 45, false, true, 'approved', 4.5, 76);

  -- 11. Beauty Face Serum
  INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, discount_price, discount_percentage, stock_quantity, is_featured, is_active, approval_status, rating, total_reviews)
  VALUES (v_admin_id, v_shop_id, v_cat_beauty, v_brand_local,
    'Vitamin C Brightening Face Serum 30ml', 'vitamin-c-face-serum-demo-11',
    'Advanced 20% Vitamin C serum with Hyaluronic Acid and Vitamin E. Brightens, hydrates, and reduces dark spots.',
    1299, 999, 23, 300, false, true, 'approved', 4.3, 210);

  -- 12. Cricket Bat
  INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, discount_price, discount_percentage, stock_quantity, is_featured, is_active, approval_status, rating, total_reviews)
  VALUES (v_admin_id, v_shop_id, v_cat_sports, v_brand_local,
    'English Willow Cricket Bat - Pro Edition', 'english-willow-bat-demo-12',
    'Grade 1 English Willow cricket bat. Full size SH. Sweet spot enhanced with 8-12 grains. Ready to play.',
    7999, 6499, 19, 40, false, true, 'approved', 4.4, 55);

  -- 13. Bengali Recipe Book
  INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, discount_price, discount_percentage, stock_quantity, is_featured, is_active, approval_status, rating, total_reviews)
  VALUES (v_admin_id, v_shop_id, v_cat_books, v_brand_local,
    'Bangla Ranna: Traditional Bengali Cookbook', 'bangla-ranna-cookbook-demo-13',
    '500+ authentic Bengali recipes with step-by-step instructions. Covers sweets, curries, rice dishes, and festival specials.',
    599, 449, 25, 500, false, true, 'approved', 4.7, 89);

  -- 14. Wireless Earbuds
  INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, discount_price, discount_percentage, stock_quantity, is_featured, is_active, approval_status, rating, total_reviews)
  VALUES (v_admin_id, v_shop_id, v_cat_electronics, v_brand_samsung,
    'Samsung Galaxy Buds3 Pro', 'galaxy-buds3-pro-demo-14',
    'Blade lights design, 2-way speaker, Intelligent ANC, 360 Audio, 30hr battery with case. Hi-Fi 24bit audio.',
    18999, 15999, 16, 120, true, true, 'approved', 4.6, 167);

  -- 15. Panjabi (Traditional)
  INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, discount_price, discount_percentage, stock_quantity, is_featured, is_active, approval_status, rating, total_reviews)
  VALUES (v_admin_id, v_shop_id, v_cat_fashion, v_brand_local,
    'Premium Cotton Panjabi - Eid Collection', 'premium-panjabi-eid-demo-15',
    'Handcrafted premium cotton panjabi with intricate embroidery. Available in multiple sizes. Perfect for Eid and festivals.',
    3499, 2799, 20, 100, true, true, 'approved', 4.5, 78);

  -- 16. Skincare Set
  INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, discount_price, discount_percentage, stock_quantity, is_featured, is_active, approval_status, rating, total_reviews)
  VALUES (v_admin_id, v_shop_id, v_cat_beauty, v_brand_local,
    'Complete Skincare Routine Set (5 products)', 'skincare-routine-set-demo-16',
    'Cleanser, Toner, Serum, Moisturizer, and Sunscreen. Suitable for all skin types. Dermatologically tested.',
    3999, 2999, 25, 150, false, true, 'approved', 4.4, 132);

  -- 17. Smart Watch
  INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, discount_price, discount_percentage, stock_quantity, is_featured, is_active, approval_status, rating, total_reviews)
  VALUES (v_admin_id, v_shop_id, v_cat_electronics, v_brand_apple,
    'Apple Watch Series 9 (45mm GPS)', 'apple-watch-series9-demo-17',
    'S9 SiP chip, Double Tap gesture, brighter always-on Retina display, blood oxygen, ECG, crash detection.',
    54999, 49999, 9, 40, true, true, 'approved', 4.7, 198);

  -- 18. Bedsheet Set
  INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, discount_price, discount_percentage, stock_quantity, is_featured, is_active, approval_status, rating, total_reviews)
  VALUES (v_admin_id, v_shop_id, v_cat_home, v_brand_local,
    'King Size Cotton Bedsheet Set (3pcs)', 'king-bedsheet-set-demo-18',
    'Premium 300TC Egyptian cotton bedsheet with 2 pillow covers. Size: 100x100 inch. Machine washable.',
    2999, 2199, 27, 200, false, true, 'approved', 4.3, 95);

  -- 19. Football
  INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, discount_price, discount_percentage, stock_quantity, is_featured, is_active, approval_status, rating, total_reviews)
  VALUES (v_admin_id, v_shop_id, v_cat_sports, v_brand_adidas,
    'Adidas UCL Pro Match Football', 'adidas-ucl-football-demo-19',
    'Official UEFA Champions League match ball. Thermally bonded seamless surface, FIFA Quality Pro certified. Size 5.',
    5999, 4999, 17, 60, false, true, 'approved', 4.6, 44);

  -- 20. Laptop Samsung
  INSERT INTO products (seller_id, shop_id, category_id, brand_id, name, slug, description, price, discount_price, discount_percentage, stock_quantity, is_featured, is_active, approval_status, rating, total_reviews)
  VALUES (v_admin_id, v_shop_id, v_cat_laptops, v_brand_samsung,
    'Samsung Galaxy Book4 Pro 14"', 'samsung-galaxy-book4-pro-demo-20',
    'Intel Core Ultra 7, 16GB RAM, 512GB SSD, Dynamic AMOLED 2X display, Intel Arc GPU, Thunderbolt 4.',
    129999, 114999, 12, 25, true, true, 'approved', 4.5, 67);

  -- ─── PRODUCT IMAGES (using real placeholder image URLs) ─
  -- Each product gets a unique image from picsum.photos (free, reliable CDN)
  -- These are real images that will display in the app and website immediately.
  -- Replace with actual product images uploaded to Supabase Storage later.

  -- Delete old placeholder images for demo products
  DELETE FROM product_images WHERE product_id IN (
    SELECT id FROM products WHERE seller_id = v_admin_id AND slug LIKE '%-demo-%'
  );

  -- Samsung Galaxy S24 Ultra
  INSERT INTO product_images (product_id, image_url, display_order, is_primary)
  SELECT id, 'https://picsum.photos/seed/galaxy-s24/600/600', 1, true FROM products WHERE slug = 'samsung-galaxy-s24-ultra-demo-1';
  INSERT INTO product_images (product_id, image_url, display_order, is_primary)
  SELECT id, 'https://picsum.photos/seed/galaxy-s24-2/600/600', 2, false FROM products WHERE slug = 'samsung-galaxy-s24-ultra-demo-1';

  -- iPhone 15 Pro Max
  INSERT INTO product_images (product_id, image_url, display_order, is_primary)
  SELECT id, 'https://picsum.photos/seed/iphone15/600/600', 1, true FROM products WHERE slug = 'iphone-15-pro-max-demo-2';
  INSERT INTO product_images (product_id, image_url, display_order, is_primary)
  SELECT id, 'https://picsum.photos/seed/iphone15-2/600/600', 2, false FROM products WHERE slug = 'iphone-15-pro-max-demo-2';

  -- Sony WH-1000XM5
  INSERT INTO product_images (product_id, image_url, display_order, is_primary)
  SELECT id, 'https://picsum.photos/seed/sony-xm5/600/600', 1, true FROM products WHERE slug = 'sony-wh1000xm5-demo-3';

  -- Nike Air Max 270
  INSERT INTO product_images (product_id, image_url, display_order, is_primary)
  SELECT id, 'https://picsum.photos/seed/nike-airmax/600/600', 1, true FROM products WHERE slug = 'nike-air-max-270-demo-4';

  -- Adidas Ultraboost
  INSERT INTO product_images (product_id, image_url, display_order, is_primary)
  SELECT id, 'https://picsum.photos/seed/adidas-ultra/600/600', 1, true FROM products WHERE slug = 'adidas-ultraboost-23-demo-5';

  -- Samsung 55" TV
  INSERT INTO product_images (product_id, image_url, display_order, is_primary)
  SELECT id, 'https://picsum.photos/seed/samsung-tv/600/600', 1, true FROM products WHERE slug = 'samsung-55-4k-tv-demo-6';

  -- Jamdani Saree
  INSERT INTO product_images (product_id, image_url, display_order, is_primary)
  SELECT id, 'https://picsum.photos/seed/jamdani/600/600', 1, true FROM products WHERE slug = 'dhakai-jamdani-saree-demo-7';

  -- Nakshi Kantha Cushion
  INSERT INTO product_images (product_id, image_url, display_order, is_primary)
  SELECT id, 'https://picsum.photos/seed/nakshi-kantha/600/600', 1, true FROM products WHERE slug = 'nakshi-kantha-cushion-set-demo-8';

  -- MacBook Air M3
  INSERT INTO product_images (product_id, image_url, display_order, is_primary)
  SELECT id, 'https://picsum.photos/seed/macbook-m3/600/600', 1, true FROM products WHERE slug = 'macbook-air-m3-15-demo-9';

  -- Samsung Tab S9
  INSERT INTO product_images (product_id, image_url, display_order, is_primary)
  SELECT id, 'https://picsum.photos/seed/tab-s9/600/600', 1, true FROM products WHERE slug = 'samsung-tab-s9-fe-demo-10';

  -- Vitamin C Serum
  INSERT INTO product_images (product_id, image_url, display_order, is_primary)
  SELECT id, 'https://picsum.photos/seed/vitaminc/600/600', 1, true FROM products WHERE slug = 'vitamin-c-face-serum-demo-11';

  -- Cricket Bat
  INSERT INTO product_images (product_id, image_url, display_order, is_primary)
  SELECT id, 'https://picsum.photos/seed/cricket-bat/600/600', 1, true FROM products WHERE slug = 'english-willow-bat-demo-12';

  -- Bengali Cookbook
  INSERT INTO product_images (product_id, image_url, display_order, is_primary)
  SELECT id, 'https://picsum.photos/seed/cookbook/600/600', 1, true FROM products WHERE slug = 'bangla-ranna-cookbook-demo-13';

  -- Galaxy Buds3 Pro
  INSERT INTO product_images (product_id, image_url, display_order, is_primary)
  SELECT id, 'https://picsum.photos/seed/galaxy-buds/600/600', 1, true FROM products WHERE slug = 'galaxy-buds3-pro-demo-14';

  -- Panjabi
  INSERT INTO product_images (product_id, image_url, display_order, is_primary)
  SELECT id, 'https://picsum.photos/seed/panjabi/600/600', 1, true FROM products WHERE slug = 'premium-panjabi-eid-demo-15';

  -- Skincare Set
  INSERT INTO product_images (product_id, image_url, display_order, is_primary)
  SELECT id, 'https://picsum.photos/seed/skincare/600/600', 1, true FROM products WHERE slug = 'skincare-routine-set-demo-16';

  -- Apple Watch
  INSERT INTO product_images (product_id, image_url, display_order, is_primary)
  SELECT id, 'https://picsum.photos/seed/apple-watch/600/600', 1, true FROM products WHERE slug = 'apple-watch-series9-demo-17';

  -- Bedsheet Set
  INSERT INTO product_images (product_id, image_url, display_order, is_primary)
  SELECT id, 'https://picsum.photos/seed/bedsheet/600/600', 1, true FROM products WHERE slug = 'king-bedsheet-set-demo-18';

  -- Football
  INSERT INTO product_images (product_id, image_url, display_order, is_primary)
  SELECT id, 'https://picsum.photos/seed/football/600/600', 1, true FROM products WHERE slug = 'adidas-ucl-football-demo-19';

  -- Galaxy Book4 Pro
  INSERT INTO product_images (product_id, image_url, display_order, is_primary)
  SELECT id, 'https://picsum.photos/seed/galaxy-book/600/600', 1, true FROM products WHERE slug = 'samsung-galaxy-book4-pro-demo-20';

  -- ─── COUPONS ─────────────────────────────────────────
  INSERT INTO coupons (code, description, discount_type, discount_value, min_purchase_amount, max_discount_amount, usage_limit, valid_from, valid_until, is_active)
  VALUES
    ('WELCOME10', 'Welcome discount - 10% off your first order', 'percentage', 10, 500, 2000, 1000, NOW(), NOW() + INTERVAL '1 year', true),
    ('BONGO20', 'BongoPortus special - 20% off', 'percentage', 20, 2000, 5000, 500, NOW(), NOW() + INTERVAL '6 months', true),
    ('FLAT500', 'Flat ৳500 off on orders above ৳5000', 'fixed', 500, 5000, NULL, 200, NOW(), NOW() + INTERVAL '3 months', true),
    ('EID25', 'Eid special - 25% off fashion & lifestyle', 'percentage', 25, 1000, 3000, 300, NOW(), NOW() + INTERVAL '2 months', true),
    ('FREESHIP', 'Free shipping on all orders', 'fixed', 50, 0, NULL, NULL, NOW(), NOW() + INTERVAL '1 year', true)
  ON CONFLICT (code) DO NOTHING;

  -- ─── PRODUCT VARIANTS (for fashion items) ────────────
  -- Nike shoes sizes
  INSERT INTO product_variants (product_id, variant_type, variant_value, stock_quantity)
  SELECT p.id, 'Size', s.size, 30
  FROM products p, (VALUES ('7'), ('8'), ('9'), ('10'), ('11')) AS s(size)
  WHERE p.slug = 'nike-air-max-270-demo-4';

  -- Adidas shoes sizes
  INSERT INTO product_variants (product_id, variant_type, variant_value, stock_quantity)
  SELECT p.id, 'Size', s.size, 25
  FROM products p, (VALUES ('7'), ('8'), ('9'), ('10'), ('11')) AS s(size)
  WHERE p.slug = 'adidas-ultraboost-23-demo-5';

  -- Panjabi sizes
  INSERT INTO product_variants (product_id, variant_type, variant_value, stock_quantity)
  SELECT p.id, 'Size', s.size, 20
  FROM products p, (VALUES ('S'), ('M'), ('L'), ('XL'), ('XXL')) AS s(size)
  WHERE p.slug = 'premium-panjabi-eid-demo-15';

  -- Phone colors
  INSERT INTO product_variants (product_id, variant_type, variant_value, stock_quantity)
  SELECT p.id, 'Color', c.color, 10
  FROM products p, (VALUES ('Titanium Black'), ('Titanium Gray'), ('Titanium Violet'), ('Titanium Yellow')) AS c(color)
  WHERE p.slug = 'samsung-galaxy-s24-ultra-demo-1';

  INSERT INTO product_variants (product_id, variant_type, variant_value, stock_quantity)
  SELECT p.id, 'Color', c.color, 8
  FROM products p, (VALUES ('Natural Titanium'), ('Blue Titanium'), ('White Titanium'), ('Black Titanium')) AS c(color)
  WHERE p.slug = 'iphone-15-pro-max-demo-2';

  RAISE NOTICE 'Successfully inserted 20 dummy products, 8 categories, 6 brands, 5 coupons, and product variants!';
END;
$$;

-- Verify the data
SELECT
  'Products' AS entity, COUNT(*) AS total FROM products WHERE approval_status = 'approved'
UNION ALL
SELECT 'Categories', COUNT(*) FROM categories WHERE is_active = true
UNION ALL
SELECT 'Brands', COUNT(*) FROM brands WHERE is_active = true
UNION ALL
SELECT 'Coupons', COUNT(*) FROM coupons WHERE is_active = true
UNION ALL
SELECT 'Product Images', COUNT(*) FROM product_images
UNION ALL
SELECT 'Product Variants', COUNT(*) FROM product_variants
ORDER BY entity;
