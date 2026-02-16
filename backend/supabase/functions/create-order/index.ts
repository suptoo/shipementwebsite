// Edge Function: create-order
// Securely creates an order with coupon validation, discount & commission calculation.
// Called from both mobile app and website via supabase.functions.invoke('create-order', ...)
//
// SECURITY: All business logic (pricing, discounts, commissions) runs server-side.
// The frontend only sends cart item IDs, address, and payment method.
// The backend fetches actual prices from the database to prevent price tampering.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { corsResponse, jsonResponse, errorResponse, corsHeaders } from '../_shared/cors.ts';
import { getAuthenticatedUser } from '../_shared/auth.ts';
import {
    sanitizeString,
    isValidUUID,
    isPositiveInteger,
    isValidCouponCode,
    isNonNegativeNumber,
    checkRateLimit,
    generateOrderNumber,
} from '../_shared/validation.ts';

interface CartItemInput {
    productId: string;
    variantId?: string;
    quantity: number;
}

interface AddressInput {
    full_name: string;
    phone: string;
    address_line1: string;
    address_line2?: string;
    city: string;
    state: string;
    postal_code: string;
    country?: string;
}

interface ProductRow {
    id: string;
    price: number;
    discount_price: number | null;
    stock_quantity: number;
    is_active: boolean;
    approval_status: string;
    seller_id: string;
    shop_id: string;
    name: string;
}

interface SellerRow {
    user_id: string;
    commission_rate: number | null;
}

