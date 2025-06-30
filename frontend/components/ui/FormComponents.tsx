// components/ui/FormComponents.tsx
'use client';

import { forwardRef, InputHTMLAttributes } from 'react';
import { cn } from '@/lib/utils';

// Checkbox Component
export interface CheckboxProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'type'> {
  label?: string;
  description?: string;
  error?: string;
  variant?: 'default' | 'card';
}

export const Checkbox = forwardRef<HTMLInputElement, CheckboxProps>(
  ({ className, label, description, error, variant = 'default', ...props }, ref) => {
    const id = props.id || `checkbox-${Math.random().toString(36).substr(2, 9)}`;

    return (
      <div className="space-y-2">
        <div className={cn(
          'flex items-start space-x-3',
          variant === 'card' && 'p-4 rounded-lg bg-white/5 border border-white/10 hover:bg-white/10 transition-colors'
        )}>
          <div className="relative flex items-center">
            <input
              type="checkbox"
              ref={ref}
              id={id}
              className="sr-only"
              {...props}
            />
            <div className={cn(
              'w-5 h-5 rounded border-2 transition-all duration-200 cursor-pointer',
              'border-white/30 bg-white/10',
              'peer-checked:border-yellow-400 peer-checked:bg-yellow-400',
              'hover:border-white/50',
              'focus-visible:ring-2 focus-visible:ring-yellow-400/20',
              props.disabled && 'opacity-50 cursor-not-allowed',
              className
            )}>
              {props.checked && (
                <svg className="w-3 h-3 text-black absolute top-0.5 left-0.5" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                </svg>
              )}
            </div>
          </div>
          
          {(label || description) && (
            <label htmlFor={id} className="flex-1 cursor-pointer">
              {label && (
                <p className="text-white text-sm font-medium">{label}</p>
              )}
              {description && (
                <p className="text-gray-400 text-xs mt-1">{description}</p>
              )}
            </label>
          )}
        </div>
        
        {error && (
          <p className="text-red-300 text-sm">{error}</p>
        )}
      </div>
    );
  }
);
Checkbox.displayName = 'Checkbox';

// Radio Group Component
export interface RadioOption {
  value: string;
  label: string;
  description?: string;
  disabled?: boolean;
}

export interface RadioGroupProps {
  options: RadioOption[];
  value?: string;
  onChange: (value: string) => void;
  name: string;
  label?: string;
  error?: string;
  variant?: 'default' | 'card';
  className?: string;
}

export function RadioGroup({
  options,
  value,
  onChange,
  name,
  label,
  error,
  variant = 'default',
  className
}: RadioGroupProps) {
  return (
    <div className={cn('space-y-4', className)}>
      {label && (
        <label className="block text-sm font-medium text-white">
          {label}
        </label>
      )}
      
      <div className="space-y-2">
        {options.map((option) => (
          <div
            key={option.value}
            className={cn(
              'flex items-start space-x-3',
              variant === 'card' && 'p-4 rounded-lg bg-white/5 border border-white/10 hover:bg-white/10 transition-colors',
              option.disabled && 'opacity-50'
            )}
          >
            <div className="relative flex items-center">
              <input
                type="radio"
                id={`${name}-${option.value}`}
                name={name}
                value={option.value}
                checked={value === option.value}
                onChange={(e) => onChange(e.target.value)}
                disabled={option.disabled}
                className="sr-only"
              />
              <div className={cn(
                'w-5 h-5 rounded-full border-2 transition-all duration-200 cursor-pointer',
                'border-white/30 bg-white/10',
                value === option.value && 'border-yellow-400 bg-yellow-400/20',
                'hover:border-white/50',
                option.disabled && 'cursor-not-allowed'
              )}>
                {value === option.value && (
                  <div className="w-2 h-2 rounded-full bg-yellow-400 absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2" />
                )}
              </div>
            </div>
            
            <label 
              htmlFor={`${name}-${option.value}`}
              className="flex-1 cursor-pointer"
            >
              <p className="text-white text-sm font-medium">{option.label}</p>
              {option.description && (
                <p className="text-gray-400 text-xs mt-1">{option.description}</p>
              )}
            </label>
          </div>
        ))}
      </div>
      
      {error && (
        <p className="text-red-300 text-sm">{error}</p>
      )}
    </div>
  );
}

// Toggle Switch Component
export interface ToggleProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'type' | 'size'> {
  label?: string;
  description?: string;
  error?: string;
  size?: 'sm' | 'md' | 'lg';
}

export const Toggle = forwardRef<HTMLInputElement, ToggleProps>(
  ({ className, label, description, error, size = 'md', ...props }, ref) => {
    const id = props.id || `toggle-${Math.random().toString(36).substr(2, 9)}`;
    
    const sizes = {
      sm: 'w-8 h-4',
      md: 'w-10 h-5',
      lg: 'w-12 h-6'
    };
    
    const thumbSizes = {
      sm: 'w-3 h-3',
      md: 'w-4 h-4', 
      lg: 'w-5 h-5'
    };

    return (
      <div className="space-y-2">
        <div className="flex items-center space-x-3">
          <div className="relative">
            <input
              type="checkbox"
              ref={ref}
              id={id}
              className="sr-only"
              {...props}
            />
            <div className={cn(
              'rounded-full transition-all duration-200 cursor-pointer',
              'bg-white/20 border border-white/30',
              props.checked && 'bg-yellow-400/30 border-yellow-400/50',
              'hover:bg-white/30',
              props.disabled && 'opacity-50 cursor-not-allowed',
              sizes[size],
              className
            )}>
              <div className={cn(
                'rounded-full transition-all duration-200 absolute top-0.5 bg-white shadow-sm',
                props.checked ? 'translate-x-full bg-yellow-400' : 'translate-x-0.5',
                thumbSizes[size]
              )} />
            </div>
          </div>
          
          {(label || description) && (
            <label htmlFor={id} className="flex-1 cursor-pointer">
              {label && (
                <p className="text-white text-sm font-medium">{label}</p>
              )}
              {description && (
                <p className="text-gray-400 text-xs mt-1">{description}</p>
              )}
            </label>
          )}
        </div>
        
        {error && (
          <p className="text-red-300 text-sm">{error}</p>
        )}
      </div>
    );
  }
);
Toggle.displayName = 'Toggle';