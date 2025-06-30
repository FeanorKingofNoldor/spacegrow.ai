// components/ui/Input.tsx
'use client';

import { forwardRef, InputHTMLAttributes, useState } from 'react';
import { Eye, EyeOff, AlertCircle, CheckCircle } from 'lucide-react';
import { cn } from '@/lib/utils';

export interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  success?: string;
  helperText?: string;
  variant?: 'default' | 'glass' | 'solid';
  inputSize?: 'sm' | 'md' | 'lg';
  showPasswordToggle?: boolean;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
}

const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ 
    className, 
    type = 'text',
    label,
    error,
    success,
    helperText,
    variant = 'default',
    inputSize = 'md',
    showPasswordToggle = false,
    leftIcon,
    rightIcon,
    disabled,
    ...props 
  }, ref) => {
    const [showPassword, setShowPassword] = useState(false);
    const [isFocused, setIsFocused] = useState(false);

    const isPasswordField = type === 'password' || showPasswordToggle;
    const inputType = isPasswordField && showPassword ? 'text' : type;

    const sizeClasses = {
      sm: 'h-9 px-3 text-sm',
      md: 'h-10 px-4 text-sm', 
      lg: 'h-12 px-4 text-base'
    };

    const variantClasses = {
      default: `
        bg-white/10 backdrop-blur-sm border border-white/20
        focus:bg-white/15 focus:border-yellow-400/50
      `,
      glass: `
        bg-white/5 backdrop-blur-md border border-white/10
        focus:bg-white/10 focus:border-yellow-400/30
      `,
      solid: `
        bg-white/20 border border-white/30
        focus:bg-white/25 focus:border-yellow-400
      `
    };

    return (
      <div className="space-y-2">
        {/* Label */}
        {label && (
          <label className="block text-sm font-medium text-white">
            {label}
            {props.required && (
              <span className="text-red-400 ml-1">*</span>
            )}
          </label>
        )}

        {/* Input Container */}
        <div className="relative">
          {/* Left Icon */}
          {leftIcon && (
            <div className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400">
              {leftIcon}
            </div>
          )}

          {/* Input Field */}
          <input
            type={inputType}
            ref={ref}
            disabled={disabled}
            onFocus={() => setIsFocused(true)}
            onBlur={() => setIsFocused(false)}
            className={cn(
              // Base styles
              `
                w-full rounded-lg text-white placeholder-gray-400
                transition-all duration-200 outline-none
                disabled:opacity-50 disabled:cursor-not-allowed
              `,
              
              // Variant styles
              variantClasses[variant],
              
              // Size styles
              sizeClasses[inputSize],
              
              // Icon padding
              leftIcon && 'pl-10',
              (rightIcon || isPasswordField || error || success) && 'pr-10',
              
              // Error states
              error && 'border-red-400/60 focus:border-red-400',
              success && 'border-green-400/60 focus:border-green-400',
              
              // Focus ring
              `focus:ring-2 ${
                error ? 'focus:ring-red-400/20' :
                success ? 'focus:ring-green-400/20' :
                'focus:ring-yellow-400/20'
              }`,
              
              className
            )}
            {...props}
          />

          {/* Right Side Icons */}
          <div className="absolute right-3 top-1/2 transform -translate-y-1/2 flex items-center space-x-1">
            {/* Status Icons */}
            {error && (
              <AlertCircle className="w-4 h-4 text-red-400" />
            )}
            {success && !error && (
              <CheckCircle className="w-4 h-4 text-green-400" />
            )}
            
            {/* Password Toggle */}
            {isPasswordField && !error && !success && (
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="text-gray-400 hover:text-white transition-colors focus:outline-none"
                tabIndex={-1}
              >
                {showPassword ? (
                  <EyeOff className="w-4 h-4" />
                ) : (
                  <Eye className="w-4 h-4" />
                )}
              </button>
            )}
            
            {/* Custom Right Icon */}
            {rightIcon && !isPasswordField && !error && !success && (
              <div className="text-gray-400">
                {rightIcon}
              </div>
            )}
          </div>

          {/* Focus Border Effect */}
          {isFocused && (
            <div className="absolute inset-0 rounded-lg border border-yellow-400/30 pointer-events-none animate-pulse" />
          )}
        </div>

        {/* Helper Text / Error / Success Messages */}
        {(error || success || helperText) && (
          <div className="flex items-start space-x-1">
            {error && (
              <>
                <AlertCircle className="w-4 h-4 text-red-400 mt-0.5 flex-shrink-0" />
                <p className="text-sm text-red-300">{error}</p>
              </>
            )}
            {success && !error && (
              <>
                <CheckCircle className="w-4 h-4 text-green-400 mt-0.5 flex-shrink-0" />
                <p className="text-sm text-green-300">{success}</p>
              </>
            )}
            {helperText && !error && !success && (
              <p className="text-sm text-gray-400">{helperText}</p>
            )}
          </div>
        )}
      </div>
    );
  }
);

Input.displayName = 'Input';

export { Input };

// Specialized Input Variants
export const SearchInput = forwardRef<HTMLInputElement, Omit<InputProps, 'leftIcon'>>(
  ({ className, ...props }, ref) => (
    <Input
      ref={ref}
      type="search"
      leftIcon={
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
      }
      placeholder="Search..."
      className={className}
      {...props}
    />
  )
);
SearchInput.displayName = 'SearchInput';

export const EmailInput = forwardRef<HTMLInputElement, Omit<InputProps, 'type' | 'leftIcon'>>(
  ({ ...props }, ref) => (
    <Input
      ref={ref}
      type="email"
      leftIcon={
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 12a4 4 0 10-8 0 4 4 0 008 0zm0 0v1.5a2.5 2.5 0 005 0V12a9 9 0 10-9 9m4.5-1.206a8.959 8.959 0 01-4.5 1.207" />
        </svg>
      }
      placeholder="your@email.com"
      {...props}
    />
  )
);
EmailInput.displayName = 'EmailInput';

export const PasswordInput = forwardRef<HTMLInputElement, Omit<InputProps, 'type' | 'showPasswordToggle'>>(
  ({ ...props }, ref) => (
    <Input
      ref={ref}
      type="password"
      showPasswordToggle
      placeholder="Enter password"
      {...props}
    />
  )
);
PasswordInput.displayName = 'PasswordInput';