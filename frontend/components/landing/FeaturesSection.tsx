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
    <section className="py-16 px-4">
      <div className="max-w-6xl mx-auto">
        <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-8 md:p-12 shadow-2xl">
          <div className="text-center mb-16">
            <h2 className="text-base font-semibold text-yellow-400 mb-4">Everything you need</h2>
            <p className="text-4xl md:text-5xl font-semibold tracking-tight text-white mb-6">
              Professional IoT growing made{' '}
              <span className="bg-gradient-to-r from-yellow-400 via-pink-500 to-purple-600 bg-clip-text text-transparent">
                simple
              </span>
            </p>
            <p className="text-lg text-gray-300 max-w-2xl mx-auto">
              From hobbyist setups to commercial operations, our platform scales with your ambitions.
            </p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {features.map((feature) => (
              <div key={feature.title} className="group text-center">
                <div className="flex flex-col items-center">
                  <div className="rounded-xl bg-white/10 backdrop-blur-sm p-4 ring-1 ring-white/20 group-hover:bg-white/20 group-hover:ring-yellow-400/40 transition-all duration-300 mb-6">
                    <feature.icon aria-hidden="true" className="h-8 w-8 text-yellow-400" />
                  </div>
                  <h3 className="text-xl font-semibold text-white mb-3 group-hover:text-yellow-400 transition-colors">
                    {feature.title}
                  </h3>
                  <p className="text-gray-300 leading-relaxed">
                    {feature.description}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}