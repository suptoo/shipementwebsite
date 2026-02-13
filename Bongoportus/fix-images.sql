-- ==============================================================================
-- SQL FIX: Update Product Images with Public Image URLs
-- ==============================================================================
-- This updates all product images to use publicly accessible Unsplash image URLs
-- Run this in your Supabase SQL editor after products are seeded
-- ==============================================================================

-- SMARTPHONES (12 products)
-- iPhone 15 Pro Max / iPhone 15 Pro
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=600&h=600&fit=crop' 
WHERE product_id IN (SELECT id FROM products WHERE slug IN ('iphone-15-pro-max-titanium', 'iphone-15-pro-blue'));

-- iPhone 14
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1678685888221-cda773a3dcdb?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'iphone-14-midnight');

-- Samsung Galaxy S24 Ultra / S24+
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=600&h=600&fit=crop' 
WHERE product_id IN (SELECT id FROM products WHERE slug IN ('samsung-s24-ultra', 'samsung-s24-plus'));

-- Samsung Galaxy Z Fold 5
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'samsung-z-fold-5');

-- Sony Xperia 1 V
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'sony-xperia-1-v');

-- Google Pixel 8 Pro / Pixel 8
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=600&h=600&fit=crop' 
WHERE product_id IN (SELECT id FROM products WHERE slug IN ('google-pixel-8-pro', 'google-pixel-8'));

-- OnePlus 12
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1605236453806-6ff36851218e?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'oneplus-12');

-- Nothing Phone (2)
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1592899677977-9c10ca588bbd?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'nothing-phone-2');

-- Xiaomi 14 Ultra
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1574944985070-8f3ebc6b79d2?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'xiaomi-14-ultra');


-- LAPTOPS (12 products)
-- MacBooks
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=600&h=600&fit=crop' 
WHERE product_id IN (SELECT id FROM products WHERE slug IN ('macbook-pro-16-m3', 'macbook-air-15-m2', 'macbook-pro-14-m3'));

-- Dell XPS
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1593642632559-0c6d3fc62b89?w=600&h=600&fit=crop' 
WHERE product_id IN (SELECT id FROM products WHERE slug IN ('dell-xps-15', 'dell-xps-13-plus'));

-- HP Spectre
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'hp-spectre-x360');

-- Lenovo ThinkPad
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'lenovo-thinkpad-x1');

-- Gaming Laptops (Asus ROG, Razer, MSI)
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1603302576837-37561b2e2302?w=600&h=600&fit=crop' 
WHERE product_id IN (SELECT id FROM products WHERE slug IN ('asus-rog-zephyrus-g14', 'razer-blade-16', 'msi-raider-ge78'));

-- Surface Laptop 5
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1587614382346-4ec70e388b28?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'surface-laptop-5');

-- Acer Swift
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1525547719571-a2d4ac8945e2?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'acer-swift-go-14');


-- MENS FASHION (12 products)
-- Nike Air Max 270
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'nike-air-max-270');

-- Nike Tech Fleece Hoodie
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'nike-tech-fleece');

-- Adidas Ultraboost Light
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1608231387042-66d1773070a5?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'adidas-ultraboost');

-- Adidas Tracksuit
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'adidas-tracksuit');

-- Classic Denim Jacket
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1576995853123-5a10305d93c0?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'classic-denim-jacket');

-- Slim Fit Chinos
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'slim-fit-chinos');

-- Oxford Cotton Shirt
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'oxford-cotton-shirt');

-- Leather Chelsea Boots
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1638247025967-b4e38f787b76?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'leather-chelsea-boots');

-- Casual White Sneakers
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'casual-white-sneakers');

-- Puffer Jacket
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'mens-puffer-jacket');

-- Graphic T-Shirt
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'graphic-print-tshirt');

-- Cargo Pants
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1517438476312-10d79c077509?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'mens-cargo-pants');


-- WOMENS FASHION (12 products)
-- Floral Summer Dress
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'floral-summer-dress');

-- High-Waisted Jeans
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'high-waisted-jeans');

-- Oversized Blazer
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'oversized-blazer');

-- Silk Blouse
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1604575396020-3c6a0b7d7a84?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'silk-blouse');

-- Pleated Midi Skirt
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1583496661160-fb5886a0afe1?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'pleated-midi-skirt');

-- Leather Handbag
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'leather-handbag');

-- Ankle Boots
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'ankle-boots');

-- Knitted Sweater
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1620799140188-3b2a02fd9a77?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'knitted-sweater');

-- Statement Earrings
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'statement-earrings');

-- Trench Coat
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'womens-trench-coat');

-- Yoga Leggings
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'yoga-leggings');

-- Evening Gown
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'evening-gown');


-- HOME & LIVING (12 products)
-- Modern Sofa
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'modern-sofa');

-- Wooden Coffee Table
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1533090481720-856c6e3c1fdc?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'wooden-coffee-table');

-- Floor Lamp
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'floor-lamp');

-- Ceramic Vase
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1578500494198-246f612d3b3d?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'ceramic-vase');

-- Cotton Bed Sheets
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'cotton-bed-sheets');

-- Wall Art Print
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'wall-art-print');

-- Indoor Plant Pot
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1485955900006-10f4d324d411?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'indoor-plant-pot');

-- Kitchen Knife Set
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1593618998160-e34014e67546?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'kitchen-knife-set');

-- Non-Stick Frying Pan
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1592154395799-5a7c2db3b4a6?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'non-stick-frying-pan');

-- Bath Towel Set
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1583845112239-97ef1341b271?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'bath-towel-set');

-- Scented Candle
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1602028915047-37269d1a73f7?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'scented-candle');

-- Throw Pillow
UPDATE product_images SET image_url = 'https://images.unsplash.com/photo-1579656381254-5d0f5e956b7b?w=600&h=600&fit=crop' 
WHERE product_id = (SELECT id FROM products WHERE slug = 'throw-pillow');


-- ============================================================================
-- UPDATE BANNERS TOO
-- ============================================================================
UPDATE cms_banners SET image_url = 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=1200&h=400&fit=crop'
WHERE title = 'Winter Sale 2025';

UPDATE cms_banners SET image_url = 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=1200&h=400&fit=crop'
WHERE title = 'Electronics Mega Sale';


-- Done! All product images now use publicly accessible Unsplash URLs.
-- Run: SELECT COUNT(*) FROM product_images WHERE image_url LIKE 'https://images.unsplash.com%';
-- Should return 60 matching rows.
