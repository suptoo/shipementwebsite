// Edge Function: admin-manage-products
// Securely handles product CRUD operations for admins and sellers.
// All product management logic runs server-side with proper role validation.
//
// SECURITY: Only admins can approve/reject/feature products.
// Sellers can only create/edit their own products.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { corsResponse, jsonResponse, errorResponse } from '../_shared/cors.ts';
import { getAuthenticatedUser } from '../_shared/auth.ts';
import {
    isValidUUID,
    sanitizeString,
    isPositiveNumber,
    isNonNegativeNumber,
    isPositiveInteger,
    checkRateLimit,
} from '../_shared/validation.ts';

serve(async (req: Request) => {
    if (req.method === 'OPTIONS') return corsResponse();

    try {
        const { user, client } = await getAuthenticatedUser(req);

        if (!checkRateLimit(`product-mgmt:${user.id}`, 30, 60_000)) {
            return errorResponse('Too many requests', 429);
        }

        // Verify admin or seller
        const { data: profile } = await client
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single();

        if (!profile || !['admin', 'seller'].includes(profile.role)) {
            return errorResponse('Forbidden: Only admins and sellers can manage products', 403);
        }

        const isAdmin = profile.role === 'admin';
        const body = await req.json();
        const { action } = body;

        switch (action) {
            case 'create': {
                // Create a new product
                const { name, description, price, discountPrice, stockQuantity, categoryId, brandId, shopId, sku } = body;

                if (!name || sanitizeString(name).length < 2) return errorResponse('Product name is required (min 2 chars)');
                if (!isPositiveNumber(price)) return errorResponse('Valid price is required');
                if (!isNonNegativeNumber(stockQuantity)) return errorResponse('Valid stock quantity is required');
                if (!isValidUUID(categoryId)) return errorResponse('Valid category is required');

                // Sellers must own the shop
                if (!isAdmin) {
                    if (!isValidUUID(shopId)) return errorResponse('Shop ID required');
                    const { data: shop } = await client
                        .from('shops')
                        .select('seller_id')
                        .eq('id', shopId)
                        .single();
                    if (!shop || shop.seller_id !== user.id) {
                        return errorResponse('Forbidden: Shop does not belong to you', 403);
                    }
                }

                // Generate slug
                const slug = sanitizeString(name, 200)
                    .toLowerCase()
                    .replace(/[^a-z0-9]+/g, '-')
                    .replace(/^-|-$/g, '') +
                    '-' + Date.now().toString(36);

                const { data: product, error } = await client
                    .from('products')
                    .insert({
                        seller_id: user.id,
                        shop_id: shopId,
                        category_id: categoryId,
                        brand_id: brandId && isValidUUID(brandId) ? brandId : null,
                        name: sanitizeString(name, 200),
                        slug,
                        description: description ? sanitizeString(description, 5000) : null,
                        price,
                        discount_price: discountPrice && isPositiveNumber(discountPrice) ? discountPrice : null,
                        discount_percentage: discountPrice && isPositiveNumber(discountPrice)
                            ? Math.round(((price - discountPrice) / price) * 100)
                            : null,
                        stock_quantity: Math.round(stockQuantity),
                        sku: sku ? sanitizeString(sku, 50) : null,
                        is_active: isAdmin, // Auto-activate for admins
                        approval_status: isAdmin ? 'approved' : 'pending',
                    })
                    .select()
                    .single();

                if (error) throw error;
                return jsonResponse({ success: true, product });
            }

            case 'update': {
                const { productId, ...updates } = body;
                if (!isValidUUID(productId)) return errorResponse('Invalid product ID');

                // Verify ownership (unless admin)
                if (!isAdmin) {
                    const { data: product } = await client
                        .from('products')
                        .select('seller_id')
                        .eq('id', productId)
                        .single();
                    if (!product || product.seller_id !== user.id) {
                        return errorResponse('Forbidden: Not your product', 403);
                    }
                }

                const updateData: Record<string, unknown> = {};
                if (updates.name) updateData.name = sanitizeString(updates.name, 200);
                if (updates.description !== undefined) updateData.description = updates.description ? sanitizeString(updates.description, 5000) : null;
                if (isPositiveNumber(updates.price)) updateData.price = updates.price;
                if (updates.discountPrice !== undefined) {
                    updateData.discount_price = isPositiveNumber(updates.discountPrice) ? updates.discountPrice : null;
                }
                if (isNonNegativeNumber(updates.stockQuantity)) updateData.stock_quantity = Math.round(updates.stockQuantity);
                if (updates.categoryId && isValidUUID(updates.categoryId)) updateData.category_id = updates.categoryId;
                if (updates.brandId !== undefined) updateData.brand_id = updates.brandId && isValidUUID(updates.brandId) ? updates.brandId : null;
                if (updates.sku !== undefined) updateData.sku = updates.sku ? sanitizeString(updates.sku, 50) : null;

                if (Object.keys(updateData).length === 0) {
                    return errorResponse('No valid updates provided');
                }

                const { data: product, error } = await client
                    .from('products')
                    .update(updateData)
                    .eq('id', productId)
                    .select()
                    .single();

                if (error) throw error;
                return jsonResponse({ success: true, product });
            }

            case 'approve':
            case 'reject': {
                // Admin only
                if (!isAdmin) return errorResponse('Forbidden: Admin only', 403);

                const { productId } = body;
                if (!isValidUUID(productId)) return errorResponse('Invalid product ID');

                const status = action === 'approve' ? 'approved' : 'rejected';
                const { error } = await client
                    .from('products')
                    .update({
                        approval_status: status,
                        is_active: action === 'approve',
                    })
                    .eq('id', productId);

                if (error) throw error;
                return jsonResponse({ success: true, status });
            }

            case 'toggle-featured': {
                // Admin only
                if (!isAdmin) return errorResponse('Forbidden: Admin only', 403);

                const { productId, isFeatured } = body;
                if (!isValidUUID(productId)) return errorResponse('Invalid product ID');

                const { error } = await client
                    .from('products')
                    .update({ is_featured: !!isFeatured })
                    .eq('id', productId);

                if (error) throw error;
                return jsonResponse({ success: true, is_featured: !!isFeatured });
            }

            case 'delete': {
                const { productId } = body;
                if (!isValidUUID(productId)) return errorResponse('Invalid product ID');

                // Verify ownership (unless admin)
                if (!isAdmin) {
                    const { data: product } = await client
                        .from('products')
                        .select('seller_id')
                        .eq('id', productId)
                        .single();
                    if (!product || product.seller_id !== user.id) {
                        return errorResponse('Forbidden: Not your product', 403);
                    }
                }

                // Soft delete (deactivate)
                const { error } = await client
                    .from('products')
                    .update({ is_active: false })
                    .eq('id', productId);

                if (error) throw error;
                return jsonResponse({ success: true, deleted: true });
            }

            default:
                return errorResponse('Invalid action. Use: create, update, approve, reject, toggle-featured, delete');
        }
    } catch (error) {
        console.error('admin-manage-products error:', error);
        const message = error instanceof Error ? error.message : 'Internal server error';
        const status = message.includes('Unauthorized') ? 401 : message.includes('Forbidden') ? 403 : 400;
        return errorResponse(message, status);
    }
});
