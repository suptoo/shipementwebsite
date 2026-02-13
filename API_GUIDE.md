# API Documentation - Bongoportus E-Commerce

## Service Layer Architecture

The application uses a service layer to interact with Supabase. All database operations are centralized in service files.

## Product Service

### Get Products with Filters

```typescript
import { productService } from '@/services/productService';

const result = await productService.getProducts(
  {
    categoryId: 'uuid',
    brandId: 'uuid',
    minPrice: 100,
    maxPrice: 5000,
    rating: 4,
    searchQuery: 'laptop',
    sortBy: 'price_asc' | 'price_desc' | 'rating' | 'newest' | 'popular'
  },
  page, // 1-based
  limit  // default 20
);

// Returns: PaginatedResponse<Product>
```

### Get Single Product

```typescript
// By ID or slug
const product = await productService.getProduct('product-slug-or-uuid');
```

### Get Featured Products

```typescript
const featured = await productService.getFeaturedProducts(10);
```

### Get Categories

```typescript
const categories = await productService.getCategories();
// Returns categories with subcategories populated
```

### Get Product Reviews

```typescript
const reviews = await productService.getProductReviews('product-id');
```

### Add Review

```typescript
await productService.addReview(
  'product-id',
  'user-id',
  5, // rating
  'Great product!',
  'Very satisfied',
  ['image-url-1', 'image-url-2'] // optional
);
```

## Cart Service

### Get User Cart

```typescript
import { cartService } from '@/services/cartService';

const cart = await cartService.getCart('user-id');
```

### Add to Cart

```typescript
await cartService.addToCart(
  'user-id',
  'product-id',
  2, // quantity
  'variant-id' // optional
);
```

### Update Quantity

```typescript
await cartService.updateQuantity('cart-item-id', 5);
```

### Remove from Cart

```typescript
await cartService.removeFromCart('cart-item-id');
```

### Clear Cart

```typescript
await cartService.clearCart('user-id');
```

### Sync Local Cart

```typescript
// Merge local cart with server cart after login
const mergedCart = await cartService.syncCart('user-id', localCartItems);
```

## Order Service

### Create Order

```typescript
import { orderService } from '@/services/orderService';

const order = await orderService.createOrder({
  userId: 'user-id',
  cartItems: [
    {
      productId: 'product-id',
      variantId: 'variant-id', // optional
      quantity: 2,
      price: 1500,
      productName: 'Product Name',
      productImageUrl: 'image-url',
      sellerId: 'seller-id',
      shopId: 'shop-id',
      commissionRate: 15
    }
  ],
  address: addressObject,
  paymentMethod: 'cod' | 'card' | 'mobile',
  couponCode: 'DISCOUNT10', // optional
  shippingCharge: 50,
  taxRate: 0.05 // optional
});
```

### Get User Orders

```typescript
const orders = await orderService.getUserOrders('user-id');
```

### Get Single Order

```typescript
const order = await orderService.getOrder('order-id');
```

### Update Order Status

```typescript
await orderService.updateOrderStatus('order-id', 'shipped');
// Status: pending, confirmed, processing, shipped, delivered, cancelled, returned
```

### Update Payment Status

```typescript
await orderService.updatePaymentStatus(
  'order-id',
  'paid',
  'stripe-payment-intent-id' // optional
);
```

### Apply Coupon

```typescript
const coupon = await orderService.applyCoupon('DISCOUNT10', subtotal);

if (coupon) {
  const discount = orderService.calculateDiscount(coupon, subtotal);
  console.log(`Discount: ${discount}`);
}
```

## Cart Store (Zustand)

### Usage

```typescript
import { useCartStore } from '@/store/cartStore';

function MyComponent() {
  const { items, addItem, removeItem, updateQuantity, clearCart, getTotalItems, getSubtotal } = useCartStore();

  // Add item
  addItem(product, variantId, quantity);

  // Remove item
  removeItem(cartItemId);

  // Update quantity
  updateQuantity(cartItemId, newQuantity);

  // Clear cart
  clearCart();

  // Get totals
  const totalItems = getTotalItems();
  const subtotal = getSubtotal();

  return <div>Cart has {totalItems} items</div>;
}
```

