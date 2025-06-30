// app/not-found.tsx
'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { CosmicButton, GhostButton } from '@/components/ui/ButtonVariants';
import { Home, ArrowLeft, Search, Compass } from 'lucide-react';

export default function NotFound() {
  const router = useRouter();

  const suggestions = [
    { label: 'Home', href: '/', icon: Home },
    { label: 'Shop', href: '/shop', icon: Search },
    { label: 'Dashboard', href: '/dashboard', icon: Compass },
    { label: 'About', href: '/about', icon: null }
  ];

  return (
    <div className="min-h-screen flex items-center justify-center px-4 bg-transparent">
      <div className="relative max-w-2xl w-full mx-auto text-center">
        {/* Floating container */}
        <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-8 md:p-12 shadow-2xl">
          
          {/* 404 Animation */}
          <div className="mb-8">
            <div className="relative inline-block">
              <h1 className="text-8xl md:text-9xl font-bold text-transparent bg-gradient-to-r from-yellow-400 via-pink-500 to-purple-600 bg-clip-text animate-pulse">
                404
              </h1>
              {/* Floating elements around 404 */}
              <div className="absolute -top-4 -right-4 w-6 h-6 bg-yellow-400/30 rounded-full animate-bounce"></div>
              <div className="absolute -bottom-2 -left-6 w-4 h-4 bg-pink-500/30 rounded-full animate-bounce" style={{ animationDelay: '0.5s' }}></div>
              <div className="absolute top-1/2 -right-8 w-3 h-3 bg-purple-600/30 rounded-full animate-bounce" style={{ animationDelay: '1s' }}></div>
            </div>
          </div>

          {/* Error Message */}
          <div className="mb-8">
            <h2 className="text-2xl md:text-3xl font-bold text-white mb-4">
              Lost in the Cosmos?
            </h2>
            <p className="text-lg text-gray-300 mb-2">
              The page you're looking for has drifted into deep space.
            </p>
            <p className="text-gray-400">
              Don't worry, our navigation systems will help you find your way back.
            </p>
          </div>

          {/* Primary Actions */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center mb-8">
            <GhostButton 
              onClick={() => router.back()}
              className="flex items-center justify-center space-x-2"
            >
              <ArrowLeft className="w-4 h-4" />
              <span>Go Back</span>
            </GhostButton>
            
            <Link href="/">
              <CosmicButton className="flex items-center justify-center space-x-2 w-full sm:w-auto">
                <Home className="w-4 h-4" />
                <span>Return Home</span>
              </CosmicButton>
            </Link>
          </div>

          {/* Suggestions */}
          <div className="border-t border-white/10 pt-8">
            <h3 className="text-lg font-semibold text-white mb-4">
              Popular Destinations
            </h3>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
              {suggestions.map((suggestion) => (
                <Link
                  key={suggestion.href}
                  href={suggestion.href}
                  className="
                    flex flex-col items-center p-4 rounded-lg
                    bg-white/5 border border-white/10
                    hover:bg-white/10 hover:border-white/20
                    transition-all duration-200 group
                  "
                >
                  {suggestion.icon && (
                    <suggestion.icon className="w-5 h-5 text-gray-400 group-hover:text-yellow-400 mb-2 transition-colors" />
                  )}
                  <span className="text-sm text-gray-300 group-hover:text-white transition-colors">
                    {suggestion.label}
                  </span>
                </Link>
              ))}
            </div>
          </div>

          {/* Search Suggestion */}
          <div className="mt-8 p-4 bg-white/5 border border-white/10 rounded-lg">
            <p className="text-sm text-gray-400">
              Looking for something specific?{' '}
              <Link href="/shop" className="text-yellow-400 hover:text-yellow-300 transition-colors">
                Try our shop
              </Link>
              {' '}or{' '}
              <Link href="/support" className="text-yellow-400 hover:text-yellow-300 transition-colors">
                contact support
              </Link>
            </p>
          </div>
        </div>

        {/* Floating decoration elements */}
        <div className="absolute -top-6 -left-6 w-12 h-12 bg-gradient-to-br from-yellow-400/20 to-orange-500/20 rounded-full blur-lg animate-slow-float"></div>
        <div className="absolute -bottom-6 -right-6 w-8 h-8 bg-gradient-to-br from-pink-500/20 to-purple-600/20 rounded-full blur-lg animate-slow-float-reverse"></div>
        <div className="absolute top-1/4 -right-12 w-6 h-6 bg-gradient-to-br from-blue-400/30 to-cyan-500/30 rounded-full blur-lg animate-slow-float" style={{ animationDelay: '2s' }}></div>
        <div className="absolute bottom-1/4 -left-12 w-10 h-10 bg-gradient-to-br from-purple-400/20 to-indigo-500/20 rounded-full blur-lg animate-slow-float-reverse" style={{ animationDelay: '3s' }}></div>
      </div>
    </div>
  );
}