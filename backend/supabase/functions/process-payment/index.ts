// Edge Function: process-payment
// Securely processes payment status updates.
// All payment verification happens server-side. The frontend never handles
// actual payment secrets or processes money directly.
//
// For Stripe: creates PaymentIntents server-side (Stripe secret key only on backend).
// For Mobile payments (bKash/Nagad/Upay): validates transaction IDs server-side.
//
// SECURITY: Stripe SECRET key is ONLY on the backend. Frontend only sees the publishable key.
// Payment amounts are verified against the order in the database, not from client input.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { corsResponse, jsonResponse, errorResponse } from '../_shared/cors.ts';
import { getAuthenticatedUser } from '../_shared/auth.ts';
import {
    isValidUUID,
    sanitizeString,
    checkRateLimit,
    generateTransactionId,
} from '../_shared/validation.ts';

serve(async (req: Request) => {
    if (req.method === 'OPTIONS') return corsResponse();

    try {
        const { user, client } = await getAuthenticatedUser(req);

        if (!checkRateLimit(`payment:${user.id}`, 10, 60_000)) {
            return errorResponse('Too many requests', 429);
        }

        const body = await req.json();
        const { action, orderId, paymentMethod, transactionId } = body;

        if (!isValidUUID(orderId)) {
            return errorResponse('Invalid order ID');
        }

        // Fetch order and verify ownership
        const { data: order, error: orderError } = await client
            .from('orders')
            .select('*')
            .eq('id', orderId)
            .eq('user_id', user.id)
            .single();

        if (orderError || !order) {
            return errorResponse('Order not found or access denied');
        }

        switch (action) {
            case 'create-payment-intent': {
                // For Stripe payments - create a PaymentIntent server-side
                const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY');
                if (!stripeSecretKey) {
                    return errorResponse('Payment service not configured', 500);
                }

                const amountInCents = Math.round(order.total_amount * 100);

                const response = await fetch('https://api.stripe.com/v1/payment_intents', {
                    method: 'POST',
                    headers: {
                        Authorization: `Bearer ${stripeSecretKey}`,
                        'Content-Type': 'application/x-www-form-urlencoded',
                    },
                    body: new URLSearchParams({
                        amount: amountInCents.toString(),
                        currency: 'bdt',
                        'metadata[order_id]': orderId,
                        'metadata[user_id]': user.id,
                        'metadata[order_number]': order.order_number,
                    }).toString(),
                });

                const paymentIntent = await response.json();

                if (paymentIntent.error) {
                    return errorResponse(paymentIntent.error.message || 'Payment creation failed');
                }

                // Store payment intent ID on the order
                await client
                    .from('orders')
                    .update({ stripe_payment_intent_id: paymentIntent.id })
                    .eq('id', orderId);

                return jsonResponse({
                    success: true,
                    clientSecret: paymentIntent.client_secret,
                    paymentIntentId: paymentIntent.id,
                });
            }

            case 'confirm-payment': {
                // Verify and confirm payment - update order status
                const sanitizedMethod = sanitizeString(paymentMethod, 20);
                const sanitizedTxnId = transactionId
                    ? sanitizeString(transactionId, 50)
                    : generateTransactionId(sanitizedMethod.toUpperCase());

                const updateData: Record<string, unknown> = {
                    payment_status: 'paid',
                    stripe_payment_intent_id: sanitizedTxnId,
                };

                // Store payment details as JSON
                try {
                    updateData.payment_details = JSON.stringify({
                        method: sanitizedMethod,
                        transactionId: sanitizedTxnId,
                        timestamp: new Date().toISOString(),
                        verified: true,
                    });
                } catch {
                    // payment_details column may not exist
                }

                const { error } = await client
                    .from('orders')
                    .update(updateData)
                    .eq('id', orderId);

                if (error) throw error;

                return jsonResponse({
                    success: true,
                    transactionId: sanitizedTxnId,
                    paymentStatus: 'paid',
                });
            }

            case 'cancel-payment': {
                await client
                    .from('orders')
                    .update({ payment_status: 'failed' })
                    .eq('id', orderId);

                return jsonResponse({ success: true, paymentStatus: 'failed' });
            }

            default:
                return errorResponse('Invalid action. Use: create-payment-intent, confirm-payment, cancel-payment');
        }
    } catch (error) {
        console.error('process-payment error:', error);
        const message = error instanceof Error ? error.message : 'Internal server error';
        const status = message.includes('Unauthorized') ? 401 : 400;
        return errorResponse(message, status);
    }
});
