// components/navigation/Header.tsx
'use client';

import { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { 
  Bars3Icon, 
  XMarkIcon,
  UserIcon,
  Cog6ToothIcon,
  ArrowRightOnRectangleIcon,
  SunIcon,
  MoonIcon,
  ComputerDesktopIcon
} from '@heroicons/react/24/outline';
import { GlassButton, NavButton, CosmicButton } from '@/components/ui/ButtonVariants';
import { Modal } from '@/components/ui/Modal';
import { LoginForm } from '@/components/auth/LoginForm';

const navigation = [
  { name: 'Products', href: '/shop' },
  { name: 'Features', href: '/features' },
  { name: 'Pricing', href: '/pricing' },
  { name: 'About', href: '/about' },
];

export function Header() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [showLoginModal, setShowLoginModal] = useState(false);
  const [showUserMenu, setShowUserMenu] = useState(false);
  const pathname = usePathname();
  const { user, logout } = useAuth();


  const handleLoginSuccess = () => {
    setShowLoginModal(false);
    // Redirect to dashboard after successful login
    window.location.href = '/user/dashboard/system_dashboard';
  };

  const handleLogout = () => {
    logout();
    setShowUserMenu(false);
    setMobileMenuOpen(false);
  };

  return (
    <>
      <header className="bg-white/10 backdrop-blur-lg border-b border-white/20 sticky top-0 z-50">
        <nav className="mx-auto flex max-w-7xl items-center justify-between p-6 lg:px-8">
          
          {/* Logo */}
          <div className="flex lg:flex-1">
            <Link href="/" className="-m-1.5 p-1.5">
              <span className="text-2xl font-bold text-gradient-cosmic">
                SpaceGrow.ai
              </span>
            </Link>
          </div>

          {/* Mobile menu button */}
          <div className="flex lg:hidden">
            <GlassButton
              onClick={() => setMobileMenuOpen(true)}
              className="h-10 w-10"
            >
              <Bars3Icon aria-hidden="true" className="h-6 w-6" />
            </GlassButton>
          </div>

          {/* Desktop navigation */}
          <div className="hidden lg:flex lg:gap-x-2">
            {navigation.map((item) => {
              const isActive = pathname === item.href;
              return (
                <Link key={item.name} href={item.href}>
                  <NavButton
                    className={`
                      ${isActive 
                        ? 'text-yellow-400 bg-white/20 border border-white/30' 
                        : 'text-white'
                      }
                    `}
                  >
                    {item.name}
                  </NavButton>
                </Link>
              );
            })}
            
            {/* Dashboard link for authenticated users */}
            {user && (
              <Link href="/user/dashboard/system_dashboard">
                <NavButton
                  className={`
                    ${pathname.startsWith('/user') 
                      ? 'text-yellow-400 bg-white/20 border border-white/30' 
                      : 'text-white'
                    }
                  `}
                >
                  Dashboard
                </NavButton>
              </Link>
            )}
          </div>

          {/* Right side actions */}
          <div className="hidden lg:flex lg:flex-1 lg:justify-end lg:items-center lg:gap-x-4">

            {user ? (
              /* Authenticated User Menu */
              <div className="relative">
                <button
                  onClick={() => setShowUserMenu(!showUserMenu)}
                  className="flex items-center space-x-2 text-white hover:text-yellow-400 transition-colors"
                >
                  <div className="w-8 h-8 bg-gradient-cosmic rounded-full flex items-center justify-center">
                    <span className="text-white text-sm font-medium">
                      {user.email[0].toUpperCase()}
                    </span>
                  </div>
                  <span className="text-sm">{user.email.split('@')[0]}</span>
                </button>

                {showUserMenu && (
                  <div className="absolute right-0 mt-2 w-56 bg-white/10 backdrop-blur-lg border border-white/20 rounded-lg shadow-lg py-2">
                    <div className="px-4 py-2 border-b border-white/20">
                      <p className="text-sm text-white font-medium">{user.email}</p>
                      <p className="text-xs text-gray-300 capitalize">{user.role} Account</p>
                    </div>
                    
                    <Link
                      href="/user/dashboard/system_dashboard"
                      className="flex items-center px-4 py-2 text-white hover:bg-white/20 transition-colors"
                      onClick={() => setShowUserMenu(false)}
                    >
                      <ComputerDesktopIcon className="h-4 w-4 mr-3" />
                      Dashboard
                    </Link>
                    
                    <Link
                      href="/user/profile"
                      className="flex items-center px-4 py-2 text-white hover:bg-white/20 transition-colors"
                      onClick={() => setShowUserMenu(false)}
                    >
                      <UserIcon className="h-4 w-4 mr-3" />
                      Profile Settings
                    </Link>
                    
                    {user.role === 'admin' && (
                      <Link
                        href="/admin/dashboard"
                        className="flex items-center px-4 py-2 text-yellow-400 hover:bg-white/20 transition-colors"
                        onClick={() => setShowUserMenu(false)}
                      >
                        <Cog6ToothIcon className="h-4 w-4 mr-3" />
                        Admin Panel
                      </Link>
                    )}
                    
                    <hr className="my-2 border-white/20" />
                    
                    <button
                      onClick={handleLogout}
                      className="flex items-center w-full px-4 py-2 text-red-400 hover:bg-red-500/20 transition-colors"
                    >
                      <ArrowRightOnRectangleIcon className="h-4 w-4 mr-3" />
                      Sign Out
                    </button>
                  </div>
                )}
              </div>
            ) : (
              /* Sign In Button */
              <CosmicButton 
                size="md"
                onClick={() => setShowLoginModal(true)}
              >
                Sign In
              </CosmicButton>
            )}
          </div>
        </nav>

        {/* Mobile menu */}
        {mobileMenuOpen && (
          <div className="lg:hidden">
            <div 
              className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm" 
              onClick={() => setMobileMenuOpen(false)} 
            />
            <div className="fixed inset-y-0 right-0 z-50 w-full overflow-y-auto bg-white/10 backdrop-blur-lg px-6 py-6 sm:max-w-sm border-l border-white/20">
              <div className="flex items-center justify-between">
                <Link href="/" className="-m-1.5 p-1.5">
                  <span className="text-xl font-bold text-gradient-cosmic">
                    SpaceGrow.ai
                  </span>
                </Link>
                <GlassButton
                  onClick={() => setMobileMenuOpen(false)}
                  className="h-10 w-10"
                >
                  <XMarkIcon aria-hidden="true" className="h-6 w-6" />
                </GlassButton>
              </div>
              
              <div className="mt-6 flow-root">
                <div className="-my-6 divide-y divide-white/20">
                  {/* Navigation Links */}
                  <div className="space-y-2 py-6">
                    {navigation.map((item) => {
                      const isActive = pathname === item.href;
                      return (
                        <Link
                          key={item.name}
                          href={item.href}
                          onClick={() => setMobileMenuOpen(false)}
                        >
                          <NavButton
                            className={`
                              w-full justify-start text-base
                              ${isActive 
                                ? 'text-yellow-400 bg-white/20 border border-white/30' 
                                : 'text-white'
                              }
                            `}
                          >
                            {item.name}
                          </NavButton>
                        </Link>
                      );
                    })}
                    
                    {/* Dashboard link for mobile */}
                    {user && (
                      <Link
                        href="/user/dashboard/system_dashboard"
                        onClick={() => setMobileMenuOpen(false)}
                      >
                        <NavButton
                          className={`
                            w-full justify-start text-base
                            ${pathname.startsWith('/user') 
                              ? 'text-yellow-400 bg-white/20 border border-white/30' 
                              : 'text-white'
                            }
                          `}
                        >
                          Dashboard
                        </NavButton>
                      </Link>
                    )}
                  </div>
                  
                  
                  {/* Auth Section Mobile */}
                  <div className="py-6">
                    {user ? (
                      <div className="space-y-3">
                        <div className="px-3 py-2 bg-white/10 rounded-lg">
                          <p className="text-sm text-white font-medium">{user.email}</p>
                          <p className="text-xs text-gray-300 capitalize">{user.role} Account</p>
                        </div>
                        
                        <Link
                          href="/user/profile"
                          onClick={() => setMobileMenuOpen(false)}
                        >
                          <NavButton className="w-full justify-start text-white">
                            <UserIcon className="h-4 w-4 mr-3" />
                            Profile Settings
                          </NavButton>
                        </Link>
                        
                        {user.role === 'admin' && (
                          <Link
                            href="/admin/dashboard"
                            onClick={() => setMobileMenuOpen(false)}
                          >
                            <NavButton className="w-full justify-start text-yellow-400">
                              <Cog6ToothIcon className="h-4 w-4 mr-3" />
                              Admin Panel
                            </NavButton>
                          </Link>
                        )}
                        
                        <button
                          onClick={handleLogout}
                          className="flex items-center w-full px-3 py-2 text-red-400 hover:bg-red-500/20 rounded-lg transition-colors"
                        >
                          <ArrowRightOnRectangleIcon className="h-4 w-4 mr-3" />
                          Sign Out
                        </button>
                      </div>
                    ) : (
                      <CosmicButton 
                        size="lg" 
                        className="w-full"
                        onClick={() => {
                          setMobileMenuOpen(false);
                          setShowLoginModal(true);
                        }}
                      >
                        Sign In
                      </CosmicButton>
                    )}
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}
      </header>

      {/* Login Modal */}
      <Modal
        isOpen={showLoginModal}
        onClose={() => setShowLoginModal(false)}
        title=""
        className="max-w-md"
      >
        <LoginForm
          onSuccess={handleLoginSuccess}
          onClose={() => setShowLoginModal(false)}
        />
      </Modal>
    </>
  );
}