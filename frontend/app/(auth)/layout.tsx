'use client';

import { useState } from 'react';
import { EnhancedAuthenticatedHeader } from '@/components/navigation/EnhancedAuthenticatedHeader';

export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);

  const toggleSidebar = () => {
    setSidebarCollapsed(!sidebarCollapsed);
  };

  return (
    <div className="min-h-screen bg-space-primary">
      {/* Cosmic Background Effects */}
      <div className="cosmic-starfield" />
      <div className="cosmic-sunflare" />
      
      <div className="relative z-10 flex h-screen">    
        {/* Main Content Area */}
        <div className="flex-1 flex flex-col overflow-hidden">
          {/* Header with proper props */}
          <EnhancedAuthenticatedHeader sidebarCollapsed={sidebarCollapsed} />
          
          {/* Main Content */}
          <main className="flex-1 overflow-auto p-6">
            {children}
          </main>
        </div>
      </div>
    </div>
  );
}
