// app/(auth)/(session_control)/reset-password/[token]/page.tsx
'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { CosmicButton } from '@/components/ui/ButtonVariants';
import { ArrowLeft, Loader2, Eye, EyeOff, Key, CheckCircle } from 'lucide-react';

interface ResetPasswordPageProps {
  params: {
    token: string;
  };
}

export default function ResetPasswordPage({ params }: ResetPasswordPageProps) {
  const [password, setPassword] = useState('');
  const [passwordConfirmation, setPasswordConfirmation] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showPasswordConfirmation, setShowPasswordConfirmation] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);
  
  const { setUser } = useAuth();
  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    // Validation
    if (password !== passwordConfirmation) {
      setError('Passwords do not match');
      setLoading(false);
      return;
    }

    if (password.length < 6) {
      setError('Password must be at least 6 characters long');
      setLoading(false);
      return;
    }

    try {
      const response = await fetch('/api/v1/auth/reset_password', {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          reset_password_token: params.token,
          password: password,
          password_confirmation: passwordConfirmation,
        }),
      });

      const data = await response.json();

      if (response.ok) {
        setSuccess(true);
        // Store user data and token if backend returns them
        if (data.data && data.token) {
          setUser(data.data);
          localStorage.setItem('auth_token', data.token);
          
          // Redirect to dashboard after a brief success message
          setTimeout(() => {
            router.push('/dashboard');
          }, 2000);
        }
      } else {
        setError(data.status?.message || 'Failed to reset password. The link may be expired or invalid.');
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
            
            <h1 className="text-2xl font-bold text-white mb-4">Password Reset Successfully!</h1>
            <p className="text-gray-300 mb-6">
              Your password has been updated. You're now signed in and will be redirected to your dashboard.
            </p>
            
            <CosmicButton 
              onClick={() => router.push('/dashboard')}
              size="lg" 
              className="w-full"
            >
              Go to Dashboard
            </CosmicButton>
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
                <Key className="w-6 h-6 text-yellow-400" />
              </div>
            </div>
            
            <h1 className="text-3xl font-bold text-white mb-2">Reset Your Password</h1>
            <p className="text-gray-300">
              Enter your new password below. Make sure it's secure and memorable.
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
            {/* New Password Field */}
            <div>
              <label htmlFor="password" className="block text-sm font-medium text-white mb-2">
                New Password
              </label>
              <div className="relative">
                <input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  minLength={6}
                  className="
                    w-full rounded-lg bg-white/10 backdrop-blur-sm border border-white/20
                    px-4 py-3 pr-12 text-white placeholder-gray-400
                    focus:outline-none focus:ring-2 focus:ring-yellow-400 focus:border-transparent
                    transition-all duration-200
                  "
                  placeholder="Enter new password (min. 6 characters)"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-white transition-colors"
                >
                  {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                </button>
              </div>
            </div>

            {/* Confirm Password Field */}
            <div>
              <label htmlFor="passwordConfirmation" className="block text-sm font-medium text-white mb-2">
                Confirm New Password
              </label>
              <div className="relative">
                <input
                  id="passwordConfirmation"
                  type={showPasswordConfirmation ? 'text' : 'password'}
                  value={passwordConfirmation}
                  onChange={(e) => setPasswordConfirmation(e.target.value)}
                  required
                  minLength={6}
                  className="
                    w-full rounded-lg bg-white/10 backdrop-blur-sm border border-white/20
                    px-4 py-3 pr-12 text-white placeholder-gray-400
                    focus:outline-none focus:ring-2 focus:ring-yellow-400 focus:border-transparent
                    transition-all duration-200
                  "
                  placeholder="Confirm your new password"
                />
                <button
                  type="button"
                  onClick={() => setShowPasswordConfirmation(!showPasswordConfirmation)}
                  className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-white transition-colors"
                >
                  {showPasswordConfirmation ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                </button>
              </div>
            </div>

            {/* Password Requirements */}
            <div className="text-xs text-gray-400 space-y-1">
              <p>Password requirements:</p>
              <ul className="list-disc list-inside space-y-1 ml-2">
                <li className={password.length >= 6 ? 'text-green-400' : 'text-gray-400'}>
                  At least 6 characters
                </li>
                <li className={password === passwordConfirmation && password.length > 0 ? 'text-green-400' : 'text-gray-400'}>
                  Passwords match
                </li>
              </ul>
            </div>

            <CosmicButton 
              type="submit" 
              size="lg" 
              className="w-full"
              disabled={loading || password !== passwordConfirmation || password.length < 6}
            >
              {loading ? (
                <>
                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                  Updating Password...
                </>
              ) : (
                'Update Password'
              )}
            </CosmicButton>
          </form>
        </div>

        {/* Floating decoration elements */}
        <div className="absolute -top-4 -left-4 w-8 h-8 bg-gradient-to-br from-yellow-400/30 to-orange-500/30 rounded-full blur-sm animate-pulse"></div>
        <div className="absolute -bottom-4 -right-4 w-6 h-6 bg-gradient-to-br from-pink-500/30 to-purple-600/30 rounded-full blur-sm animate-pulse" style={{ animationDelay: '1s' }}></div>
        <div className="absolute top-1/2 -right-8 w-4 h-4 bg-gradient-to-br from-blue-400/40 to-cyan-500/40 rounded-full blur-sm animate-pulse" style={{ animationDelay: '2s' }}></div>
      </div>
    </div>
  );
}