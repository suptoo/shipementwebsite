// Edge Function: admin-upload-image
// Securely handles image uploads to Supabase Storage.
// Only admins and sellers can upload product images.
// Images are stored in the 'product-images' bucket.
//
// SECURITY: Validates file type, size, and user permissions server-side.
// Prevents unauthorized uploads and malicious file types.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { corsHeaders, corsResponse, jsonResponse, errorResponse } from '../_shared/cors.ts';
import { getAuthenticatedUser } from '../_shared/auth.ts';
import { isValidUUID, checkRateLimit } from '../_shared/validation.ts';

const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB
const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
const ALLOWED_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];

serve(async (req: Request) => {
    if (req.method === 'OPTIONS') return corsResponse();

    try {
        const { user, client } = await getAuthenticatedUser(req);

        if (!checkRateLimit(`upload:${user.id}`, 30, 60_000)) {
            return errorResponse('Too many uploads. Please wait.', 429);
        }

        // Verify admin or seller role
        const { data: profile } = await client
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single();

        if (!profile || !['admin', 'seller'].includes(profile.role)) {
            return errorResponse('Forbidden: Only admins and sellers can upload images', 403);
        }

        const contentType = req.headers.get('content-type') || '';

        if (contentType.includes('multipart/form-data')) {
            // Handle multipart form upload
            const formData = await req.formData();
            const file = formData.get('file') as File | null;
            const bucket = (formData.get('bucket') as string) || 'product-images';
            const folder = (formData.get('folder') as string) || 'uploads';
            const productId = formData.get('productId') as string | null;

            if (!file) {
                return errorResponse('No file provided');
            }

            // Validate file type
            if (!ALLOWED_MIME_TYPES.includes(file.type)) {
                return errorResponse(`Invalid file type: ${file.type}. Allowed: ${ALLOWED_MIME_TYPES.join(', ')}`);
            }

            // Validate file size
            if (file.size > MAX_FILE_SIZE) {
                return errorResponse(`File too large: ${(file.size / 1024 / 1024).toFixed(1)}MB. Max: 5MB`);
            }

            // Validate extension
            const ext = '.' + file.name.split('.').pop()?.toLowerCase();
            if (!ALLOWED_EXTENSIONS.includes(ext)) {
                return errorResponse(`Invalid file extension: ${ext}`);
            }

            // Generate unique filename
            const timestamp = Date.now();
            const random = crypto.getRandomValues(new Uint8Array(4));
            const randomStr = Array.from(random).map(b => b.toString(16).padStart(2, '0')).join('');
            const fileName = `${folder}/${timestamp}_${randomStr}${ext}`;

            // Upload to Supabase Storage
            const fileBuffer = await file.arrayBuffer();
            const { data: uploadData, error: uploadError } = await client.storage
                .from(bucket)
                .upload(fileName, fileBuffer, {
                    contentType: file.type,
                    upsert: false,
                });

            if (uploadError) throw uploadError;

            // Get public URL
            const { data: urlData } = client.storage
                .from(bucket)
                .getPublicUrl(fileName);

            // If productId provided, add to product_images table
            if (productId && isValidUUID(productId)) {
                // Get current image count for display_order
                const { data: existingImages } = await client
                    .from('product_images')
                    .select('id')
                    .eq('product_id', productId);

                const displayOrder = (existingImages?.length || 0) + 1;
                const isPrimary = displayOrder === 1;

                await client.from('product_images').insert({
                    product_id: productId,
                    image_url: urlData.publicUrl,
                    display_order: displayOrder,
                    is_primary: isPrimary,
                });
            }

            return jsonResponse({
                success: true,
                url: urlData.publicUrl,
                path: uploadData.path,
                bucket,
            });
        } else {
            // Handle JSON body with base64 encoded image
            const { imageData, bucket = 'product-images', folder = 'uploads', productId, mimeType = 'image/jpeg' } = await req.json();

            if (!imageData || typeof imageData !== 'string') {
                return errorResponse('No image data provided');
            }

            if (!ALLOWED_MIME_TYPES.includes(mimeType)) {
                return errorResponse(`Invalid mime type: ${mimeType}`);
            }

            // Decode base64
            const base64Data = imageData.replace(/^data:image\/\w+;base64,/, '');
            const binaryStr = atob(base64Data);
            const bytes = new Uint8Array(binaryStr.length);
            for (let i = 0; i < binaryStr.length; i++) {
                bytes[i] = binaryStr.charCodeAt(i);
            }

            if (bytes.length > MAX_FILE_SIZE) {
                return errorResponse('Image too large (max 5MB)');
            }

            const ext = mimeType.split('/')[1] === 'jpeg' ? '.jpg' : `.${mimeType.split('/')[1]}`;
            const timestamp = Date.now();
            const random = crypto.getRandomValues(new Uint8Array(4));
            const randomStr = Array.from(random).map(b => b.toString(16).padStart(2, '0')).join('');
            const fileName = `${folder}/${timestamp}_${randomStr}${ext}`;

            const { data: uploadData, error: uploadError } = await client.storage
                .from(bucket)
                .upload(fileName, bytes.buffer, {
                    contentType: mimeType,
                    upsert: false,
                });

            if (uploadError) throw uploadError;

            const { data: urlData } = client.storage
                .from(bucket)
                .getPublicUrl(fileName);

            if (productId && isValidUUID(productId)) {
                const { data: existingImages } = await client
                    .from('product_images')
                    .select('id')
                    .eq('product_id', productId);

                const displayOrder = (existingImages?.length || 0) + 1;
                await client.from('product_images').insert({
                    product_id: productId,
                    image_url: urlData.publicUrl,
                    display_order: displayOrder,
                    is_primary: displayOrder === 1,
                });
            }

            return jsonResponse({
                success: true,
                url: urlData.publicUrl,
                path: uploadData.path,
                bucket,
            });
        }
    } catch (error) {
        console.error('admin-upload-image error:', error);
        const message = error instanceof Error ? error.message : 'Internal server error';
        const status = message.includes('Unauthorized') ? 401 : message.includes('Forbidden') ? 403 : 400;
        return errorResponse(message, status);
    }
});
