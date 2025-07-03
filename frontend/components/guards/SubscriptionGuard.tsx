// components/guards/SubscriptionGuard.tsx
'use client';

import { useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { Button } from '@/components/ui/Button';
import { useAuth } from '@/contexts/AuthContext';
import { useSubscriptionGuard } from '@/contexts/SubscriptionContext';
import { AlertTriangle, CreditCard, Clock, XCircle } from 'lucide-react';

interface SubscriptionGuardProps {
  children: React.ReactNode;
  requiresSubscription?: boolean;
}

export function SubscriptionGuard({ 
  children, 
  requiresSubscription = true 
}: SubscriptionGuardProps) {
  const { user, loading: authLoading } = useAuth();
  const { 
    hasSubscription, 
    subscriptionStatus, 
    needsOnboarding, 
    isBlocked,
    loading: subscriptionLoading 
  } = useSubscriptionGuard();
  
  const router = useRouter();
  const pathname = usePathname();

  // Pages that don't require subscription
  const publicPages = [
    '/',
    '/login',
    '/register',
    '/about',
    '/pricing',
    '/features',
    '/contact',
    '/forgot-password',
    '/reset-password'
  ];

  // Onboarding pages that don't require active subscription
  const onboardingPages = [
    '/onboarding',
    '/onboarding/choose-plan',
    '/onboarding/payment'
  ];

  // Subscription management pages that work with any subscription state
  const subscriptionPages = [
    '/user/subscription',
    '/user/billing'
  ];

  const isPublicPage = publicPages.includes(pathname);
  const isOnboardingPage = onboardingPages.some(page => pathname.startsWith(page));
  const isSubscriptionPage = subscriptionPages.some(page => pathname.startsWith(page));

  // Handle redirects
  useEffect(() => {
    if (authLoading || subscriptionLoading) return;

    // Not logged in - redirect to login (except public pages)
    if (!user && !isPublicPage) {
      router.push('/login');
      return;
    }

    // Logged in but needs onboarding OR subscription expired/canceled
    if (user && (needsOnboarding || (hasSubscription && isBlocked && subscriptionStatus === 'canceled'))) {
      if (!isOnboardingPage && !isPublicPage) {
        router.push('/onboarding/choose-plan');
        return;
      }
    }

    // Has subscription but payment issues (past due) - redirect to billing
    if (user && hasSubscription && isBlocked && subscriptionStatus === 'past_due') {
      if (!isSubscriptionPage && !isPublicPage && !isOnboardingPage) {
        router.push('/user/billing');
        return;
      }
    }

    // Has subscription but other blocking issues - redirect to subscription management
    if (user && hasSubscription && isBlocked && subscriptionStatus !== 'past_due' && subscriptionStatus !== 'canceled') {
      if (!isSubscriptionPage && !isPublicPage && !isOnboardingPage) {
        router.push('/user/subscription');
        return;
      }
    }
  }, [
    user, 
    needsOnboarding, 
    hasSubscription, 
    isBlocked, 
    subscriptionStatus,
    pathname,
    isPublicPage,
    isOnboardingPage,
    isSubscriptionPage,
    authLoading,
    subscriptionLoading,
    router
  ]);

  // Show loading spinner during auth/subscription checks
  if (authLoading || subscriptionLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <LoadingSpinner size="lg" text="Loading..." />
      </div>
    );
  }

  // Allow access to public pages
  if (isPublicPage) {
    return <>{children}</>;
  }

  // Allow access to onboarding pages when needed
  if (isOnboardingPage && (needsOnboarding || (hasSubscription && isBlocked && subscriptionStatus === 'canceled'))) {
    return <>{children}</>;
  }

  // Allow access to subscription pages for any authenticated user
  if (isSubscriptionPage && user) {
    return <>{children}</>;
  }

  // Show subscription status warnings/blocks
  if (user && hasSubscription && isBlocked) {
    return <SubscriptionBlockedScreen status={subscriptionStatus} />;
  }

  // Show onboarding required screen
  if (user && needsOnboarding) {
    return <OnboardingRequiredScreen />;
  }

  // User not authenticated
  if (!user) {
    return <UnauthenticatedScreen />;
  }

  // All checks passed - render children
  return <>{children}</>;
}

