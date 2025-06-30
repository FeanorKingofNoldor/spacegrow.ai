// components/dashboard/DashboardLayoutWrapper.tsx
'use client';

import { useState } from 'react';
import { Sidebar } from '@/components/navigation/Sidebar';
import { EnhancedAuthenticatedHeader } from '@/components/navigation/EnhancedAuthenticatedHeader';

interface DashboardLayoutWrapperProps {
  children: React.ReactNode;
}

export function DashboardLayoutWrapper({ children }: DashboardLayoutWrapperProps) {
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
        {/* Sidebar */}
        <Sidebar collapsed={sidebarCollapsed} onToggle={toggleSidebar} />

        {/* Main Content Area */}
        <div className="flex-1 flex flex-col overflow-hidden">
          {/* Header */}
          <EnhancedAuthenticatedHeader sidebarCollapsed={sidebarCollapsed} />

          {/* Main Content */}
          <main className="flex-1 overflow-y-auto p-6">
            {children}
          </main>
        </div>
      </div>
    </div>
  );
}