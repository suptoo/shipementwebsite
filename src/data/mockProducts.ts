import { Product, Category, Brand } from '../types';

const CATEGORIES: Record<string, Category> = {
  smartphones: { id: 'cat_smartphones', name: 'Smartphones', slug: 'smartphones', parent_id: null, icon_url: null, image_url: null, display_order: 1, is_active: true },
  laptops: { id: 'cat_laptops', name: 'Laptops', slug: 'laptops', parent_id: null, icon_url: null, image_url: null, display_order: 2, is_active: true },
  mens_fashion: { id: 'cat_mens_fashion', name: 'Mens Fashion', slug: 'mens-fashion', parent_id: null, icon_url: null, image_url: null, display_order: 3, is_active: true },
  womens_fashion: { id: 'cat_womens_fashion', name: 'Womens Fashion', slug: 'womens-fashion', parent_id: null, icon_url: null, image_url: null, display_order: 4, is_active: true },
  home: { id: 'cat_home', name: 'Home & Living', slug: 'home-living', parent_id: null, icon_url: null, image_url: null, display_order: 5, is_active: true },
};

const BRANDS: Record<string, Brand> = {
  apple: { id: 'brand_apple', name: 'Apple', slug: 'apple', logo_url: null, is_active: true },
  samsung: { id: 'brand_samsung', name: 'Samsung', slug: 'samsung', logo_url: null, is_active: true },
  nike: { id: 'brand_nike', name: 'Nike', slug: 'nike', logo_url: null, is_active: true },
  adidas: { id: 'brand_adidas', name: 'Adidas', slug: 'adidas', logo_url: null, is_active: true },
  sony: { id: 'brand_sony', name: 'Sony', slug: 'sony', logo_url: null, is_active: true },
};

const createProduct = (
  id: string,
  name: string,
  slug: string,
  categoryKey: string,
  price: number,
  imageUrl: string,
  brandKey?: string,
  description: string = 'High quality product.',
  rating: number = 4.5
): Product => {
  const category = CATEGORIES[categoryKey];
  const brand = brandKey ? BRANDS[brandKey] : undefined;

  return {
    id,
    seller_id: 'mock_seller_id',
    shop_id: 'mock_shop_id',
    category_id: category.id,
    brand_id: brand?.id || null,
    name,
    slug,
    description,
    price,
    discount_price: null,
    discount_percentage: null,
    stock_quantity: 50,
    sku: `SKU-${id}`,
    rating,
    total_reviews: Math.floor(Math.random() * 200) + 10,
    total_sales: Math.floor(Math.random() * 500),
    is_featured: Math.random() > 0.8,
    is_active: true,
    approval_status: 'approved',
    category,
    brand,
    images: [
      {
        id: `img_${id}`,
        product_id: id,
        image_url: imageUrl,
        display_order: 0,
        is_primary: true,
      },
    ],
  };
};

