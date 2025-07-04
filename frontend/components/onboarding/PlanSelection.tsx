// components/onboarding/PlanSelection.tsx
'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/Button';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { Plan } from '@/types/subscription';
import { useSubscription } from '@/contexts/SubscriptionContext';
import { useAuth } from '@/contexts/AuthContext';
import { Check, Star, Zap, Users, TrendingUp, Building, Mail, Phone } from 'lucide-react';
import { cn } from '@/lib/utils';

export function PlanSelection() {
  const [selectedInterval, setSelectedInterval] = useState<'month' | 'year'>('month');
  const [loadingPlanId, setLoadingPlanId] = useState<number | null>(null);
  
  const { plans, loading, error, selectPlan } = useSubscription();
  const { user } = useAuth();
  const router = useRouter();

  // Auto-redirect if user already has subscription
  useEffect(() => {
    if (user?.subscription) {
      router.push('/user/dashboard');
    }
  }, [user, router]);

  const handlePlanSelect = async (planId: number) => {
    setLoadingPlanId(planId);
    try {
      // Directly proceed to payment processing
      await selectPlan(planId, selectedInterval);
      // selectPlan should handle the redirect to Stripe checkout
    } catch (error) {
      console.error('Plan selection failed:', error);
      setLoadingPlanId(null);
    }
  };

  const handleEnterpriseContact = () => {
    // You can customize this to open a modal, redirect to contact page, or mailto
    window.location.href = 'mailto:enterprise@spacegrow.ai?subject=Enterprise%20Solutions%20Inquiry';
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <LoadingSpinner size="lg" text="Loading plans..." />
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-xl font-semibold text-red-400 mb-2">Error Loading Plans</h2>
          <p className="text-cosmic-text-muted">{error}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-transparent py-12 px-4">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12">
          <div className="flex justify-center mb-6">
            <div className="w-16 h-16 bg-gradient-cosmic rounded-xl flex items-center justify-center">
              <Star className="w-8 h-8 text-white" />
            </div>
          </div>
          <h1 className="text-4xl font-bold text-cosmic-text mb-4">
            Choose Your Plan
          </h1>
          <p className="text-xl text-cosmic-text-muted max-w-2xl mx-auto">
            Welcome to SpaceGrow.ai! Select a plan to start monitoring your IoT devices 
            and unlock the full potential of smart growing.
          </p>
        </div>

        {/* Billing Toggle */}
        <div className="flex justify-center mb-12">
          <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-1">
            <button
              onClick={() => setSelectedInterval('month')}
              className={cn(
                'px-6 py-3 rounded-lg text-sm font-medium transition-all duration-200',
                selectedInterval === 'month'
                  ? 'bg-stellar-accent text-cosmic-text shadow-lg'
                  : 'text-cosmic-text-muted hover:text-cosmic-text'
              )}
            >
              Monthly
            </button>
            <button
              onClick={() => setSelectedInterval('year')}
              className={cn(
                'px-6 py-3 rounded-lg text-sm font-medium transition-all duration-200 relative',
                selectedInterval === 'year'
                  ? 'bg-stellar-accent text-cosmic-text shadow-lg'
                  : 'text-cosmic-text-muted hover:text-cosmic-text'
              )}
            >
              Yearly
              <span className="absolute -top-2 -right-2 bg-green-500 text-white text-xs px-2 py-1 rounded-full">
                20% OFF
              </span>
            </button>
          </div>
        </div>

        {/* Plans Grid - Now includes Enterprise */}
        <div className="grid lg:grid-cols-3 gap-8 mb-12">
          {plans.map((plan) => (
            <PlanCard
              key={plan.id}
              plan={plan}
              interval={selectedInterval}
              loading={loadingPlanId === plan.id}
              onSelect={() => handlePlanSelect(plan.id)}
            />
          ))}
          
          {/* Enterprise Plan */}
          <EnterpriseCard onContact={handleEnterpriseContact} />
        </div>

        {/* Trust Indicators */}
        <div className="text-center">
          <p className="text-cosmic-text-muted text-sm">
            🔒 Secure payment • ⚡ Instant activation • 📞 24/7 support
          </p>
        </div>

        {/* Feature Comparison */}
        <div className="mt-16">
          <FeatureComparison plans={plans} />
        </div>
      </div>
    </div>
  );
}

