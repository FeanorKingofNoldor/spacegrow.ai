// components/ui/Select.tsx
'use client';

import { useState, useRef, useEffect, forwardRef } from 'react';
import { ChevronDown, Check, X, Search } from 'lucide-react';
import { cn } from '@/lib/utils';

export interface SelectOption {
  value: string;
  label: string;
  disabled?: boolean;
}

export interface SelectProps {
  options: SelectOption[];
  value?: string | string[];
  onChange: (value: string | string[]) => void;
  placeholder?: string;
  label?: string;
  error?: string;
  success?: string;
  helperText?: string;
  multiple?: boolean;
  searchable?: boolean;
  clearable?: boolean;
  disabled?: boolean;
  size?: 'sm' | 'md' | 'lg';
  variant?: 'default' | 'glass' | 'solid';
  className?: string;
}

const Select = forwardRef<HTMLDivElement, SelectProps>(
  ({
    options,
    value,
    onChange,
    placeholder = 'Select option...',
    label,
    error,
    success,
    helperText,
    multiple = false,
    searchable = false,
    clearable = false,
    disabled = false,
    size = 'md',
    variant = 'default',
    className
  }, ref) => {
    const [isOpen, setIsOpen] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');
    const selectRef = useRef<HTMLDivElement>(null);

    // Close dropdown when clicking outside
    useEffect(() => {
      function handleClickOutside(event: MouseEvent) {
        if (selectRef.current && !selectRef.current.contains(event.target as Node)) {
          setIsOpen(false);
          setSearchTerm('');
        }
      }
      document.addEventListener('mousedown', handleClickOutside);
      return () => document.removeEventListener('mousedown', handleClickOutside);
    }, []);

    const sizeClasses = {
      sm: 'h-9 px-3 text-sm',
      md: 'h-10 px-4 text-sm',
      lg: 'h-12 px-4 text-base'
    };

    const variantClasses = {
      default: `
        bg-white/10 backdrop-blur-sm border border-white/20
        focus-within:bg-white/15 focus-within:border-yellow-400/50
      `,
      glass: `
        bg-white/5 backdrop-blur-md border border-white/10
        focus-within:bg-white/10 focus-within:border-yellow-400/30
      `,
      solid: `
        bg-white/20 border border-white/30
        focus-within:bg-white/25 focus-within:border-yellow-400
      `
    };

    // Filter options based on search
    const filteredOptions = searchable
      ? options.filter(option =>
          option.label.toLowerCase().includes(searchTerm.toLowerCase())
        )
      : options;

    // Get selected options
    const selectedOptions = multiple
      ? options.filter(option => Array.isArray(value) && value.includes(option.value))
      : options.find(option => option.value === value);

    // Handle option selection
    const handleSelect = (optionValue: string) => {
      if (multiple) {
        const currentValues = Array.isArray(value) ? value : [];
        const newValues = currentValues.includes(optionValue)
          ? currentValues.filter(v => v !== optionValue)
          : [...currentValues, optionValue];
        onChange(newValues);
      } else {
        onChange(optionValue);
        setIsOpen(false);
        setSearchTerm('');
      }
    };

    // Clear selection
    const handleClear = (e: React.MouseEvent) => {
      e.stopPropagation();
      onChange(multiple ? [] : '');
    };

    // Display value
    const displayValue = () => {
      if (multiple && Array.isArray(value)) {
        if (value.length === 0) return placeholder;
        if (value.length === 1) {
          const option = options.find(opt => opt.value === value[0]);
          return option?.label || value[0];
        }
        return `${value.length} selected`;
      } else {
        const option = options.find(opt => opt.value === value);
        return option?.label || placeholder;
      }
    };

    return (
      <div className="space-y-2">
        {/* Label */}
        {label && (
          <label className="block text-sm font-medium text-white">
            {label}
          </label>
        )}

        {/* Select Container */}
        <div 
          ref={selectRef}
          className={cn('relative', className)}
        >
          {/* Select Trigger */}
          <div
            onClick={() => !disabled && setIsOpen(!isOpen)}
            className={cn(
              'w-full flex items-center justify-between rounded-lg text-white cursor-pointer transition-all duration-200',
              variantClasses[variant],
              sizeClasses[size],
              error && 'border-red-400/60',
              success && 'border-green-400/60',
              disabled && 'opacity-50 cursor-not-allowed',
              className
            )}
          >
            <span className={cn(
              'truncate',
              (!value || (Array.isArray(value) && value.length === 0)) && 'text-gray-400'
            )}>
              {displayValue()}
            </span>
            
            <div className="flex items-center space-x-2">
              {clearable && value && (Array.isArray(value) ? value.length > 0 : value) && (
                <button
                  onClick={handleClear}
                  className="text-gray-400 hover:text-white transition-colors"
                >
                  <X className="w-4 h-4" />
                </button>
              )}
              <ChevronDown className={cn(
                'w-4 h-4 text-gray-400 transition-transform duration-200',
                isOpen && 'rotate-180'
              )} />
            </div>
          </div>

          {/* Dropdown */}
          {isOpen && (
            <div className="absolute top-full left-0 right-0 mt-1 bg-white/10 backdrop-blur-lg border border-white/20 rounded-lg shadow-2xl z-50 max-h-60 overflow-hidden">
              
              {/* Search Input */}
              {searchable && (
                <div className="p-2 border-b border-white/10">
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
                    <input
                      type="text"
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      placeholder="Search options..."
                      className="w-full pl-10 pr-4 py-2 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:border-yellow-400/50 transition-colors"
                    />
                  </div>
                </div>
              )}

              {/* Options */}
              <div className="max-h-48 overflow-y-auto">
                {filteredOptions.length === 0 ? (
                  <div className="p-3 text-gray-400 text-center">
                    {searchable ? 'No options found' : 'No options available'}
                  </div>
                ) : (
                  filteredOptions.map((option) => {
                    const isSelected = multiple
                      ? Array.isArray(value) && value.includes(option.value)
                      : value === option.value;

                    return (
                      <div
                        key={option.value}
                        onClick={() => !option.disabled && handleSelect(option.value)}
                        className={cn(
                          'flex items-center justify-between px-3 py-2 cursor-pointer transition-colors',
                          option.disabled
                            ? 'text-gray-500 cursor-not-allowed'
                            : 'text-white hover:bg-white/10',
                          isSelected && 'bg-yellow-500/20 text-yellow-400'
                        )}
                      >
                        <span className="truncate">{option.label}</span>
                        {isSelected && <Check className="w-4 h-4" />}
                      </div>
                    );
                  })
                )}
              </div>
            </div>
          )}
        </div>

        {/* Helper Text / Error / Success Messages */}
        {(error || success || helperText) && (
          <div className="flex items-start space-x-1">
            {error && (
              <p className="text-sm text-red-300">{error}</p>
            )}
            {success && !error && (
              <p className="text-sm text-green-300">{success}</p>
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

Select.displayName = 'Select';

export { Select };