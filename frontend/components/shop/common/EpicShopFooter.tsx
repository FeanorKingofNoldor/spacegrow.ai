// components/shop/common/EpicShopFooter.tsx
'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { 
  Rocket, 
  Star, 
  Zap, 
  Shield, 
  Heart, 
  Mail, 
  Phone, 
  MapPin, 
  Twitter, 
  Github, 
  Instagram, 
  Linkedin,
  Store,
  Thermometer,
  Droplets,
  Package,
  Wrench,
  Award,
  Users,
  TrendingUp,
  Globe,
  Sparkles,
  Atom
} from 'lucide-react';
import { ClientOnlyDotSparkles, ClientOnlyIconSparkles } from '@/components/ui/client-only-sparkles';

const quickLinks = [
  { name: 'All Products', href: '/shop', icon: <Store className="w-4 h-4" /> },
  { name: 'Environmental', href: '/shop/environmental-monitor', icon: <Thermometer className="w-4 h-4" /> },
  { name: 'Liquid Monitors', href: '/shop/liquid-monitor', icon: <Droplets className="w-4 h-4" /> },
  { name: 'Bundles', href: '/shop/bundles', icon: <Package className="w-4 h-4" /> },
  { name: 'Accessories', href: '/shop/accessories', icon: <Wrench className="w-4 h-4" /> },
];

const supportLinks = [
  { name: 'Setup Guide', href: '/support/setup' },
  { name: 'Troubleshooting', href: '/support/troubleshooting' },
  { name: 'API Documentation', href: '/docs/api' },
  { name: 'Warranty', href: '/support/warranty' },
  { name: 'Returns', href: '/shop/refunds' },
];

const companyLinks = [
  { name: 'About Us', href: '/about' },
  { name: 'Careers', href: '/careers' },
  { name: 'Press Kit', href: '/press' },
  { name: 'Partnerships', href: '/partners' },
  { name: 'Sustainability', href: '/sustainability' },
];

const socialLinks = [
  { name: 'Twitter', href: '#', icon: <Twitter className="w-5 h-5" />, color: 'hover:text-blue-400' },
  { name: 'Instagram', href: '#', icon: <Instagram className="w-5 h-5" />, color: 'hover:text-pink-400' },
  { name: 'LinkedIn', href: '#', icon: <Linkedin className="w-5 h-5" />, color: 'hover:text-blue-500' },
  { name: 'GitHub', href: '#', icon: <Github className="w-5 h-5" />, color: 'hover:text-purple-400' },
];

const stats = [
  { label: 'Happy Growers', value: '50,000+', icon: <Users className="w-6 h-6" /> },
  { label: 'Devices Sold', value: '100,000+', icon: <TrendingUp className="w-6 h-6" /> },
  { label: 'Countries', value: '85+', icon: <Globe className="w-6 h-6" /> },
  { label: 'Uptime', value: '99.9%', icon: <Shield className="w-6 h-6" /> },
];

