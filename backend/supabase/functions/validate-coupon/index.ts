// Edge Function: validate-coupon
// Securely validates coupon codes server-side.
// Called from frontend before order placement to show discount preview.
//
// SECURITY: Coupon validation logic (dates, usage limits, min purchase) runs server-side.
// Frontend cannot bypass coupon restrictions.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { corsResponse, jsonResponse, errorResponse } from '../_shared/cors.ts';
import { getAuthenticatedUser } from '../_shared/auth.ts';
import { sanitizeString, isValidCouponCode, isPositiveNumber, checkRateLimit } from '../_shared/validation.ts';

serve(async (req: Request) => {
    if (req.method === 'OPTIONS') return corsResponse();

    try {
        const { user, client } = await getAuthenticatedUser(req);

        // Rate limit: max 20 coupon validations per minute
        if (!checkRateLimit(`coupon:${user.id}`, 20, 60_000)) {
            return errorResponse('Too many requests', 429);
        }

        const { code, subtotal } = await req.json();

        if (!code || !isValidCouponCode(code)) {
            return jsonResponse({ valid: false, message: 'Invalid coupon code format' });
        }

        if (!isPositiveNumber(subtotal)) {
            return errorResponse('Invalid subtotal amount');
        }

        const sanitizedCode = sanitizeString(code, 30).toUpperCase();

        const { data: coupon, error } = await client
            .from('coupons')
            .select('*')
            .eq('code', sanitizedCode)
            .eq('is_active', true)
            .single();

        if (error || !coupon) {
            return jsonResponse({ valid: false, message: 'Coupon not found or inactive' });
        }

        // Validate dates
        const now = new Date();
        const validFrom = new Date(coupon.valid_from);
        const validUntil = coupon.valid_until ? new Date(coupon.valid_until) : null;

        if (now < validFrom) {
            return jsonResponse({ valid: false, message: 'Coupon is not yet active' });
        }
        if (validUntil && now > validUntil) {
            return jsonResponse({ valid: false, message: 'Coupon has expired' });
        }

        // Check usage limit
        if (coupon.usage_limit && coupon.used_count >= coupon.usage_limit) {
            return jsonResponse({ valid: false, message: 'Coupon usage limit reached' });
        }

        // Check minimum purchase
        if (subtotal < coupon.min_purchase_amount) {
            return jsonResponse({
                valid: false,
                message: `Minimum purchase of ৳${coupon.min_purchase_amount} required`,
            });
        }

        // Calculate discount
        let discount = 0;
        if (coupon.discount_type === 'percentage') {
            discount = subtotal * (coupon.discount_value / 100);
        } else {
            discount = coupon.discount_value;
        }

        if (coupon.max_discount_amount && discount > coupon.max_discount_amount) {
            discount = coupon.max_discount_amount;
        }
        discount = Math.round(discount * 100) / 100;

        return jsonResponse({
            valid: true,
            coupon: {
                code: coupon.code,
                description: coupon.description,
                discount_type: coupon.discount_type,
                discount_value: coupon.discount_value,
                discount_amount: discount,
            },
        });
    } catch (error) {
        console.error('validate-coupon error:', error);
        const message = error instanceof Error ? error.message : 'Internal server error';
        const status = message.includes('Unauthorized') ? 401 : 400;
        return errorResponse(message, status);
    }
});
