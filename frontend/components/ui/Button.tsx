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
          'inline-flex items-center justify-center rounded-lg font-semibold transition-all duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-purple-500 disabled:pointer-events-none disabled:opacity-50',
          
          // Variants
          {
            // Cosmic gradient button (primary)
            'cosmic': 'bg-gradient-cosmic text-white shadow-lg hover:scale-105 animate-nebula-glow',
            
            // Outline button
            'outline': 'border border-gray-300 dark:border-gray-600 bg-transparent text-gray-900 dark:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-800 hover:text-purple-600 dark:hover:text-purple-400',
            
            // Ghost button
            'ghost': 'bg-transparent text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 hover:text-gray-900 dark:hover:text-gray-100',
            
            // Glass button
            'glass': 'bg-space-glass border border-space-border text-gray-900 dark:text-gray-100 hover:text-purple-600 dark:hover:text-purple-400 hover:bg-gradient-cosmic hover:text-white',
            
            // Stellar accent button
            'stellar': 'bg-purple-600 dark:bg-green-500 text-white hover:bg-purple-700 dark:hover:bg-green-600 shadow-md'
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