export function EpicShopFooter() {
  const [currentYear] = useState(new Date().getFullYear());
  const [emailInput, setEmailInput] = useState('');
  const [isSubscribed, setIsSubscribed] = useState(false);

  const handleNewsletterSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (emailInput) {
      setIsSubscribed(true);
      setEmailInput('');
      setTimeout(() => setIsSubscribed(false), 3000);
    }
  };

  return (
    <footer className="relative overflow-hidden">
      {/* Cosmic background for footer */}
      <div className="absolute inset-0 bg-gradient-to-t from-black via-purple-900/50 to-transparent">

		{/* Floating particles */}
		<ClientOnlyIconSparkles 
		count={30}
		className=""
		iconClassName="w-2 h-2 text-white/30"
		/>
        
        {/* Glowing orbs */}
        <div className="absolute bottom-0 left-1/4 w-32 h-32 bg-gradient-radial from-blue-500/20 to-transparent rounded-full blur-2xl animate-pulse"></div>
        <div className="absolute top-10 right-1/3 w-24 h-24 bg-gradient-radial from-purple-500/20 to-transparent rounded-full blur-xl animate-pulse" style={{ animationDelay: '1s' }}></div>
      </div>

      <div className="relative backdrop-blur-md bg-gray-900/80 border-t border-purple-500/30">
        {/* Stats Banner */}
        <div className="border-b border-gray-800/50">
          <div className="container mx-auto px-4 py-8">
            <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
              {stats.map((stat, index) => (
                <div 
                  key={stat.label} 
                  className="text-center group"
                  style={{ animationDelay: `${index * 0.1}s` }}
                >
                  <div className="flex items-center justify-center mb-2">
                    <div className="p-3 bg-gradient-to-r from-purple-600/20 to-pink-600/20 rounded-full group-hover:scale-110 transition-transform">
                      <div className="text-purple-400 group-hover:text-pink-400 transition-colors">
                        {stat.icon}
                      </div>
                    </div>
                  </div>
                  <div className="text-2xl font-bold text-white mb-1">{stat.value}</div>
                  <div className="text-sm text-gray-400">{stat.label}</div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Main Footer Content */}
        <div className="container mx-auto px-4 py-12">
          <div className="grid lg:grid-cols-5 gap-8">
            {/* Company Info */}
            <div className="lg:col-span-2">
              <div className="flex items-center gap-3 mb-6">
                <div className="relative">
                  <div className="absolute inset-0 bg-gradient-to-r from-purple-600 to-pink-600 rounded-xl blur-lg opacity-50"></div>
                  <div className="relative w-12 h-12 bg-gradient-to-r from-purple-600 to-pink-600 rounded-xl flex items-center justify-center">
                    <Rocket className="w-6 h-6 text-white" />
                  </div>
                </div>
                <div>
                  <h3 className="text-2xl font-bold bg-gradient-to-r from-purple-400 to-pink-400 bg-clip-text text-transparent">
                    SpaceGrow
                  </h3>
                  <p className="text-xs text-gray-400">Grow Beyond Earth</p>
                </div>
              </div>
              
              <p className="text-gray-300 mb-6 leading-relaxed">
                Revolutionary IoT monitoring systems designed for the future of agriculture. 
                From Earth to Mars, we're helping growers achieve perfect conditions with 
                laboratory-grade precision and space-age technology.
              </p>

              {/* Newsletter Signup */}
              <div className="mb-6">
                <h4 className="text-white font-semibold mb-3 flex items-center gap-2">
                  <Zap className="w-4 h-4 text-yellow-400" />
                  Join the Space Growers
                </h4>
                <form onSubmit={handleNewsletterSubmit} className="flex gap-2">
                  <input
                    type="email"
                    placeholder="Enter your email"
                    value={emailInput}
                    onChange={(e) => setEmailInput(e.target.value)}
                    className="flex-1 px-4 py-2 bg-gray-800/50 border border-gray-600/50 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500"
                    disabled={isSubscribed}
                  />
                  <button
                    type="submit"
                    disabled={isSubscribed}
                    className={`px-6 py-2 rounded-lg font-medium transition-all duration-300 ${
                      isSubscribed 
                        ? 'bg-green-600 text-white' 
                        : 'bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white transform hover:scale-105'
                    }`}
                  >
                    {isSubscribed ? (
                      <div className="flex items-center gap-2">
                        <Star className="w-4 h-4" />
                        Subscribed!
                      </div>
                    ) : (
                      'Launch'
                    )}
                  </button>
                </form>
              </div>

              {/* Contact Info */}
              <div className="space-y-3">
                <div className="flex items-center gap-3 text-gray-300">
                  <Mail className="w-4 h-4 text-purple-400" />
                  <span>support@spacegrow.ai</span>
                </div>
                <div className="flex items-center gap-3 text-gray-300">
                  <Phone className="w-4 h-4 text-purple-400" />
                  <span>1-800-XSPACE (1-800-977-2233)</span>
                </div>
                <div className="flex items-center gap-3 text-gray-300">
                  <MapPin className="w-4 h-4 text-purple-400" />
                  <span>Mars Colony Prep Center, Earth HQ</span>
                </div>
              </div>
            </div>

            {/* Quick Links */}
            <div>
              <h4 className="text-white font-semibold mb-6 flex items-center gap-2">
                <Store className="w-4 h-4 text-blue-400" />
                Shop Categories
              </h4>
              <ul className="space-y-3">
                {quickLinks.map((link) => (
                  <li key={link.name}>
                    <Link 
                      href={link.href}
                      className="flex items-center gap-2 text-gray-300 hover:text-white transition-colors group"
                    >
                      <span className="text-gray-500 group-hover:text-blue-400 transition-colors">
                        {link.icon}
                      </span>
                      {link.name}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>

            {/* Support */}
            <div>
              <h4 className="text-white font-semibold mb-6 flex items-center gap-2">
                <Shield className="w-4 h-4 text-green-400" />
                Support
              </h4>
              <ul className="space-y-3">
                {supportLinks.map((link) => (
                  <li key={link.name}>
                    <Link 
                      href={link.href}
                      className="text-gray-300 hover:text-white transition-colors"
                    >
                      {link.name}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>

            {/* Company */}
            <div>
              <h4 className="text-white font-semibold mb-6 flex items-center gap-2">
                <Award className="w-4 h-4 text-yellow-400" />
                Company
              </h4>
              <ul className="space-y-3">
                {companyLinks.map((link) => (
                  <li key={link.name}>
                    <Link 
                      href={link.href}
                      className="text-gray-300 hover:text-white transition-colors"
                    >
                      {link.name}
                    </Link>
                  </li>
                ))}
              </ul>

              {/* Social Links */}
              <div className="mt-8">
                <h5 className="text-white font-medium mb-4">Follow Our Journey</h5>
                <div className="flex gap-3">
                  {socialLinks.map((social) => (
                    <a
                      key={social.name}
                      href={social.href}
                      className={`p-3 bg-gray-800/50 rounded-lg ${social.color} transition-all duration-300 transform hover:scale-110`}
                      title={social.name}
                    >
                      {social.icon}
                    </a>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="border-t border-gray-800/50">
          <div className="container mx-auto px-4 py-6">
            <div className="flex flex-col md:flex-row justify-between items-center gap-4">
              <div className="flex items-center gap-6 text-sm text-gray-400">
                <span>© {currentYear} SpaceGrow. All rights reserved.</span>
                <Link href="/privacy" className="hover:text-white transition-colors">Privacy Policy</Link>
                <Link href="/terms" className="hover:text-white transition-colors">Terms of Service</Link>
              </div>
              
              <div className="flex items-center gap-2 text-sm text-gray-400">
                <span>Made with</span>
                <Heart className="w-4 h-4 text-red-400 animate-pulse" />
                <span>for growers everywhere</span>
                <Atom className="w-4 h-4 text-purple-400 animate-spin" style={{ animationDuration: '3s' }} />
              </div>
            </div>
          </div>
        </div>
      </div>
    </footer>
  );
}