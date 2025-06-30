// components/ui/Textarea.tsx
'use client';

import { forwardRef, TextareaHTMLAttributes, useState, useEffect, useRef } from 'react';
import { AlertCircle, CheckCircle } from 'lucide-react';
import { cn } from '@/lib/utils';

export interface TextareaProps extends TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string;
  error?: string;
  success?: string;
  helperText?: string;
  variant?: 'default' | 'glass' | 'solid';
  textareaSize?: 'sm' | 'md' | 'lg';
  autoResize?: boolean;
  showCharacterCount?: boolean;
  maxLength?: number;
}

const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(
  ({
    className,
    label,
    error,
    success,
    helperText,
    variant = 'default',
    textareaSize = 'md',
    autoResize = false,
    showCharacterCount = false,
    maxLength,
    disabled,
    value,
    onChange,
    ...props
  }, ref) => {
    const [isFocused, setIsFocused] = useState(false);
    const [charCount, setCharCount] = useState(0);
    const textareaRef = useRef<HTMLTextAreaElement>(null);

    // Auto-resize functionality
    useEffect(() => {
      const textarea = textareaRef.current;
      if (autoResize && textarea) {
        textarea.style.height = 'auto';
        textarea.style.height = `${textarea.scrollHeight}px`;
      }
    }, [value, autoResize]);

    // Character count
    useEffect(() => {
      if (showCharacterCount || maxLength) {
        const count = typeof value === 'string' ? value.length : 0;
        setCharCount(count);
      }
    }, [value, showCharacterCount, maxLength]);

    const sizeClasses = {
      sm: 'min-h-[80px] px-3 py-2 text-sm',
      md: 'min-h-[100px] px-4 py-3 text-sm',
      lg: 'min-h-[120px] px-4 py-3 text-base'
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

    const handleChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
      if (maxLength && e.target.value.length > maxLength) {
        return;
      }
      onChange?.(e);
    };

    const isOverLimit = maxLength && charCount > maxLength * 0.9;

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

        {/* Textarea Container */}
        <div className="relative">
          <textarea
            ref={(node) => {
              // Handle both refs
              if (typeof ref === 'function') {
                ref(node);
              } else if (ref) {
                ref.current = node;
              }
              textareaRef.current = node;
            }}
            disabled={disabled}
            value={value}
            onChange={handleChange}
            onFocus={() => setIsFocused(true)}
            onBlur={() => setIsFocused(false)}
            className={cn(
              // Base styles
              `
                w-full rounded-lg text-white placeholder-gray-400 resize-none
                transition-all duration-200 outline-none
                disabled:opacity-50 disabled:cursor-not-allowed
              `,
              
              // Variant styles
              variantClasses[variant],
              
              // Size styles
              sizeClasses[textareaSize],
              
              // Auto-resize
              autoResize && 'resize-none overflow-hidden',
              
              // Error/Success states
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

          {/* Status Icons */}
          <div className="absolute top-3 right-3 flex items-center space-x-1">
            {error && (
              <AlertCircle className="w-4 h-4 text-red-400" />
            )}
            {success && !error && (
              <CheckCircle className="w-4 h-4 text-green-400" />
            )}
          </div>

          {/* Focus Border Effect */}
          {isFocused && (
            <div className="absolute inset-0 rounded-lg border border-yellow-400/30 pointer-events-none animate-pulse" />
          )}
        </div>

        {/* Footer Info */}
        <div className="flex items-center justify-between">
          {/* Helper Text / Error / Success Messages */}
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

          {/* Character Count */}
          {(showCharacterCount || maxLength) && (
            <p className={cn(
              'text-xs transition-colors',
              isOverLimit ? 'text-yellow-400' :
              maxLength && charCount === maxLength ? 'text-red-400' :
              'text-gray-400'
            )}>
              {maxLength ? `${charCount}/${maxLength}` : charCount}
            </p>
          )}
        </div>
      </div>
    );
  }
);

Textarea.displayName = 'Textarea';

export { Textarea };