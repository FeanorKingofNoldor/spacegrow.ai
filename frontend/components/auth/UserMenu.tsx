// components/auth/UserMenu.tsx
'use client';

import { useState, useRef, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { 
  User, 
  Settings, 
  LogOut, 
  ChevronDown,
  Crown,
  Shield,
  CreditCard,
  HelpCircle
} from 'lucide-react';

export function UserMenu() {
  const [isOpen, setIsOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);
  const { user, logout } = useAuth();
  const router = useRouter();

  // Close menu when clicking outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleLogout = async () => {
    await logout();
    router.push('/');
    setIsOpen(false);
  };

  if (!user) return null;

  const menuItems = [
    {
      label: 'Profile',
      href: '/dashboard/profile',
      icon: User,
      description: 'Manage your account'
    },
    {
      label: 'Subscription',
      href: '/dashboard/subscriptions',
      icon: CreditCard,
      description: 'Billing & plans'
    },
    {
      label: 'Support',
      href: '/dashboard/support',
      icon: HelpCircle,
      description: 'Get help'
    }
  ];

  return (
    <div className="relative" ref={menuRef}>
      {/* User Avatar Button */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="
          flex items-center space-x-2 p-2 rounded-lg
          bg-white/10 backdrop-blur-sm border border-white/20
          hover:bg-white/20 transition-all duration-200
          focus:outline-none focus:ring-2 focus:ring-yellow-400
        "
      >
        {/* Avatar */}
        <div className="w-8 h-8 bg-gradient-cosmic rounded-full flex items-center justify-center relative">
          <span className="text-white text-sm font-bold">
            {user.email.charAt(0).toUpperCase()}
          </span>
          
          {/* Role indicator */}
          {user.role === 'admin' && (
            <Shield className="absolute -top-1 -right-1 w-3 h-3 text-red-400 bg-gray-900 rounded-full p-0.5" />
          )}
          {user.role === 'pro' && (
            <Crown className="absolute -top-1 -right-1 w-3 h-3 text-yellow-400 bg-gray-900 rounded-full p-0.5" />
          )}
        </div>

        {/* User Info */}
        <div className="hidden sm:block text-left">
          <p className="text-white text-sm font-medium">
            {user.email.split('@')[0]}
          </p>
          <p className="text-gray-400 text-xs capitalize">
            {user.role}
          </p>
        </div>

        {/* Chevron */}
        <ChevronDown className={`
          w-4 h-4 text-gray-400 transition-transform duration-200
          ${isOpen ? 'rotate-180' : ''}
        `} />
      </button>

      {/* Dropdown Menu */}
      {isOpen && (
        <div className="
          absolute right-0 mt-2 w-64 
          bg-white/10 backdrop-blur-lg border border-white/20 
          rounded-2xl shadow-2xl z-50
        ">
          {/* User Header */}
          <div className="p-4 border-b border-white/10">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-gradient-cosmic rounded-full flex items-center justify-center">
                <span className="text-white font-bold">
                  {user.email.charAt(0).toUpperCase()}
                </span>
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-white font-medium truncate">
                  {user.email}
                </p>
                <div className="flex items-center space-x-2">
                  <span className={`
                    px-2 py-1 text-xs font-medium rounded-full
                    ${user.role === 'admin' ? 'bg-red-500/20 text-red-300' : 
                      user.role === 'pro' ? 'bg-yellow-500/20 text-yellow-300' : 
                      'bg-blue-500/20 text-blue-300'}
                  `}>
                    {user.role.toUpperCase()}
                  </span>
                  <span className="text-gray-400 text-xs">
                    {user.devices_count} devices
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* Menu Items */}
          <div className="p-2">
            {menuItems.map((item) => (
              <Link
                key={item.label}
                href={item.href}
                onClick={() => setIsOpen(false)}
                className="
                  flex items-center space-x-3 p-3 rounded-lg
                  text-gray-300 hover:text-white hover:bg-white/10
                  transition-all duration-200 group
                "
              >
                <item.icon className="w-5 h-5 text-gray-400 group-hover:text-yellow-400" />
                <div>
                  <p className="text-sm font-medium">{item.label}</p>
                  <p className="text-xs text-gray-400">{item.description}</p>
                </div>
              </Link>
            ))}

            {/* Logout */}
            <button
              onClick={handleLogout}
              className="
                w-full flex items-center space-x-3 p-3 rounded-lg
                text-gray-300 hover:text-red-400 hover:bg-red-500/10
                transition-all duration-200 group
              "
            >
              <LogOut className="w-5 h-5 text-gray-400 group-hover:text-red-400" />
              <div className="text-left">
                <p className="text-sm font-medium">Sign Out</p>
                <p className="text-xs text-gray-400">Logout from your account</p>
              </div>
            </button>
          </div>

          {/* Upgrade Prompt (for non-pro users) */}
          {user.role === 'user' && (
            <div className="p-4 border-t border-white/10">
              <Link
                href="/dashboard/subscriptions"
                onClick={() => setIsOpen(false)}
                className="
                  block p-3 rounded-lg bg-gradient-cosmic
                  text-center hover:scale-105 transition-transform duration-200
                "
              >
                <div className="flex items-center justify-center space-x-2">
                  <Crown className="w-4 h-4" />
                  <span className="text-sm font-medium text-white">
                    Upgrade to Pro
                  </span>
                </div>
                <p className="text-xs text-white/80 mt-1">
                  More devices & advanced features
                </p>
              </Link>
            </div>
          )}
        </div>
      )}
    </div>
  );
}