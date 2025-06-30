// components/ui/LoadingSpinner.tsx
'use client';

interface LoadingSpinnerProps {
  size?: 'sm' | 'md' | 'lg' | 'xl';
  text?: string;
  fullScreen?: boolean;
  className?: string;
}

export function LoadingSpinner({ 
  size = 'md', 
  text = 'Loading...', 
  fullScreen = false,
  className = '' 
}: LoadingSpinnerProps) {
  const sizeClasses = {
    sm: 'w-4 h-4',
    md: 'w-8 h-8', 
    lg: 'w-12 h-12',
    xl: 'w-16 h-16'
  };

  const textSizes = {
    sm: 'text-sm',
    md: 'text-base',
    lg: 'text-lg', 
    xl: 'text-xl'
  };

  const spinner = (
    <div className={`flex flex-col items-center justify-center gap-4 ${className}`}>
      {/* Cosmic Spinner */}
      <div className="relative">
        {/* Outer ring */}
        <div 
          className={`${sizeClasses[size]} border-4 border-white/20 border-t-yellow-400 rounded-full animate-spin`}
        />
        {/* Inner glow effect */}
        <div 
          className={`absolute inset-0 ${sizeClasses[size]} border-4 border-transparent border-t-yellow-400/50 rounded-full animate-spin`}
          style={{ animationDirection: 'reverse', animationDuration: '1.5s' }}
        />
        {/* Center dot */}
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="w-1 h-1 bg-yellow-400 rounded-full animate-pulse" />
        </div>
      </div>
      
      {/* Loading text */}
      {text && (
        <p className={`${textSizes[size]} text-white font-medium`}>
          {text}
        </p>
      )}
    </div>
  );

  if (fullScreen) {
    return (
      <div className="fixed inset-0 bg-transparent backdrop-blur-sm flex items-center justify-center z-50">
        <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-8 shadow-2xl">
          {spinner}
        </div>
      </div>
    );
  }

  return spinner;
}

// Minimal inline spinner for buttons
export function InlineSpinner({ size = 'sm' }: { size?: 'sm' | 'md' }) {
  const sizeClass = size === 'sm' ? 'w-4 h-4' : 'w-6 h-6';
  
  return (
    <div className={`${sizeClass} border-2 border-white/30 border-t-white rounded-full animate-spin`} />
  );
}

// Page-level loading component
export function PageLoader({ text = 'Loading page...' }: { text?: string }) {
  return (
    <div className="min-h-screen flex items-center justify-center px-4 bg-transparent">
      <div className="max-w-md w-full mx-auto">
        <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-12 shadow-2xl text-center">
          <LoadingSpinner size="xl" text={text} />
          
          {/* Floating decoration elements */}
          <div className="absolute -top-4 -left-4 w-8 h-8 bg-gradient-to-br from-yellow-400/30 to-orange-500/30 rounded-full blur-sm animate-pulse"></div>
          <div className="absolute -bottom-4 -right-4 w-6 h-6 bg-gradient-to-br from-pink-500/30 to-purple-600/30 rounded-full blur-sm animate-pulse" style={{ animationDelay: '1s' }}></div>
          <div className="absolute top-1/2 -right-8 w-4 h-4 bg-gradient-to-br from-blue-400/40 to-cyan-500/40 rounded-full blur-sm animate-pulse" style={{ animationDelay: '2s' }}></div>
        </div>
      </div>
    </div>
  );
}