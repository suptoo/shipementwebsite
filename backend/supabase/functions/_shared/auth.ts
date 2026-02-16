import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

/**
 * Create an authenticated Supabase client using the user's JWT from the request.
 * This ensures all operations respect RLS policies.
 */
export function createAuthClient(req: Request) {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
        throw new Error('Missing Authorization header');
    }

    return createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_ANON_KEY') ?? '',
        {
            global: { headers: { Authorization: authHeader } },
        }
    );
}

/**
 * Create a Supabase admin client using the service role key.
 * Use ONLY for operations that need to bypass RLS (e.g., admin actions).
 * NEVER expose the service role key to the frontend.
 */
export function createAdminClient() {
    return createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );
}

/**
 * Extract and verify the authenticated user from the request.
 * Throws if user is not authenticated.
 */
export async function getAuthenticatedUser(req: Request) {
    const client = createAuthClient(req);
    const {
        data: { user },
        error,
    } = await client.auth.getUser();

    if (error || !user) {
        throw new Error('Unauthorized: Invalid or expired token');
    }

    return { user, client };
}

/**
 * Verify that the authenticated user has admin role.
 * Throws if not admin.
 */
export async function requireAdmin(req: Request) {
    const { user, client } = await getAuthenticatedUser(req);

    const { data: profile, error } = await client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

    if (error || !profile || profile.role !== 'admin') {
        throw new Error('Forbidden: Admin access required');
    }

    return { user, client, profile };
}

/**
 * Verify that the authenticated user has seller role.
 * Throws if not seller or admin.
 */
export async function requireSeller(req: Request) {
    const { user, client } = await getAuthenticatedUser(req);

    const { data: profile, error } = await client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

    if (error || !profile || !['seller', 'admin'].includes(profile.role)) {
        throw new Error('Forbidden: Seller access required');
    }

    return { user, client, profile };
}
