// components/shop/common/EpicShopFooter.tsx
'use client';

import Link from 'next/link';
import { Shield, Truck, RefreshCw, Headphones } from 'lucide-react';

const features = [
  {
    icon: Shield,
    title: 'Secure Payments',
    description: 'SSL encrypted checkout'
  },
  {
    icon: Truck,
    title: 'Free Shipping',
    description: 'On orders over $200'
  },
  {
    icon: RefreshCw,
    title: '30-Day Returns',
    description: 'Hassle-free returns'
  },
  {
    icon: Headphones,
    title: '24/7 Support',
    description: 'Expert technical help'
  }
];

const navigation = {
  products: [
    { name: 'Environmental Monitor', href: '/shop/environmental-monitor' },
    { name: 'Liquid Monitor', href: '/shop/liquid-monitor' },
    { name: 'Accessories', href: '/shop/accessories' },
    { name: 'Bundles', href: '/shop/bundles' },
  ],
  support: [
    { name: 'Setup Guide', href: '/docs/setup' },
    { name: 'API Documentation', href: '/docs/api' },
    { name: 'Troubleshooting', href: '/support' },
    { name: 'Contact Support', href: '/contact' },
  ],
  company: [
    { name: 'About SpaceGrow', href: '/about' },
    { name: 'Technology', href: '/technology' },
    { name: 'Partners', href: '/partners' },
    { name: 'Careers', href: '/careers' },
  ],
  legal: [
    { name: 'Privacy Policy', href: '/privacy' },
    { name: 'Terms of Service', href: '/terms' },
    { name: 'Shipping Policy', href: '/shipping' },
    { name: 'Refund Policy', href: '/refunds' },
  ],
};

export function EpicShopFooter() {
  return (
    <footer className="bg-space-secondary border-t border-space-border">
      {/* Features Section */}
      <div className="bg-space-card/50 backdrop-blur-sm">
        <div className="mx-auto max-w-7xl px-6 py-12 lg:px-8">
          <div className="grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-4">
            {features.map((feature, index) => (
              <div 
                key={feature.title} 
                className="flex items-center space-x-4 animate-drift"
                style={{ animationDelay: `${index * 0.1}s` }}
              >
                <div className="flex-shrink-0">
                  <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-gradient-cosmic">
                    <feature.icon className="h-5 w-5 text-white" />
                  </div>
                </div>
                <div>
                  <h3 className="text-sm font-semibold text-cosmic-text">
                    {feature.title}
                  </h3>
                  <p className="text-xs text-cosmic-text-muted">
                    {feature.description}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Main Footer */}
      <div className="mx-auto max-w-7xl px-6 py-16 sm:py-20 lg:px-8">
        <div className="xl:grid xl:grid-cols-3 xl:gap-8">
          
          {/* Brand Section */}
          <div className="space-y-8">
            <div className="text-2xl font-bold text-gradient-cosmic">
              SpaceGrow.ai
            </div>
            <p className="text-sm text-cosmic-text-muted max-w-md">
              Professional IoT solutions for intelligent growing. Monitor, control, and optimize your environment with precision sensors and real-time data.
            </p>
            
            {/* Newsletter */}
            <div className="space-y-4">
              <h3 className="text-sm font-semibold text-cosmic-text">Stay Updated</h3>
              <form className="flex gap-2">
                <input
                  type="email"
                  placeholder="Enter your email"
                  className="
                    flex-1 rounded-lg bg-space-glass border border-space-border 
                    px-3 py-2 text-sm text-cosmic-text placeholder-cosmic-text-light
                    focus:outline-none focus:ring-2 focus:ring-stellar-accent focus:border-transparent
                    transition-all duration-200
                  "
                />
                <button
                  type="submit"
                  className="
                    rounded-lg bg-gradient-cosmic px-4 py-2 text-sm font-semibold text-white
                    hover:scale-105 transition-all duration-200 animate-nebula-glow
                  "
                >
                  Subscribe
                </button>
              </form>
            </div>
          </div>

          {/* Links Grid */}
          <div className="mt-16 grid grid-cols-2 gap-8 xl:col-span-2 xl:mt-0">
            <div className="md:grid md:grid-cols-2 md:gap-8">
              <div>
                <h3 className="text-sm font-semibold text-cosmic-text">Products</h3>
                <ul role="list" className="mt-6 space-y-4">
                  {navigation.products.map((item) => (
                    <li key={item.name}>
                      <Link
                        href={item.href}
                        className="text-sm text-cosmic-text-muted hover:text-stellar-accent transition-colors"
                      >
                        {item.name}
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
              <div className="mt-10 md:mt-0">
                <h3 className="text-sm font-semibold text-cosmic-text">Support</h3>
                <ul role="list" className="mt-6 space-y-4">
                  {navigation.support.map((item) => (
                    <li key={item.name}>
                      <Link
                        href={item.href}
                        className="text-sm text-cosmic-text-muted hover:text-stellar-accent transition-colors"
                      >
                        {item.name}
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
            <div className="md:grid md:grid-cols-2 md:gap-8">
              <div>
                <h3 className="text-sm font-semibold text-cosmic-text">Company</h3>
                <ul role="list" className="mt-6 space-y-4">
                  {navigation.company.map((item) => (
                    <li key={item.name}>
                      <Link
                        href={item.href}
                        className="text-sm text-cosmic-text-muted hover:text-stellar-accent transition-colors"
                      >
                        {item.name}
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
              <div className="mt-10 md:mt-0">
                <h3 className="text-sm font-semibold text-cosmic-text">Legal</h3>
                <ul role="list" className="mt-6 space-y-4">
                  {navigation.legal.map((item) => (
                    <li key={item.name}>
                      <Link
                        href={item.href}
                        className="text-sm text-cosmic-text-muted hover:text-stellar-accent transition-colors"
                      >
                        {item.name}
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </div>
        </div>

        {/* Bottom Section */}
        <div className="mt-16 border-t border-space-border pt-8 sm:mt-20">
          <div className="flex flex-col items-center justify-between sm:flex-row">
            <p className="text-sm text-cosmic-text-light">
              &copy; 2025 SpaceGrow.ai. All rights reserved.
            </p>
            <div className="mt-4 sm:mt-0">
              <div className="flex items-center space-x-2">
                <div className="h-2 w-2 bg-stellar-accent rounded-full animate-pulse"></div>
                <span className="text-sm text-cosmic-text-light">
                  Secure Shopping Experience
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </footer>
  );
}