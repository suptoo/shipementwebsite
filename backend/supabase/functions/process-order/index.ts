// Edge Function: process-order (UPDATED)
// Post-payment order processing: stock deduction, commission calculation, seller balance updates.
// Called AFTER create-order, when payment is confirmed.
// This function uses the SERVICE_ROLE_KEY to bypass RLS for admin-level operations.
//
// SECURITY: Uses service role key (never exposed to frontend).
// All financial calculations happen server-side.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { corsResponse, jsonResponse, errorResponse } from '../_shared/cors.ts';
import { getAuthenticatedUser, createAdminClient } from '../_shared/auth.ts';
import { isValidUUID, checkRateLimit } from '../_shared/validation.ts';

serve(async (req: Request) => {
    if (req.method === 'OPTIONS') return corsResponse();

    try {
        const { user } = await getAuthenticatedUser(req);

        if (!checkRateLimit(`process:${user.id}`, 10, 60_000)) {
            return errorResponse('Too many requests', 429);
        }

        const { orderId } = await req.json();

        if (!isValidUUID(orderId)) {
            return errorResponse('Invalid order ID');
        }

        // Use admin client for privileged operations
        const adminClient = createAdminClient();

        // Fetch order with items
        const { data: order, error: orderError } = await adminClient
            .from('orders')
            .select('*, order_items(*)')
            .eq('id', orderId)
            .single();

        if (orderError) throw orderError;

        // Verify the order belongs to the requesting user
        if (order.user_id !== user.id) {
            return errorResponse('Forbidden: Not your order', 403);
        }

        // Only process pending/confirmed orders
        if (!['pending', 'confirmed'].includes(order.order_status)) {
            return errorResponse(`Order already ${order.order_status}`);
        }

        // Validate stock and process each item
        for (const item of order.order_items) {
            if (!item.product_id) continue;

            const { data: product } = await adminClient
                .from('products')
                .select('stock_quantity, price')
                .eq('id', item.product_id)
                .single();

            if (!product || product.stock_quantity < item.quantity) {
                throw new Error(`Insufficient stock for: ${item.product_name}`);
            }

            // Deduct stock
            await adminClient
                .from('products')
                .update({ stock_quantity: product.stock_quantity - item.quantity })
                .eq('id', item.product_id);

            // Calculate commission using the rate stored on the order item
            const commission = item.total_price * (item.commission_rate / 100);
            const sellerEarnings = item.total_price - commission;

            // Update order item with final calculations
            await adminClient
                .from('order_items')
                .update({
                    commission_amount: Math.round(commission * 100) / 100,
                    seller_earnings: Math.round(sellerEarnings * 100) / 100,
                    item_status: 'confirmed',
                })
                .eq('id', item.id);

            // Update seller balance (using RPC if available, fallback to direct update)
            if (item.seller_id) {
                try {
                    await adminClient.rpc('increment_seller_balance', {
                        p_seller_id: item.seller_id,
                        p_amount: sellerEarnings,
                    });
                } catch {
                    // Fallback: direct update
                    const { data: seller } = await adminClient
                        .from('seller_profiles')
                        .select('total_earnings, available_balance')
                        .eq('user_id', item.seller_id)
                        .single();

                    if (seller) {
                        await adminClient
                            .from('seller_profiles')
                            .update({
                                total_earnings: (seller.total_earnings || 0) + sellerEarnings,
                                available_balance: (seller.available_balance || 0) + sellerEarnings,
                            })
                            .eq('user_id', item.seller_id);
                    }
                }
            }
        }

        // Confirm order
        await adminClient
            .from('orders')
            .update({ order_status: 'confirmed' })
            .eq('id', orderId);

        return jsonResponse({ success: true, orderId, status: 'confirmed' });
    } catch (error) {
        console.error('process-order error:', error);
        const message = error instanceof Error ? error.message : 'Internal server error';
        const status = message.includes('Unauthorized') ? 401 : message.includes('Forbidden') ? 403 : 400;
        return errorResponse(message, status);
    }
});