## Authentication

### Sign Up

```typescript
import { useAuth } from '@/context/AuthContext';

const { signUp } = useAuth();

await signUp('email@example.com', 'password', 'Full Name');
```

### Sign In

```typescript
const { signIn } = useAuth();

await signIn('email@example.com', 'password');
```

### Sign Out

```typescript
const { signOut } = useAuth();

await signOut();
```

### Get Current User

```typescript
const { user, loading, isAdmin, isSeller } = useAuth();

if (loading) return <div>Loading...</div>;

if (isAdmin) {
  // Show admin features
}
```

## Direct Supabase Queries

For custom queries not covered by services:

```typescript
import { supabase } from '@/lib/supabase';

// Example: Get user addresses
const { data, error } = await supabase
  .from('user_addresses')
  .select('*')
  .eq('user_id', userId)
  .order('is_default', { ascending: false });

// Example: Add to wishlist
await supabase
  .from('wishlists')
  .insert({
    user_id: userId,
    product_id: productId
  });
```

## Stripe Integration

### Initialize Stripe

```typescript
import { getStripe } from '@/lib/stripe';

const stripe = await getStripe();
```

### Format Amount

```typescript
import { formatAmountForStripe, formatAmountFromStripe } from '@/lib/stripe';

// Convert to cents for Stripe
const amountInCents = formatAmountForStripe(150.50); // 15050

// Convert from cents
const amount = formatAmountFromStripe(15050); // 150.50
```

## Error Handling

All service methods throw errors that should be caught:

```typescript
try {
  const products = await productService.getProducts();
} catch (error) {
  console.error('Error loading products:', error);
  // Show user-friendly error message
}
```

## Real-time Subscriptions

Subscribe to real-time changes:

```typescript
// Subscribe to new orders
const subscription = supabase
  .channel('orders')
  .on('postgres_changes', 
    { event: 'INSERT', schema: 'public', table: 'orders' },
    (payload) => {
      console.log('New order:', payload.new);
    }
  )
  .subscribe();

// Unsubscribe when component unmounts
return () => {
  subscription.unsubscribe();
};
```

## File Upload (Supabase Storage)

```typescript
// Upload product image
const file = event.target.files[0];

const { data, error } = await supabase.storage
  .from('products')
  .upload(`${productId}/${Date.now()}.jpg`, file);

if (error) throw error;

// Get public URL
const { data: { publicUrl } } = supabase.storage
  .from('products')
  .getPublicUrl(data.path);
```

## Database Policies (RLS)

Enable Row Level Security policies in Supabase:

```sql
-- Example: Users can only see their own orders
CREATE POLICY "Users can view own orders" ON orders
  FOR SELECT USING (auth.uid() = user_id);

-- Example: Sellers can manage their own products
CREATE POLICY "Sellers can manage own products" ON products
  FOR ALL USING (
    auth.uid() = (
      SELECT user_id FROM seller_profiles WHERE id = products.seller_id
    )
  );
```

## Best Practices

1. **Always use services** instead of direct Supabase queries in components
2. **Handle loading states** properly
3. **Catch and display errors** user-friendly way
4. **Use TypeScript types** from types/index.ts
5. **Validate input** before submitting to database
6. **Use pagination** for large datasets
7. **Implement optimistic updates** for better UX
8. **Cache frequently accessed data**

## Common Patterns

### Protected Routes

```typescript
function ProtectedRoute({ children }) {
  const { user, loading } = useAuth();

  if (loading) return <Loading />;
  if (!user) return <Navigate to="/login" />;

  return children;
}
```

### Data Fetching

```typescript
function ProductList() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadProducts();
  }, []);

  async function loadProducts() {
    try {
      const data = await productService.getProducts();
      setProducts(data);
    } catch (error) {
      console.error(error);
    } finally {
      setLoading(false);
    }
  }

  if (loading) return <Loading />;

  return <div>{/* Render products */}</div>;
}
```

---

For more examples, check the source code in `src/services/` and `src/components/`.
