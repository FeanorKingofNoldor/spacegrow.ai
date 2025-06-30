// components/ui/Card.tsx
'use client';

import { forwardRef, HTMLAttributes } from 'react';
import { cn } from '@/lib/utils';

export interface CardProps extends HTMLAttributes<HTMLDivElement> {
  variant?: 'default' | 'glass' | 'solid' | 'highlight' | 'interactive';
  size?: 'sm' | 'md' | 'lg' | 'xl';
  hover?: boolean;
  glow?: boolean;
}

const Card = forwardRef<HTMLDivElement, CardProps>(
  ({ className, variant = 'default', size = 'md', hover = false, glow = false, children, ...props }, ref) => {
    const variants = {
      default: 'bg-white/10 backdrop-blur-sm border border-white/20',
      glass: 'bg-white/5 backdrop-blur-md border border-white/10',
      solid: 'bg-white/20 border border-white/30',
      highlight: 'bg-gradient-cosmic border border-yellow-400/30',
      interactive: 'bg-white/10 backdrop-blur-sm border border-white/20 hover:bg-white/15 hover:border-yellow-400/40 cursor-pointer'
    };

    const sizes = {
      sm: 'p-4 rounded-lg',
      md: 'p-6 rounded-xl', 
      lg: 'p-8 rounded-2xl',
      xl: 'p-10 rounded-3xl'
    };

    return (
      <div
        ref={ref}
        className={cn(
          'transition-all duration-200',
          variants[variant],
          sizes[size],
          hover && 'hover:scale-105 hover:shadow-2xl',
          glow && 'shadow-lg shadow-yellow-400/10',
          className
        )}
        {...props}
      >
        {children}
      </div>
    );
  }
);

Card.displayName = 'Card';

// Specialized Card Components
export const StatCard = forwardRef<HTMLDivElement, { 
  title: string; 
  value: string | number; 
  subtitle?: string;
  icon?: React.ReactNode;
  trend?: 'up' | 'down' | 'neutral';
  className?: string;
}>(({ title, value, subtitle, icon, trend, className }, ref) => (
  <Card ref={ref} variant="glass" hover glow className={cn('text-center', className)}>
    {icon && (
      <div className="flex justify-center mb-3">
        <div className="w-12 h-12 bg-yellow-500/20 rounded-full flex items-center justify-center">
          {icon}
        </div>
      </div>
    )}
    <h3 className="text-gray-300 text-sm font-medium mb-2">{title}</h3>
    <p className="text-white text-2xl font-bold mb-1">{value}</p>
    {subtitle && (
      <p className={cn(
        'text-xs font-medium',
        trend === 'up' ? 'text-green-400' :
        trend === 'down' ? 'text-red-400' :
        'text-gray-400'
      )}>
        {subtitle}
      </p>
    )}
  </Card>
));
StatCard.displayName = 'StatCard';

export const DeviceCard = forwardRef<HTMLDivElement, {
  name: string;
  status: 'active' | 'pending' | 'disabled';
  type?: string;
  lastConnection?: string;
  onClick?: () => void;
  className?: string;
}>(({ name, status, type, lastConnection, onClick, className }, ref) => {
  const statusColors = {
    active: 'text-green-400 bg-green-500/20',
    pending: 'text-yellow-400 bg-yellow-500/20', 
    disabled: 'text-red-400 bg-red-500/20'
  };

  return (
    <Card 
      ref={ref} 
      variant="interactive" 
      onClick={onClick}
      className={cn('space-y-4', className)}
    >
      <div className="flex items-start justify-between">
        <div>
          <h3 className="text-white font-semibold text-lg">{name}</h3>
          {type && <p className="text-gray-400 text-sm">{type}</p>}
        </div>
        <span className={cn(
          'px-2 py-1 text-xs font-medium rounded-full',
          statusColors[status]
        )}>
          {status}
        </span>
      </div>
      {lastConnection && (
        <p className="text-gray-400 text-sm">
          Last seen: {lastConnection}
        </p>
      )}
    </Card>
  );
});
DeviceCard.displayName = 'DeviceCard';

export { Card };