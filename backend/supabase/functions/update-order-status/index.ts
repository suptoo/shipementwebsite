// Edge Function: update-order-status
// Securely updates order status. Only admins and sellers can update orders.
// Regular users can only cancel their own pending orders.
//
// SECURITY: Role-based access control enforced server-side.
// Users cannot mark orders as delivered or modify payment status.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { corsResponse, jsonResponse, errorResponse } from '../_shared/cors.ts';
import { getAuthenticatedUser } from '../_shared/auth.ts';
import { isValidUUID, sanitizeString, checkRateLimit } from '../_shared/validation.ts';

const VALID_ORDER_STATUSES = ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'returned'];
const VALID_PAYMENT_STATUSES = ['pending', 'paid', 'failed', 'refunded'];

serve(async (req: Request) => {
    if (req.method === 'OPTIONS') return corsResponse();

    try {
        const { user, client } = await getAuthenticatedUser(req);

        if (!checkRateLimit(`order-status:${user.id}`, 30, 60_000)) {
            return errorResponse('Too many requests', 429);
        }

        const { orderId, orderStatus, paymentStatus, trackingNumber, courierName } = await req.json();

        if (!isValidUUID(orderId)) {
            return errorResponse('Invalid order ID');
        }

        // Get user's role
        const { data: profile } = await client
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single();

        const isAdmin = profile?.role === 'admin';
        const isSeller = profile?.role === 'seller';

        // Fetch order
        const { data: order, error: orderError } = await client
            .from('orders')
            .select('*, order_items(seller_id)')
            .eq('id', orderId)
            .single();

        if (orderError || !order) {
            return errorResponse('Order not found');
        }

        // Permission checks
        if (!isAdmin) {
            if (isSeller) {
                // Sellers can only update their own order items' orders
                const sellerItemIds = order.order_items
                    ?.filter((item: any) => item.seller_id === user.id)
                    .map((item: any) => item.seller_id);
                if (!sellerItemIds || sellerItemIds.length === 0) {
                    return errorResponse('Forbidden: You do not have items in this order', 403);
                }
                // Sellers can only set: confirmed, processing, shipped
                if (orderStatus && !['confirmed', 'processing', 'shipped'].includes(orderStatus)) {
                    return errorResponse('Forbidden: Sellers can only confirm, process, or ship orders', 403);
                }
            } else {
                // Regular users can only cancel their own pending orders
                if (order.user_id !== user.id) {
                    return errorResponse('Forbidden: Not your order', 403);
                }
                if (orderStatus !== 'cancelled') {
                    return errorResponse('Forbidden: You can only cancel orders', 403);
                }
                if (order.order_status !== 'pending') {
                    return errorResponse('Cannot cancel: Order is already being processed', 400);
                }
            }
        }

        // Build update object
        const updateData: Record<string, unknown> = {};

        if (orderStatus) {
            const status = sanitizeString(orderStatus, 20);
            if (!VALID_ORDER_STATUSES.includes(status)) {
                return errorResponse('Invalid order status');
            }
            updateData.order_status = status;
        }

        if (paymentStatus && isAdmin) {
            const status = sanitizeString(paymentStatus, 20);
            if (!VALID_PAYMENT_STATUSES.includes(status)) {
                return errorResponse('Invalid payment status');
            }
            updateData.payment_status = status;
        }

        if (trackingNumber && (isAdmin || isSeller)) {
            updateData.tracking_number = sanitizeString(trackingNumber, 100);
        }

        if (courierName && (isAdmin || isSeller)) {
            updateData.courier_name = sanitizeString(courierName, 100);
        }

        if (Object.keys(updateData).length === 0) {
            return errorResponse('No valid updates provided');
        }

        const { error } = await client
            .from('orders')
            .update(updateData)
            .eq('id', orderId);

        if (error) throw error;

        // If cancelled, restore stock
        if (updateData.order_status === 'cancelled') {
            const { data: items } = await client
                .from('order_items')
                .select('product_id, quantity')
                .eq('order_id', orderId);

            if (items) {
                for (const item of items) {
                    await client.rpc('increment_stock', {
                        p_product_id: item.product_id,
                        p_quantity: item.quantity,
                    }).catch(() => { });
                }
            }
        }

        return jsonResponse({ success: true, updated: updateData });
    } catch (error) {
        console.error('update-order-status error:', error);
        const message = error instanceof Error ? error.message : 'Internal server error';
        const status = message.includes('Unauthorized') ? 401 : message.includes('Forbidden') ? 403 : 400;
        return errorResponse(message, status);
    }
});
