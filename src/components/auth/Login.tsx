import React, { useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { LogIn, UserPlus, Loader2, Eye, EyeOff, CheckCircle, Mail } from 'lucide-react';
import { supabase } from '../../lib/supabase';

export const Login: React.FC = () => {
  const { signIn, signUp, signInWithGoogle, signInWithFacebook } = useAuth();
  const [isSignUp, setIsSignUp] = useState(false);
  const [loading, setLoading] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [showForgotPassword, setShowForgotPassword] = useState(false);
  const [forgotEmail, setForgotEmail] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSuccess('');

    // Client-side validation
    if (isSignUp && !fullName.trim()) {
      setError('Please enter your full name.');
      return;
    }
    if (!email.trim()) {
      setError('Please enter your email address.');
      return;
    }
    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email.trim())) {
      setError('Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setError('Password must be at least 6 characters long.');
      return;
    }
    if (isSignUp && password !== confirmPassword) {
      setError('Passwords do not match. Please try again.');
      return;
    }

    setLoading(true);

    try {
      if (isSignUp) {
        await signUp(email, password, fullName);
        setSuccess('Account created successfully! You can now sign in, or check your email to verify your account.');
        // Switch to sign-in mode after successful signup
        setTimeout(() => {
          setIsSignUp(false);
          setPassword('');
          setConfirmPassword('');
          setSuccess('');
        }, 4000);
      } else {
        await signIn(email, password);
      }
    } catch (err: any) {
      const msg = err.message || 'An error occurred';
      // Provide user-friendly error messages
      if (msg.includes('Invalid login credentials')) {
        setError('Incorrect email or password. Please try again.');
      } else if (msg.includes('Email not confirmed')) {
        setError('Please confirm your email first. Check your inbox for a verification link.');
      } else if (msg.includes('already registered') || msg.includes('already exists')) {
        setError('This email is already registered. Please sign in instead.');
        setIsSignUp(false);
      } else if (msg.includes('rate limit') || msg.includes('too many')) {
        setError('Too many attempts. Please wait a moment and try again.');
      } else {
        setError(msg);
      }
    } finally {
      setLoading(false);
    }
  };

  const handleForgotPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSuccess('');

    if (!forgotEmail.trim()) {
      setError('Please enter your email address.');
      return;
    }

    setLoading(true);
    try {
      const { error } = await supabase.auth.resetPasswordForEmail(forgotEmail, {
        redirectTo: `${window.location.origin}/login`,
      });
      if (error) throw error;
      setSuccess('Password reset link sent! Check your email inbox.');
      setTimeout(() => setShowForgotPassword(false), 3000);
    } catch (err: any) {
      setError(err.message || 'Failed to send reset email.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-600 via-indigo-700 to-purple-800 flex items-center justify-center px-4 py-6 sm:p-4 relative overflow-hidden">
      {/* Animated background pattern */}
      <div className="absolute inset-0 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PGRlZnM+PHBhdHRlcm4gaWQ9ImdyaWQiIHdpZHRoPSI2MCIgaGVpZ2h0PSI2MCIgcGF0dGVyblVuaXRzPSJ1c2VyU3BhY2VPblVzZSI+PHBhdGggZD0iTSAxMCAwIEwgMCAwIDAgMTAiIGZpbGw9Im5vbmUiIHN0cm9rZT0id2hpdGUiIHN0cm9rZS1vcGFjaXR5PSIwLjA1IiBzdHJva2Utd2lkdGg9IjEiLz48L3BhdHRlcm4+PC9kZWZzPjxyZWN0IHdpZHRoPSIxMDAlIiBoZWlnaHQ9IjEwMCUiIGZpbGw9InVybCgjZ3JpZCkiLz48L3N2Zz4=')] opacity-40"></div>

      {/* Animated background elements */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-blue-400/20 rounded-full blur-3xl animate-pulse"></div>
        <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-purple-400/20 rounded-full blur-3xl animate-pulse" style={{ animationDelay: '1.5s' }}></div>
      </div>

      <div className="max-w-md w-full bg-white rounded-3xl shadow-2xl p-6 sm:p-10 transform transition-all relative z-10 border border-white/20 max-h-[95vh] overflow-y-auto scrollbar-hide">
        <div className="text-center mb-6 sm:mb-8">
          <div className="mb-4 sm:mb-6 flex justify-center">
            <div className="w-16 h-16 sm:w-20 sm:h-20 bg-gradient-to-br from-blue-600 to-indigo-600 rounded-2xl flex items-center justify-center shadow-xl transform hover:scale-110 transition-transform duration-300">
              <svg className="w-10 h-10 sm:w-12 sm:h-12 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
              </svg>
            </div>
          </div>
          <h1 className="text-3xl sm:text-5xl font-extrabold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent mb-1 sm:mb-2">
            Bongoportus
          </h1>
          <p className="text-gray-600 font-medium text-sm sm:text-base">Your trusted marketplace</p>
        </div>

        <div className="flex gap-2 mb-6 sm:mb-8 bg-gray-100 p-1 rounded-xl">
          <button
            onClick={() => {
              setIsSignUp(false);
              setError('');
              setSuccess('');
              setShowForgotPassword(false);
            }}
            className={`flex-1 py-3 px-4 rounded-lg font-bold transition-all duration-300 ${!isSignUp && !showForgotPassword
              ? 'bg-white text-blue-600 shadow-lg scale-[1.02]'
              : 'text-gray-600 hover:text-gray-900'
              }`}
          >
            <LogIn className="inline-block w-4 h-4 mr-2" />
            Sign In
          </button>
          <button
            onClick={() => {
              setIsSignUp(true);
              setError('');
              setSuccess('');
              setShowForgotPassword(false);
            }}
            className={`flex-1 py-3 px-4 rounded-lg font-bold transition-all duration-300 ${isSignUp
              ? 'bg-white text-blue-600 shadow-lg scale-[1.02]'
              : 'text-gray-600 hover:text-gray-900'
              }`}
          >
            <UserPlus className="inline-block w-4 h-4 mr-2" />
            Sign Up
          </button>
        </div>

        {/* Forgot Password Form */}
        {showForgotPassword ? (
          <form onSubmit={handleForgotPassword} className="space-y-5">
            <div className="text-center mb-2">
              <Mail className="w-10 h-10 text-blue-500 mx-auto mb-2" />
              <p className="text-gray-600 text-sm">Enter your email and we'll send you a password reset link.</p>
            </div>
            <div>
              <label className="block text-sm font-semibold text-slate-700 mb-2">Email Address</label>
              <input
                type="email"
                value={forgotEmail}
                onChange={(e) => setForgotEmail(e.target.value)}
                required
                className="w-full px-4 py-3 border-2 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all duration-200 bg-white"
                placeholder="you@example.com"
              />
            </div>

            {error && (
              <div className="bg-red-50 border-2 border-red-200 text-red-700 px-4 py-3 rounded-xl text-sm font-medium">
                {error}
              </div>
            )}
            {success && (
              <div className="bg-green-50 border-2 border-green-200 text-green-700 px-4 py-3 rounded-xl text-sm font-medium flex items-center gap-2">
                <CheckCircle className="w-4 h-4 flex-shrink-0" />
                {success}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-gradient-to-r from-blue-900 to-blue-800 text-white py-4 px-4 rounded-xl font-bold text-lg hover:from-blue-800 hover:to-blue-700 transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center shadow-lg"
            >
              {loading ? (
                <>
                  <Loader2 className="animate-spin w-5 h-5 mr-2" />
                  Sending...
                </>
              ) : (
                'Send Reset Link'
              )}
            </button>

            <button
              type="button"
              onClick={() => { setShowForgotPassword(false); setError(''); setSuccess(''); }}
              className="w-full text-blue-600 hover:text-blue-800 font-medium text-sm py-2"
            >
              ← Back to Sign In
            </button>
          </form>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-5">
            {isSignUp && (
              <div className="animate-in fade-in duration-300">
                <label className="block text-sm font-semibold text-slate-700 mb-2">
                  Full Name
                </label>
                <input
                  type="text"
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  required
                  className="w-full px-4 py-3 border-2 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all duration-200 bg-white"
                  placeholder="John Doe"
                />
              </div>
            )}

            <div>
              <label className="block text-sm font-semibold text-slate-700 mb-2">
                Email Address
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="w-full px-4 py-3 border-2 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all duration-200 bg-white"
                placeholder="you@example.com"
              />
            </div>

            <div>
              <label className="block text-sm font-semibold text-slate-700 mb-2">
                Password
              </label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  minLength={6}
                  className="w-full px-4 py-3 pr-12 border-2 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all duration-200 bg-white text-base"
                  placeholder="••••••••"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-700 transition-colors p-1"
                >
                  {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                </button>
              </div>
            </div>

            {isSignUp && (
              <div className="animate-in fade-in duration-300">
                <label className="block text-sm font-semibold text-slate-700 mb-2">
                  Confirm Password
                </label>
                <div className="relative">
                  <input
                    type={showConfirmPassword ? 'text' : 'password'}
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    required
                    minLength={6}
                    className={`w-full px-4 py-3 pr-12 border-2 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all duration-200 bg-white text-base ${confirmPassword && password !== confirmPassword
                        ? 'border-red-300 focus:border-red-500 focus:ring-red-200'
                        : confirmPassword && password === confirmPassword
                          ? 'border-green-300 focus:border-green-500 focus:ring-green-200'
                          : 'border-slate-200'
                      }`}
                    placeholder="••••••••"
                  />
                  <button
                    type="button"
                    onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-700 transition-colors p-1"
                  >
                    {showConfirmPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                  </button>
                </div>
                {confirmPassword && password !== confirmPassword && (
                  <p className="text-xs text-red-500 mt-1">Passwords do not match</p>
                )}
                {confirmPassword && password === confirmPassword && (
                  <p className="text-xs text-green-500 mt-1 flex items-center gap-1">
                    <CheckCircle className="w-3 h-3" /> Passwords match
                  </p>
                )}
              </div>
            )}
            {error && (
              <div className="bg-red-50 border-2 border-red-200 text-red-700 px-4 py-3 rounded-xl text-sm font-medium animate-in fade-in duration-200">
                {error}
              </div>
            )}

            {success && (
              <div className="bg-green-50 border-2 border-green-200 text-green-700 px-4 py-3 rounded-xl text-sm font-medium animate-in fade-in duration-200 flex items-center gap-2">
                <CheckCircle className="w-4 h-4 flex-shrink-0" />
                {success}
              </div>
            )}

            <button
              type="submit"
              disabled={loading || (isSignUp && password !== confirmPassword && confirmPassword.length > 0)}
              className="w-full bg-gradient-to-r from-blue-900 to-blue-800 text-white py-3.5 sm:py-4 px-4 rounded-xl font-bold text-base sm:text-lg hover:from-blue-800 hover:to-blue-700 transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center shadow-lg shadow-blue-900/30 hover:shadow-xl hover:shadow-blue-900/40 transform hover:scale-[1.02] active:scale-[0.98]"
            >
              {loading ? (
                <>
                  <Loader2 className="animate-spin w-5 h-5 mr-2" />
                  Processing...
                </>
              ) : isSignUp ? (
                'Create Account'
              ) : (
                'Sign In'
              )}
            </button>

            {/* Forgot Password */}
            {!isSignUp && (
              <div className="text-center">
                <button
                  type="button"
                  onClick={() => { setShowForgotPassword(true); setError(''); setSuccess(''); setForgotEmail(email); }}
                  className="text-blue-600 hover:text-blue-800 text-sm font-medium hover:underline"
                >
                  Forgot your password?
                </button>
              </div>
            )}

            {/* Password hint for signup */}
            {isSignUp && (
              <p className="text-xs text-gray-400 text-center">Password must be at least 6 characters</p>
            )}
          </form>
        )}

        {/* Divider */}
        <div className="relative my-5 sm:my-6">
          <div className="absolute inset-0 flex items-center">
            <div className="w-full border-t border-gray-300"></div>
          </div>
          <div className="relative flex justify-center text-sm">
            <span className="px-4 bg-white text-gray-500 font-medium">Or continue with</span>
          </div>
        </div>

        {/* Google Sign In */}
        <button
          type="button"
          onClick={async () => {
            try {
              setLoading(true);
              setError('');
              await signInWithGoogle();
            } catch (err: any) {
              setError(err.message || 'Failed to sign in with Google');
              setLoading(false);
            }
          }}
          disabled={loading}
          className="w-full bg-white border-2 border-gray-300 text-gray-700 py-3 px-4 rounded-xl font-semibold hover:bg-gray-50 hover:border-gray-400 transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center shadow-sm hover:shadow-md transform hover:scale-[1.02] active:scale-[0.98]"
        >
          <svg className="w-5 h-5 mr-3" viewBox="0 0 24 24">
            <path
              fill="#4285F4"
              d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
            />
            <path
              fill="#34A853"
              d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
            />
            <path
              fill="#FBBC05"
              d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
            />
            <path
              fill="#EA4335"
              d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
            />
          </svg>
          Sign in with Google
        </button>

        {/* Facebook Sign In */}
        <button
          type="button"
          onClick={async () => {
            try {
              setLoading(true);
              setError('');
              await signInWithFacebook();
            } catch (err: any) {
              setError(err.message || 'Failed to sign in with Facebook');
              setLoading(false);
            }
          }}
          disabled={loading}
          className="w-full bg-[#1877F2] hover:bg-[#166FE5] text-white py-3 px-4 rounded-xl font-semibold transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center shadow-sm hover:shadow-md transform hover:scale-[1.02] active:scale-[0.98] mt-2 sm:mt-3"
        >
          <svg className="w-5 h-5 mr-3" viewBox="0 0 24 24" fill="currentColor">
            <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" />
          </svg>
          Sign in with Facebook
        </button>

      </div>
    </div>
  );
};
