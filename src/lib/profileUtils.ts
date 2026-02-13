import { User } from '@supabase/supabase-js';
import { supabase } from './supabase';

/** Admin emails — these always get the 'admin' role */
const ADMIN_EMAILS: string[] = [
  'umorfaruksupto@gmail.com',
];

/** Check if an email belongs to an admin */
export const isAdminEmail = (email: string | undefined | null): boolean => {
  if (!email) return false;
  return ADMIN_EMAILS.includes(email.toLowerCase().trim());
};

/**
 * Ensures a matching row exists in `profiles` for the authenticated Supabase user.
 * Prevents FK violations when creating inquiries or chat messages.
 * Automatically assigns admin role to ADMIN_EMAILS.
 * Silently handles DB errors (e.g. table not created yet) to avoid blocking auth flow.
 */
export const ensureProfileRecord = async (user: User) => {
  if (!user) return;

  const role = isAdminEmail(user.email) ? 'admin' : 'user';

  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('id, role')
      .eq('id', user.id)
      .maybeSingle();

    if (error && error.code !== 'PGRST116') {
      // Table might not exist yet — don't block auth
      console.warn('Profile check failed (DB may not be set up):', error.message);
      return;
    }

    if (!data) {
      // Profile doesn't exist — create it
      const { error: insertError } = await supabase.from('profiles').insert({
        id: user.id,
        email: user.email ?? '',
        full_name: user.user_metadata?.full_name ?? null,
        role,
      });

      if (insertError && insertError.code !== '23505') {
        console.warn('Profile creation failed:', insertError.message);
      }
    } else if (isAdminEmail(user.email) && data.role !== 'admin') {
      // Profile exists but admin email doesn't have admin role — fix it
      await supabase
        .from('profiles')
        .update({ role: 'admin' })
        .eq('id', user.id);
    }
  } catch (err) {
    // Never block the auth flow — log and continue
    console.warn('ensureProfileRecord error:', err);
  }
};
