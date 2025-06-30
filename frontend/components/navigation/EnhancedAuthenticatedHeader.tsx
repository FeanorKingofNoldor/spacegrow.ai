// components/navigation/EnhancedAuthenticatedHeader.tsx
'use client';

import { useAuth } from '@/contexts/AuthContext';
import Link from 'next/link';

interface EnhancedAuthenticatedHeaderProps {
  sidebarCollapsed: boolean;
}

export function EnhancedAuthenticatedHeader({ sidebarCollapsed }: EnhancedAuthenticatedHeaderProps) {
  const { user } = useAuth();

  return (
    <header className="bg-space-glass backdrop-blur-md border-b border-space-border px-6 py-4">
      <div className="flex items-center justify-between">
        {/* Left - Logo (only show if sidebar is collapsed) */}
        {sidebarCollapsed && (
          <div className="flex items-center space-x-2">
            <div className="w-8 h-8 bg-gradient-cosmic rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-sm">SG</span>
            </div>
            <span className="font-bold text-cosmic-text">SpaceGrow.ai</span>
          </div>
        )}

        {/* Center - Core Navigation */}
        <nav className="flex items-center space-x-6">
          <Link 
            href="/shop"
            className="text-cosmic-text hover:text-stellar-accent transition-colors font-medium"
          >
            Shop
          </Link>
          <Link 
            href="/forum"
            className="text-cosmic-text hover:text-stellar-accent transition-colors font-medium"
          >
            Forum
          </Link>
          <Link 
            href="/system"
            className="text-cosmic-text hover:text-stellar-accent transition-colors font-medium"
          >
            System
          </Link>
          <Link 
            href="/dashboard"
            className="text-stellar-accent font-medium"
          >
            Dashboard
          </Link>
        </nav>

        {/* Right - User Avatar */}
        <div className="flex items-center space-x-3">

          
          <div className="w-8 h-8 bg-gradient-cosmic rounded-full flex items-center justify-center">
            <span className="text-white text-sm font-medium">
              {user?.email?.[0]?.toUpperCase() || 'U'}
            </span>
          </div>
        </div>
      </div>
    </header>
  );
}