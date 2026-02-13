# 🚀 Bongoportus Deployment Guide

## Quick Start

### 1. Database Setup

Run the SQL files in order:

```bash
# 1. Setup database schema
psql your_database_url < database-setup.sql

# 2. Seed initial data
psql your_database_url < 2_seed.sql
```

Or in Supabase Dashboard:
1. Go to SQL Editor
2. Copy contents of `database-setup.sql` and run
3. Then copy contents of `2_seed.sql` and run

### 2. Environment Configuration

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
