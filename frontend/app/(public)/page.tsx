'use client';

import { HeroSection } from '@/components/landing/HeroSection';
import { FeaturesSection } from '@/components/landing/FeaturesSection';
import { ProductShowcase } from '@/components/landing/ProductShowcase';
import { StatsSection } from '@/components/landing/StatsSection';
import { CtaSection } from '@/components/landing/CtaSection';

export default function HomePage() {
  return (
    <>
      {/* Hero Section (Your existing beautiful hero) */}
      <HeroSection />

      {/* Features Section */}
      <FeaturesSection />

      {/* Product Showcase */}
      <ProductShowcase />

      {/* Stats Section */}
      <StatsSection />

      {/* Final CTA */}
      <CtaSection />
    </>
  );
}