interface PlanCardProps {
  plan: Plan;
  interval: 'month' | 'year';
  loading: boolean;
  onSelect: () => void;
}

function PlanCard({ plan, interval, loading, onSelect }: PlanCardProps) {
  const price = interval === 'month' ? plan.monthly_price : plan.yearly_price;
  const period = interval === 'month' ? 'month' : 'year';
  const isPopular = plan.name === 'Professional';
  
  const yearlyDiscount = interval === 'year' ? 
    ((plan.monthly_price * 12 - plan.yearly_price) / (plan.monthly_price * 12) * 100).toFixed(0) : 0;

  const planIcons = {
    'Basic': Users,
    'Professional': TrendingUp,
    'Enterprise': Zap
  };

  const PlanIcon = planIcons[plan.name as keyof typeof planIcons] || Users;

  return (
    <div
      className={cn(
        'relative rounded-2xl p-8 transition-all duration-300',
        'bg-space-glass backdrop-blur-md border border-space-border',
        'hover:border-stellar-accent/50 hover:shadow-lg hover:shadow-stellar-accent/10',
        isPopular && 'scale-105 border-stellar-accent/70'
      )}
    >
      {/* Popular Badge */}
      {isPopular && (
        <div className="absolute -top-4 left-1/2 transform -translate-x-1/2">
          <div className="bg-gradient-cosmic px-4 py-2 rounded-full text-white text-sm font-medium">
            ⭐ Most Popular
          </div>
        </div>
      )}

      {/* Plan Header */}
      <div className="text-center mb-6">
        <div className="w-16 h-16 bg-gradient-cosmic rounded-xl flex items-center justify-center mx-auto mb-4">
          <PlanIcon className="w-8 h-8 text-white" />
        </div>
        <h3 className="text-2xl font-bold text-cosmic-text mb-2">{plan.name}</h3>
        <p className="text-cosmic-text-muted">{plan.description}</p>
      </div>

      {/* Pricing */}
      <div className="text-center mb-6">
        <div className="flex items-baseline justify-center mb-2">
          <span className="text-4xl font-bold text-cosmic-text">${price}</span>
          <span className="text-cosmic-text-muted ml-1">/{period}</span>
        </div>
        {interval === 'year' && yearlyDiscount && (
          <div className="text-green-400 text-sm font-medium">
            Save {yearlyDiscount}% with yearly billing
          </div>
        )}
        <div className="text-cosmic-text-muted text-sm mt-1">
          {plan.device_limit} devices included
        </div>
      </div>

      {/* Features */}
      <div className="space-y-3 mb-8">
        {plan.features.map((feature, index) => (
          <div key={index} className="flex items-center text-cosmic-text">
            <Check className="w-5 h-5 text-green-400 mr-3 flex-shrink-0" />
            <span className="text-sm">{feature}</span>
          </div>
        ))}
        {plan.device_limit < 10 && (
          <div className="flex items-center text-cosmic-text">
            <Check className="w-5 h-5 text-green-400 mr-3 flex-shrink-0" />
            <span className="text-sm">Additional devices +$5/month each</span>
          </div>
        )}
      </div>

      {/* Choose Plan Button */}
      <Button
        onClick={onSelect}
        disabled={loading}
        variant="cosmic"
        className="w-full"
        size="lg"
      >
        {loading ? (
          <>
            <LoadingSpinner size="sm" />
            <span className="ml-2">Processing...</span>
          </>
        ) : (
          'Choose Plan'
        )}
      </Button>
    </div>
  );
}

