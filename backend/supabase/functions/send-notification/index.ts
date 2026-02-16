// Edge Function: send-notification
// Sends push notifications to users. Called from both mobile and web.
// Uses service role key to bypass RLS (notifications are system-generated).

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { corsResponse, jsonResponse, errorResponse } from '../_shared/cors.ts';
import { getAuthenticatedUser, createAdminClient } from '../_shared/auth.ts';
import { isValidUUID, sanitizeString, checkRateLimit } from '../_shared/validation.ts';

serve(async (req: Request) => {
    if (req.method === 'OPTIONS') return corsResponse();

    try {
        const { user } = await getAuthenticatedUser(req);

        if (!checkRateLimit(`notify:${user.id}`, 20, 60_000)) {
            return errorResponse('Too many requests', 429);
        }

        const { userId, type, title, message, link } = await req.json();

        if (!isValidUUID(userId)) {
            return errorResponse('Invalid user ID');
        }

        const adminClient = createAdminClient();

        const { error } = await adminClient.from('notifications').insert({
            user_id: userId,
            type: sanitizeString(type, 50),
            title: sanitizeString(title, 200),
            message: sanitizeString(message, 1000),
            link: link ? sanitizeString(link, 500) : null,
        });

        if (error) throw error;

        return jsonResponse({ success: true });
    } catch (error) {
        console.error('send-notification error:', error);
        const message = error instanceof Error ? error.message : 'Internal server error';
        const status = message.includes('Unauthorized') ? 401 : 400;
        return errorResponse(message, status);
    }
});
