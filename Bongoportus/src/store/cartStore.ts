import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { CartItem, Product, ProductVariant } from '../types';

interface CartStore {
  items: CartItem[];
  addItem: (product: Product, variantId?: string, quantity?: number) => void;
  removeItem: (itemId: string) => void;
  updateQuantity: (itemId: string, quantity: number) => void;
  clearCart: () => void;
  getTotalItems: () => number;
  getSubtotal: () => number;
}

export const useCartStore = create<CartStore>()(
  persist(
    (set, get) => ({
      items: [],

      addItem: (product, variantId, quantity = 1) => {
        set((state) => {
          // Check if item already exists
          const existingIndex = state.items.findIndex(
            (item) =>
              item.product_id === product.id &&
              item.variant_id === variantId
          );

          if (existingIndex !== -1) {
            // Update quantity if item exists
            const newItems = [...state.items];
            newItems[existingIndex].quantity += quantity;
            return { items: newItems };
          } else {
            // Add new item
            const newItem: CartItem = {
              id: `cart_${Date.now()}_${Math.random()}`,
              user_id: '', // Will be set when syncing with DB
              product_id: product.id,
              variant_id: variantId || null,
              quantity,
              product,
              variant: variantId
                ? product.variants?.find((v) => v.id === variantId)
                : undefined,
            };
            return { items: [...state.items, newItem] };
          }
        });
      },

      removeItem: (itemId) => {
        set((state) => ({
          items: state.items.filter((item) => item.id !== itemId),
        }));
      },

      updateQuantity: (itemId, quantity) => {
        set((state) => {
          if (quantity <= 0) {
            return { items: state.items.filter((item) => item.id !== itemId) };
          }
          const newItems = state.items.map((item) =>
            item.id === itemId ? { ...item, quantity } : item
          );
          return { items: newItems };
        });
      },

      clearCart: () => {
        set({ items: [] });
      },

      getTotalItems: () => {
        return get().items.reduce((total, item) => total + item.quantity, 0);
      },

      getSubtotal: () => {
        return get().items.reduce((total, item) => {
          const price = item.product?.discount_price || item.product?.price || 0;
          const variantModifier = item.variant?.price_modifier || 0;
          return total + (price + variantModifier) * item.quantity;
        }, 0);
      },
    }),
    {
      name: 'cart-storage',
    }
  )
);
