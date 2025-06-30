// components/landing/FeaturesSection.tsx
'use client';

import { Monitor, Zap, BarChart3, Shield } from 'lucide-react';

const features = [
  {
    icon: Monitor,
    title: 'Real-time Monitoring',
    description: 'Track temperature, humidity, pH, and more with precision sensors that never sleep.',
  },
  {
    icon: Zap,
    title: 'Automated Controls',
    description: 'Smart automation that responds to your environment and keeps everything optimal.',
  },
  {
    icon: BarChart3,
    title: 'Advanced Analytics',
    description: 'Deep insights and trends to optimize your growing strategy with data-driven decisions.',
  },
  {
    icon: Shield,
    title: 'Enterprise Grade',
    description: 'Reliable, secure, and scalable infrastructure trusted by professional growers.',
  },
];

export function FeaturesSection() {
  return (
    <section className="bg-gray-900 py-24 sm:py-32">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-base/7 font-semibold text-green-400">Everything you need</h2>
          <p className="mt-2 text-pretty text-4xl font-semibold tracking-tight text-white sm:text-5xl">
            Professional IoT growing made simple
          </p>
          <p className="mt-6 text-lg/8 text-gray-300">
            From hobbyist setups to commercial operations, our platform scales with your ambitions.
          </p>
        </div>
        <div className="mx-auto mt-16 max-w-2xl sm:mt-20 lg:mt-24 lg:max-w-none">
          <dl className="grid max-w-xl grid-cols-1 gap-x-8 gap-y-16 lg:max-w-none lg:grid-cols-4">
            {features.map((feature) => (
              <div key={feature.title} className="group">
                <div className="flex flex-col items-start">
                  <div className="rounded-lg bg-green-600/10 p-2 ring-1 ring-green-600/25 group-hover:bg-green-600/20 transition-colors">
                    <feature.icon aria-hidden="true" className="h-6 w-6 text-green-400" />
                  </div>
                  <dt className="mt-4 text-base/7 font-semibold text-white">{feature.title}</dt>
                  <dd className="mt-2 text-base/7 text-gray-400">{feature.description}</dd>
                </div>
              </div>
            ))}
          </dl>
        </div>
      </div>
    </section>
  );
}