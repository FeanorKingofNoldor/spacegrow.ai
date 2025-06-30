// components/ui/ButtonVariants.tsx
'use client';

import { forwardRef } from 'react';
import { Button, ButtonProps } from './Button';
import { cn } from '@/lib/utils';

// Primary CTA Button
export const CosmicButton = forwardRef<HTMLButtonElement, Omit<ButtonProps, 'variant'>>(
  ({ className, ...props }, ref) => (
    <Button
      ref={ref}
      variant="cosmic"
      className={cn('shadow-lg hover:scale-105', className)}
      {...props}
    />
  )
);
CosmicButton.displayName = 'CosmicButton';

// Secondary Button
export const OutlineButton = forwardRef<HTMLButtonElement, Omit<ButtonProps, 'variant'>>(
  ({ className, ...props }, ref) => (
    <Button
      ref={ref}
      variant="outline"
      className={className}
      {...props}
    />
  )
);
OutlineButton.displayName = 'OutlineButton';

// Subtle Button
export const GhostButton = forwardRef<HTMLButtonElement, Omit<ButtonProps, 'variant'>>(
  ({ className, ...props }, ref) => (
    <Button
      ref={ref}
      variant="ghost"
      className={className}
      {...props}
    />
  )
);
GhostButton.displayName = 'GhostButton';

// Glass Effect Button
export const GlassButton = forwardRef<HTMLButtonElement, Omit<ButtonProps, 'variant'>>(
  ({ className, ...props }, ref) => (
    <Button
      ref={ref}
      variant="glass"
      className={cn('backdrop-blur-sm', className)}
      {...props}
    />
  )
);
GlassButton.displayName = 'GlassButton';

// Navigation Button
export const NavButton = forwardRef<HTMLButtonElement, Omit<ButtonProps, 'variant'>>(
  ({ className, ...props }, ref) => (
    <Button
      ref={ref}
      variant="ghost"
      className={cn('rounded-lg px-3 py-2', className)}
      {...props}
    />
  )
);
NavButton.displayName = 'NavButton';