// components/landing/HeroSection.tsx
'use client';

import Link from 'next/link';
import { CosmicButton, GhostButton } from '@/components/ui/ButtonVariants';

export function HeroSection() {
  return (
    <div className="min-h-screen flex items-center justify-center px-4 bg-transparent">
      {/* Floating container */}
      <div className="relative max-w-4xl mx-auto">
        {/* Glass effect container */}
        <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-8 md:p-12 shadow-2xl">
          <div className="text-center">
            {/* Announcement badge */}
            <div className="inline-flex items-center justify-center mb-8">
              <div className="relative rounded-full px-4 py-2 text-sm bg-white/10 backdrop-blur-sm border border-white/20 text-white hover:bg-white/20 transition-all duration-200">
                Revolutionary IoT growing technology.{' '}
                <Link href="/about" className="font-semibold text-yellow-400 hover:text-yellow-300 transition-colors">
                  <span aria-hidden="true" className="absolute inset-0" />
                  Learn more <span aria-hidden="true">&rarr;</span>
                </Link>
              </div>
            </div>
            
            {/* Main heading */}
            <h1 className="text-balance text-5xl md:text-6xl lg:text-7xl font-semibold tracking-tight text-white mb-6">
              Smart IoT devices for{' '}
              <span className="bg-gradient-to-r from-yellow-400 via-pink-500 to-purple-600 bg-clip-text text-transparent">
                intelligent growing
              </span>
            </h1>
            
            {/* Description */}
            <p className="mt-6 text-lg md:text-xl text-gray-300 max-w-2xl mx-auto">
              Monitor, control, and optimize your growing environment with precision sensors, automated controls, and real-time data insights.
            </p>
            
            {/* CTA Buttons */}
            <div className="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4">
              <Link href="/shop">
                <CosmicButton size="lg" className="group min-w-[160px]">
                  Shop Devices
                  <span className="inline-block transition-transform group-hover:translate-x-1 ml-2">→</span>
                </CosmicButton>
              </Link>
              <Link href="/about">
                <GhostButton size="lg" className="text-white hover:text-yellow-400 border-white/30 hover:border-yellow-400/50 min-w-[160px]">
                  Learn more <span aria-hidden="true">→</span>
                </GhostButton>
              </Link>
            </div>
          </div>
        </div>
        
        {/* Floating decoration elements */}
        <div className="absolute -top-4 -left-4 w-8 h-8 bg-gradient-to-br from-yellow-400/30 to-orange-500/30 rounded-full blur-sm animate-pulse"></div>
        <div className="absolute -bottom-4 -right-4 w-6 h-6 bg-gradient-to-br from-pink-500/30 to-purple-600/30 rounded-full blur-sm animate-pulse" style={{ animationDelay: '1s' }}></div>
        <div className="absolute top-1/2 -right-8 w-4 h-4 bg-gradient-to-br from-blue-400/40 to-cyan-500/40 rounded-full blur-sm animate-pulse" style={{ animationDelay: '2s' }}></div>
      </div>
    </div>
  );
}