export const MOCK_PRODUCTS: Product[] = [
  // Smartphones (12)
  createProduct('1', 'iPhone 15 Pro Max', 'iphone-15-pro-max', 'smartphones', 1499, 'https://images.unsplash.com/photo-1696446701796-da61225697cc?auto=format&fit=crop&q=80&w=800', 'apple', 'The ultimate iPhone with titanium design.', 4.9),
  createProduct('2', 'iPhone 15 Pro', 'iphone-15-pro', 'smartphones', 1299, 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?auto=format&fit=crop&q=80&w=800', 'apple', 'Pro camera system, pro performance.', 4.8),
  createProduct('3', 'iPhone 14', 'iphone-14', 'smartphones', 999, 'https://images.unsplash.com/photo-1678652197831-2d180705cd2c?auto=format&fit=crop&q=80&w=800', 'apple', 'Full of fantastic features.', 4.7),
  createProduct('4', 'Samsung Galaxy S24 Ultra', 'samsung-s24-ultra', 'smartphones', 1399, 'https://images.unsplash.com/photo-1610945265064-f4d215f0e245?auto=format&fit=crop&q=80&w=800', 'samsung', 'Galaxy AI is here.', 4.9),
  createProduct('5', 'Samsung Galaxy S24+', 'samsung-s24-plus', 'smartphones', 1199, 'https://images.unsplash.com/photo-1610945490264-925872d0264c?auto=format&fit=crop&q=80&w=800', 'samsung', 'Epic moments, now accessible.', 4.7),
  createProduct('6', 'Samsung Galaxy Z Fold 5', 'samsung-z-fold-5', 'smartphones', 1799, 'https://images.unsplash.com/photo-1658243232922-2274036f32b5?auto=format&fit=crop&q=80&w=800', 'samsung', 'Unfold your world.', 4.6),
  createProduct('7', 'Sony Xperia 1 V', 'sony-xperia-1-v', 'smartphones', 1199, 'https://images.unsplash.com/photo-1598327105666-5b89351aff23?auto=format&fit=crop&q=80&w=800', 'sony', 'Next-gen sensor. Next-gen imaging.', 4.5),
  createProduct('8', 'Google Pixel 8 Pro', 'google-pixel-8-pro', 'smartphones', 999, 'https://images.unsplash.com/photo-1598327105666-5b89351aff23?auto=format&fit=crop&q=80&w=800', undefined, 'The AI-first phone from Google.', 4.7),
  createProduct('9', 'Google Pixel 8', 'google-pixel-8', 'smartphones', 699, 'https://images.unsplash.com/photo-1598327105666-5b89351aff23?auto=format&fit=crop&q=80&w=800', undefined, 'Powerful, helpful, and personal.', 4.6),
  createProduct('10', 'OnePlus 12', 'oneplus-12', 'smartphones', 799, 'https://images.unsplash.com/photo-1565849904461-04a58ad377e0?auto=format&fit=crop&q=80&w=800', undefined, 'Smooth beyond belief.', 4.5),
  createProduct('11', 'Nothing Phone (2)', 'nothing-phone-2', 'smartphones', 599, 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&q=80&w=800', undefined, 'Come to the bright side.', 4.4),
  createProduct('12', 'Xiaomi 14 Ultra', 'xiaomi-14-ultra', 'smartphones', 1099, 'https://images.unsplash.com/photo-1598327105666-5b89351aff23?auto=format&fit=crop&q=80&w=800', undefined, 'Lens to legend.', 4.6),

  // Laptops (12)
  createProduct('13', 'MacBook Pro 16 M3 Max', 'macbook-pro-16-m3', 'laptops', 3499, 'https://images.unsplash.com/photo-1517336714731-489689fd1ca4?auto=format&fit=crop&q=80&w=800', 'apple', 'Mind-blowing. Head-turning.', 4.9),
  createProduct('14', 'MacBook Air 15 M2', 'macbook-air-15-m2', 'laptops', 1299, 'https://images.unsplash.com/photo-1611186871348-b1ce696e52c9?auto=format&fit=crop&q=80&w=800', 'apple', 'Impressively big. Impossibly thin.', 4.8),
  createProduct('15', 'MacBook Pro 14 M3', 'macbook-pro-14-m3', 'laptops', 1599, 'https://images.unsplash.com/photo-1531297461136-82lw9b285bb6?auto=format&fit=crop&q=80&w=800', 'apple', 'Serious power.', 4.8),
  createProduct('16', 'Dell XPS 15', 'dell-xps-15', 'laptops', 1899, 'https://images.unsplash.com/photo-1593642632823-8f78536788c6?auto=format&fit=crop&q=80&w=800', undefined, 'Immersive display. Premium design.', 4.6),
  createProduct('17', 'Dell XPS 13 Plus', 'dell-xps-13-plus', 'laptops', 1399, 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?auto=format&fit=crop&q=80&w=800', undefined, 'Twice as powerful as before.', 4.5),
  createProduct('18', 'HP Spectre x360', 'hp-spectre-x360', 'laptops', 1499, 'https://images.unsplash.com/photo-1544731612-de7f96afe55f?auto=format&fit=crop&q=80&w=800', undefined, 'Craftsmanship meets power.', 4.7),
  createProduct('19', 'Lenovo ThinkPad X1', 'lenovo-thinkpad-x1', 'laptops', 1699, 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?auto=format&fit=crop&q=80&w=800', undefined, 'Ultralight. Ultra-powerful.', 4.8),
  createProduct('20', 'Asus ROG Zephyrus G14', 'asus-rog-zephyrus-g14', 'laptops', 1599, 'https://images.unsplash.com/photo-1603302576837-37561b2e2302?auto=format&fit=crop&q=80&w=800', undefined, 'World\'s most powerful 14-inch gaming laptop.', 4.7),
  createProduct('21', 'Razer Blade 16', 'razer-blade-16', 'laptops', 2999, 'https://images.unsplash.com/photo-1525547719571-a2d4ac8945e2?auto=format&fit=crop&q=80&w=800', undefined, 'Fastest display. Most powerful graphics.', 4.6),
  createProduct('22', 'Surface Laptop 5', 'surface-laptop-5', 'laptops', 999, 'https://images.unsplash.com/photo-1587614382346-4ec70e388b28?auto=format&fit=crop&q=80&w=800', undefined, 'Style and speed.', 4.5),
  createProduct('23', 'Acer Swift Go 14', 'acer-swift-go-14', 'laptops', 799, 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?auto=format&fit=crop&q=80&w=800', undefined, 'Ready to go.', 4.4),
  createProduct('24', 'MSI Raider GE78', 'msi-raider-ge78', 'laptops', 2499, 'https://images.unsplash.com/photo-1593642702821-c8da6771f0c6?auto=format&fit=crop&q=80&w=800', undefined, 'Light \'em up.', 4.5),

  // Mens Fashion (12)
  createProduct('25', 'Nike Air Max 270', 'nike-air-max-270', 'mens_fashion', 150, 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&q=80&w=800', 'nike', 'Big air. Bold look.', 4.8),
  createProduct('26', 'Nike Tech Fleece', 'nike-tech-fleece', 'mens_fashion', 110, 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?auto=format&fit=crop&q=80&w=800', 'nike', 'Warmth without weight.', 4.7),
  createProduct('27', 'Adidas Ultraboost', 'adidas-ultraboost', 'mens_fashion', 190, 'https://images.unsplash.com/photo-1608231387042-66d1773070a5?auto=format&fit=crop&q=80&w=800', 'adidas', 'Epic energy.', 4.8),
  createProduct('28', 'Adidas Tracksuit', 'adidas-tracksuit', 'mens_fashion', 80, 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&q=80&w=800', 'adidas', 'Classic comfort.', 4.6),
  createProduct('29', 'Classic Denim Jacket', 'classic-denim-jacket', 'mens_fashion', 60, 'https://images.unsplash.com/photo-1576871337632-b9aef4c17ab9?auto=format&fit=crop&q=80&w=800', undefined, 'Timeless style.', 4.5),
  createProduct('30', 'Slim Fit Chinos', 'slim-fit-chinos', 'mens_fashion', 45, 'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?auto=format&fit=crop&q=80&w=800', undefined, 'Versatile and comfortable.', 4.4),
  createProduct('31', 'Oxford Cotton Shirt', 'oxford-cotton-shirt', 'mens_fashion', 55, 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?auto=format&fit=crop&q=80&w=800', undefined, 'Sharp and professional.', 4.6),
  createProduct('32', 'Leather Chelsea Boots', 'leather-chelsea-boots', 'mens_fashion', 120, 'https://images.unsplash.com/photo-1638247025967-b4e38f787b76?auto=format&fit=crop&q=80&w=800', undefined, 'Sleek and durable.', 4.7),
  createProduct('33', 'Casual White Sneakers', 'casual-white-sneakers', 'mens_fashion', 70, 'https://images.unsplash.com/photo-1521774971864-62e842046145?auto=format&fit=crop&q=80&w=800', undefined, 'Everyday essential.', 4.5),
  createProduct('34', 'Puffer Jacket', 'mens-puffer-jacket', 'mens_fashion', 130, 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?auto=format&fit=crop&q=80&w=800', undefined, 'Winter ready.', 4.8),
  createProduct('35', 'Graphic Print T-Shirt', 'graphic-print-tshirt', 'mens_fashion', 25, 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&q=80&w=800', undefined, 'Express yourself.', 4.3),
  createProduct('36', 'Cargo Pants', 'mens-cargo-pants', 'mens_fashion', 50, 'https://images.unsplash.com/photo-1517487881594-2787fef5ebf7?auto=format&fit=crop&q=80&w=800', undefined, 'Utility meets style.', 4.4),

  // Womens Fashion (12)
  createProduct('37', 'Floral Summer Dress', 'floral-summer-dress', 'womens_fashion', 45, 'https://images.unsplash.com/photo-1515347619252-60a6bf4fffce?auto=format&fit=crop&q=80&w=800', undefined, 'Breezy and beautiful.', 4.7),
  createProduct('38', 'High-Waisted Jeans', 'high-waisted-jeans', 'womens_fashion', 55, 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?auto=format&fit=crop&q=80&w=800', undefined, 'Flattering fit.', 4.6),
  createProduct('39', 'Oversized Blazer', 'oversized-blazer', 'womens_fashion', 85, 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?auto=format&fit=crop&q=80&w=800', undefined, 'Chic and professional.', 4.8),
  createProduct('40', 'Silk Blouse', 'silk-blouse', 'womens_fashion', 70, 'https://images.unsplash.com/photo-1564257631407-4deb1f99d992?auto=format&fit=crop&q=80&w=800', undefined, 'Luxurious feel.', 4.7),
  createProduct('41', 'Pleated Midi Skirt', 'pleated-midi-skirt', 'womens_fashion', 50, 'https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa?auto=format&fit=crop&q=80&w=800', undefined, 'Elegant movement.', 4.5),
  createProduct('42', 'Leather Handbag', 'leather-handbag', 'womens_fashion', 120, 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?auto=format&fit=crop&q=80&w=800', undefined, 'Everyday essential.', 4.9),
  createProduct('43', 'Ankle Boots', 'ankle-boots', 'womens_fashion', 90, 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&q=80&w=800', undefined, 'Stylish and sturdy.', 4.6),
  createProduct('44', 'Knitted Sweater', 'knitted-sweater', 'womens_fashion', 60, 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?auto=format&fit=crop&q=80&w=800', undefined, 'Cozy comfort.', 4.8),
  createProduct('45', 'Statement Earrings', 'statement-earrings', 'womens_fashion', 20, 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?auto=format&fit=crop&q=80&w=800', undefined, 'Bold accessory.', 4.4),
  createProduct('46', 'Trench Coat', 'womens-trench-coat', 'womens_fashion', 140, 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?auto=format&fit=crop&q=80&w=800', undefined, 'Classic outerwear.', 4.8),
  createProduct('47', 'Yoga Leggings', 'yoga-leggings', 'womens_fashion', 35, 'https://images.unsplash.com/photo-1506619216599-9d16d0903dfd?auto=format&fit=crop&q=80&w=800', undefined, 'Stretch and support.', 4.7),
  createProduct('48', 'Evening Gown', 'evening-gown', 'womens_fashion', 180, 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?auto=format&fit=crop&q=80&w=800', undefined, 'For special occasions.', 4.9),

  // Home & Living (12)
  createProduct('49', 'Modern Sofa', 'modern-sofa', 'home', 599, 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&q=80&w=800', undefined, 'Comfortable and stylish.', 4.8),
  createProduct('50', 'Wooden Coffee Table', 'wooden-coffee-table', 'home', 150, 'https://images.unsplash.com/photo-1533090481720-856c6e3c1fdc?auto=format&fit=crop&q=80&w=800', undefined, 'Solid oak wood.', 4.7),
  createProduct('51', 'Floor Lamp', 'floor-lamp', 'home', 80, 'https://images.unsplash.com/photo-1507473888900-52e1adad5420?auto=format&fit=crop&q=80&w=800', undefined, 'Warm ambient lighting.', 4.6),
  createProduct('52', 'Ceramic Vase', 'ceramic-vase', 'home', 30, 'https://images.unsplash.com/photo-1581783342308-f792ca43d5bc?auto=format&fit=crop&q=80&w=800', undefined, 'Handcrafted beauty.', 4.8),
  createProduct('53', 'Cotton Bed Sheets', 'cotton-bed-sheets', 'home', 45, 'https://images.unsplash.com/photo-1629946832022-c327f74956e9?auto=format&fit=crop&q=80&w=800', undefined, 'Soft and breathable.', 4.5),
  createProduct('54', 'Wall Art Print', 'wall-art-print', 'home', 25, 'https://images.unsplash.com/photo-1580130732478-7f14bc97e724?auto=format&fit=crop&q=80&w=800', undefined, 'Abstract design.', 4.4),
  createProduct('55', 'Indoor Plant Pot', 'indoor-plant-pot', 'home', 15, 'https://images.unsplash.com/photo-1485955900006-10f4d324d411?auto=format&fit=crop&q=80&w=800', undefined, 'Minimalist design.', 4.7),
  createProduct('56', 'Kitchen Knife Set', 'kitchen-knife-set', 'home', 90, 'https://images.unsplash.com/photo-1593618998160-e34014e67546?auto=format&fit=crop&q=80&w=800', undefined, 'Professional grade.', 4.8),
  createProduct('57', 'Non-Stick Frying Pan', 'non-stick-frying-pan', 'home', 35, 'https://images.unsplash.com/photo-1584942368913-b985c9d73c5d?auto=format&fit=crop&q=80&w=800', undefined, 'Easy cooking.', 4.6),
  createProduct('58', 'Bath Towel Set', 'bath-towel-set', 'home', 40, 'https://images.unsplash.com/photo-1564356340072-d8a98d400631?auto=format&fit=crop&q=80&w=800', undefined, 'Plush and absorbent.', 4.5),
  createProduct('59', 'Scented Candle', 'scented-candle', 'home', 18, 'https://images.unsplash.com/photo-1602825266988-75fe51ae490c?auto=format&fit=crop&q=80&w=800', undefined, 'Relaxing lavender.', 4.8),
  createProduct('60', 'Throw Pillow', 'throw-pillow', 'home', 22, 'https://images.unsplash.com/photo-1584100936595-c0654b55a2e6?auto=format&fit=crop&q=80&w=800', undefined, 'Decorative accent.', 4.6),
];
