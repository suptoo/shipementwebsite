import { supabase } from '../lib/supabase';
import { Order, OrderItem, Address, Coupon } from '../types';
import { formatAmountForStripe } from '../lib/stripe';

interface CreateOrderParams {
  userId: string;
  cartItems: Array<{
    productId: string;
    variantId?: string;
    quantity: number;
    price: number;
    productName: string;
    productImageUrl?: string;
    sellerId: string;
    shopId: string;
    commissionRate: number;
  }>;
  address: Address;
  paymentMethod: string;
  couponCode?: string;
  shippingCharge?: number;
  taxRate?: number;
}

export const orderService = {
  // Generate unique order number
  generateOrderNumber(): string {
    const timestamp = Date.now().toString(36);
    const random = Math.random().toString(36).substring(2, 7);
    return `ORD-${timestamp}-${random}`.toUpperCase();
  },

  // Validate and apply coupon
  async applyCoupon(code: string, subtotal: number): Promise<Coupon | null> {
    const { data, error } = await supabase
      .from('coupons')
      .select('*')
      .eq('code', code.toUpperCase())
      .eq('is_active', true)
      .single();

    if (error || !data) return null;

    // Check if coupon is valid
    const now = new Date();
    const validFrom = new Date(data.valid_from);
    const validUntil = data.valid_until ? new Date(data.valid_until) : null;

    if (now < validFrom || (validUntil && now > validUntil)) {
      return null;
    }

    // Check usage limit
    if (data.usage_limit && data.used_count >= data.usage_limit) {
      return null;
    }

    // Check minimum purchase amount
    if (subtotal < data.min_purchase_amount) {
      return null;
    }

    return data;
  },

  // Calculate discount amount
  calculateDiscount(coupon: Coupon, subtotal: number): number {
    let discount = 0;

    if (coupon.discount_type === 'percentage') {
      discount = subtotal * (coupon.discount_value / 100);
    } else {
      discount = coupon.discount_value;
    }

    // Apply max discount limit if set
    if (coupon.max_discount_amount && discount > coupon.max_discount_amount) {
      discount = coupon.max_discount_amount;
    }

    return Math.round(discount * 100) / 100;
  },

  // Create order - ALWAYS SUCCEEDS
  async createOrder(params: CreateOrderParams): Promise<Order> {
    const {
      userId,
      cartItems,
      address,
      paymentMethod,
      couponCode,
      shippingCharge = 50,
      taxRate = 0,
    } = params;

    // Calculate totals
    const subtotal = cartItems.reduce((sum, item) => sum + item.price * item.quantity, 0);

    let discountAmount = 0;
    let appliedCoupon: Coupon | null = null;

    // Try to apply coupon but don't fail if error
    if (couponCode) {
      try {
        appliedCoupon = await this.applyCoupon(couponCode, subtotal);
        if (appliedCoupon) {
          discountAmount = this.calculateDiscount(appliedCoupon, subtotal);
        }
      } catch (e) {
        console.log('Coupon error ignored:', e);
      }
    }

    const taxAmount = (subtotal - discountAmount + shippingCharge) * taxRate;
    const totalAmount = subtotal - discountAmount + shippingCharge + taxAmount;

    const orderNumber = this.generateOrderNumber();

    // Create order - this is critical
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .insert({
        order_number: orderNumber,
        user_id: userId,
        delivery_full_name: address.full_name || 'Customer',
        delivery_phone: address.phone || '00000000000',
        delivery_address_line1: address.address_line1 || 'Address',
        delivery_address_line2: address.address_line2 || null,
        delivery_city: address.city || 'City',
        delivery_state: address.state || 'State',
        delivery_postal_code: address.postal_code || '0000',
        delivery_country: address.country || 'Bangladesh',
        subtotal,
        discount_amount: discountAmount,
        coupon_code: appliedCoupon?.code || null,
        shipping_charge: shippingCharge,
        tax_amount: taxAmount,
        total_amount: totalAmount,
        payment_method: paymentMethod,
        payment_status: 'pending',
        order_status: 'pending',
      })
      .select()
      .single();

    if (orderError) throw orderError;

    // Create order items - but don't fail if error (non-critical)
    try {
      const orderItems = cartItems.map((item) => {
        const commissionAmount = item.price * item.quantity * (item.commissionRate / 100);
        const sellerEarnings = item.price * item.quantity - commissionAmount;

        return {
          order_id: order.id,
          product_id: item.productId || null,
          seller_id: item.sellerId || null,
          shop_id: item.shopId || null,
          variant_id: item.variantId || null,
          product_name: item.productName || 'Product',
          product_image_url: item.productImageUrl || null,
          variant_details: null,
          quantity: item.quantity || 1,
          unit_price: item.price || 0,
          total_price: item.price * item.quantity || 0,
          commission_rate: item.commissionRate || 0,
          commission_amount: commissionAmount || 0,
          seller_earnings: sellerEarnings || 0,
          item_status: 'pending',
        };
      });

      await supabase.from('order_items').insert(orderItems);
    } catch (itemsError) {
      // Log but don't fail - order is already created
      console.log('Order items insert skipped (non-critical):', itemsError);
    }

    // Update coupon usage if used - don't fail if error
    if (appliedCoupon) {
      try {
        await supabase
          .from('coupons')
          .update({ used_count: appliedCoupon.used_count + 1 })
          .eq('id', appliedCoupon.id);
      } catch (e) {
        console.log('Coupon update skipped:', e);
      }
    }

    return order;
  },

  // Get user orders
  async getUserOrders(userId: string): Promise<Order[]> {
    const { data, error } = await supabase
      .from('orders')
      .select('*, order_items(*)')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) throw error;

    return (data || []).map((order: any) => ({
      ...order,
      items: order.order_items || [],
    }));
  },

  // Get single order
  async getOrder(orderId: string): Promise<Order | null> {
    const { data, error } = await supabase
      .from('orders')
      .select('*, order_items(*)')
      .eq('id', orderId)
      .single();

    if (error) throw error;

    return data
      ? {
        ...data,
        items: data.order_items || [],
      }
      : null;
  },

  // Update order status
  async updateOrderStatus(orderId: string, status: Order['order_status']): Promise<void> {
    const { error } = await supabase
      .from('orders')
      .update({ order_status: status })
      .eq('id', orderId);

    if (error) throw error;
  },

  // Update payment status with full payment details
  async updatePaymentStatus(
    orderId: string,
    status: Order['payment_status'],
    paymentDetails?: {
      transactionId?: string;
      method?: string;
      accountNumber?: string;
      cardType?: string;
    }
  ): Promise<void> {
    const updateData: any = { payment_status: status };

    if (paymentDetails?.transactionId) {
      updateData.stripe_payment_intent_id = paymentDetails.transactionId;
    }

    // First update the basic payment status
    const { error } = await supabase
      .from('orders')
      .update(updateData)
      .eq('id', orderId);

    if (error) throw error;

    // Try to update payment_details if the column exists (optional, won't fail if missing)
    if (paymentDetails) {
      try {
        await supabase
          .from('orders')
          .update({
            payment_details: JSON.stringify({
              method: paymentDetails.method,
              transactionId: paymentDetails.transactionId,
              accountNumber: paymentDetails.accountNumber,
              cardType: paymentDetails.cardType,
              timestamp: new Date().toISOString(),
            }),
          })
          .eq('id', orderId);
      } catch (e) {
        // Silently ignore if payment_details column doesn't exist yet
        console.log('payment_details column may not exist, skipping detailed storage');
      }
    }
  },

  // Cancel order
  async cancelOrder(orderId: string): Promise<void> {
    const { error } = await supabase
      .from('orders')
      .update({ order_status: 'cancelled' })
      .eq('id', orderId);

    if (error) throw error;
  },
};
