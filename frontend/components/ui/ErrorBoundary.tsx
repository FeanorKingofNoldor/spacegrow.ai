// components/ui/ErrorBoundary.tsx
'use client';

import { Component, ErrorInfo, ReactNode } from 'react';
import { AlertTriangle, RefreshCw, Home } from 'lucide-react';
import { CosmicButton, GhostButton } from './ButtonVariants';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
  errorInfo?: ErrorInfo;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('ErrorBoundary caught an error:', error, errorInfo);
    this.setState({ error, errorInfo });
  }

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) {
        return this.props.fallback;
      }

      return (
        <div className="min-h-screen flex items-center justify-center px-4 bg-transparent">
          <div className="max-w-md w-full mx-auto">
            <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-8 shadow-2xl text-center">
              
              {/* Error Icon */}
              <div className="flex justify-center mb-6">
                <div className="w-16 h-16 bg-red-500/20 rounded-full flex items-center justify-center">
                  <AlertTriangle className="w-8 h-8 text-red-400" />
                </div>
              </div>
              
              {/* Error Message */}
              <h1 className="text-2xl font-bold text-white mb-4">
                Something went wrong
              </h1>
              <p className="text-gray-300 mb-6">
                We encountered an unexpected error. This has been logged and our team will look into it.
              </p>
              
              {/* Error Details (Development) */}
              {process.env.NODE_ENV === 'development' && this.state.error && (
                <details className="mb-6 text-left">
                  <summary className="text-sm text-gray-400 cursor-pointer hover:text-white">
                    Technical Details
                  </summary>
                  <div className="mt-2 p-3 bg-red-500/10 border border-red-500/20 rounded-lg">
                    <pre className="text-xs text-red-300 whitespace-pre-wrap overflow-x-auto">
                      {this.state.error.toString()}
                      {this.state.errorInfo && this.state.errorInfo.componentStack}
                    </pre>
                  </div>
                </details>
              )}
              
              {/* Actions */}
              <div className="space-y-3">
                <CosmicButton 
                  onClick={() => window.location.reload()}
                  className="w-full"
                >
                  <RefreshCw className="w-4 h-4 mr-2" />
                  Reload Page
                </CosmicButton>
                
                <GhostButton 
                  onClick={() => window.location.href = '/'}
                  className="w-full"
                >
                  <Home className="w-4 h-4 mr-2" />
                  Go to Homepage
                </GhostButton>
              </div>
              
              {/* Report Issue */}
              <p className="text-xs text-gray-400 mt-6">
                If this problem persists, please{' '}
                <a 
                  href="/support" 
                  className="text-yellow-400 hover:text-yellow-300 transition-colors"
                >
                  contact support
                </a>
              </p>
            </div>
            
            {/* Floating decorations */}
            <div className="absolute -top-4 -left-4 w-8 h-8 bg-gradient-to-br from-red-400/30 to-orange-500/30 rounded-full blur-sm animate-pulse"></div>
            <div className="absolute -bottom-4 -right-4 w-6 h-6 bg-gradient-to-br from-red-500/30 to-pink-600/30 rounded-full blur-sm animate-pulse" style={{ animationDelay: '1s' }}></div>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

// Hook-based error boundary for functional components
export function withErrorBoundary<P extends object>(
  Component: React.ComponentType<P>,
  fallback?: ReactNode
) {
  return function WrappedComponent(props: P) {
    return (
      <ErrorBoundary fallback={fallback}>
        <Component {...props} />
      </ErrorBoundary>
    );
  };
}