import { User } from '@supabase/supabase-js';
import { supabase } from './supabase';

const ADMIN_EMAIL = 'umorfaruksupto@gmail.com';

/**
 * Ensures a matching row exists in `profiles` for the authenticated Supabase user.
 * Prevents FK violations when creating inquiries or chat messages.
 */
export const ensureProfileRecord = async (user: User) => {
  if (!user) return;

  const { data, error } = await supabase
    .from('profiles')
    .select('id')
    .eq('id', user.id)
    .maybeSingle();

  if (error && error.code !== 'PGRST116') {
    throw error;
  }

  if (!data) {
    const { error: insertError } = await supabase.from('profiles').insert({
      id: user.id,
      email: user.email ?? '',
      full_name: user.user_metadata?.full_name ?? null,
      role: user.email === ADMIN_EMAIL ? 'admin' : 'user',
    });

    if (insertError && insertError.code !== '23505') {
      throw insertError;
    }
  }
};
