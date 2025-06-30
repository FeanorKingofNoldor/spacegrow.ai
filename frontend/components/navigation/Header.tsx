// components/navigation/Header.tsx
'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useTheme } from '@/contexts/ThemeContext';
import { 
  Bars3Icon, 
  XMarkIcon,
  SunIcon,
  MoonIcon 
} from '@heroicons/react/24/outline';
import { ThemeButton, NavButton, CosmicButton } from '@/components/ui/ButtonVariants';

const navigation = [
  { name: 'Products', href: '/shop' },
  { name: 'Features', href: '/features' },
  { name: 'Pricing', href: '/pricing' },
  { name: 'About', href: '/about' },
];

export function Header() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [mounted, setMounted] = useState(false);
  const pathname = usePathname();

  // Always call useTheme (never conditionally!)
  const { theme: contextTheme, toggleTheme: contextToggleTheme } = useTheme();
  
  // Wait for client-side mounting
  useEffect(() => {
    setMounted(true);
  }, []);

  // Use context values only after mounting, fallback before
  const theme = mounted ? contextTheme : 'dark';
  const toggleTheme = mounted ? contextToggleTheme : (() => {});

  return (
    <header className="bg-space-card/80 backdrop-blur-lg border-b border-space-border sticky top-0 z-50">
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
          <ThemeButton
            onClick={() => setMobileMenuOpen(true)}
            className="h-10 w-10"
          >
            <Bars3Icon aria-hidden="true" className="h-6 w-6" />
          </ThemeButton>
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
                      ? 'text-stellar-accent bg-space-glass border border-space-border' 
                      : ''
                    }
                  `}
                >
                  {item.name}
                </NavButton>
              </Link>
            );
          })}
        </div>

        {/* Right side actions */}
        <div className="hidden lg:flex lg:flex-1 lg:justify-end lg:items-center lg:gap-x-4">
          
          {/* Theme Toggle */}
          <ThemeButton
            onClick={toggleTheme}
            title={`Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`}
            disabled={!mounted}
          >
            {theme === 'dark' ? (
              <SunIcon className="h-5 w-5" />
            ) : (
              <MoonIcon className="h-5 w-5" />
            )}
          </ThemeButton>

          {/* Sign In Button */}
          <Link href="/login">
            <CosmicButton size="md">
              Sign In
            </CosmicButton>
          </Link>
        </div>
      </nav>

      {/* Mobile menu */}
      {mobileMenuOpen && (
        <div className="lg:hidden">
          <div 
            className="fixed inset-0 z-50 bg-space-primary/80 backdrop-blur-sm" 
            onClick={() => setMobileMenuOpen(false)} 
          />
          <div className="fixed inset-y-0 right-0 z-50 w-full overflow-y-auto bg-space-card px-6 py-6 sm:max-w-sm border-l border-space-border">
            <div className="flex items-center justify-between">
              <Link href="/" className="-m-1.5 p-1.5">
                <span className="text-xl font-bold text-gradient-cosmic">
                  SpaceGrow.ai
                </span>
              </Link>
              <ThemeButton
                onClick={() => setMobileMenuOpen(false)}
                className="h-10 w-10"
              >
                <XMarkIcon aria-hidden="true" className="h-6 w-6" />
              </ThemeButton>
            </div>
            <div className="mt-6 flow-root">
              <div className="-my-6 divide-y divide-space-border">
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
                              ? 'text-stellar-accent bg-space-glass border border-space-border' 
                              : ''
                            }
                          `}
                        >
                          {item.name}
                        </NavButton>
                      </Link>
                    );
                  })}
                </div>
                <div className="py-6 space-y-4">
                  <ThemeButton
                    onClick={toggleTheme}
                    disabled={!mounted}
                    className="w-full h-12 flex items-center justify-center gap-2"
                  >
                    {theme === 'dark' ? (
                      <>
                        <SunIcon className="h-5 w-5" />
                        Light Mode
                      </>
                    ) : (
                      <>
                        <MoonIcon className="h-5 w-5" />
                        Dark Mode
                      </>
                    )}
                  </ThemeButton>
                  <Link
                    href="/login"
                    onClick={() => setMobileMenuOpen(false)}
                  >
                    <CosmicButton size="lg" className="w-full">
                      Sign In
                    </CosmicButton>
                  </Link>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </header>
  );
}