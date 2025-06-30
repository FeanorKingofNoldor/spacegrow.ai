// app/(auth)/(session_control)/login/page.tsx
'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { CosmicButton, GhostButton } from '@/components/ui/ButtonVariants';
import { Eye, EyeOff, ArrowLeft, Loader2 } from 'lucide-react';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [isSignUp, setIsSignUp] = useState(false);
  
  const { login } = useAuth();
  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const success = await login(email, password);
      if (success) {
        router.push('/dashboard');
      } else {
        setError('Invalid email or password');
      }
    } catch (err) {
      setError('Something went wrong. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center px-4 bg-transparent">
      <div className="relative max-w-md w-full mx-auto">
        {/* Floating container */}
        <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-8 shadow-2xl">
          
          {/* Header */}
          <div className="text-center mb-8">
            <Link href="/" className="inline-flex items-center text-white hover:text-yellow-400 transition-colors mb-6">
              <ArrowLeft className="w-4 h-4 mr-2" />
              Back to SpaceGrow.ai
            </Link>
            <h1 className="text-3xl font-bold text-white mb-2">
              {isSignUp ? 'Create Account' : 'Welcome Back'}
            </h1>
            <p className="text-gray-300">
              {isSignUp 
                ? 'Start your smart growing journey' 
                : 'Sign in to your SpaceGrow.ai account'
              }
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
            {/* Email Field */}
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
                placeholder="your@email.com"
              />
            </div>

            {/* Password Field */}
            <div>
              <label htmlFor="password" className="block text-sm font-medium text-white mb-2">
                Password
              </label>
              <div className="relative">
                <input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  className="
                    w-full rounded-lg bg-white/10 backdrop-blur-sm border border-white/20
                    px-4 py-3 pr-12 text-white placeholder-gray-400
                    focus:outline-none focus:ring-2 focus:ring-yellow-400 focus:border-transparent
                    transition-all duration-200
                  "
                  placeholder="Enter your password"
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

            {/* Submit Button */}
            <CosmicButton 
              type="submit" 
              size="lg" 
              className="w-full"
              disabled={loading}
            >
              {loading ? (
                <>
                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                  {isSignUp ? 'Creating Account...' : 'Signing In...'}
                </>
              ) : (
                isSignUp ? 'Create Account' : 'Sign In'
              )}
            </CosmicButton>
          </form>

          {/* Toggle Sign Up / Sign In */}
          <div className="mt-6 text-center">
            <p className="text-gray-300">
              {isSignUp ? 'Already have an account?' : "Don't have an account?"}{' '}
              <button
                onClick={() => setIsSignUp(!isSignUp)}
                className="text-yellow-400 hover:text-yellow-300 font-medium transition-colors"
              >
                {isSignUp ? 'Sign in' : 'Sign up'}
              </button>
            </p>
          </div>

          {/* Forgot Password */}
          {!isSignUp && (
            <div className="mt-4 text-center">
              <Link 
                href="/forgot-password" 
                className="text-sm text-gray-400 hover:text-white transition-colors"
              >
                Forgot your password?
              </Link>
            </div>
          )}
        </div>

        {/* Floating decoration elements */}
        <div className="absolute -top-4 -left-4 w-8 h-8 bg-gradient-to-br from-yellow-400/30 to-orange-500/30 rounded-full blur-sm animate-pulse"></div>
        <div className="absolute -bottom-4 -right-4 w-6 h-6 bg-gradient-to-br from-pink-500/30 to-purple-600/30 rounded-full blur-sm animate-pulse" style={{ animationDelay: '1s' }}></div>
        <div className="absolute top-1/2 -right-8 w-4 h-4 bg-gradient-to-br from-blue-400/40 to-cyan-500/40 rounded-full blur-sm animate-pulse" style={{ animationDelay: '2s' }}></div>
      </div>
    </div>
  );
}