// app/(auth)/(session_control)/forgot-password/page.tsx
'use client';

import { useState } from 'react';
import Link from 'next/link';
import { CosmicButton } from '@/components/ui/ButtonVariants';
import { ArrowLeft, Loader2, Mail, CheckCircle } from 'lucide-react';

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const response = await fetch('/api/v1/auth/forgot_password', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email }),
      });

      const data = await response.json();

      if (response.ok) {
        setSuccess(true);
      } else {
        setError(data.status?.message || 'Something went wrong. Please try again.');
      }
    } catch (err) {
      setError('Network error. Please check your connection and try again.');
    } finally {
      setLoading(false);
    }
  };

  if (success) {
    return (
      <div className="min-h-screen flex items-center justify-center px-4 bg-transparent">
        <div className="relative max-w-md w-full mx-auto">
          <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-8 shadow-2xl text-center">
            <div className="flex justify-center mb-6">
              <div className="w-16 h-16 bg-green-500/20 rounded-full flex items-center justify-center">
                <CheckCircle className="w-8 h-8 text-green-400" />
              </div>
            </div>
            
            <h1 className="text-2xl font-bold text-white mb-4">Check Your Email</h1>
            <p className="text-gray-300 mb-6">
              We've sent password reset instructions to <strong>{email}</strong>. 
              Please check your email and follow the link to reset your password.
            </p>
            
            <div className="space-y-4">
              <Link href="/login">
                <CosmicButton size="lg" className="w-full">
                  Back to Sign In
                </CosmicButton>
              </Link>
              
              <p className="text-sm text-gray-400">
                Didn't receive an email? Check your spam folder or{' '}
                <button
                  onClick={() => {
                    setSuccess(false);
                    setEmail('');
                  }}
                  className="text-yellow-400 hover:text-yellow-300 transition-colors"
                >
                  try again
                </button>
              </p>
            </div>
          </div>
          
          {/* Floating decorations */}
          <div className="absolute -top-4 -left-4 w-8 h-8 bg-gradient-to-br from-green-400/30 to-blue-500/30 rounded-full blur-sm animate-pulse"></div>
          <div className="absolute -bottom-4 -right-4 w-6 h-6 bg-gradient-to-br from-green-500/30 to-teal-600/30 rounded-full blur-sm animate-pulse" style={{ animationDelay: '1s' }}></div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center px-4 bg-transparent">
      <div className="relative max-w-md w-full mx-auto">
        <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-8 shadow-2xl">
          
          {/* Header */}
          <div className="text-center mb-8">
            <Link href="/login" className="inline-flex items-center text-white hover:text-yellow-400 transition-colors mb-6">
              <ArrowLeft className="w-4 h-4 mr-2" />
              Back to Sign In
            </Link>
            
            <div className="flex justify-center mb-4">
              <div className="w-12 h-12 bg-yellow-500/20 rounded-full flex items-center justify-center">
                <Mail className="w-6 h-6 text-yellow-400" />
              </div>
            </div>
            
            <h1 className="text-3xl font-bold text-white mb-2">Forgot Password?</h1>
            <p className="text-gray-300">
              No worries! Enter your email and we'll send you reset instructions.
            </p>
          </div>

          {/* Error Message */}
          {error && (
            <div className="bg-red-500/20 border border-red-500/30 rounded-lg p-3 mb-6">
              <p className="text-red-300 text-sm">{error}</p>
            </div>
          )}

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-white mb-2">
                Email Address
              </label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="
                  w-full rounded-lg bg-white/10 backdrop-blur-sm border border-white/20
                  px-4 py-3 text-white placeholder-gray-400
                  focus:outline-none focus:ring-2 focus:ring-yellow-400 focus:border-transparent
                  transition-all duration-200
                "
                placeholder="Enter your email address"
              />
            </div>

            <CosmicButton 
              type="submit" 
              size="lg" 
              className="w-full"
              disabled={loading}
            >
              {loading ? (
                <>
                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                  Sending Instructions...
                </>
              ) : (
                'Send Reset Instructions'
              )}
            </CosmicButton>
          </form>

          {/* Back to Login */}
          <div className="mt-6 text-center">
            <p className="text-gray-300">
              Remember your password?{' '}
              <Link href="/login" className="text-yellow-400 hover:text-yellow-300 font-medium transition-colors">
                Sign in instead
              </Link>
            </p>
          </div>
        </div>

        {/* Floating decoration elements */}
        <div className="absolute -top-4 -left-4 w-8 h-8 bg-gradient-to-br from-yellow-400/30 to-orange-500/30 rounded-full blur-sm animate-pulse"></div>
        <div className="absolute -bottom-4 -right-4 w-6 h-6 bg-gradient-to-br from-pink-500/30 to-purple-600/30 rounded-full blur-sm animate-pulse" style={{ animationDelay: '1s' }}></div>
        <div className="absolute top-1/2 -right-8 w-4 h-4 bg-gradient-to-br from-blue-400/40 to-cyan-500/40 rounded-full blur-sm animate-pulse" style={{ animationDelay: '2s' }}></div>
      </div>
    </div>
  );
}