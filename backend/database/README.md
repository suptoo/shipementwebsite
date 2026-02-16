# BongoPortus Database Setup

## Quick Start (Single File)

**Use this if you want everything in one go:**

1. Sign up at your Supabase project with email: `umorfaruksupto@gmail.com`
2. Go to **SQL Editor** in Supabase Dashboard
3. Copy and paste the entire contents of **`complete-setup.sql`**
4. Click **Run**
5. Done! ✅

This single file includes:
- All tables and schema
- All RLS policies (66 policies)
- Helper functions for security
- Storage bucket for product images
- Triggers for auto-updates
- 8 categories, 6 brands, 5 coupons
- 20 demo products with real images
- Product variants

---

## Alternative: Step-by-Step (3 Files)

**Use this if you want more control:**

### Step 1: Schema
Run `schema.sql` first - creates all tables, RLS policies, triggers, basic seed data.

### Step 2: Security Hardening
Run `security-hardening.sql` - adds additional security functions and storage policies.

### Step 3: Dummy Products
Run `dummy-products.sql` - adds 20 test products with images.

---

## Important Notes

⚠️ **Admin User Required**: You MUST sign up with `umorfaruksupto@gmail.com` first, then run the SQL. Otherwise, products won't be created.

✅ **Idempotent**: All files are safe to re-run multiple times. They use:
- `CREATE TABLE IF NOT EXISTS`
- `DROP POLICY IF EXISTS` before every `CREATE POLICY`
- `ON CONFLICT DO NOTHING` for seed data
- `INSERT ... ON CONFLICT` for upserts

🔄 **Updates**: If you modify categories, brands, or products, just re-run the SQL - it will update existing records.

---

## File Descriptions

| File | Lines | Purpose |
|------|-------|---------|
| **complete-setup.sql** | ~940 | Everything in one file (RECOMMENDED) |
| schema.sql | ~780 | Core database schema + RLS |
| security-hardening.sql | ~230 | Additional security + storage |
| dummy-products.sql | ~390 | 20 test products with images |

---

## After Running SQL

1. **Verify** by checking the output - should show product counts
2. **Mobile App** and **Website** will automatically connect (keys already configured)
3. **Browse products** without login (public access enabled)
4. **Images** load instantly (using picsum.photos CDN)

---

## Troubleshooting

**"Admin user not found"**  
→ Sign up with `umorfaruksupto@gmail.com` first, then re-run the SQL

**"Policy already exists"**  
→ Ignore this - means you ran it before. Script will continue.

**"Table already exists"**  
→ Ignore this - script handles it gracefully with `IF NOT EXISTS`

**Images not showing in app?**  
→ All products now use `picsum.photos` URLs - should work immediately. If not, check your internet connection.
