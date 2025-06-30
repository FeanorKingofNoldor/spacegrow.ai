// components/dashboard/QuickActionsSection.tsx
'use client';

import { Button } from '@/components/ui/Button';
import { Settings, BarChart3, Zap, HelpCircle } from 'lucide-react';

export function QuickActionsSection() {
  return (
    <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
      <h2 className="text-xl font-semibold text-cosmic-text mb-4">Quick Actions</h2>
      <div className="grid grid-cols-2 gap-3">
        <Button variant="outline" size="sm" className="h-12">
          <div className="text-center">
            <Settings size={16} className="mx-auto mb-1" />
            <div className="text-xs">Add Device</div>
          </div>
        </Button>
        <Button variant="outline" size="sm" className="h-12">
          <div className="text-center">
            <BarChart3 size={16} className="mx-auto mb-1" />
            <div className="text-xs">View Reports</div>
          </div>
        </Button>
        <Button variant="outline" size="sm" className="h-12">
          <div className="text-center">
            <Zap size={16} className="mx-auto mb-1" />
            <div className="text-xs">Automation</div>
          </div>
        </Button>
        <Button variant="outline" size="sm" className="h-12">
          <div className="text-center">
            <HelpCircle size={16} className="mx-auto mb-1" />
            <div className="text-xs">Get Help</div>
          </div>
        </Button>
      </div>
    </div>
  );
}