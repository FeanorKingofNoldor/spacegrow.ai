// app/(dashboard)/user/page.tsx - Main user landing page (redirects to system dashboard)
'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { useSubscriptionGuard } from '@/contexts/SubscriptionContext';
import { useAuth } from '@/contexts/AuthContext';

export default function UserPage() {
  const router = useRouter();
  const { user, loading: authLoading } = useAuth();
  const { 
    hasSubscription, 
    needsOnboarding, 
    isBlocked, 
    subscriptionStatus,
    loading: subscriptionLoading 
  } = useSubscriptionGuard();

  useEffect(() => {
    // Wait for auth and subscription data to load
    if (authLoading || subscriptionLoading) return;

    // Not authenticated - handled by SubscriptionGuard
    if (!user) return;

    // User needs to complete onboarding
    if (needsOnboarding) {
      router.push('/onboarding/choose-plan');
      return;
    }

    // Subscription is blocked (past due, canceled)
    if (isBlocked) {
      if (subscriptionStatus === 'past_due') {
        router.push('/user/billing'); // Direct to payment update
      } else {
        router.push('/user/subscription'); // Direct to plan selection
      }
      return;
    }

    // All good - redirect to main dashboard
    router.push('/user/dashboard/system_dashboard');
  }, [
    router, 
    user, 
    authLoading, 
    subscriptionLoading, 
    needsOnboarding, 
    isBlocked, 
    subscriptionStatus
  ]);

  return (
    <div className="min-h-screen bg-space-primary flex items-center justify-center">
      <div className="cosmic-starfield" />
      <div className="cosmic-sunflare" />
      <div className="relative z-10">
        <LoadingSpinner text="Loading your dashboard..." />
      </div>
    </div>
  );
}