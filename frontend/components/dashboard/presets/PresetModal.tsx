// components/dashboard/PresetModal.tsx - FIXED with proper scrolling and hook usage
'use client';

import { useState, useEffect } from 'react';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { PresetTabs } from './PresetTabs';
import { PresetForm } from './PresetForm';
import { Device } from '@/types/device';
import { Preset, CreatePresetData } from '@/types/preset';
import { useDevicePresets, usePresets } from '@/contexts/PresetContext'; // ✅ FIXED: Import hooks directly
import { Plus, Settings, Zap } from 'lucide-react';
import { cn } from '@/lib/utils';

interface PresetModalProps {
  isOpen: boolean;
  onClose: () => void;
  device: Device;
  onPresetApplied?: (preset: Preset) => void;
}

type ModalView = 'presets' | 'create' | 'edit';

export function PresetModal({ isOpen, onClose, device, onPresetApplied }: PresetModalProps) {
  const [currentView, setCurrentView] = useState<ModalView>('presets');
  const [selectedPreset, setSelectedPreset] = useState<Preset | null>(null);
  const [applyingPreset, setApplyingPreset] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);

  // ✅ FIXED: Use hooks directly at component level
  const { createPreset, updatePreset, applyPreset } = usePresets();

  // Get presets for this device type
  const { 
    predefinedPresets, 
    userPresets, 
    loading, 
    error: presetError,
    refetch 
  } = useDevicePresets(device);

  // Get device type information
  const deviceTypeName = device.device_type || 'Unknown Device';
  const isEnvironmentalMonitor = deviceTypeName.includes('Environmental Monitor');
  const isLiquidMonitor = deviceTypeName.includes('Liquid Monitor');

  // Reset state when modal opens/closes
  useEffect(() => {
    if (isOpen) {
      setCurrentView('presets');
      setSelectedPreset(null);
      setApplyingPreset(null);
      setError(null);
    }
  }, [isOpen]);

  // Auto-refetch when modal opens
  useEffect(() => {
    if (isOpen) {
      refetch();
    }
  }, [isOpen, refetch]);

  const handlePresetSelect = (preset: Preset) => {
    setSelectedPreset(preset);
  };

  const handleApplyPreset = async (preset: Preset) => {
    if (!preset || applyingPreset === preset.id) return;

    setApplyingPreset(preset.id);
    setError(null);

    try {
      console.log('🔄 Applying preset:', preset.name, 'to device:', device.name);
      
      await applyPreset(device.id, preset.id);
      
      console.log('✅ Preset applied successfully');
      onPresetApplied?.(preset);
      
      // Show success for a moment, then close
      setTimeout(() => {
        onClose();
      }, 1000);
      
    } catch (err) {
      console.error('❌ Failed to apply preset:', err);
      setError(err instanceof Error ? err.message : 'Failed to apply preset');
    } finally {
      setApplyingPreset(null);
    }
  };

  const handleCreatePreset = () => {
    setCurrentView('create');
    setSelectedPreset(null);
  };

  const handleEditPreset = (preset: Preset) => {
    setSelectedPreset(preset);
    setCurrentView('edit');
  };

  const handleFormSubmit = async (data: CreatePresetData) => {
    try {
      console.log('🔄 Saving preset:', data.name);
      
      // ✅ FIXED: Use hooks directly (no dynamic import)
      if (currentView === 'create') {
        await createPreset(data);
      } else if (currentView === 'edit' && selectedPreset) {
        await updatePreset(selectedPreset.id, data);
      }
      
      console.log('✅ Preset saved successfully');
      setCurrentView('presets');
      setSelectedPreset(null);
      // ✅ No need to refetch - context updates automatically
      
    } catch (err) {
      console.error('❌ Failed to save preset:', err);
      setError(err instanceof Error ? err.message : 'Failed to save preset');
    }
  };

  const handleFormCancel = () => {
    setCurrentView('presets');
    setSelectedPreset(null);
  };

  const getModalTitle = () => {
    switch (currentView) {
      case 'create':
        return `Create Custom Preset - ${device.name}`;
      case 'edit':
        return `Edit Preset - ${selectedPreset?.name}`;
      default:
        return `Configure Presets - ${device.name}`;
    }
  };

  const getDeviceTypeIcon = () => {
    if (isEnvironmentalMonitor) {
      return <Settings className="text-green-400" size={20} />;
    } else if (isLiquidMonitor) {
      return <Zap className="text-blue-400" size={20} />;
    }
    return <Settings className="text-cosmic-blue" size={20} />;
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={getModalTitle()}
      size="lg"
      className="max-h-[90vh] flex flex-col"
    >
      {/* ✅ FIXED: Proper scrollable structure with consistent background */}
      <div className="flex flex-col h-full max-h-[80vh]">
        
        {/* Fixed Header Section */}
        <div className="flex-shrink-0 space-y-4">
          {/* Device Info Header */}
          <div className="flex items-center space-x-3 p-4 bg-space-secondary rounded-lg">
            {getDeviceTypeIcon()}
            <div>
              <h3 className="font-semibold text-cosmic-text">{device.name}</h3>
              <p className="text-sm text-cosmic-text-muted">{deviceTypeName}</p>
            </div>
          </div>

          {/* Error Display */}
          {(error || presetError) && (
            <div className="bg-red-500/10 border border-red-500/20 rounded-lg p-4">
              <p className="text-red-400 text-sm">{error || presetError}</p>
            </div>
          )}

          {/* Loading State */}
          {loading && currentView === 'presets' && (
            <div className="flex items-center justify-center py-8">
              <LoadingSpinner />
            </div>
          )}
        </div>

        {/* ✅ FIXED: Scrollable Content Area with consistent background */}
        <div className="flex-1 overflow-y-auto min-h-0 bg-transparent"> {/* Ensure transparent background */}
          {!loading && (
            <>
              {currentView === 'presets' && (
                <div className="space-y-4 p-1 bg-transparent"> {/* ✅ FIXED: Transparent background */}
                  {/* Create Preset Button */}
                  <div className="flex justify-between items-center">
                    <p className="text-cosmic-text-muted text-sm">
                      Choose a preset to apply or create your own custom configuration
                    </p>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={handleCreatePreset}
                    >
                      <Plus size={16} className="mr-2" />
                      Create Custom
                    </Button>
                  </div>

                  {/* ✅ FIXED: Scrollable Preset Tabs with proper background inheritance */}
                  <div className="overflow-y-auto max-h-96 bg-transparent"> {/* ✅ FIXED: Background inheritance */}
                    <PresetTabs
                      presets={predefinedPresets}
                      userPresets={userPresets}
                      onPresetSelect={handlePresetSelect}
                      onApplyPreset={handleApplyPreset}
                      onEditPreset={handleEditPreset}
                      selectedPreset={selectedPreset}
                      applyingPresetId={applyingPreset}
                      device={device}
                    />
                  </div>
                </div>
              )}

              {(currentView === 'create' || currentView === 'edit') && (
                <div className="p-1 bg-transparent"> {/* ✅ FIXED: Transparent background */}
                  <PresetForm
                    device={device}
                    initialPreset={selectedPreset}
                    onSubmit={handleFormSubmit}
                    onCancel={handleFormCancel}
                    mode={currentView}
                  />
                </div>
              )}
            </>
          )}
        </div>

        {/* Fixed Footer Section */}
        {currentView === 'presets' && !loading && (
          <div className="flex-shrink-0 border-t border-space-border pt-4 mt-4">
            <div className="flex justify-between items-center">
              <div className="text-xs text-cosmic-text-muted">
                {predefinedPresets.length} predefined • {userPresets.length} custom presets
              </div>
              <Button variant="ghost" onClick={onClose}>
                Close
              </Button>
            </div>
          </div>
        )}
      </div>
    </Modal>
  );
}