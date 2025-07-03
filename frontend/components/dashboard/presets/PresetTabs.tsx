// components/dashboard/PresetTabs.tsx
'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/Button';
import { LoadingSpinner, InlineSpinner } from '@/components/ui/LoadingSpinner';
import { Device } from '@/types/device';
import { Preset } from '@/types/preset';
import { Settings, User, Play, Edit, Trash2, Lightbulb, Droplets, Zap } from 'lucide-react';
import { cn } from '@/lib/utils';

interface PresetTabsProps {
  presets: Preset[];
  userPresets: Preset[];
  onPresetSelect: (preset: Preset) => void;
  onApplyPreset: (preset: Preset) => void;
  onEditPreset: (preset: Preset) => void;
  selectedPreset?: Preset | null;
  applyingPresetId?: number | null;
  device: Device;
}

type TabType = 'predefined' | 'custom';

export function PresetTabs({
  presets,
  userPresets,
  onPresetSelect,
  onApplyPreset,
  onEditPreset,
  selectedPreset,
  applyingPresetId,
  device
}: PresetTabsProps) {
  const [activeTab, setActiveTab] = useState<TabType>('predefined');

  const isEnvironmentalMonitor = device.device_type?.includes('Environmental Monitor');
  const isLiquidMonitor = device.device_type?.includes('Liquid Monitor');

  // Get icon for preset based on device type and preset name
  const getPresetIcon = (preset: Preset) => {
    if (isEnvironmentalMonitor) {
      if (preset.name.toLowerCase().includes('cannabis')) {
        return <div className="w-8 h-8 bg-green-500/20 rounded-lg flex items-center justify-center">
          <Lightbulb size={16} className="text-green-400" />
        </div>;
      } else if (preset.name.toLowerCase().includes('chili')) {
        return <div className="w-8 h-8 bg-red-500/20 rounded-lg flex items-center justify-center">
          <Droplets size={16} className="text-red-400" />
        </div>;
      }
      return <div className="w-8 h-8 bg-blue-500/20 rounded-lg flex items-center justify-center">
        <Settings size={16} className="text-blue-400" />
      </div>;
    } else if (isLiquidMonitor) {
      return <div className="w-8 h-8 bg-purple-500/20 rounded-lg flex items-center justify-center">
        <Zap size={16} className="text-purple-400" />
      </div>;
    }
    return <div className="w-8 h-8 bg-cosmic-blue/20 rounded-lg flex items-center justify-center">
      <Settings size={16} className="text-cosmic-blue" />
    </div>;
  };

  // Format settings for display
  const formatSettings = (preset: Preset) => {
    if (isEnvironmentalMonitor) {
      const settings = preset.settings as any;
      return [
        `Lights: ${settings.lights?.on_at || '08:00hrs'} - ${settings.lights?.off_at || '20:00hrs'}`,
        `Spray: ${settings.spray?.on_for || 10}s on, ${settings.spray?.off_for || 30}s off`
      ];
    } else if (isLiquidMonitor) {
      const settings = preset.settings as any;
      const pumps = [];
      for (let i = 1; i <= 5; i++) {
        const duration = settings[`pump${i}`]?.duration || 0;
        if (duration > 0) {
          pumps.push(`Pump ${i}: ${duration}s`);
        }
      }
      return pumps.length > 0 ? pumps : ['No pumps configured'];
    }
    return ['Custom configuration'];
  };

  const renderPresetCard = (preset: Preset, isUserPreset: boolean = false) => {
    const isSelected = selectedPreset?.id === preset.id;
    const isApplying = applyingPresetId === preset.id;
    const settings = formatSettings(preset);

    return (
      <div
        key={preset.id}
        className={cn(
          'bg-space-secondary border border-space-border rounded-lg p-4 transition-all duration-200',
          isSelected ? 'border-stellar-accent bg-stellar-accent/10' : 'hover:border-space-border/60',
          isApplying && 'opacity-60'
        )}
      >
        {/* Preset Header */}
        <div className="flex items-start justify-between mb-3">
          <div className="flex items-center space-x-3">
            {getPresetIcon(preset)}
            <div>
              <h4 className="font-medium text-cosmic-text">{preset.name}</h4>
              <p className="text-xs text-cosmic-text-muted">
                {isUserPreset ? 'Custom preset' : 'Predefined preset'}
              </p>
            </div>
          </div>
          
          {isUserPreset && (
            <Button
              variant="ghost"
              size="sm"
              onClick={() => onEditPreset(preset)}
              disabled={isApplying}
            >
              <Edit size={14} />
            </Button>
          )}
        </div>

        {/* Settings Preview */}
        <div className="space-y-1 mb-4">
          {settings.map((setting, index) => (
            <p key={index} className="text-xs text-cosmic-text-muted">
              {setting}
            </p>
          ))}
        </div>

        {/* Actions */}
        <div className="flex space-x-2">
          <Button
            variant={isSelected ? "cosmic" : "outline"}
            size="sm"
            className="flex-1"
            onClick={() => onPresetSelect(preset)}
            disabled={isApplying}
          >
            {isSelected ? 'Selected' : 'Select'}
          </Button>
          
          <Button
            variant="stellar"
            size="sm"
            onClick={() => onApplyPreset(preset)}
            disabled={isApplying || !isSelected}
          >
            {isApplying ? (
              <InlineSpinner size="sm" />
            ) : (
              <Play size={14} />
            )}
          </Button>
        </div>
      </div>
    );
  };

  return (
    <div className="space-y-4">
      {/* Tab Navigation */}
      <div className="flex space-x-1 bg-space-secondary rounded-lg p-1">
        <button
          className={cn(
            'flex-1 flex items-center justify-center space-x-2 px-4 py-2 rounded-md text-sm font-medium transition-all',
            activeTab === 'predefined'
              ? 'bg-cosmic-blue/20 text-cosmic-blue'
              : 'text-cosmic-text-muted hover:text-cosmic-text'
          )}
          onClick={() => setActiveTab('predefined')}
        >
          <Settings size={16} />
          <span>Predefined ({presets.length})</span>
        </button>
        
        <button
          className={cn(
            'flex-1 flex items-center justify-center space-x-2 px-4 py-2 rounded-md text-sm font-medium transition-all',
            activeTab === 'custom'
              ? 'bg-cosmic-blue/20 text-cosmic-blue'
              : 'text-cosmic-text-muted hover:text-cosmic-text'
          )}
          onClick={() => setActiveTab('custom')}
        >
          <User size={16} />
          <span>Custom ({userPresets.length})</span>
        </button>
      </div>

      {/* Tab Content */}
      <div className="min-h-[300px]">
        {activeTab === 'predefined' && (
          <div className="space-y-3">
            {presets.length > 0 ? (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {presets.map(preset => renderPresetCard(preset, false))}
              </div>
            ) : (
              <div className="text-center py-8">
                <Settings size={48} className="mx-auto text-cosmic-text-muted mb-4" />
                <h3 className="text-cosmic-text font-medium mb-2">No Predefined Presets</h3>
                <p className="text-cosmic-text-muted text-sm">
                  No predefined presets available for this device type.
                </p>
              </div>
            )}
          </div>
        )}

        {activeTab === 'custom' && (
          <div className="space-y-3">
            {userPresets.length > 0 ? (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {userPresets.map(preset => renderPresetCard(preset, true))}
              </div>
            ) : (
              <div className="text-center py-8">
                <User size={48} className="mx-auto text-cosmic-text-muted mb-4" />
                <h3 className="text-cosmic-text font-medium mb-2">No Custom Presets</h3>
                <p className="text-cosmic-text-muted text-sm mb-4">
                  Create your own preset configurations for this device.
                </p>
                <Button variant="cosmic" size="sm">
                  Create Your First Preset
                </Button>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Help Text */}
      <div className="bg-cosmic-blue/10 border border-cosmic-blue/20 rounded-lg p-3">
        <p className="text-xs text-cosmic-text-muted">
          <strong>Tip:</strong> Select a preset to preview its settings, then click the play button to apply it to your device. 
          Custom presets can be edited and deleted.
        </p>
      </div>
    </div>
  );
}