function SubscriptionBlockedScreen({ status }: { status: string | null }) {
  const router = useRouter();

  const statusConfig = {
    past_due: {
      icon: CreditCard,
      title: 'Payment Required',
      message: 'Your subscription payment is overdue. Please update your payment method to continue using all features.',
      buttonText: 'Update Payment',
      buttonAction: () => router.push('/user/billing'),
      color: 'orange'
    },
    canceled: {
      icon: XCircle,
      title: 'Subscription Ended',
      message: 'Your subscription has ended. Choose a new plan to continue monitoring your devices.',
      buttonText: 'Choose New Plan',
      buttonAction: () => router.push('/onboarding/choose-plan'),
      color: 'red'
    }
  };

  const config = statusConfig[status as keyof typeof statusConfig] || {
    icon: XCircle,
    title: 'Subscription Issue',
    message: 'There is an issue with your subscription. Please contact support or choose a new plan.',
    buttonText: 'Choose Plan',
    buttonAction: () => router.push('/onboarding/choose-plan'),
    color: 'red'
  };
  
  const Icon = config.icon;

  return (
    <div className="min-h-screen flex items-center justify-center px-4">
      <div className="max-w-md w-full text-center">
        <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-2xl p-8">
          <div className={`w-16 h-16 bg-${config.color}-500/20 rounded-full flex items-center justify-center mx-auto mb-6`}>
            <Icon className={`w-8 h-8 text-${config.color}-400`} />
          </div>
          
          <h1 className="text-2xl font-bold text-cosmic-text mb-4">
            {config.title}
          </h1>
          
          <p className="text-cosmic-text-muted mb-8">
            {config.message}
          </p>
          
          <div className="space-y-3">
            <Button
              onClick={config.buttonAction}
              variant="cosmic"
              className="w-full"
            >
              {config.buttonText}
            </Button>
            
            <Button
              onClick={() => router.push('/support')}
              variant="ghost"
              className="w-full"
            >
              Contact Support
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}

function OnboardingRequiredScreen() {
  const router = useRouter();

  return (
    <div className="min-h-screen flex items-center justify-center px-4">
      <div className="max-w-md w-full text-center">
        <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-2xl p-8">
          <div className="w-16 h-16 bg-stellar-accent/20 rounded-full flex items-center justify-center mx-auto mb-6">
            <Clock className="w-8 h-8 text-stellar-accent" />
          </div>
          
          <h1 className="text-2xl font-bold text-cosmic-text mb-4">
            Complete Your Setup
          </h1>
          
          <p className="text-cosmic-text-muted mb-8">
            Welcome to SpaceGrow.ai! Please choose a plan to start monitoring your devices and unlock all features.
          </p>
          
          <Button
            onClick={() => router.push('/onboarding/choose-plan')}
            variant="cosmic"
            className="w-full"
          >
            Choose Your Plan
          </Button>
        </div>
      </div>
    </div>
  );
}

function UnauthenticatedScreen() {
  const router = useRouter();

  return (
    <div className="min-h-screen flex items-center justify-center px-4">
      <div className="max-w-md w-full text-center">
        <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-2xl p-8">
          <div className="w-16 h-16 bg-red-500/20 rounded-full flex items-center justify-center mx-auto mb-6">
            <AlertTriangle className="w-8 h-8 text-red-400" />
          </div>
          
          <h1 className="text-2xl font-bold text-cosmic-text mb-4">
            Authentication Required
          </h1>
          
          <p className="text-cosmic-text-muted mb-8">
            Please log in to access this page.
          </p>
          
          <div className="space-y-3">
            <Button
              onClick={() => router.push('/login')}
              variant="cosmic"
              className="w-full"
            >
              Log In
            </Button>
            
            <Button
              onClick={() => router.push('/register')}
              variant="outline"
              className="w-full"
            >
              Create Account
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}