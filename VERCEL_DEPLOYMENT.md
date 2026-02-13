# 🚀 Vercel Deployment - Environment Variables

## Required Environment Variables

Copy these to your Vercel project settings:

### 📍 Vercel Dashboard Location
1. Go to: https://vercel.com/dashboard
2. Select your project (or import from GitHub)
3. Go to **Settings** → **Environment Variables**
4. Add each variable below

---

## Environment Variables to Add

### 1. Supabase URL
```
Name:  VITE_SUPABASE_URL
Value: https://rgzvlxhimentlidcdvtp.supabase.co
```

### 2. Supabase Anon Key
```
Name:  VITE_SUPABASE_ANON_KEY
Value: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJnenZseGhpbWVudGxpZGNkdnRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5ODk5NDMsImV4cCI6MjA4NjU2NTk0M30.wpy1fITfTXXLW9K8WHHdkyNSHEgdRjeXFXRgG-4ktgAq
```

### 3. Stripe Public Key (Optional - if using Stripe)
```
Name:  VITE_STRIPE_PUBLIC_KEY
Value: pk_test_your_stripe_key_here
```

---

## 🔧 Important Vercel Settings

### Build Settings

**Framework Preset**: `Vite`

**Build Command**:
```bash
npm run build
```

**Output Directory**:
```
dist
```

**Install Command**:
```bash
npm install
```

**Node Version**: `18.x` (or higher)

---

## 📝 Quick Setup Steps

### Option 1: Using Vercel Dashboard

1. **Import your repository**
   - Go to https://vercel.com/new
   - Click "Import Git Repository"
   - Select: `suptoo/shipementwebsite`
   - Click "Import"

2. **Configure Project**
   - Framework Preset: **Vite** (auto-detected)
   - Root Directory: `./` (leave default)
   - Click "Deploy"

3. **Add Environment Variables**
   - After first deployment, go to **Settings** → **Environment Variables**
   - Add the two required variables above
   - Click "Redeploy" to apply changes

### Option 2: Using Vercel CLI

```bash
# Install Vercel CLI globally
npm i -g vercel

# Navigate to project directory
cd shipementwebsite

# Login to Vercel
vercel login

# Deploy (first time - will prompt for settings)
vercel

# Follow prompts:
# - Set up and deploy? Y
# - Scope: Your account
# - Link to existing project? N
# - Project name: bongoportus (or your choice)
# - Directory: ./ (just press Enter)
# - Override settings? N

# After deployment, add environment variables
vercel env add VITE_SUPABASE_URL
# Paste: https://rgzvlxhimentlidcdvtp.supabase.co
# Select: Production, Preview, Development

vercel env add VITE_SUPABASE_ANON_KEY
# Paste: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJnenZseGhpbWVudGxpZGNkdnRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5ODk5NDMsImV4cCI6MjA4NjU2NTk0M30.wpy1fITfTXXLW9K8WHHdkyNSHEgdRjeXFXRgG-4ktgAq
# Select: Production, Preview, Development

# Redeploy with new environment variables
vercel --prod
```

---

## 🔐 Google OAuth Configuration for Production

After deploying to Vercel, update your Google OAuth settings:

### 1. Get your Vercel domain
Example: `https://bongoportus.vercel.app`

### 2. Update Google Cloud Console

Go to [Google Cloud Console](https://console.cloud.google.com) → APIs & Services → Credentials

**Add to Authorized JavaScript origins:**
```
https://bongoportus.vercel.app
https://rgzvlxhimentlidcdvtp.supabase.co
```

**Add to Authorized redirect URIs:**
```
https://rgzvlxhimentlidcdvtp.supabase.co/auth/v1/callback
https://bongoportus.vercel.app/
```

### 3. Update Supabase Redirect URLs (Optional)

Go to [Supabase Dashboard](https://app.supabase.com/project/rgzvlxhimentlidcdvtp/auth/url-configuration)

**Add to Redirect URLs:**
```
https://bongoportus.vercel.app/
https://bongoportus.vercel.app/**
```

---

## 🎯 Post-Deployment Checklist

After deploying to Vercel:

- [ ] ✅ Environment variables added
- [ ] ✅ Build succeeds (check Deployments tab)
- [ ] ✅ Site loads correctly
- [ ] ✅ Database connection works (browse products)
- [ ] ✅ Email authentication works
- [ ] ✅ Google OAuth configured (if enabled)
- [ ] ✅ Add custom domain (optional)
- [ ] ✅ Enable HTTPS (automatic on Vercel)
- [ ] ✅ Test checkout flow
- [ ] ✅ Test admin panel access

---

## 🌐 Custom Domain (Optional)

### Add Your Own Domain

1. Go to Vercel Dashboard → Your Project → **Settings** → **Domains**
2. Click **Add Domain**
3. Enter your domain: `yourdomain.com`
4. Follow DNS configuration instructions
5. Update Google OAuth redirect URIs with your custom domain

---

## 📊 Performance Optimization

Vercel automatically provides:

✅ **CDN**: Global edge network
✅ **SSL**: Automatic HTTPS
✅ **Compression**: Gzip/Brotli compression
✅ **Caching**: Static asset caching
✅ **Image Optimization**: Automatic (if using Vercel Image)
✅ **Analytics**: Built-in analytics dashboard

---

## 🐛 Troubleshooting

### Build fails with "Module not found"
**Solution**: Ensure all dependencies are in `package.json`, run `npm install` locally to verify

### Environment variables not working
**Solution**: 
- Variable names must start with `VITE_` for Vite apps
- Redeploy after adding variables
- Check they're set for the correct environment (Production)

### Google OAuth redirect fails
**Solution**: 
- Verify callback URL in Google Console matches exactly
- Check Supabase redirect URLs include your Vercel domain
- Clear browser cache and try again

### 404 on page refresh
**Solution**: Vite handles this automatically with `vite.config.ts`. If issue persists, add `vercel.json`:
```json
{
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
}
```

---

## 🆘 Support Links

- **Vercel Docs**: https://vercel.com/docs
- **Vite Deployment**: https://vitejs.dev/guide/static-deploy.html#vercel
- **Supabase + Vercel**: https://supabase.com/docs/guides/hosting/vercel
- **Project GitHub**: https://github.com/suptoo/shipementwebsite

---

## 📦 Summary: Copy/Paste for Vercel

**Environment Variables:**
```
VITE_SUPABASE_URL=https://rgzvlxhimentlidcdvtp.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJnenZseGhpbWVudGxpZGNkdnRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5ODk5NDMsImV4cCI6MjA4NjU2NTk0M30.wpy1fITfTXXLW9K8WHHdkyNSHEgdRjeXFXRgG-4ktgAq
```

**OAuth Callback URL:**
```
https://rgzvlxhimentlidcdvtp.supabase.co/auth/v1/callback
```

**That's it! Your app will be live in minutes! 🚀**
