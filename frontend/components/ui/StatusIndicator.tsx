// components/ui/StatusIndicator.tsx
'use client';

import { cn } from '@/lib/utils';

interface StatusIndicatorProps {
  status: 'ok' | 'warning' | 'error' | 'no_data';
  size?: 'sm' | 'md' | 'lg';
  showText?: boolean;
  className?: string;
}

export function StatusIndicator({ 
  status, 
  size = 'md', 
  showText = true, 
  className 
}: StatusIndicatorProps) {
  
  // Status color mapping based on your backend system
  const getStatusConfig = (status: string) => {
    switch (status) {
      case 'ok':
        return {
          dotClass: 'bg-green-400',
          textClass: 'text-green-400',
          bgClass: 'bg-green-800/10 border-green-800/50',
          message: 'Operating normally'
        };
      case 'warning':
        return {
          dotClass: 'bg-orange-400',
          textClass: 'text-orange-400',
          bgClass: 'bg-orange-800/10 border-orange-800/50',
          message: 'Sensors showing warnings'
        };
      case 'error':
        return {
          dotClass: 'bg-red-400',
          textClass: 'text-red-400',
          bgClass: 'bg-red-800/10 border-red-800/50',
          message: 'Critical sensor errors'
        };
      case 'no_data':
      default:
        return {
          dotClass: 'bg-gray-400',
          textClass: 'text-gray-400',
          bgClass: 'bg-gray-800/10 border-gray-800/50',
          message: 'No sensor data'
        };
    }
  };

  const config = getStatusConfig(status);
  
  // Size configurations
  const sizeConfig = {
    sm: {
      dot: 'w-2 h-2',
      text: 'text-xs',
      container: 'gap-1.5'
    },
    md: {
      dot: 'w-3 h-3',
      text: 'text-sm',
      container: 'gap-2'
    },
    lg: {
      dot: 'w-4 h-4',
      text: 'text-base',
      container: 'gap-2.5'
    }
  };

  const sizes = sizeConfig[size];

  return (
    <div className={cn(
      'flex items-center',
      sizes.container,
      className
    )}>
      {/* Status Dot */}
      <div className={cn(
        'rounded-full flex-shrink-0',
        sizes.dot,
        config.dotClass
      )} />
      
      {/* Status Text */}
      {showText && (
        <span className={cn(
          'font-medium capitalize',
          sizes.text,
          config.textClass
        )}>
          {status === 'no_data' ? 'No Data' : status.toUpperCase()}
        </span>
      )}
    </div>
  );
}

// Status Badge Component (alternative style)
export function StatusBadge({ 
  status, 
  size = 'md', 
  className 
}: StatusIndicatorProps) {
  const config = getStatusConfig(status);
  
  const sizeConfig = {
    sm: 'px-2 py-1 text-xs',
    md: 'px-2.5 py-1.5 text-sm',
    lg: 'px-3 py-2 text-base'
  };

  function getStatusConfig(status: string) {
    switch (status) {
      case 'ok':
        return {
          bgClass: 'bg-green-800/10 border-green-800/50',
          textClass: 'text-green-400',
          message: 'Operating normally'
        };
      case 'warning':
        return {
          bgClass: 'bg-orange-800/10 border-orange-800/50',
          textClass: 'text-orange-400',
          message: 'Sensors showing warnings'
        };
      case 'error':
        return {
          bgClass: 'bg-red-800/10 border-red-800/50',
          textClass: 'text-red-400',
          message: 'Critical sensor errors'
        };
      case 'no_data':
      default:
        return {
          bgClass: 'bg-gray-800/10 border-gray-800/50',
          textClass: 'text-gray-400',
          message: 'No sensor data'
        };
    }
  }

  return (
    <div className={cn(
      'inline-flex items-center rounded-full border font-medium',
      sizeConfig[size],
      config.bgClass,
      config.textClass,
      className
    )}>
      {status === 'no_data' ? 'No Data' : status.toUpperCase()}
    </div>
  );
}