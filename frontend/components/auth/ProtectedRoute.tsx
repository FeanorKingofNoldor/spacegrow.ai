// components/auth/ProtectedRoute.tsx
'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';

interface ProtectedRouteProps {
  children: React.ReactNode;
  allowedRoles?: Array<'user' | 'pro' | 'admin'>;
  requireAuth?: boolean;
  fallbackUrl?: string;
}

export function ProtectedRoute({ 
  children, 
  allowedRoles = ['user', 'pro', 'admin'],
  requireAuth = true,
  fallbackUrl = '/login'
}: ProtectedRouteProps) {
  const { user, loading, isAuthenticated } = useAuth();
  const router = useRouter();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  // Wait for mounting and auth check
  if (!mounted || loading) {
    return <LoadingSpinner />;
  }

  // Check authentication requirement
  if (requireAuth && !isAuthenticated) {
    router.push(fallbackUrl);
    return <LoadingSpinner />;
  }

  // Check role-based access
  if (requireAuth && user && !allowedRoles.includes(user.role)) {
    return (
      <div className="min-h-screen flex items-center justify-center px-4 bg-transparent">
        <div className="max-w-md w-full mx-auto">
          <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-8 shadow-2xl text-center">
            <div className="w-16 h-16 bg-red-500/20 rounded-full flex items-center justify-center mx-auto mb-6">
              <svg className="w-8 h-8 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z" />
              </svg>
            </div>
            
            <h1 className="text-2xl font-bold text-white mb-4">Access Denied</h1>
            <p className="text-gray-300 mb-6">
              You don't have permission to access this page. 
              {user.role === 'user' && allowedRoles.includes('pro') && (
                <span className="block mt-2">Consider upgrading to Pro for access to advanced features.</span>
              )}
            </p>
            
            <div className="space-y-3">
              <button
                onClick={() => router.push('/dashboard')}
                className="w-full bg-gradient-cosmic text-white px-4 py-2 rounded-lg hover:scale-105 transition-all duration-200"
              >
                Go to Dashboard
              </button>
              
              {user.role === 'user' && allowedRoles.includes('pro') && (
                <button
                  onClick={() => router.push('/dashboard/subscriptions')}
                  className="w-full bg-white/10 border border-white/20 text-white px-4 py-2 rounded-lg hover:bg-white/20 transition-all duration-200"
                >
                  Upgrade to Pro
                </button>
              )}
            </div>
          </div>
        </div>
      </div>
    );
  }

  // Render children if all checks pass
  return <>{children}</>;
}

// Helper HOC for easier usage
export function withAuth<P extends object>(
  Component: React.ComponentType<P>,
  allowedRoles?: Array<'user' | 'pro' | 'admin'>
) {
  return function AuthenticatedComponent(props: P) {
    return (
      <ProtectedRoute allowedRoles={allowedRoles}>
        <Component {...props} />
      </ProtectedRoute>
    );
  };
}