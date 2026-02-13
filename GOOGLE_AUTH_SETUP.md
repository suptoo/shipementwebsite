# 🔐 Google OAuth Setup Guide

## Overview

This guide will help you enable **Sign in with Google** for your Bongoportus e-commerce platform.

## Prerequisites

- Supabase project created
- Google Cloud Console access

---

## Step 1: Configure Google Cloud Console

### 1.1 Create/Select a Project

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select an existing one
3. Name it (e.g., "Bongoportus OAuth")

### 1.2 Enable Google+ API

1. Go to **APIs & Services** → **Library**
2. Search for "Google+ API"
3. Click **Enable**

### 1.3 Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Select **External** user type
3. Fill in required fields:
   - **App name**: Bongoportus
   - **User support email**: your-email@example.com
   - **Developer contact**: your-email@example.com
4. Click **Save and Continue**
5. Skip **Scopes** (click Save and Continue)
6. Add test users if needed
7. Click **Save and Continue**

### 1.4 Create OAuth 2.0 Credentials

1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth client ID**
3. Select **Web application**
4. Configure:
   - **Name**: Bongoportus Web Client
   - **Authorized JavaScript origins**: 
     ```
     https://rgzvlxhimentlidcdvtp.supabase.co
     http://localhost:5173
     ```
   - **Authorized redirect URIs**:
     ```
     https://rgzvlxhimentlidcdvtp.supabase.co/auth/v1/callback
     http://localhost:5173/auth/callback
     ```
5. Click **Create**
6. **Copy** your:
   - Client ID
   - Client Secret

---

## Step 2: Configure Supabase

### 2.1 Add Google Provider

1. Go to your [Supabase Dashboard](https://app.supabase.com/project/rgzvlxhimentlidcdvtp)
2. Navigate to **Authentication** → **Providers**
3. Find **Google** and click **Enable**
4. Paste your Google credentials:
   - **Client ID**: (from Step 1.4)
   - **Client Secret**: (from Step 1.4)
5. Click **Save**

### 2.2 Verify Redirect URL

Your Supabase callback URL should be:
```
https://rgzvlxhimentlidcdvtp.supabase.co/auth/v1/callback
```

This is already configured in your app.

---

## Step 3: Test Authentication

### 3.1 Local Development

1. Start your dev server:
   ```bash
   npm run dev
   ```

2. Go to the login page: `http://localhost:5173/login`

3. Click **"Sign in with Google"**

4. Complete Google authentication

5. You should be redirected back and logged in!

### 3.2 Production

Once deployed, update your Google Cloud Console redirect URIs to include your production domain:

```
https://yourdomain.com/auth/callback
```

---

## Step 4: User Profile Creation

When a user signs in with Google for the first time:

1. Supabase automatically creates an `auth.users` record
2. Our `handle_new_user()` trigger creates a `profiles` record
3. The user is logged in and redirected

The profile will use:
- **Email**: from Google account
- **Full Name**: from Google account
- **Avatar**: Google profile picture URL

---

## Troubleshooting

### Error: "redirect_uri_mismatch"

**Solution**: Verify that the redirect URI in Google Cloud Console exactly matches:
```
https://rgzvlxhimentlidcdvtp.supabase.co/auth/v1/callback
```

### Error: "Access blocked: This app's request is invalid"

**Solution**: Make sure you've enabled the Google+ API and configured the OAuth consent screen.

### User not redirected after sign-in

**Solution**: Check that `redirectTo` in `AuthContext.tsx` matches your domain:
```typescript
redirectTo: `${window.location.origin}/`
```

### Profile not created

**Solution**: Verify the `handle_new_user()` function is working:
1. Go to Supabase SQL Editor
2. Run: `SELECT * FROM profiles WHERE email = 'your-google-email@gmail.com'`
3. If empty, check trigger: `SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';`

---

## Security Best Practices

✅ **Keep Client Secret secure** - Never commit to Git
✅ **Use HTTPS in production** - Required for OAuth
✅ **Rotate secrets periodically** - Every 6-12 months
✅ **Limit OAuth scopes** - Only request email and profile
✅ **Monitor authentication logs** - Check Supabase Auth logs regularly

---

## Additional OAuth Providers

Want to add more providers? Supabase supports:

- **GitHub**
- **Facebook**
- **Twitter**
- **Discord**
- **Microsoft**
- **Apple**
- And more!

Follow a similar process:
1. Create OAuth app in provider's console
2. Configure redirect URIs
3. Enable in Supabase → Authentication → Providers
4. Add button in `Login.tsx`
5. Add method in `AuthContext.tsx`

---

## Support

Need help?
- [Supabase Auth Docs](https://supabase.com/docs/guides/auth)
- [Google OAuth Docs](https://developers.google.com/identity/protocols/oauth2)
- [GitHub Issues](https://github.com/suptoo/shipementwebsite/issues)
