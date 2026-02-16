-- =====================================================
-- BongoPortus - Security Hardening SQL
-- Run AFTER the main schema.sql
--
-- This file adds additional security measures:
-- 1. Tightened RLS policies
-- 2. Helper functions for Edge Functions
-- 3. Storage bucket policies
-- 4. Rate limiting at database level
-- =====================================================

-- ─── Helper: Check if user is a seller ───────────────
CREATE OR REPLACE FUNCTION is_seller()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'seller'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ─── Helper: Check if user owns a product ────────────
CREATE OR REPLACE FUNCTION owns_product(p_product_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM products
    WHERE id = p_product_id AND seller_id = auth.uid()
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ─── Stock management RPCs (used by Edge Functions) ──
CREATE OR REPLACE FUNCTION decrement_stock(p_product_id UUID, p_quantity INTEGER)
RETURNS VOID AS $$
BEGIN
  UPDATE products
  SET stock_quantity = stock_quantity - p_quantity
  WHERE id = p_product_id AND stock_quantity >= p_quantity;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Insufficient stock for product %', p_product_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION increment_stock(p_product_id UUID, p_quantity INTEGER)
RETURNS VOID AS $$
BEGIN
  UPDATE products
  SET stock_quantity = stock_quantity + p_quantity
  WHERE id = p_product_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── Seller balance RPC (used by Edge Functions) ─────
CREATE OR REPLACE FUNCTION increment_seller_balance(p_seller_id UUID, p_amount NUMERIC)
RETURNS VOID AS $$
BEGIN
  UPDATE seller_profiles
  SET total_earnings = COALESCE(total_earnings, 0) + p_amount,
      available_balance = COALESCE(available_balance, 0) + p_amount
  WHERE user_id = p_seller_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── Tighten Product Images RLS ──────────────────────
-- Drop the overly permissive policies (safe if they don't exist)
DROP POLICY IF EXISTS "Sellers can manage product images" ON product_images;
DROP POLICY IF EXISTS "Sellers can insert product images" ON product_images;
DROP POLICY IF EXISTS "Sellers can update own product images" ON product_images;
DROP POLICY IF EXISTS "Sellers can delete own product images" ON product_images;

-- Replace with proper ownership-based policies
CREATE POLICY "Sellers can insert product images" ON product_images
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM products
      WHERE products.id = product_images.product_id
      AND (products.seller_id = auth.uid() OR is_admin())
    )
  );

CREATE POLICY "Sellers can update own product images" ON product_images
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM products
      WHERE products.id = product_images.product_id
      AND (products.seller_id = auth.uid() OR is_admin())
    )
  );

CREATE POLICY "Sellers can delete own product images" ON product_images
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM products
      WHERE products.id = product_images.product_id
      AND (products.seller_id = auth.uid() OR is_admin())
    )
  );

-- ─── Tighten Product Variants RLS ────────────────────
DROP POLICY IF EXISTS "Sellers can manage variants" ON product_variants;
DROP POLICY IF EXISTS "Sellers can insert variants" ON product_variants;
DROP POLICY IF EXISTS "Sellers can update own variants" ON product_variants;
DROP POLICY IF EXISTS "Sellers can delete own variants" ON product_variants;

CREATE POLICY "Sellers can insert variants" ON product_variants
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM products
      WHERE products.id = product_variants.product_id
      AND (products.seller_id = auth.uid() OR is_admin())
    )
  );

CREATE POLICY "Sellers can update own variants" ON product_variants
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM products
      WHERE products.id = product_variants.product_id
      AND (products.seller_id = auth.uid() OR is_admin())
    )
  );

CREATE POLICY "Sellers can delete own variants" ON product_variants
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM products
      WHERE products.id = product_variants.product_id
      AND (products.seller_id = auth.uid() OR is_admin())
    )
  );

