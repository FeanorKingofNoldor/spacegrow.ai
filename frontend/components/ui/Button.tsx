// components/ui/Button.tsx
'use client';

import { forwardRef, ButtonHTMLAttributes } from 'react';
import { cn } from '@/lib/utils';

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'cosmic' | 'outline' | 'ghost' | 'glass' | 'stellar';
  size?: 'sm' | 'md' | 'lg' | 'xl';
  children: React.ReactNode;
}

const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'cosmic', size = 'md', children, disabled, ...props }, ref) => {
    return (
      <button
        className={cn(
          // Base styles
          'inline-flex items-center justify-center rounded-lg font-semibold transition-all duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-yellow-400 disabled:pointer-events-none disabled:opacity-50',
          
          // Variants
          {
            // Cosmic gradient button (primary)
            'cosmic': 'bg-gradient-cosmic border border-yellow-400/30 text-white shadow-lg hover:scale-105 animate-nebula-glow hover:border-yellow-400/50',
            
            // Outline button
            'outline': 'border border-white/40 bg-transparent text-white hover:bg-white/10 hover:text-yellow-400 hover:border-yellow-400',
            
            // Ghost button
            'ghost': 'border border-transparent bg-transparent text-gray-300 hover:bg-white/10 hover:text-white hover:border-white/30',
            
            // Glass button
            'glass': 'bg-white/10 backdrop-blur-sm border border-white/30 text-white hover:text-yellow-400 hover:bg-white/20 hover:border-yellow-400/50',
            
            // Stellar accent button
            'stellar': 'bg-yellow-500 border border-yellow-600 text-black hover:bg-yellow-400 shadow-md hover:border-yellow-500'
          }[variant],
          
          // Sizes
          {
            'sm': 'h-8 px-3 text-xs',
            'md': 'h-10 px-4 text-sm',
            'lg': 'h-12 px-6 text-base',
            'xl': 'h-14 px-8 text-lg'
          }[size],
          
          className
        )}
        ref={ref}
        disabled={disabled}
        {...props}
      >
        {children}
      </button>
    );
  }
);

Button.displayName = 'Button';

export { Button };