// components/landing/CtaSection.tsx
'use client';

import Link from 'next/link';
import { CosmicButton, OutlineButton } from '@/components/ui/ButtonVariants';

export function CtaSection() {
  return (
    <section className="py-16 px-4">
      <div className="max-w-4xl mx-auto">
        <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-8 md:p-12 shadow-2xl text-center">
          <h2 className="text-4xl md:text-5xl font-semibold tracking-tight text-white mb-6">
            Ready to grow{' '}
            <span className="bg-gradient-to-r from-yellow-400 via-pink-500 to-purple-600 bg-clip-text text-transparent">
              smarter?
            </span>
          </h2>
          <p className="mx-auto max-w-xl text-lg text-gray-300 mb-10">
            Start monitoring your environment with precision sensors and intelligent automation.
            Professional results, hobbyist friendly.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <Link href="/shop">
              <CosmicButton size="lg" className="min-w-[140px]">
                Shop Now
              </CosmicButton>
            </Link>
            <Link href="/pricing">
              <OutlineButton size="lg" className="min-w-[140px]">
                View Pricing
              </OutlineButton>
            </Link>
          </div>
        </div>
      </div>
    </section>
  );
}