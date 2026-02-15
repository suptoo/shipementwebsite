import React, { createContext, useContext, useEffect, useState } from 'react';
import { User, Session } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';
import { Profile } from '../types';
import { ensureProfileRecord, isAdminEmail } from '../lib/profileUtils';

interface AuthContextType {
  user: User | null;
  profile: Profile | null;
  session: Session | null;
  loading: boolean;
  signUp: (email: string, password: string, fullName: string) => Promise<void>;
  signIn: (email: string, password: string) => Promise<void>;
  signInWithGoogle: () => Promise<void>;
  signInWithFacebook: () => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      if (session?.user) {
        fetchProfile(session.user.id);
      } else {
        setLoading(false);
      }
    });

    // Listen for auth changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
      setUser(session?.user ?? null);
      if (session?.user) {
        fetchProfile(session.user.id);
      } else {
        setProfile(null);
        setLoading(false);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  const fetchProfile = async (userId: string) => {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();

      if (error) {
        // If profiles table doesn't exist or row not found, create a basic profile from user data
        if (error.code === 'PGRST116' || error.code === '42P01') {
          // No profile row found — try to create one
          const currentUser = (await supabase.auth.getUser()).data.user;
          if (currentUser) {
            await ensureProfileRecord(currentUser);
            // Retry fetch
            const { data: retryData } = await supabase
              .from('profiles')
              .select('*')
              .eq('id', userId)
              .single();
            if (retryData) {
              if (isAdminEmail(retryData.email)) retryData.role = 'admin';
              setProfile(retryData);
              return;
            }
          }
          // Fallback: create a client-side profile from auth user
          const { data: { user: authUser } } = await supabase.auth.getUser();
          if (authUser) {
            setProfile({
              id: authUser.id,
              email: authUser.email ?? '',
              full_name: authUser.user_metadata?.full_name ?? null,
              phone: null,
              avatar_url: authUser.user_metadata?.avatar_url ?? null,
              role: isAdminEmail(authUser.email) ? 'admin' : 'user',
              is_verified: false,
              is_blocked: false,
              created_at: authUser.created_at,
            });
          }
          return;
        }
        throw error;
      }

      // Force admin role for configured admin emails
      if (data && isAdminEmail(data.email)) {
        data.role = 'admin';
      }

      setProfile(data);
    } catch (error) {
      console.error('Error fetching profile:', error);
    } finally {
      setLoading(false);
    }
  };

  const signUp = async (email: string, password: string, fullName: string) => {
    // Trim inputs
    const trimmedEmail = email.trim().toLowerCase();
    const trimmedName = fullName.trim();

    const { data, error } = await supabase.auth.signUp({
      email: trimmedEmail,
      password,
      options: {
        data: {
          full_name: trimmedName,
        },
      },
    });

    if (error) {
      if (error.message?.toLowerCase().includes('registered') || error.message?.toLowerCase().includes('already')) {
        throw new Error('An account already exists for this email. Please sign in instead.');
      }
      if (error.message?.toLowerCase().includes('valid email')) {
        throw new Error('Please enter a valid email address.');
      }
      if (error.message?.toLowerCase().includes('password')) {
        throw new Error('Password must be at least 6 characters long.');
      }
      throw error;
    }

    // Supabase may return a user with a fake session if email already exists (identities = [])
    if (data.user && data.user.identities && data.user.identities.length === 0) {
      throw new Error('An account already exists for this email. Please sign in instead.');
    }

    if (data.user) {
      await ensureProfileRecord(data.user);

      // If Supabase auto-confirms (no email verification required),
      // the session will exist — user is logged in immediately
      if (data.session) {
        setSession(data.session);
        setUser(data.user);
        await fetchProfile(data.user.id);
      }
    }
  };

  const signIn = async (email: string, password: string) => {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) throw error;

    if (data.user) {
      await ensureProfileRecord(data.user);
    }
  };

  const signInWithGoogle = async () => {
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `${window.location.origin}/`,
        queryParams: {
          access_type: 'offline',
          prompt: 'consent',
        },
      },
    });

    if (error) throw error;
  };

  const signInWithFacebook = async () => {
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'facebook',
      options: {
        redirectTo: `${window.location.origin}/`,
        scopes: 'email,public_profile',
      },
    });

    if (error) throw error;
  };

  const signOut = async () => {
    try {
      // Clear local state first
      setUser(null);
      setProfile(null);
      setSession(null);

      // Sign out from Supabase
      const { error } = await supabase.auth.signOut();
      if (error) throw error;

      // Force reload to clear any cached data
      window.location.href = '/login';
    } catch (error) {
      console.error('Error signing out:', error);
      throw error;
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        profile,
        session,
        loading,
        signUp,
        signIn,
        signInWithGoogle,
        signInWithFacebook,
        signOut,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
