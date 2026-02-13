# Deployment Guide - Bongoportus E-Commerce Platform

## Deployment Options

### Option 1: Vercel (Recommended for Frontend)

1. **Install Vercel CLI**
```bash
npm i -g vercel
```

2. **Login to Vercel**
```bash
vercel login
```

3. **Deploy**
```bash
vercel --prod
```

4. **Set Environment Variables** in Vercel Dashboard:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`

### Option 2: Netlify

1. **Build the project**
```bash
npm run build
```

2. **Deploy to Netlify**
   - Drag and drop `dist` folder to Netlify
   - Or connect GitHub repository

3. **Set Environment Variables** in Netlify Settings

### Option 3: Docker

1. **Build Docker image**
```bash
docker build -t bongoportus-ecommerce .
```

2. **Run container**
```bash
docker run -p 80:80 bongoportus-ecommerce
```

3. **Using Docker Compose**
```bash
docker-compose up -d
```

## Backend Setup (Supabase)

### 1. Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Create a new project
3. Note your project URL and anon key

### 2. Run Database Schema

1. Navigate to SQL Editor in Supabase Dashboard
2. Copy contents of `supabase-setup.sql`
3. Execute the SQL script

### 3. Configure Storage (Optional)

For product images and user uploads:

1. Go to Storage in Supabase Dashboard
2. Create buckets:
   - `products` (public)
   - `shops` (public)
   - `users` (public)

3. Set policies for public access

### 4. Configure Authentication

1. Enable Email authentication
2. Configure email templates
3. Set up email provider (SMTP)

## Stripe Configuration

### 1. Get API Keys

1. Go to [https://dashboard.stripe.com](https://dashboard.stripe.com)
2. Get Test/Live API keys
3. Update in code or environment variables

### 2. Set Up Webhooks (Optional)

For payment confirmations:

```
Webhook URL: https://your-domain.com/api/stripe-webhook
Events: payment_intent.succeeded, payment_intent.payment_failed
```

## Environment Variables

### Development (.env.local)

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
VITE_STRIPE_PUBLISHABLE_KEY=pk_test_...
```

### Production

Set these in your hosting platform:

- Vercel: Project Settings → Environment Variables
- Netlify: Site Settings → Build & Deploy → Environment
- Docker: docker-compose.yml or .env file

## Post-Deployment Checklist

- [ ] Database schema executed successfully
- [ ] Admin account created
- [ ] Test user registration and login
- [ ] Test product creation
- [ ] Test cart and checkout
- [ ] Test Stripe payment (test mode)
- [ ] Verify email notifications work
- [ ] Set up custom domain
- [ ] Configure SSL certificate
- [ ] Set up monitoring (Sentry, LogRocket)
- [ ] Configure backup strategy

## Performance Optimization

### 1. Enable CDN

Use Cloudflare or similar for:
- Static asset caching
- DDoS protection
- Image optimization

### 2. Database Indexing

Already configured in `supabase-setup.sql`:
- Product search indexes
- Category/brand lookups
- Order queries

### 3. Image Optimization

Use CDN with automatic resizing:
- Cloudinary
- ImageKit
- Supabase Storage with transformations

## Monitoring & Analytics

### Application Monitoring

```bash
npm install --save @sentry/react
```

### Performance Monitoring

```bash
npm install --save web-vitals
```

### Analytics

- Google Analytics
- Mixpanel
- Plausible (privacy-focused)

## Security Considerations

### 1. API Keys

- Never commit keys to repository
- Use environment variables
- Rotate keys periodically

### 2. Database Security

- Enable RLS (Row Level Security) in Supabase
- Restrict API access
- Set up proper policies

### 3. Payment Security

- Use Stripe's secure checkout
- Never store card details
- Implement 3D Secure

## Backup Strategy

### Database Backups

Supabase provides:
- Automatic daily backups (7 days retention on free tier)
- Manual backups via Dashboard
- Export to SQL file

### Custom Backup Script

```bash
# Export database
pg_dump $DATABASE_URL > backup-$(date +%Y%m%d).sql
```

## Scaling Considerations

### Database

- Upgrade Supabase plan for more connections
- Implement connection pooling
- Add read replicas for reporting

### Frontend

- Use CDN for static assets
- Implement code splitting
- Enable service workers (PWA)

### Caching

- Redis for session storage
- Cache product listings
- Cache category/brand data

## Troubleshooting

### Build Errors

```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm install
npm run build
```

### Database Connection Issues

- Check Supabase project status
- Verify credentials
- Check network/firewall settings

### Payment Issues

- Verify Stripe keys are correct
- Check webhook configuration
- Review Stripe dashboard logs

## Support

For deployment issues:
- Check logs in hosting platform
- Review Supabase logs
- Check browser console for errors

---

**For additional help, consult the main README.md or open an issue on GitHub.**
