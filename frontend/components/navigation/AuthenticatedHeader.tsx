// components/navigation/AuthenticatedHeader.tsx
'use client';

import { useState } from 'react';
import { useTheme } from '@/contexts/ThemeContext';
import { 
  Bars3Icon, 
  BellIcon, 
  MagnifyingGlassIcon,
  SunIcon,
  MoonIcon 
} from '@heroicons/react/24/outline';

interface AuthenticatedHeaderProps {
  toggleSidebar: () => void;
}

export function AuthenticatedHeader({ toggleSidebar }: AuthenticatedHeaderProps) {
  const { theme, toggleTheme } = useTheme();
  const [notifications] = useState(3); // Mock notification count

  return (
    <header className="bg-space-card border-b border-space-border backdrop-blur-lg">
      <div className="px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center py-4">
          
          {/* Left side - Mobile menu + Search */}
          <div className="flex items-center space-x-4">
            <button
              onClick={toggleSidebar}
              className="md:hidden p-2 rounded-lg text-cosmic-text-muted hover:bg-space-glass hover:text-cosmic-text transition-colors"
            >
              <Bars3Icon className="h-5 w-5" />
            </button>
            
            {/* Search */}
            <div className="hidden sm:block">
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <MagnifyingGlassIcon className="h-4 w-4 text-cosmic-text-light" />
                </div>
                <input
                  type="text"
                  placeholder="Search devices, sensors..."
                  className="
                    block w-full pl-10 pr-3 py-2 
                    bg-space-glass border border-space-border rounded-xl
                    text-cosmic-text placeholder-cosmic-text-light
                    focus:outline-none focus:ring-2 focus:ring-stellar-accent focus:border-transparent
                    transition-all duration-200
                  "
                />
              </div>
            </div>
          </div>

          {/* Right side - Actions */}
          <div className="flex items-center space-x-3">
            
            {/* Theme Toggle */}
            <button
              onClick={toggleTheme}
              className="
                p-2 rounded-xl bg-space-glass border border-space-border
                text-cosmic-text-muted hover:text-stellar-accent hover:bg-gradient-cosmic
                transition-all duration-200 group
              "
              title={`Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`}
            >
              {theme === 'dark' ? (
                <SunIcon className="h-5 w-5 group-hover:text-white transition-colors" />
              ) : (
                <MoonIcon className="h-5 w-5 group-hover:text-white transition-colors" />
              )}
            </button>

            {/* Notifications */}
            <button className="
              relative p-2 rounded-xl bg-space-glass border border-space-border
              text-cosmic-text-muted hover:text-stellar-accent hover:bg-gradient-cosmic
              transition-all duration-200 group
            ">
              <BellIcon className="h-5 w-5 group-hover:text-white transition-colors" />
              {notifications > 0 && (
                <span className="
                  absolute -top-1 -right-1 h-4 w-4 
                  bg-cosmic-pink text-white text-xs font-bold
                  rounded-full flex items-center justify-center
                  animate-pulse
                ">
                  {notifications}
                </span>
              )}
            </button>

            {/* Status Indicator */}
            <div className="hidden sm:flex items-center space-x-2 px-3 py-2 bg-space-glass rounded-xl border border-space-border">
              <div className="flex items-center space-x-2">
                <div className="h-2 w-2 bg-stellar-accent rounded-full animate-pulse"></div>
                <span className="text-xs text-cosmic-text-muted">
                  All Systems Online
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
}