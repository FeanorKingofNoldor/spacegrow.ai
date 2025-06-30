// components/auth/AuthGuard.tsx
'use client';

import { useAuth } from '@/contexts/AuthContext';
import { useEffect, useState } from 'react';
import { Modal } from '@/components/ui/Modal';
import { LoginForm } from './LoginForm';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';

interface AuthGuardProps {
  children: React.ReactNode;
  fallback?: React.ReactNode;
  redirectTo?: string;
}

export function AuthGuard({ children, fallback }: AuthGuardProps) {
  const { user, loading } = useAuth();
  const [showLoginModal, setShowLoginModal] = useState(false);

  useEffect(() => {
    if (!loading && !user) {
      setShowLoginModal(true);
    } else if (user) {
      setShowLoginModal(false);
    }
  }, [user, loading]);

  // Show loading spinner while checking auth
  if (loading) {
    return (
      <div className="min-h-screen bg-space-primary flex items-center justify-center">
        <div className="cosmic-starfield" />
        <div className="cosmic-sunflare" />
        <div className="relative z-10">
          <LoadingSpinner />
        </div>
      </div>
    );
  }

  // Show children if authenticated
  if (user) {
    return <>{children}</>;
  }

  // Show fallback or login modal if not authenticated
  return (
    <>
      {fallback || (
        <div className="min-h-screen bg-space-primary flex items-center justify-center">
          <div className="cosmic-starfield" />
          <div className="cosmic-sunflare" />
          <div className="relative z-10 p-6 text-center">
            <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-8 max-w-md">
              <h2 className="text-xl font-bold text-cosmic-text mb-4">Authentication Required</h2>
              <p className="text-cosmic-text-muted mb-6">
                Please sign in to access your growing dashboard.
              </p>
              <button
                onClick={() => setShowLoginModal(true)}
                className="text-stellar-accent hover:underline"
              >
                Click here to sign in
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Login Modal */}
      <Modal
        isOpen={showLoginModal}
        onClose={() => setShowLoginModal(false)}
        title=""
        className="max-w-md"
      >
        <LoginForm
          onSuccess={() => setShowLoginModal(false)}
          onClose={() => setShowLoginModal(false)}
        />
      </Modal>
    </>
  );
}