function EnterpriseCard({ onContact }: { onContact: () => void }) {
  return (
    <div className="relative rounded-2xl p-8 transition-all duration-300 bg-space-glass backdrop-blur-md border border-space-border hover:border-stellar-accent/50 hover:shadow-lg hover:shadow-stellar-accent/10">
      {/* Enterprise Header */}
      <div className="text-center mb-6">
        <div className="w-16 h-16 bg-gradient-to-br from-purple-500 to-pink-500 rounded-xl flex items-center justify-center mx-auto mb-4">
          <Building className="w-8 h-8 text-white" />
        </div>
        <h3 className="text-2xl font-bold text-cosmic-text mb-2">Enterprise</h3>
        <p className="text-cosmic-text-muted">Custom solutions for large organizations</p>
      </div>

      {/* Custom Pricing */}
      <div className="text-center mb-6">
        <div className="flex items-baseline justify-center mb-2">
          <span className="text-2xl font-bold text-cosmic-text">Custom</span>
        </div>
        <div className="text-cosmic-text-muted text-sm">
          Tailored to your needs
        </div>
      </div>

      {/* Enterprise Features */}
      <div className="space-y-3 mb-8">
        {[
          'Unlimited devices',
          'Dedicated account manager',
          'Custom integrations',
          'On-premise deployment',
          'SLA guarantees',
          'Priority support',
          'Custom training',
          'Volume discounts'
        ].map((feature, index) => (
          <div key={index} className="flex items-center text-cosmic-text">
            <Check className="w-5 h-5 text-green-400 mr-3 flex-shrink-0" />
            <span className="text-sm">{feature}</span>
          </div>
        ))}
      </div>

      {/* Contact Button */}
      <Button
        onClick={onContact}
        variant="outline"
        className="w-full mb-4"
        size="lg"
      >
        <Mail className="w-4 h-4 mr-2" />
        Contact Sales
      </Button>

      {/* Additional Contact Options */}
      <div className="text-center">
        <p className="text-cosmic-text-muted text-xs mb-2">
          Or call us directly:
        </p>
        <a 
          href="tel:+1-555-SPACEGROW" 
          className="text-stellar-accent hover:text-stellar-accent/80 text-sm font-medium flex items-center justify-center"
        >
          <Phone className="w-3 h-3 mr-1" />
          +1 (555) SPACE-GROW
        </a>
      </div>
    </div>
  );
}

function FeatureComparison({ plans }: { plans: Plan[] }) {
  const allFeatures = [
    'Basic device monitoring',
    'Email notifications',
    'API access',
    'Standard support',
    'Advanced analytics',
    'Priority support',
    'Custom integrations',
    'Data export',
    'White-label options',
    'On-premise deployment',
    'Dedicated support'
  ];

  // Add Enterprise to comparison
  const plansWithEnterprise = [...plans, {
    id: 999,
    name: 'Enterprise',
    features: [
      'unlimited devices',
      'dedicated account manager', 
      'custom integrations',
      'on-premise deployment',
      'priority support',
      'sla guarantees',
      'custom training',
      'advanced analytics',
      'data export',
      'white-label options'
    ]
  }];

  return (
    <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-2xl p-8">
      <h3 className="text-2xl font-bold text-cosmic-text text-center mb-8">
        Feature Comparison
      </h3>
      
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="border-b border-space-border">
              <th className="text-left py-4 text-cosmic-text font-medium">Features</th>
              {plansWithEnterprise.map((plan) => (
                <th key={plan.id} className="text-center py-4 text-cosmic-text font-medium">
                  {plan.name}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {allFeatures.map((feature, index) => (
              <tr key={index} className="border-b border-space-border/50">
                <td className="py-4 text-cosmic-text">{feature}</td>
                {plansWithEnterprise.map((plan) => (
                  <td key={plan.id} className="text-center py-4">
                    {plan.features.some(f => f.toLowerCase().includes(feature.toLowerCase().split(' ')[0])) ? (
                      <Check className="w-5 h-5 text-green-400 mx-auto" />
                    ) : (
                      <span className="text-cosmic-text-muted">-</span>
                    )}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}