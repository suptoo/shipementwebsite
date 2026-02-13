import { supabase } from '../lib/supabase';
import { CartItem } from '../types';

export const cartService = {
  // Get user's cart
  async getCart(userId: string): Promise<CartItem[]> {
    const { data, error } = await supabase
      .from('cart_items')
      .select('*, products(*, product_images(*)), product_variants(*)')
      .eq('user_id', userId);

    if (error) throw error;

    return (data || []).map((item: any) => ({
      ...item,
      product: item.products
        ? {
            ...item.products,
            images: item.products.product_images || [],
          }
        : null,
      variant: item.product_variants,
    }));
  },

  // Add item to cart
  async addToCart(
    userId: string,
    productId: string,
    quantity: number = 1,
    variantId?: string
  ): Promise<CartItem> {
    // Check if item already exists
    const { data: existing } = await supabase
      .from('cart_items')
      .select('*')
      .eq('user_id', userId)
      .eq('product_id', productId)
      .eq('variant_id', variantId || null)
      .single();

    if (existing) {
      // Update quantity
      const { data, error } = await supabase
        .from('cart_items')
        .update({ quantity: existing.quantity + quantity })
        .eq('id', existing.id)
        .select('*, products(*, product_images(*)), product_variants(*)')
        .single();

      if (error) throw error;
      return data;
    } else {
      // Insert new item
      const { data, error } = await supabase
        .from('cart_items')
        .insert({
          user_id: userId,
          product_id: productId,
          variant_id: variantId || null,
          quantity,
        })
        .select('*, products(*, product_images(*)), product_variants(*)')
        .single();

      if (error) throw error;
      return data;
    }
  },

  // Update cart item quantity
  async updateQuantity(cartItemId: string, quantity: number): Promise<void> {
    if (quantity <= 0) {
      await this.removeFromCart(cartItemId);
      return;
    }

    const { error } = await supabase
      .from('cart_items')
      .update({ quantity })
      .eq('id', cartItemId);

    if (error) throw error;
  },

  // Remove item from cart
  async removeFromCart(cartItemId: string): Promise<void> {
    const { error } = await supabase
      .from('cart_items')
      .delete()
      .eq('id', cartItemId);

    if (error) throw error;
  },

  // Clear user's cart
  async clearCart(userId: string): Promise<void> {
    const { error } = await supabase
      .from('cart_items')
      .delete()
      .eq('user_id', userId);

    if (error) throw error;
  },

  // Sync local cart with server
  async syncCart(userId: string, localItems: CartItem[]): Promise<CartItem[]> {
    // Add local items to server
    for (const item of localItems) {
      await this.addToCart(
        userId,
        item.product_id,
        item.quantity,
        item.variant_id || undefined
      );
    }

    // Return merged cart
    return await this.getCart(userId);
  },
};
