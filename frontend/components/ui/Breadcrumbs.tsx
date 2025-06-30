// components/navigation/Breadcrumbs.tsx
'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { ChevronRight, Home } from 'lucide-react';
import { cn } from '@/lib/utils';

export interface BreadcrumbItem {
  label: string;
  href?: string;
  icon?: React.ReactNode;
}

export interface BreadcrumbsProps {
  items?: BreadcrumbItem[];
  separator?: React.ReactNode;
  showHome?: boolean;
  homeHref?: string;
  className?: string;
}

// Default path mappings for auto-generation
const pathMappings: Record<string, string> = {
  dashboard: 'Dashboard',
  devices: 'Devices',
  subscriptions: 'Subscriptions',
  profile: 'Profile',
  settings: 'Settings',
  admin: 'Admin',
  shop: 'Shop',
  cart: 'Cart',
  checkout: 'Checkout',
  orders: 'Orders',
  onboarding: 'Onboarding',
  docs: 'Documentation',
  support: 'Support',
  about: 'About',
  features: 'Features',
  pricing: 'Pricing'
};

export function Breadcrumbs({
  items,
  separator = <ChevronRight className="w-4 h-4 text-gray-400" />,
  showHome = true,
  homeHref = '/',
  className
}: BreadcrumbsProps) {
  const pathname = usePathname();

  // Auto-generate breadcrumbs if not provided
  const breadcrumbItems = items || generateBreadcrumbs(pathname);

  // Don't show breadcrumbs on home page
  if (pathname === '/' || breadcrumbItems.length === 0) {
    return null;
  }

  return (
    <nav 
      aria-label="Breadcrumb"
      className={cn('flex items-center space-x-2 text-sm', className)}
    >
      {/* Home Link */}
      {showHome && (
        <>
          <Link
            href={homeHref}
            className="flex items-center text-gray-400 hover:text-white transition-colors"
          >
            <Home className="w-4 h-4" />
            <span className="sr-only">Home</span>
          </Link>
          {breadcrumbItems.length > 0 && (
            <span className="flex-shrink-0">{separator}</span>
          )}
        </>
      )}

      {/* Breadcrumb Items */}
      {breadcrumbItems.map((item, index) => {
        const isLast = index === breadcrumbItems.length - 1;

        return (
          <div key={index} className="flex items-center space-x-2">
            {item.href && !isLast ? (
              <Link
                href={item.href}
                className="flex items-center space-x-1 text-gray-400 hover:text-white transition-colors"
              >
                {item.icon && <span className="flex-shrink-0">{item.icon}</span>}
                <span className="truncate max-w-[150px]">{item.label}</span>
              </Link>
            ) : (
              <span
                className={cn(
                  'flex items-center space-x-1 truncate max-w-[150px]',
                  isLast ? 'text-white font-medium' : 'text-gray-400'
                )}
                aria-current={isLast ? 'page' : undefined}
              >
                {item.icon && <span className="flex-shrink-0">{item.icon}</span>}
                <span>{item.label}</span>
              </span>
            )}

            {!isLast && (
              <span className="flex-shrink-0">{separator}</span>
            )}
          </div>
        );
      })}
    </nav>
  );
}

// Generate breadcrumbs from pathname
function generateBreadcrumbs(pathname: string): BreadcrumbItem[] {
  // Remove leading/trailing slashes and split
  const segments = pathname.replace(/^\/+|\/+$/g, '').split('/').filter(Boolean);
  
  if (segments.length === 0) return [];

  const breadcrumbs: BreadcrumbItem[] = [];
  let currentPath = '';

  segments.forEach((segment, index) => {
    currentPath += `/${segment}`;
    
    // Skip dynamic segments like [id]
    if (segment.startsWith('[') && segment.endsWith(']')) {
      return;
    }

    // Get label from mapping or format segment
    const label = pathMappings[segment] || formatSegment(segment);
    
    // Don't include href for last item (current page)
    const isLast = index === segments.length - 1;
    
    breadcrumbs.push({
      label,
      href: isLast ? undefined : currentPath
    });
  });

  return breadcrumbs;
}

// Format segment for display
function formatSegment(segment: string): string {
  return segment
    .split('-')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

// Specialized breadcrumb variants
export function DashboardBreadcrumbs({ className }: { className?: string }) {
  const pathname = usePathname();
  
  // Custom items for dashboard
  const items = generateBreadcrumbs(pathname);
  
  return (
    <Breadcrumbs 
      items={items}
      homeHref="/dashboard"
      className={className}
    />
  );
}

export function ShopBreadcrumbs({ className }: { className?: string }) {
  const pathname = usePathname();
  
  // Custom items for shop
  const items = generateBreadcrumbs(pathname);
  
  return (
    <Breadcrumbs 
      items={items}
      homeHref="/shop"
      className={className}
    />
  );
}