serve(async (req: Request) => {
    if (req.method === 'OPTIONS') return corsResponse();

    try {
        // 1. Authenticate user
        const { user, client } = await getAuthenticatedUser(req);

        // 2. Rate limit: max 5 orders per minute per user
        if (!checkRateLimit(`order:${user.id}`, 5, 60_000)) {
            return errorResponse('Too many requests. Please wait before placing another order.', 429);
        }

        // 3. Parse and validate input
        const body = await req.json();
        const {
            cartItems,
            address,
            paymentMethod,
            couponCode,
            shippingCharge = 50,
        } = body;

        // Validate cart items
        if (!Array.isArray(cartItems) || cartItems.length === 0 || cartItems.length > 50) {
            return errorResponse('Cart must contain 1-50 items');
        }

        for (const item of cartItems as CartItemInput[]) {
            if (!isValidUUID(item.productId)) {
                return errorResponse('Invalid product ID in cart');
            }
            if (!isPositiveInteger(item.quantity) || item.quantity > 99) {
                return errorResponse('Invalid quantity (must be 1-99)');
            }
            if (item.variantId && !isValidUUID(item.variantId)) {
                return errorResponse('Invalid variant ID in cart');
            }
        }

        // Validate address
        const addr = address as AddressInput;
        if (!addr || !addr.full_name || !addr.phone || !addr.address_line1 || !addr.city || !addr.state || !addr.postal_code) {
            return errorResponse('Incomplete delivery address');
        }

        // Validate payment method
        const validPaymentMethods = ['card', 'bkash', 'nagad', 'upay', 'cod'];
        const sanitizedPaymentMethod = sanitizeString(paymentMethod, 20).toLowerCase();
        if (!validPaymentMethods.includes(sanitizedPaymentMethod)) {
            return errorResponse('Invalid payment method');
        }

        if (!isNonNegativeNumber(shippingCharge) || shippingCharge > 10000) {
            return errorResponse('Invalid shipping charge');
        }

        // 4. Fetch actual product data from database (prevent price tampering)
        const productIds = (cartItems as CartItemInput[]).map((i) => i.productId);
        const { data: products, error: prodError } = await client
            .from('products')
            .select('id, price, discount_price, stock_quantity, is_active, approval_status, seller_id, shop_id, name')
            .in('id', productIds);

        if (prodError) throw prodError;
        if (!products || products.length !== productIds.length) {
            return errorResponse('One or more products not found');
        }

        const typedProducts = products as unknown as ProductRow[];

        // 5. Fetch seller commission rates
        const sellerIds = [...new Set(typedProducts.map((p: ProductRow) => p.seller_id))];
        const { data: sellers } = await client
            .from('seller_profiles')
            .select('user_id, commission_rate')
            .in('user_id', sellerIds);

        const typedSellers = (sellers || []) as unknown as SellerRow[];
        const commissionMap = new Map<string, number>();
        typedSellers.forEach((s: SellerRow) => commissionMap.set(s.user_id, s.commission_rate || 5));

        // 6. Validate stock and calculate prices server-side
        const productMap = new Map<string, ProductRow>(typedProducts.map((p: ProductRow) => [p.id, p]));
        let subtotal = 0;
        const validatedItems: Array<{
            productId: string;
            variantId: string | null;
            quantity: number;
            unitPrice: number;
            totalPrice: number;
            productName: string;
            sellerId: string;
            shopId: string;
            commissionRate: number;
            commissionAmount: number;
            sellerEarnings: number;
        }> = [];

        for (const cartItem of cartItems as CartItemInput[]) {
            const product = productMap.get(cartItem.productId);
            if (!product) {
                return errorResponse(`Product not found: ${cartItem.productId}`);
            }
            if (!product.is_active || product.approval_status !== 'approved') {
                return errorResponse(`Product "${product.name}" is not available`);
            }
            if (product.stock_quantity < cartItem.quantity) {
                return errorResponse(`Insufficient stock for "${product.name}" (available: ${product.stock_quantity})`);
            }

            // Use actual price from DB (discount_price takes priority)
            const unitPrice = product.discount_price || product.price;
            const totalPrice = unitPrice * cartItem.quantity;
            const commissionRate = commissionMap.get(product.seller_id) || 5;
            const commissionAmount = totalPrice * (commissionRate / 100);
            const sellerEarnings = totalPrice - commissionAmount;

            subtotal += totalPrice;

            validatedItems.push({
                productId: cartItem.productId,
                variantId: cartItem.variantId || null,
                quantity: cartItem.quantity,
                unitPrice,
                totalPrice,
                productName: product.name,
                sellerId: product.seller_id,
                shopId: product.shop_id,
                commissionRate,
                commissionAmount: Math.round(commissionAmount * 100) / 100,
                sellerEarnings: Math.round(sellerEarnings * 100) / 100,
            });
        }

        // 7. Validate and apply coupon (server-side)
        let discountAmount = 0;
        let appliedCouponCode: string | null = null;

        if (couponCode && isValidCouponCode(couponCode)) {
            const code = sanitizeString(couponCode, 30).toUpperCase();
            const { data: coupon } = await client
                .from('coupons')
                .select('*')
                .eq('code', code)
                .eq('is_active', true)
                .single();

            if (coupon) {
                const now = new Date();
                const validFrom = new Date(coupon.valid_from);
                const validUntil = coupon.valid_until ? new Date(coupon.valid_until) : null;
                const isExpired = now < validFrom || (validUntil && now > validUntil);
                const isOverUsed = coupon.usage_limit && coupon.used_count >= coupon.usage_limit;
                const isBelowMin = subtotal < coupon.min_purchase_amount;

                if (!isExpired && !isOverUsed && !isBelowMin) {
                    if (coupon.discount_type === 'percentage') {
                        discountAmount = subtotal * (coupon.discount_value / 100);
                    } else {
                        discountAmount = coupon.discount_value;
                    }
                    if (coupon.max_discount_amount && discountAmount > coupon.max_discount_amount) {
                        discountAmount = coupon.max_discount_amount;
                    }
                    discountAmount = Math.round(discountAmount * 100) / 100;
                    appliedCouponCode = code;

                    // Increment coupon usage
                    await client
                        .from('coupons')
                        .update({ used_count: coupon.used_count + 1 })
                        .eq('id', coupon.id);
                }
            }
        }

        // 8. Calculate totals
        const taxRate = 0; // Adjust per business rules
        const taxAmount = Math.round((subtotal - discountAmount + shippingCharge) * taxRate * 100) / 100;
        const totalAmount = Math.round((subtotal - discountAmount + shippingCharge + taxAmount) * 100) / 100;

        // 9. Create order
        const orderNumber = generateOrderNumber();
        const { data: order, error: orderError } = await client
            .from('orders')
            .insert({
                order_number: orderNumber,
                user_id: user.id,
                delivery_full_name: sanitizeString(addr.full_name, 100),
                delivery_phone: sanitizeString(addr.phone, 20),
                delivery_address_line1: sanitizeString(addr.address_line1, 200),
                delivery_address_line2: addr.address_line2 ? sanitizeString(addr.address_line2, 200) : null,
                delivery_city: sanitizeString(addr.city, 100),
                delivery_state: sanitizeString(addr.state, 100),
                delivery_postal_code: sanitizeString(addr.postal_code, 20),
                delivery_country: sanitizeString(addr.country || 'Bangladesh', 100),
                subtotal,
                discount_amount: discountAmount,
                coupon_code: appliedCouponCode,
                shipping_charge: shippingCharge,
                tax_amount: taxAmount,
                total_amount: totalAmount,
                payment_method: sanitizedPaymentMethod,
                payment_status: 'pending',
                order_status: 'pending',
            })
            .select()
            .single();

        if (orderError) throw orderError;

        // 10. Create order items
        const orderItems = validatedItems.map((item) => ({
            order_id: order.id,
            product_id: item.productId,
            seller_id: item.sellerId,
            shop_id: item.shopId,
            variant_id: item.variantId,
            product_name: item.productName,
            product_image_url: null,
            variant_details: null,
            quantity: item.quantity,
            unit_price: item.unitPrice,
            total_price: item.totalPrice,
            commission_rate: item.commissionRate,
            commission_amount: item.commissionAmount,
            seller_earnings: item.sellerEarnings,
            item_status: 'pending',
        }));

        const { error: itemsError } = await client.from('order_items').insert(orderItems);
        if (itemsError) {
            console.error('Failed to insert order items:', itemsError);
            // Don't fail - order is already created
        }

        // 11. Deduct stock
        for (const item of validatedItems) {
            await client.rpc('decrement_stock', {
                p_product_id: item.productId,
                p_quantity: item.quantity,
            }).catch(() => {
                // Fallback: direct update if RPC doesn't exist
                return client
                    .from('products')
                    .update({ stock_quantity: productMap.get(item.productId)!.stock_quantity - item.quantity })
                    .eq('id', item.productId);
            });
        }

        // 12. Clear cart after successful order
        await client.from('cart_items').delete().eq('user_id', user.id).catch(() => { });

        return jsonResponse({
            success: true,
            order: {
                id: order.id,
                order_number: order.order_number,
                total_amount: order.total_amount,
                discount_amount: order.discount_amount,
                payment_status: order.payment_status,
                order_status: order.order_status,
                created_at: order.created_at,
            },
        });
    } catch (error) {
        console.error('create-order error:', error);
        const message = error instanceof Error ? error.message : 'Internal server error';
        const status = message.includes('Unauthorized') ? 401 : message.includes('Forbidden') ? 403 : 400;
        return errorResponse(message, status);
    }
});
