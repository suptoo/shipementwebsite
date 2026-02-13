# Bongoportus - Complete Setup Guide

## 🚀 Project Overview

Bongoportus is a full-stack multi-vendor e-commerce platform featuring:
- Real-time chat support with pre-chat survey
- Product catalog with variants, images, and reviews
- Shopping cart and checkout with Stripe payment
- Multi-vendor seller management
- Role-based access control (Admin/Seller/User)
- Order tracking and management
- Mobile-responsive design with modern UI

## 📋 Technology Stack

- **Frontend**: React 18 + TypeScript + Vite
- **Styling**: Tailwind CSS
- **Backend**: Supabase (Auth, PostgreSQL, Realtime, Storage)
- **Icons**: Lucide React
- **Routing**: React Router DOM v6

---

## 🛠️ Setup Instructions

### Step 1: Install Dependencies

```bash
npm install
```

### Step 2: Set Up Supabase

1. Go to [https://supabase.com](https://supabase.com) and create a new project
2. Wait for the project to be ready (takes ~2 minutes)
3. Get your credentials:
   - Go to **Project Settings** → **API**
   - Copy your **Project URL** and **anon public** key

### Step 3: Configure Environment Variables

1. Create a `.env` file in the project root:

```bash
cp .env.example .env
```

2. Edit `.env` and add your Supabase credentials:

```env
VITE_SUPABASE_URL=your_project_url_here
VITE_SUPABASE_ANON_KEY=your_anon_key_here
```

### Step 4: Set Up Database

1. In your Supabase dashboard, go to **SQL Editor**
2. Open the file `supabase-setup.sql` from this project
3. Copy and paste the entire SQL script into the SQL Editor
4. Click **Run** to execute the script

This will create:
- All necessary tables (profiles, products, inquiries, messages)
- Row Level Security policies
- Database triggers
- Storage bucket for chat images
- Sample product data

### Step 5: Create an Admin User

1. Run the application (see below)
2. Sign up with your email
3. In Supabase dashboard, go to **SQL Editor** and run:

```sql
UPDATE profiles SET role = 'admin' WHERE email = 'your_email@example.com';
```

Replace `your_email@example.com` with the email you used to sign up.

### Step 6: Configure Storage

1. In Supabase dashboard, go to **Storage**
2. Verify that the `chat-attachments` bucket exists (created by the SQL script)
3. Make sure it's set to **Public**

---

## 🏃 Running the Application

### Development Mode

```bash
npm run dev
```

The app will be available at `http://localhost:5173`

### Build for Production

```bash
npm run build
```

### Preview Production Build

```bash
npm run preview
```

---

## 📱 Using the Application

### As a User:

1. **Sign Up/Login**: Create an account or log in
2. **Browse Products**: Explore product catalog with filters and search
3. **Shopping Cart**: Add products to cart, manage quantities
4. **Checkout**: Complete purchase with multiple payment options
5. **Order Tracking**: Track your orders from processing to delivery
6. **Start Chat**: Click the floating chat button (bottom-right)
   - First time: Fill out the survey (Amount, Address, Days)
   - After: Direct access to your open chat session
7. **Send Messages**: Type messages or attach images using the paperclip icon

### As an Admin:

1. **Manage Platform**: 
   - Approve/reject seller accounts
   - Approve/reject products
   - Manage orders and refunds
   - Create coupons and campaigns
2. **Admin Dashboard**: 
   - View platform analytics (users, sellers, products, orders)
   - Monitor pending approvals
   - Track revenue and sales
3. **Customer Support**:
   - View all open inquiries
   - Chat with customers
   - Close resolved inquiries

---

## 🎨 Features Breakdown

### 1. Authentication & Profiles
- Email/password authentication via Supabase Auth
- Automatic profile creation on signup
- Role-based access (admin/user)

### 2. Product Marketplace
- **Users**: Browse products, add to cart, purchase
- **Sellers**: Manage shop, products, orders, and earnings
- **Admins**: Platform oversight, approve sellers/products
- Responsive grid layout with filters and search
- Product variants (size, color, type)
- Reviews and ratings system

### 3. Gated Chat System
**Critical Logic**:
- When user clicks "Chat Support":
  1. Check if they have an `open` inquiry
  2. If YES → Open chat directly
  3. If NO → Show survey modal first
  4. On survey submit → Create inquiry → Open chat

### 4. Real-Time Messaging
- Instant message delivery using Supabase Realtime
- Image upload to Supabase Storage
- Display images inline in chat bubbles
- Admin sees customer survey context at top of chat

### 5. Admin Dashboard
- List all open inquiries
- View customer requirements (survey answers)
- Open chat with any customer
- Close inquiries when resolved

---

## 🗂️ Project Structure

```
Bongoportus/
├── src/
│   ├── components/
│   │   ├── admin/
│   │   │   └── AdminDashboard.tsx      # Admin inquiry management
│   │   ├── auth/
│   │   │   └── Login.tsx                # Login/Signup page
│   │   ├── chat/
│   │   │   ├── ChatSupport.tsx          # Floating chat button + logic
│   │   │   ├── ChatWindow.tsx           # Real-time chat interface
│   │   │   └── SurveyModal.tsx          # Pre-chat survey form
│   │   ├── common/
│   │   │   └── Navbar.tsx               # Navigation bar
│   │   └── products/
│   │       ├── ProductGrid.tsx          # Product listing
│   │       └── ProductModal.tsx         # Add/Edit product form
│   ├── context/
│   │   └── AuthContext.tsx              # Auth state management
│   ├── lib/
│   │   └── supabase.ts                  # Supabase client
│   ├── types/
│   │   ├── database.ts                  # Supabase types
│   │   └── index.ts                     # TypeScript interfaces
│   ├── App.tsx                          # Main app with routing
│   ├── main.tsx                         # Entry point
│   └── index.css                        # Global styles
├── supabase-setup.sql                   # Database setup script
├── .env.example                         # Environment template
└── package.json                         # Dependencies
```

---

## 🔒 Security Features

- Row Level Security (RLS) on all tables
- Users can only see their own inquiries
- Admins can see all inquiries
- Only admins can modify products
- Image uploads restricted to authenticated users
- Secure file storage with Supabase

---

## 🎨 Design Theme

- **Primary Colors**: Deep Blue (#1e3a8a - blue-900), Slate Grey
- **Accent**: Blue-700 for gradients
- **Background**: Slate-50
- **Mobile-First**: Responsive breakpoints (md, lg, xl)
- **Icons**: Lucide React (consistent style)

---

## 📊 Database Schema Summary

### Tables:
1. **profiles**: User information with roles (user, seller, admin)
2. **seller_profiles**: Seller KYC and verification data
3. **shops**: Seller shop information
4. **categories**: Product categories with hierarchy
5. **brands**: Product brands
6. **products**: Product catalog with variants and images
7. **product_images**: Product image gallery
8. **product_variants**: Product variants (size, color, etc.)
9. **orders**: Order management
10. **order_items**: Individual order items
11. **cart_items**: Shopping cart
12. **reviews**: Product reviews and ratings
13. **wishlists**: User wishlists
14. **coupons**: Discount coupons
15. **user_addresses**: Delivery addresses
16. **notifications**: System notifications
17. **inquiries**: Chat sessions with survey data
18. **messages**: Chat messages with optional images

### Key Relationships:
- `products.seller_id` → `seller_profiles.id`
- `products.category_id` → `categories.id`
- `orders.user_id` → `profiles.id`
- `order_items.product_id` → `products.id`
- `inquiries.user_id` → `profiles.id`
- `messages.inquiry_id` → `inquiries.id`

---

## 🐛 Troubleshooting

### Issue: Can't connect to Supabase
- Verify `.env` file has correct credentials
- Check Supabase project is active (not paused)

### Issue: Chat images not uploading
- Verify `chat-attachments` bucket exists and is public
- Check storage policies in Supabase dashboard

### Issue: Not seeing admin features
- Run the SQL command to set your role to 'admin'
- Refresh the page after updating

### Issue: Real-time not working
- Check Supabase Realtime is enabled for your project
- Verify RLS policies allow reading messages

---

## 📚 Additional Commands

### Clear All Data (Development)
```sql
TRUNCATE messages, inquiries, products, profiles CASCADE;
```

### Make Multiple Admins
```sql
UPDATE profiles SET role = 'admin' WHERE email IN ('admin1@example.com', 'admin2@example.com');
```

---

## 🎯 Next Steps

1. **Customize**: Update colors, logo, and branding in components
2. **Enhance**: Add email notifications for new inquiries
3. **Deploy**: Deploy to Vercel, Netlify, or your preferred platform
4. **Monitor**: Set up Supabase analytics and logging

---

## 💡 Support

For issues or questions:
1. Check Supabase logs in dashboard
2. Review browser console for errors
3. Verify all SQL policies are correctly applied

---

**Built with ❤️ using React, Tailwind CSS, and Supabase**
