import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://fpabonricmesnmjzetfv.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwYWJvbnJpY21lc25tanpldGZ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzIzNzIwMDAsImV4cCI6MjA0Nzk0ODAwMH0.YJVvDlukUNd4OA9zMHHuPcnGvCppQWm1_I9kG8YRY5udWUJsyoEXXwQZiffDa-aAQ6-MBMA3HpppCUTMfOOUKw';

console.log('Testing Supabase connection...');
console.log('URL:', supabaseUrl);
console.log('Key (first 50 chars):', supabaseAnonKey.substring(0, 50));

const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Test the connection
const testConnection = async () => {
  try {
    const { data, error } = await supabase.auth.getSession();
    if (error) {
      console.error('❌ Connection error:', error.message);
      console.error('Error details:', error);
    } else {
      console.log('✅ Connection successful!');
      console.log('Session data:', data);
    }

    // Try to query a table
    const { data: profiles, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .limit(1);
    
    if (profileError) {
      console.error('❌ Database query error:', profileError.message);
      console.error('This likely means the tables haven\'t been created yet.');
      console.error('Please run the supabase-setup.sql script in your Supabase SQL Editor.');
    } else {
      console.log('✅ Database query successful!');
      console.log('Profiles:', profiles);
    }
  } catch (err) {
    console.error('❌ Unexpected error:', err);
  }
};

testConnection();
