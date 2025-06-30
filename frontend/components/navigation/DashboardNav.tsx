// components/navigation/DashboardNav.tsx
'use client';

import { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { 
  LayoutDashboard,
  Cpu,
  Settings,
  CreditCard,
  User,
  BookOpen,
  HelpCircle,
  Home,
  ChevronLeft,
  ChevronRight,
  Crown,
  Shield
} from 'lucide-react';

const navigationItems = [
  {
    name: 'Overview',
    href: '/dashboard',
    icon: LayoutDashboard,
    roles: ['user', 'pro', 'admin']
  },
  {
    name: 'Devices',
    href: '/dashboard/devices',
    icon: Cpu,
    roles: ['user', 'pro', 'admin']
  },
  {
    name: 'Subscription',
    href: '/dashboard/subscriptions',
    icon: CreditCard,
    roles: ['user', 'pro', 'admin']
  },
  {
    name: 'Profile',
    href: '/dashboard/profile',
    icon: User,
    roles: ['user', 'pro', 'admin']
  },
  {
    name: 'Documentation',
    href: '/dashboard/docs',
    icon: BookOpen,
    roles: ['user', 'pro', 'admin']
  },
  {
    name: 'Support',
    href: '/dashboard/support',
    icon: HelpCircle,
    roles: ['user', 'pro', 'admin']
  },
  // Admin only
  {
    name: 'Admin Dashboard',
    href: '/admin/dashboard',
    icon: Shield,
    roles: ['admin']
  }
];

export function DashboardNav() {
  const [collapsed, setCollapsed] = useState(false);
  const pathname = usePathname();
  const { user } = useAuth();

  const filteredItems = navigationItems.filter(item => 
    user && item.roles.includes(user.role)
  );

  return (
    <aside className={`
      ${collapsed ? 'w-16' : 'w-64'} 
      bg-white/5 backdrop-blur-sm border-r border-white/20 
      transition-all duration-300 ease-in-out
      flex flex-col h-[calc(100vh-73px)] sticky top-[73px]
    `}>
      
      {/* Collapse Toggle */}
      <div className="p-4 border-b border-white/10">
        <button
          onClick={() => setCollapsed(!collapsed)}
          className="w-full flex items-center justify-center p-2 rounded-lg bg-white/10 hover:bg-white/20 transition-colors"
        >
          {collapsed ? (
            <ChevronRight className="w-5 h-5 text-white" />
          ) : (
            <ChevronLeft className="w-5 h-5 text-white" />
          )}
        </button>
      </div>

      {/* Navigation Items */}
      <nav className="flex-1 p-4 space-y-2">
        {/* Back to Site */}
        <Link
          href="/"
          className={`
            flex items-center space-x-3 px-3 py-2 rounded-lg
            text-gray-400 hover:text-white hover:bg-white/10
            transition-all duration-200 group
            ${collapsed ? 'justify-center' : ''}
          `}
        >
          <Home className="w-5 h-5" />
          {!collapsed && <span className="text-sm">Back to Site</span>}
        </Link>

        <div className="h-px bg-white/10 my-4" />

        {/* Main Navigation */}
        {filteredItems.map((item) => {
          const isActive = pathname === item.href || 
            (item.href !== '/dashboard' && pathname.startsWith(item.href));
          
          return (
            <Link
              key={item.name}
              href={item.href}
              className={`
                flex items-center space-x-3 px-3 py-2 rounded-lg
                transition-all duration-200 group relative
                ${collapsed ? 'justify-center' : ''}
                ${isActive 
                  ? 'bg-yellow-500/20 text-yellow-400 border border-yellow-500/30' 
                  : 'text-gray-300 hover:text-white hover:bg-white/10'
                }
              `}
            >
              <item.icon className={`w-5 h-5 ${isActive ? 'text-yellow-400' : ''}`} />
              
              {!collapsed && (
                <span className="text-sm font-medium">{item.name}</span>
              )}
              
              {/* Role indicators */}
              {!collapsed && item.roles.includes('admin') && user?.role === 'admin' && (
                <Shield className="w-3 h-3 text-red-400 ml-auto" />
              )}
              {!collapsed && item.roles.includes('pro') && user?.role === 'pro' && (
                <Crown className="w-3 h-3 text-yellow-400 ml-auto" />
              )}

              {/* Tooltip for collapsed state */}
              {collapsed && (
                <div className="
                  absolute left-full ml-2 px-2 py-1 bg-white/10 backdrop-blur-sm 
                  text-white text-xs rounded border border-white/20
                  opacity-0 group-hover:opacity-100 transition-opacity
                  pointer-events-none whitespace-nowrap z-50
                ">
                  {item.name}
                </div>
              )}
            </Link>
          );
        })}
      </nav>

      {/* User Info (when expanded) */}
      {!collapsed && user && (
        <div className="p-4 border-t border-white/10">
          <div className="flex items-center space-x-3 p-3 rounded-lg bg-white/5">
            <div className="w-8 h-8 bg-gradient-cosmic rounded-full flex items-center justify-center">
              <span className="text-white text-sm font-bold">
                {user.email.charAt(0).toUpperCase()}
              </span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-white text-sm font-medium truncate">
                {user.email}
              </p>
              <p className="text-gray-400 text-xs">
                {user.devices_count} device{user.devices_count !== 1 ? 's' : ''}
              </p>
            </div>
          </div>
        </div>
      )}
    </aside>
  );
}