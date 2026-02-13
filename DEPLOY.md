# 🚀 Bongoportus Deployment Guide

## Quick Start

### 1. Database Setup

**Single SQL File - Run this in Supabase SQL Editor:**

```bash
# Use the complete database file (includes schema + sample data)
complete-database.sql
```

**In Supabase Dashboard:**
1. Go to [SQL Editor](https://app.supabase.com/project/rgzvlxhimentlidcdvtp/sql)
2. Click **New Query**
3. Copy entire contents of `complete-database.sql`
4. Click **Run** or press `Ctrl+Enter`
5. Wait for completion (takes 10-30 seconds)

✅ This creates all tables, triggers, functions, AND sample products in one run!

### 2. Enable Google Sign-In (Optional but Recommended)

See [GOOGLE_AUTH_SETUP.md](GOOGLE_AUTH_SETUP.md) for complete instructions.

**Quick steps:**
1. Create OAuth app in Google Cloud Console
2. Get Client ID and Client Secret
3. Add to Supabase → Authentication → Providers → Google
4. Done! Google Sign-In is enabled

### 3. Environment Configuration

```bash
# Copy the example file
cp .env.example .env

# Edit .env with your credentials
nano .env
```

Required variables:
- `VITE_SUPABASE_URL`: Your Supabase project URL
- `VITE_SUPABASE_ANON_KEY`: Your Supabase anon/public key

### 3. Install Dependencies

```bash
npm install
```

### 4. Development

```bash
npm run dev
```

### 5. Production Build

```bash
npm run build
npm run preview  # Test production build locally
```

## Deployment Platforms

### Vercel (Recommended)

```bash
npm install -g vercel
vercel
```

Add environment variables in Vercel dashboard.

### Netlify

```bash
npm run build
# Deploy the 'dist' folder
```

### Docker

```bash
docker-compose up -d
```

## Database Configuration

### Supabase Setup

1. Create a new project at https://supabase.com
2. Copy your project URL and anon key from Settings > API
3. Run SQL migrations in SQL Editor (database-setup.sql, then 2_seed.sql)
4. Update your `.env` file
5. Enable Row Level Security (RLS) policies as needed

### Required Tables

The `database-setup.sql` creates:
- profiles
- products
- orders
- cart_items
- messages
- conversations
- reviews
- And more...

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| VITE_SUPABASE_URL | Supabase project URL | Yes |
| VITE_SUPABASE_ANON_KEY | Supabase public API key | Yes |
| VITE_STRIPE_PUBLIC_KEY | Stripe public key (for payments) | No |

## Post-Deployment Checklist

- [ ] Database migrations completed
- [ ] Environment variables configured
- [ ] SSL certificate active
- [ ] Custom domain configured (optional)
- [ ] CORS settings verified
- [ ] Test user registration and login
- [ ] Test product browsing and cart
- [ ] Test seller dashboard (if applicable)
- [ ] Enable analytics (optional)

## Troubleshooting

### "Missing Supabase environment variables"
- Ensure `.env` file exists with correct values
- Check that variable names match exactly (case-sensitive)

### Database connection errors
- Verify Supabase project URL is correct
- Check that anon key hasn't expired
- Ensure RLS policies are configured

### Build errors
- Run `npm install` to ensure all dependencies are installed
- Clear node_modules and reinstall if needed
- Check Node.js version (v16+ recommended)

## Support

For issues, check:
- [Supabase Documentation](https://supabase.com/docs)
- [Vite Documentation](https://vitejs.dev)
- Project issues on GitHub
