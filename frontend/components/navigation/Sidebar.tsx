// components/navigation/Sidebar.tsx
'use client';

import { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { 
  HomeIcon, 
  CpuChipIcon, 
  ChartBarIcon, 
  CogIcon,
  BuildingStorefrontIcon,
  UserIcon
} from '@heroicons/react/24/outline';

const navigation = [
  { name: 'Dashboard', href: '/dashboard', icon: HomeIcon },
  { name: 'Devices', href: '/devices', icon: CpuChipIcon },
  { name: 'Analytics', href: '/analytics', icon: ChartBarIcon },
  { name: 'Settings', href: '/settings', icon: CogIcon },
  { name: 'Shop', href: '/shop', icon: BuildingStorefrontIcon },
  { name: 'Profile', href: '/profile', icon: UserIcon },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <div className="hidden md:flex md:w-64 md:flex-col">
      <div className="flex flex-col flex-grow pt-5 bg-space-secondary border-r border-space-border overflow-y-auto">
        <div className="flex items-center flex-shrink-0 px-4">
          <div className="text-xl font-bold text-gradient-cosmic">
            SpaceGrow.ai
          </div>
        </div>
        
        <div className="mt-8 flex-grow flex flex-col">
          <nav className="flex-1 px-2 pb-4 space-y-1">
            {navigation.map((item) => {
              const isActive = pathname === item.href;
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  className={`
                    group flex items-center px-3 py-2 text-sm font-medium rounded-xl transition-all duration-200
                    ${isActive 
                      ? 'bg-gradient-cosmic text-white shadow-lg animate-nebula-glow' 
                      : 'text-cosmic-text-muted hover:bg-space-glass hover:text-cosmic-text'
                    }
                  `}
                >
                  <item.icon
                    className={`
                      mr-3 flex-shrink-0 h-5 w-5 transition-colors
                      ${isActive ? 'text-white' : 'text-cosmic-text-light group-hover:text-stellar-accent'}
                    `}
                  />
                  {item.name}
                </Link>
              );
            })}
          </nav>
        </div>

        {/* User section at bottom */}
        <div className="flex-shrink-0 px-4 py-4 border-t border-space-border">
          <div className="bg-space-glass rounded-xl p-3 animate-drift">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="h-8 w-8 rounded-full bg-gradient-cosmic flex items-center justify-center">
                  <UserIcon className="h-5 w-5 text-white" />
                </div>
              </div>
              <div className="ml-3">
                <p className="text-sm font-medium text-cosmic-text">
                  User Name
                </p>
                <p className="text-xs text-cosmic-text-light">
                  user@example.com
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}