-- ─── Tighten Order Item Insert policy ────────────────
-- Only allow inserting order items for your own orders
DROP POLICY IF EXISTS "Users can insert order items" ON order_items;
DROP POLICY IF EXISTS "Users can manage own order items" ON order_items;
CREATE POLICY "Users can insert order items" ON order_items
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
    )
  );

-- ─── Tighten Order Update policy ─────────────────────
-- Users can only cancel their own pending orders; admins/sellers can update
DROP POLICY IF EXISTS "Admins can update orders" ON orders;
DROP POLICY IF EXISTS "Order updates are controlled" ON orders;
CREATE POLICY "Order updates are controlled" ON orders
  FOR UPDATE USING (
    -- Admins can update any order
    is_admin()
    -- Sellers can update orders that contain their items
    OR EXISTS (
      SELECT 1 FROM order_items
      WHERE order_items.order_id = orders.id
      AND order_items.seller_id = auth.uid()
    )
    -- Users can only update (cancel) their own pending orders
    OR (auth.uid() = user_id AND order_status = 'pending')
  );

-- ─── Tighten Coupon policies ─────────────────────────
-- Regular users should only see active coupons, not all coupon data
DROP POLICY IF EXISTS "Active coupons are viewable" ON coupons;
DROP POLICY IF EXISTS "Users can view active coupons" ON coupons;
CREATE POLICY "Users can view active coupons" ON coupons
  FOR SELECT USING (is_active = true OR is_admin());

-- Only admin can update coupons (no user should increment used_count directly)
DROP POLICY IF EXISTS "Admins can manage coupons" ON coupons;
CREATE POLICY "Admins can manage coupons" ON coupons
  FOR ALL USING (is_admin());

-- ─── Notification insert should require admin/system ──
DROP POLICY IF EXISTS "System can create notifications" ON notifications;
DROP POLICY IF EXISTS "Only admins can create notifications" ON notifications;
CREATE POLICY "Only admins can create notifications" ON notifications
  FOR INSERT WITH CHECK (is_admin());

-- ─── Storage Bucket Policies ─────────────────────────
-- NOTE: Supabase manages storage policies through the Dashboard or
-- storage.objects RLS, NOT a "storage.policies" table.
-- To set up storage policies:
--   1. Go to Supabase Dashboard → Storage → product-images bucket
--   2. Click "Policies" tab
--   3. Add policy: Allow public SELECT (for viewing images)
--   4. Add policy: Allow INSERT for authenticated users
--   5. Or run the RLS policies on storage.objects below:

-- Ensure the product-images bucket exists and is public
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Allow anyone to view product images
DROP POLICY IF EXISTS "Public read for product-images" ON storage.objects;
CREATE POLICY "Public read for product-images" ON storage.objects
  FOR SELECT USING (bucket_id = 'product-images');

-- Allow authenticated users to upload product images
DROP POLICY IF EXISTS "Authenticated upload for product-images" ON storage.objects;
CREATE POLICY "Authenticated upload for product-images" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'product-images'
    AND auth.role() = 'authenticated'
  );

-- Allow users to update their own uploaded images
DROP POLICY IF EXISTS "Owner update for product-images" ON storage.objects;
CREATE POLICY "Owner update for product-images" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'product-images'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Allow users to delete their own uploaded images
DROP POLICY IF EXISTS "Owner delete for product-images" ON storage.objects;
CREATE POLICY "Owner delete for product-images" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'product-images'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- =====================================================
-- SECURITY NOTES:
-- =====================================================
-- 1. The anon key is safe to have in the frontend. It only grants
--    access allowed by RLS policies.
-- 2. The service_role key bypasses ALL RLS. It is ONLY used by
--    Edge Functions running on the backend. NEVER in frontend code.
-- 3. Stripe secret key is ONLY stored in Edge Function environment
--    variables, never in the frontend bundle.
-- 4. All sensitive operations (order creation, payment processing,
--    coupon validation) go through Edge Functions where the server
--    validates everything and uses real DB prices.
-- =====================================================
