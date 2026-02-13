# Bongoportus - Multi-Vendor E-Commerce Platform

A full-featured, production-ready multi-vendor e-commerce platform built with React, TypeScript, Supabase, and Stripe. Similar to platforms like Daraz, this system supports multiple sellers, comprehensive product management, order processing, and secure payment integration.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![TypeScript](https://img.shields.io/badge/TypeScript-5.3-blue)
![React](https://img.shields.io/badge/React-18.2-blue)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-green)
![Stripe](https://img.shields.io/badge/Stripe-Payments-purple)

## 🚀 Features

### Customer Features
- 🔐 **User Authentication** - Email/phone registration with OTP verification
- 🔍 **Advanced Search & Filters** - Search by category, brand, price, rating
- 🛒 **Shopping Cart** - Add to cart with quantity management
- 💳 **Multiple Payment Methods** - Cash on Delivery, Card Payment (Stripe), Mobile Banking
- 📦 **Order Tracking** - Real-time order status updates
- ⭐ **Reviews & Ratings** - Product reviews with photo uploads
- ❤️ **Wishlist** - Save products for later
- 🎟️ **Coupon System** - Apply discount coupons at checkout
- 💬 **Direct Messaging** - Chat directly with sellers about products
- 📱 **Responsive Design** - Mobile-first, works on all devices
- 🎫 **Support Tickets** - Submit and track support requests with admin team

### Seller Features (Vendor Panel)
- 📝 **Seller Registration** - KYC verification with document upload
- 📊 **Seller Dashboard** - Overview of orders, products, and earnings
- 🏪 **Shop Management** - Customize shop name, logo, banner, description
- 📦 **Product Management** - Add/edit/delete products with variants and images
- 💰 **Financial Management** - View earnings, commission reports, withdrawal requests
- 📋 **Order Management** - Accept/reject orders, update status, print invoices
- 💬 **Customer Communication** - Direct messaging with buyers about products and orders
- 🔔 **Real-time Notifications** - Get notified of new orders and messages

### Admin Features
- 🎛️ **Admin Dashboard** - Platform analytics and metrics
- 👥 **User Management** - Manage users, block/unblock accounts
- 🏬 **Seller Management** - Approve sellers, verify documents, set commissions
- 📦 **Product Management** - Add/edit/delete ANY product, approve seller products, manage categories/brands
- 📋 **Order Management** - Oversee all orders, handle refunds
- 🎯 **Marketing Tools** - Create coupons, campaigns, flash sales
- 📧 **Notifications** - Email, SMS, and push notifications
- 💬 **Support System** - Manage support tickets, help customers and sellers
- 🎨 **CMS Management** - Manage banners, sliders, pages
- 📊 **Reports** - Sales reports, seller performance, analytics

### Technical Features
- 🔒 **Security** - SSL, two-factor authentication, fraud detection
- 🚚 **Courier Integration** - Ready for Pathao, Steadfast, RedX integration
- 🌐 **API-First** - RESTful API architecture via Supabase
- 📱 **PWA Ready** - Progressive Web App capabilities
- ⚡ **Performance** - Optimized with caching and lazy loading
- 🎨 **Modern UI** - Tailwind CSS with beautiful gradients and animations

## 🛠️ Tech Stack

- **Frontend**: React 18.2, TypeScript 5.3, Vite 5.0
- **Styling**: Tailwind CSS 3.3
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Realtime)
- **Payments**: Stripe (@stripe/stripe-js)
- **State Management**: Zustand (cart), React Context (auth)
- **Routing**: React Router DOM 6.20
- **Icons**: Lucide React
- **Build Tool**: Vite

## 📋 Prerequisites

- Node.js 18+ and npm
- Supabase account (free tier available)
- Stripe account (test mode for development)
- Git

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/bongoportus.git
cd bongoportus
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Set Up Supabase

1. Create a new project at [supabase.com](https://supabase.com)
2. Go to SQL Editor and run the schema from `supabase-setup.sql`
3. Enable Email Auth in Authentication > Providers
4. Configure Storage bucket for product images

### 4. Configure Environment Variables

Create a `.env` file in the root directory:

```env
VITE_SUPABASE_URL=your_supabase_project_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
VITE_STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key
```

### 5. Run Development Server

```bash
npm run dev
```

Visit `http://localhost:3000`

### 6. Login Credentials

**Default Admin:**
- Email: `admin@bongoportus.com`
- Password: `admin123`

**Test User:**
- Email: `user@bongoportus.com`
- Password: `user123`

## 📂 Project Structure

```
Bongoportus/
├── src/
│   ├── components/
│   │   ├── admin/           # Admin dashboard components
│   │   ├── auth/            # Login/signup components
│   │   ├── chat/            # Customer support chat
│   │   ├── common/          # Shared components (Navbar, Button, etc.)
│   │   ├── products/        # Product display components
│   │   └── ...
│   ├── context/             # React Context (AuthContext)
│   ├── hooks/               # Custom React hooks
│   ├── lib/                 # Utilities (Supabase, Stripe clients)
│   ├── pages/               # Page components (Home, Cart, Checkout)
│   ├── services/            # API services (products, orders, cart)
│   ├── store/               # Zustand stores (cart store)
│   ├── types/               # TypeScript type definitions
│   ├── App.tsx              # Main app component with routing
│   └── main.tsx             # Entry point
├── public/                  # Static assets
├── supabase-setup.sql       # Database schema
├── API_GUIDE.md             # API documentation
├── DEPLOYMENT.md            # Deployment guide
└── package.json             # Dependencies
```

## 💾 Database Schema

The platform uses 20+ tables for comprehensive functionality:

**Core Tables:**
- `profiles` - User accounts with role-based permissions
- `seller_profiles` - Seller KYC and verification
- `shops` - Seller shop information
- `products` - Product catalog
- `product_images` - Product image gallery
- `product_variants` - Size, color, type variants
- `categories` - Hierarchical product categories
- `brands` - Product brands

**E-Commerce:**
- `cart_items` - Shopping cart
- `orders` - Order records with Stripe integration
- `order_items` - Individual order line items
- `reviews` - Product reviews and ratings
- `wishlists` - User wishlists
- `coupons` - Discount coupons
- `user_addresses` - Delivery addresses

**System:**
- `notifications` - User notifications
- `conversations` - Direct messaging (buyer-seller, buyer-admin, seller-admin)
- `messages` - Chat messages
- `support_tickets` - Admin support system
- `ticket_messages` - Support ticket conversations
- `cms_pages` - Content management
- `banners` - Homepage banners

See `supabase-setup.sql` for complete schema with indexes, triggers, and seed data.

## 🔐 Authentication & Roles

The platform supports three user roles:

- **User** - Browse, purchase, review products
- **Seller** - Manage shop, products, orders
- **Admin** - Platform oversight and management

Role-based access is enforced through Supabase Row Level Security (RLS) policies.

## 💳 Payment Integration

Stripe is integrated for card payments:

- Test mode for development
- Production keys for live transactions
- Support for multiple currencies
- Secure payment intent flow
- Webhook support for payment status updates

See `src/lib/stripe.ts` for payment utilities.

## 📡 API Services

All database operations are abstracted into service layers:

- **productService** - Product CRUD, filtering, search
- **cartService** - Cart operations, sync
- **orderService** - Order creation, status updates, coupons

See `API_GUIDE.md` for complete API documentation with examples.

## 🎨 Customization

### Branding
- Update logo in `src/components/common/Navbar.tsx`
- Modify color scheme in `tailwind.config.js`
- Customize homepage in `src/pages/Home.tsx`

### Payment Gateway
- Replace Stripe with local gateway in `src/lib/stripe.ts`
- Update checkout flow in `src/pages/Checkout.tsx`

### Courier Integration
- Implement courier APIs in `src/services/courierService.ts`
- Add tracking in `src/pages/OrderTracking.tsx`

## 🚀 Deployment

### Vercel (Recommended)

```bash
npm run build
vercel deploy
```

### Netlify

```bash
npm run build
netlify deploy --prod --dir=dist
```

### Docker

```bash
docker build -t bongoportus .
docker run -p 80:80 bongoportus
```

See `DEPLOYMENT.md` for detailed deployment instructions.

## 📚 Documentation

- [API Guide](API_GUIDE.md) - Complete API documentation
- [Deployment Guide](DEPLOYMENT.md) - Deployment instructions
- [Setup Guide](SETUP_GUIDE.md) - Detailed setup walkthrough

## 🧪 Testing

```bash
# Run tests (when configured)
npm test

# Run linter
npm run lint

# Type checking
npm run type-check
```

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- Inspired by Daraz and other multi-vendor platforms
- Built with [React](https://react.dev/)
- Backend powered by [Supabase](https://supabase.com)
- Payments by [Stripe](https://stripe.com)
- Styled with [Tailwind CSS](https://tailwindcss.com)

## 📞 Support

For support, email support@bongoportus.com or open an issue in the repository.

## 🗺️ Roadmap

- [ ] Mobile app (React Native)
- [ ] AI product recommendations
- [ ] Advanced analytics dashboard
- [ ] Multi-language support
- [ ] Seller mobile app
- [ ] Social media integration
- [ ] Live streaming for product demos
- [ ] Affiliate marketing system

---

**Made with ❤️ for the e-commerce community**
