import { createClient } from '@supabase/supabase-js';

const FALLBACK_SUPABASE_URL = 'https://fpabonricmesnmjzetfv.supabase.co';
const FALLBACK_SUPABASE_ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwYWJvbnJpY21lc25tanpldGZ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzIzNzIwMDAsImV4cCI6MjA0Nzk0ODAwMH0.YJVvDlukUNd4OA9zMHHuPcnGvCppQWm1_I9kG8YRY5udWUJsyoEXXwQZiffDa-aAQ6-MBMA3HpppCUTMfOOUKw';

const supabaseUrl = (import.meta as any).env?.VITE_SUPABASE_URL || FALLBACK_SUPABASE_URL;
const supabaseAnonKey = (import.meta as any).env?.VITE_SUPABASE_ANON_KEY || FALLBACK_SUPABASE_ANON_KEY;

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

export const isUsingFallbackSupabase =
  supabaseUrl === FALLBACK_SUPABASE_URL || supabaseAnonKey === FALLBACK_SUPABASE_ANON_KEY;

