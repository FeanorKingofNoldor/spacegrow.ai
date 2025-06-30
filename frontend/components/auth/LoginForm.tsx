// components/auth/LoginForm.tsx
'use client';

import { useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';

interface LoginFormProps {
  onSuccess?: () => void;
  onClose?: () => void;
}

export function LoginForm({ onSuccess, onClose }: LoginFormProps) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [isSignUp, setIsSignUp] = useState(false);
  const { login } = useAuth();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      const success = await login(email, password);
      if (success) {
        onSuccess?.();
        onClose?.();
      } else {
        setError('Invalid email or password');
      }
    } catch (error) {
      setError('Login failed. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('Sign up functionality coming soon!');
  };

  return (
    <div className="w-full max-w-md mx-auto">
      {/* Header */}
      <div className="text-center mb-6">
        <div className="w-12 h-12 bg-gradient-cosmic rounded-lg flex items-center justify-center mx-auto mb-3">
          <span className="text-white font-bold">SG</span>
        </div>
        <h2 className="text-xl font-bold text-cosmic-text">
          {isSignUp ? 'Create Account' : 'Welcome Back'}
        </h2>
        <p className="text-cosmic-text-muted text-sm">
          {isSignUp ? 'Join SpaceGrow.ai today' : 'Sign in to your growing dashboard'}
        </p>
      </div>

      {/* Form */}
      <form onSubmit={isSignUp ? handleSignUp : handleSubmit} className="space-y-4">
        {error && (
          <div className="bg-red-500/10 border border-red-500/20 rounded-lg p-3">
            <p className="text-red-400 text-sm">{error}</p>
          </div>
        )}

        <div>
          <label htmlFor="email" className="block text-sm font-medium text-cosmic-text mb-1">
            Email
          </label>
          <Input
            id="email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="your@email.com"
            required
            disabled={isLoading}
          />
        </div>

        <div>
          <label htmlFor="password" className="block text-sm font-medium text-cosmic-text mb-1">
            Password
          </label>
          <Input
            id="password"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Enter your password"
            required
            disabled={isLoading}
          />
        </div>

        {isSignUp && (
          <div>
            <label htmlFor="confirmPassword" className="block text-sm font-medium text-cosmic-text mb-1">
              Confirm Password
            </label>
            <Input
              id="confirmPassword"
              type="password"
              placeholder="Confirm your password"
              required
              disabled={isLoading}
            />
          </div>
        )}

        <Button 
          type="submit" 
          variant="cosmic" 
          size="lg" 
          className="w-full"
          disabled={isLoading}
        >
          {isLoading 
            ? (isSignUp ? 'Creating Account...' : 'Signing In...') 
            : (isSignUp ? 'Create Account' : 'Sign In')
          }
        </Button>
      </form>

      {/* Toggle between login/signup */}
      <div className="mt-4 text-center">
        <button
          type="button"
          onClick={() => {
            setIsSignUp(!isSignUp);
            setError('');
            setEmail('');
            setPassword('');
          }}
          className="text-stellar-accent hover:underline text-sm"
          disabled={isLoading}
        >
          {isSignUp 
            ? 'Already have an account? Sign in' 
            : "Don't have an account? Sign up"
          }
        </button>
      </div>

      {/* Forgot password */}
      {!isSignUp && (
        <div className="mt-2 text-center">
          <button
            type="button"
            onClick={() => setError('Password reset functionality coming soon!')}
            className="text-cosmic-text-muted hover:text-stellar-accent text-sm"
            disabled={isLoading}
          >
            Forgot password?
          </button>
        </div>
      )}
    </div>
  );
}