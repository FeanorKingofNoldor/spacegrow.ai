// components/navigation/Sidebar.tsx
'use client';

import { useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { Button } from '@/components/ui/Button';
import { 
  Home,
  Settings,
  BarChart3,
  Zap,
  Users,
  BookOpen,
  HelpCircle,
  User,
  CreditCard,
  LogOut,
  ChevronLeft,
  ChevronRight,
  Shield,
  Crown,
  Receipt
} from 'lucide-react';
import Link from 'next/link';
import { useRouter, usePathname } from 'next/navigation';

interface SidebarProps {
  collapsed: boolean;
  onToggle: () => void;
}

export function Sidebar({ collapsed, onToggle }: SidebarProps) {
  const [profileDropdownOpen, setProfileDropdownOpen] = useState(false);
  const { user, logout } = useAuth();
  const router = useRouter();
  const pathname = usePathname();

  const handleLogout = () => {
    logout();
    router.push('/');
  };

  return (
    <aside className={`
      bg-space-glass backdrop-blur-md border-r border-space-border
      transition-all duration-300 ease-in-out
      ${collapsed ? 'w-16' : 'w-64'}
      flex flex-col h-full
    `}>
      {/* Sidebar Header */}
      <div className="flex items-center justify-between p-4 border-b border-space-border">
        {!collapsed && (
          <div className="flex items-center space-x-2">
            <div className="w-8 h-8 bg-gradient-cosmic rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-sm">SG</span>
            </div>
            <span className="font-bold text-cosmic-text">SpaceGrow.ai</span>
          </div>
        )}
        <Button
          variant="ghost"
          size="sm"
          onClick={onToggle}
          className="p-1.5 h-auto"
        >
          {collapsed ? <ChevronRight size={16} /> : <ChevronLeft size={16} />}
        </Button>
      </div>

      {/* Navigation Items */}
      <nav className="flex-1 p-2 space-y-1 overflow-y-auto">
        <SidebarItem
          href="/user/dashboard/system_dashboard"
          icon={Home}
          label="System Dashboard"
          collapsed={collapsed}
          active={pathname === '/user/dashboard/system_dashboard'}
        />
        <SidebarItem
          href="/user/dashboard/device_dashboard"
          icon={Settings}
          label="Device Dashboard"
          collapsed={collapsed}
          active={pathname === '/user/dashboard/device_dashboard'}
        />
        
        {/* Separator */}
        <div className="my-3 border-t border-space-border opacity-30" />
        
        <SidebarItem
          href="/user/devices"
          icon={Settings}
          label="My Devices"
          collapsed={collapsed}
          active={pathname.startsWith('/user/devices')}
        />
        <SidebarItem
          href="/user/analytics"
          icon={BarChart3}
          label="Analytics & Reports"
          collapsed={collapsed}
          active={pathname.startsWith('/user/analytics')}
        />
        <SidebarItem
          href="/user/automation"
          icon={Zap}
          label="Automation Rules"
          collapsed={collapsed}
          active={pathname.startsWith('/user/automation')}
        />
        
        {/* ✅ NEW: Subscription Section */}
        <div className="my-3 border-t border-space-border opacity-30" />
        
        <SidebarItem
          href="/user/subscription"
          icon={Crown}
          label="Subscription"
          collapsed={collapsed}
          active={pathname.startsWith('/user/subscription')}
        />
        <SidebarItem
          href="/user/billing"
          icon={Receipt}
          label="Billing"
          collapsed={collapsed}
          active={pathname.startsWith('/user/billing')}
        />
        
        {/* Separator */}
        <div className="my-3 border-t border-space-border opacity-30" />
        
        <SidebarItem
          href="/user/profile"
          icon={User}
          label="Profile"
          collapsed={collapsed}
          active={pathname.startsWith('/user/profile')}
        />
        
        {/* External Links */}
        <SidebarItem
          href="/community"
          icon={Users}
          label="Community"
          collapsed={collapsed}
          active={pathname.startsWith('/community')}
        />
        <SidebarItem
          href="/docs"
          icon={BookOpen}
          label="Documentation"
          collapsed={collapsed}
          active={pathname.startsWith('/docs')}
        />
        <SidebarItem
          href="/support"
          icon={HelpCircle}
          label="Support & Help"
          collapsed={collapsed}
          active={pathname.startsWith('/support')}
        />
        
        {/* Admin Section - Only show for admins */}
        {user?.role === 'admin' && (
          <>
            <div className="my-3 border-t border-stellar-accent/30 opacity-50" />
            <SidebarItem
              href="/admin/dashboard"
              icon={Shield}
              label="Admin Panel"
              collapsed={collapsed}
              active={pathname.startsWith('/admin')}
            />
          </>
        )}
      </nav>

      {/* Bottom Section - Profile & Logout */}
      <div className="border-t border-space-border p-2 space-y-1">
        {/* Profile Dropdown */}
        <div className="relative">
          <button
            onClick={() => setProfileDropdownOpen(!profileDropdownOpen)}
            className={`
              w-full flex items-center space-x-3 px-3 py-2 rounded-lg
              text-cosmic-text hover:bg-space-glass hover:text-stellar-accent
              transition-colors duration-200
              ${collapsed ? 'justify-center' : ''}
            `}
          >
            <User size={20} />
            {!collapsed && (
              <>
                <span className="flex-1 text-left text-sm">Profile</span>
                <span className="text-xs text-cosmic-text-muted">▼</span>
              </>
            )}
          </button>

          {/* Profile Dropdown Menu */}
          {profileDropdownOpen && !collapsed && (
            <div className="absolute bottom-full left-0 right-0 mb-1 bg-space-glass backdrop-blur-md border border-space-border rounded-lg shadow-lg">
              <Link 
                href="/user/profile"
                className="block px-3 py-2 text-sm text-cosmic-text hover:bg-space-glass hover:text-stellar-accent transition-colors"
                onClick={() => setProfileDropdownOpen(false)}
              >
                Edit Profile
              </Link>
              <Link 
                href="/user/subscription"
                className="block px-3 py-2 text-sm text-cosmic-text hover:bg-space-glass hover:text-stellar-accent transition-colors"
                onClick={() => setProfileDropdownOpen(false)}
              >
                <div className="flex items-center space-x-2">
                  <Crown size={16} />
                  <span>Subscription</span>
                </div>
              </Link>
              <Link 
                href="/user/billing"
                className="block px-3 py-2 text-sm text-cosmic-text hover:bg-space-glass hover:text-stellar-accent transition-colors"
                onClick={() => setProfileDropdownOpen(false)}
              >
                <div className="flex items-center space-x-2">
                  <CreditCard size={16} />
                  <span>Billing & Payments</span>
                </div>
              </Link>
            </div>
          )}
        </div>

        {/* Logout Button */}
        <button
          onClick={handleLogout}
          className={`
            w-full flex items-center space-x-3 px-3 py-2 rounded-lg
            text-red-400 hover:bg-red-500/10 hover:text-red-300
            transition-colors duration-200
            ${collapsed ? 'justify-center' : ''}
          `}
        >
          <LogOut size={20} />
          {!collapsed && <span className="text-sm">Logout</span>}
        </button>
      </div>
    </aside>
  );
}

// Sidebar Item Component
interface SidebarItemProps {
  href: string;
  icon: React.ComponentType<{ size?: number; className?: string }>;
  label: string;
  collapsed: boolean;
  active?: boolean;
}

function SidebarItem({ href, icon: Icon, label, collapsed, active = false }: SidebarItemProps) {
  return (
    <Link
      href={href}
      className={`
        flex items-center space-x-3 px-3 py-2 rounded-lg transition-colors duration-200
        ${active 
          ? 'bg-stellar-accent/10 text-stellar-accent border border-stellar-accent/20' 
          : 'text-cosmic-text hover:bg-space-glass hover:text-stellar-accent'
        }
        ${collapsed ? 'justify-center' : ''}
      `}
      title={collapsed ? label : undefined}
    >
      <Icon size={20} />
      {!collapsed && <span className="text-sm font-medium">{label}</span>}
    </Link>
  );
}