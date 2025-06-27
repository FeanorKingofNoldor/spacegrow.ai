'use client'

import { useState } from 'react'
import Link from 'next/link'
import { CheckIcon, XMarkIcon } from '@heroicons/react/20/solid'

const pricing = {
  tiers: [
    {
      id: 'starter',
      name: 'Starter',
      description: 'Perfect for hobbyists and small growing operations.',
      price: { monthly: '$19', annually: '$190' },
      highlights: [
        '2 devices included',
        'Basic monitoring & alerts', 
        'Mobile app access',
        'Data export (CSV)',
        'Email support'
      ],
      featured: false,
    },
    {
      id: 'pro',
      name: 'Professional',
      description: 'Advanced features for serious growers.',
      price: { monthly: '$49', annually: '$490' },
      highlights: [
        '4 devices included',
        'Advanced analytics & automation',
        'Priority support & live chat',
        'Custom alert configurations',
        'API access',
        'Historical data analysis'
      ],
      featured: true,
    },
    {
      id: 'enterprise',
      name: 'Enterprise',
      description: 'Custom solutions for commercial operations.',
      price: { monthly: 'Custom', annually: 'Custom' },
      highlights: [
        'Unlimited devices',
        'White-label solutions',
        'Dedicated account manager',
        'Custom integrations',
        '24/7 phone support',
        'On-site installation'
      ],
      featured: false,
    },
  ],
  sections: [
    {
      name: 'Features',
      features: [
        { name: 'Device limit', tiers: { Starter: '2', Professional: '4', Enterprise: 'Unlimited' } },
        { name: 'Real-time monitoring', tiers: { Starter: true, Professional: true, Enterprise: true } },
        { name: 'Mobile app', tiers: { Starter: true, Professional: true, Enterprise: true } },
        { name: 'Email alerts', tiers: { Starter: true, Professional: true, Enterprise: true } },
        { name: 'SMS alerts', tiers: { Starter: false, Professional: true, Enterprise: true } },
        { name: 'Custom alert thresholds', tiers: { Starter: false, Professional: true, Enterprise: true } },
      ],
    },
    {
      name: 'Analytics & Data',
      features: [
        { name: 'Basic charts', tiers: { Starter: true, Professional: true, Enterprise: true } },
        { name: 'Advanced analytics', tiers: { Starter: false, Professional: true, Enterprise: true } },
        { name: 'Historical data (months)', tiers: { Starter: '3', Professional: '12', Enterprise: 'Unlimited' } },
        { name: 'Data export (CSV)', tiers: { Starter: true, Professional: true, Enterprise: true } },
        { name: 'API access', tiers: { Starter: false, Professional: true, Enterprise: true } },
        { name: 'Custom reports', tiers: { Starter: false, Professional: false, Enterprise: true } },
      ],
    },
    {
      name: 'Support',
      features: [
        { name: 'Knowledge base', tiers: { Starter: true, Professional: true, Enterprise: true } },
        { name: 'Email support', tiers: { Starter: true, Professional: true, Enterprise: true } },
        { name: 'Live chat support', tiers: { Starter: false, Professional: true, Enterprise: true } },
        { name: 'Phone support', tiers: { Starter: false, Professional: false, Enterprise: true } },
        { name: 'Priority support', tiers: { Starter: false, Professional: true, Enterprise: true } },
        { name: 'Dedicated account manager', tiers: { Starter: false, Professional: false, Enterprise: true } },
      ],
    },
  ],
}

const faqs = [
  {
    id: 1,
    question: "Can I upgrade or downgrade my plan at any time?",
    answer: "Yes! You can upgrade or downgrade your plan at any time from your account dashboard. Changes take effect immediately, and we'll prorate any billing differences."
  },
  {
    id: 2,
    question: "What happens if I exceed my device limit?",
    answer: "If you need to connect more devices than your plan allows, you'll be prompted to upgrade to a higher tier. We'll help you migrate seamlessly with no data loss."
  },
  {
    id: 3,
    question: "Is there a free trial available?",
    answer: "Yes! We offer a 14-day free trial with full access to Professional features. No credit card required to start your trial."
  },
  {
    id: 4,
    question: "Do you offer discounts for educational institutions?",
    answer: "Absolutely! We provide 50% discounts for educational institutions, research facilities, and non-profit organizations. Contact our sales team for details."
  },
  {
    id: 5,
    question: "What payment methods do you accept?",
    answer: "We accept all major credit cards, PayPal, and bank transfers for annual plans. Enterprise customers can also arrange for purchase orders and custom billing terms."
  },
  {
    id: 6,
    question: "Is my data secure and backed up?",
    answer: "Yes! All data is encrypted in transit and at rest. We maintain multiple backups across different geographic regions and guarantee 99.9% uptime."
  }
]

function classNames(...classes: (string | boolean | undefined)[]): string {
  return classes.filter(Boolean).join(' ')
}

export default function PricingPage() {
  const [billingCycle, setBillingCycle] = useState<'monthly' | 'annually'>('monthly')

  return (
    <div className="bg-white dark:bg-gray-900">
      {/* Header */}
      <div className="bg-gray-900 dark:bg-gray-950">
        <div className="mx-auto max-w-7xl px-6 py-24 sm:py-32 lg:px-8">
          <div className="mx-auto max-w-4xl text-center">
            <h1 className="text-4xl font-bold tracking-tight text-white sm:text-6xl">
              Simple, transparent pricing
            </h1>
            <p className="mt-6 text-lg leading-8 text-gray-300">
              Choose the perfect plan for your growing operation. Start with our free trial and scale as you grow.
            </p>
          </div>

          {/* Billing toggle */}
          <div className="mt-16 flex justify-center">
            <fieldset aria-label="Payment frequency">
              <div className="grid grid-cols-2 gap-x-1 rounded-full bg-white/5 p-1 text-center text-xs font-semibold leading-5 text-white">
                <label className={classNames(
                  "cursor-pointer rounded-full px-2.5 py-1",
                  billingCycle === 'monthly' ? 'bg-blue-500' : 'hover:bg-white/10'
                )}>
                  <input
                    type="radio"
                    name="frequency"
                    value="monthly"
                    checked={billingCycle === 'monthly'}
                    onChange={(e) => setBillingCycle(e.target.value as 'monthly')}
                    className="sr-only"
                  />
                  <span>Monthly</span>
                </label>
                <label className={classNames(
                  "cursor-pointer rounded-full px-2.5 py-1",
                  billingCycle === 'annually' ? 'bg-blue-500' : 'hover:bg-white/10'
                )}>
                  <input
                    type="radio"
                    name="frequency"
                    value="annually"
                    checked={billingCycle === 'annually'}
                    onChange={(e) => setBillingCycle(e.target.value as 'annually')}
                    className="sr-only"
                  />
                  <span>Annually</span>
                </label>
              </div>
            </fieldset>
          </div>
          {billingCycle === 'annually' && (
            <p className="mt-4 text-center text-sm text-green-400">
              💰 Save up to 20% with annual billing
            </p>
          )}
        </div>
      </div>

      {/* Pricing cards */}
      <div className="mx-auto max-w-7xl px-6 pb-24 pt-12 lg:px-8">
        <div className="mx-auto max-w-4xl">
          <div className="grid grid-cols-1 gap-8 lg:grid-cols-3">
            {pricing.tiers.map((tier) => (
              <div
                key={tier.id}
                className={classNames(
                  tier.featured
                    ? 'bg-gray-900 dark:bg-gray-800 ring-2 ring-blue-500 shadow-2xl'
                    : 'bg-white dark:bg-gray-800 ring-1 ring-gray-200 dark:ring-gray-700 shadow-lg',
                  'rounded-3xl p-8 xl:p-10',
                )}
              >
                <div className="flex items-center justify-between gap-x-4">
                  <h3
                    className={classNames(
                      tier.featured ? 'text-blue-400' : 'text-gray-900 dark:text-white',
                      'text-lg font-semibold leading-8',
                    )}
                  >
                    {tier.name}
                  </h3>
                  {tier.featured && (
                    <p className="rounded-full bg-blue-600/10 px-2.5 py-1 text-xs font-semibold leading-5 text-blue-400">
                      Most popular
                    </p>
                  )}
                </div>
                <p className={classNames(
                  tier.featured ? 'text-gray-300' : 'text-gray-600 dark:text-gray-400',
                  'mt-4 text-sm leading-6'
                )}>
                  {tier.description}
                </p>
                <p className="mt-6 flex items-baseline gap-x-1">
                  <span
                    className={classNames(
                      tier.featured ? 'text-white' : 'text-gray-900 dark:text-white',
                      'text-4xl font-bold tracking-tight',
                    )}
                  >
                    {billingCycle === 'monthly' ? tier.price.monthly : tier.price.annually}
                  </span>
                  {tier.price.monthly !== 'Custom' && (
                    <span
                      className={classNames(
                        tier.featured ? 'text-gray-300' : 'text-gray-600 dark:text-gray-400',
                        'text-sm font-semibold leading-6',
                      )}
                    >
                      /{billingCycle === 'monthly' ? 'month' : 'year'}
                    </span>
                  )}
                </p>
                <Link
                  href={tier.name === 'Enterprise' ? '/support#contact' : '/signup'}
                  className={classNames(
                    tier.featured
                      ? 'bg-blue-500 text-white shadow-sm hover:bg-blue-400 focus-visible:outline-blue-500'
                      : 'bg-blue-600 text-white shadow-sm hover:bg-blue-500 focus-visible:outline-blue-600',
                    'mt-6 block w-full rounded-md px-3 py-2 text-center text-sm font-semibold leading-6 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2',
                  )}
                >
                  {tier.name === 'Enterprise' ? 'Contact sales' : 'Start free trial'}
                </Link>
                <ul
                  role="list"
                  className={classNames(
                    tier.featured ? 'text-gray-300' : 'text-gray-600 dark:text-gray-400',
                    'mt-8 space-y-3 text-sm leading-6',
                  )}
                >
                  {tier.highlights.map((highlight) => (
                    <li key={highlight} className="flex gap-x-3">
                      <CheckIcon
                        className={classNames(
                          tier.featured ? 'text-blue-400' : 'text-blue-600',
                          'h-6 w-5 flex-none',
                        )}
                        aria-hidden="true"
                      />
                      {highlight}
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Feature comparison */}
      <div className="mx-auto max-w-7xl px-6 pb-24 lg:px-8">
        <div className="mx-auto max-w-4xl">
          <h2 className="text-3xl font-bold tracking-tight text-gray-900 dark:text-white text-center mb-16">
            Compare all features
          </h2>
          
          {/* Mobile comparison */}
          <div className="lg:hidden space-y-16">
            {pricing.tiers.map((tier) => {
              // Helper to map tier.name to the correct key type
              type TierKey = 'Starter' | 'Professional' | 'Enterprise';
              const getTierKey = (name: string): TierKey => {
                switch (name.toLowerCase()) {
                  case 'starter':
                    return 'Starter';
                  case 'professional':
                    return 'Professional';
                  case 'enterprise':
                    return 'Enterprise';
                  default:
                    throw new Error('Unknown tier name');
                }
              };

              return (
                <div key={tier.id} className="border-t border-gray-200 dark:border-gray-700">
                  <div
                    className={classNames(
                      tier.featured ? 'border-blue-600' : 'border-transparent',
                      '-mt-px w-72 border-t-2 pt-10 md:w-80',
                    )}
                  >
                    <h3
                      className={classNames(
                        tier.featured ? 'text-blue-600' : 'text-gray-900 dark:text-white',
                        'text-sm font-semibold leading-6',
                      )}
                    >
                      {tier.name}
                    </h3>
                    <p className="mt-1 text-sm leading-6 text-gray-600 dark:text-gray-400">{tier.description}</p>
                  </div>

                  <div className="mt-10 space-y-10">
                    {pricing.sections.map((section) => (
                      <div key={section.name}>
                        <h4 className="text-sm font-semibold leading-6 text-gray-900 dark:text-white">{section.name}</h4>
                        <div className="relative mt-6">
                          <div
                            className={classNames(
                              tier.featured ? 'ring-2 ring-blue-600' : 'ring-1 ring-gray-200 dark:ring-gray-700',
                              'rounded-lg bg-white dark:bg-gray-800 shadow-sm',
                            )}
                          >
                            <dl className="divide-y divide-gray-200 dark:divide-gray-700 text-sm leading-6">
                              {section.features.map((feature) => {
                                const tierKey = getTierKey(tier.name);
                                const value = feature.tiers[tierKey];
                                return (
                                  <div
                                    key={feature.name}
                                    className="flex items-center justify-between px-4 py-3"
                                  >
                                    <dt className="text-gray-600 dark:text-gray-400">{feature.name}</dt>
                                    <dd className="flex items-center">
                                      {typeof value === 'string' ? (
                                        <span
                                          className={
                                            tier.featured ? 'font-semibold text-blue-600' : 'text-gray-900 dark:text-white'
                                          }
                                        >
                                          {value}
                                        </span>
                                      ) : (
                                        <>
                                          {value === true ? (
                                            <CheckIcon
                                              className="h-5 w-5 text-blue-600"
                                              aria-hidden="true"
                                            />
                                          ) : (
                                            <XMarkIcon
                                              className="h-5 w-5 text-gray-400"
                                              aria-hidden="true"
                                            />
                                          )}
                                          <span className="sr-only">
                                            {value === true ? 'Yes' : 'No'}
                                          </span>
                                        </>
                                      )}
                                    </dd>
                                  </div>
                                );
                              })}
                            </dl>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              );
            })}
          </div>

          {/* Desktop comparison */}
          <div className="hidden lg:block">
            <div className="grid grid-cols-4 gap-x-8 border-t border-gray-200 dark:border-gray-700">
              <div></div>
              {pricing.tiers.map((tier) => (
                <div key={tier.id} className="-mt-px">
                  <div
                    className={classNames(
                      tier.featured ? 'border-blue-600' : 'border-transparent',
                      'border-t-2 pt-10',
                    )}
                  >
                    <p
                      className={classNames(
                        tier.featured ? 'text-blue-600' : 'text-gray-900 dark:text-white',
                        'text-sm font-semibold leading-6',
                      )}
                    >
                      {tier.name}
                    </p>
                    <p className="mt-1 text-sm leading-6 text-gray-600 dark:text-gray-400">{tier.description}</p>
                  </div>
                </div>
              ))}
            </div>

            <div className="space-y-16 mt-6">
              {pricing.sections.map((section) => (
                <div key={section.name}>
                  <h3 className="text-sm font-semibold leading-6 text-gray-900 dark:text-white">{section.name}</h3>
                  <div className="relative mt-10">
                    <table className="w-full border-separate border-spacing-x-8">
                      <thead>
                        <tr>
                          <th></th>
                          {pricing.tiers.map((tier) => (
                            <th key={tier.id}>
                              <span className="sr-only">{tier.name} tier</span>
                            </th>
                          ))}
                        </tr>
                      </thead>
                      <tbody>
                        {section.features.map((feature, featureIdx) => (
                          <tr key={feature.name}>
                            <th
                              scope="row"
                              className="w-1/4 py-3 pr-4 text-left text-sm font-normal leading-6 text-gray-900 dark:text-white"
                            >
                              {feature.name}
                              {featureIdx !== section.features.length - 1 && (
                                <div className="absolute inset-x-8 mt-3 h-px bg-gray-200 dark:bg-gray-700" />
                              )}
                            </th>
                            {pricing.tiers.map((tier) => {
                              type TierKey = 'Starter' | 'Professional' | 'Enterprise';
                              const getTierKey = (name: string): TierKey => {
                                switch (name.toLowerCase()) {
                                  case 'starter':
                                    return 'Starter';
                                  case 'professional':
                                    return 'Professional';
                                  case 'enterprise':
                                    return 'Enterprise';
                                  default:
                                    throw new Error('Unknown tier name');
                                }
                              };
                              const tierKey = getTierKey(tier.name);
                              const value = feature.tiers[tierKey];
                              return (
                                <td key={tier.id} className="w-1/4 px-4 py-3 text-center">
                                  {typeof value === 'string' ? (
                                    <span
                                      className={classNames(
                                        tier.featured ? 'font-semibold text-blue-600' : 'text-gray-900 dark:text-white',
                                        'text-sm leading-6',
                                      )}
                                    >
                                      {value}
                                    </span>
                                  ) : (
                                    <>
                                      {value === true ? (
                                        <CheckIcon className="mx-auto h-5 w-5 text-blue-600" aria-hidden="true" />
                                      ) : (
                                        <XMarkIcon
                                          className="mx-auto h-5 w-5 text-gray-400"
                                          aria-hidden="true"
                                        />
                                      )}
                                      <span className="sr-only">
                                        {value === true ? 'Yes' : 'No'}
                                      </span>
                                    </>
                                  )}
                                </td>
                              );
                            })}
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* FAQ section */}
      <div className="mx-auto max-w-7xl px-6 pb-24 lg:px-8">
        <div className="mx-auto max-w-4xl">
          <h2 className="text-3xl font-bold tracking-tight text-gray-900 dark:text-white text-center mb-16">
            Frequently asked questions
          </h2>
          <dl className="space-y-8">
            {faqs.map((faq) => (
              <div key={faq.id} className="border-b border-gray-200 dark:border-gray-700 pb-8">
                <dt className="text-lg font-semibold leading-7 text-gray-900 dark:text-white">
                  {faq.question}
                </dt>
                <dd className="mt-4 text-base leading-7 text-gray-600 dark:text-gray-400">
                  {faq.answer}
                </dd>
              </div>
            ))}
          </dl>
        </div>
      </div>

      {/* CTA section */}
      <div className="bg-gray-50 dark:bg-gray-800">
        <div className="mx-auto max-w-7xl px-6 py-24 sm:py-32 lg:px-8">
          <div className="mx-auto max-w-2xl text-center">
            <h2 className="text-3xl font-bold tracking-tight text-gray-900 dark:text-white sm:text-4xl">
              Start monitoring today
            </h2>
            <p className="mx-auto mt-6 max-w-xl text-lg leading-8 text-gray-600 dark:text-gray-400">
              Join thousands of growers who trust SpaceGrow.ai to optimize their growing operations.
              Start your free trial today.
            </p>
            <div className="mt-10 flex items-center justify-center gap-x-6">
              <Link
                href="/signup"
                className="rounded-md bg-blue-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600"
              >
                Start free trial
              </Link>
              <Link
                href="/devices" 
                className="text-sm font-semibold leading-6 text-gray-900 dark:text-white"
              >
                View devices <span aria-hidden="true">→</span>
              </Link>
            </div>
            <p className="mt-4 text-sm text-gray-500 dark:text-gray-400">
              No credit card required • 14-day free trial • Cancel anytime
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}