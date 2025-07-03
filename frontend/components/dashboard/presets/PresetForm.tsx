// components/dashboard/PresetForm.tsx
'use client';

import { useState, useEffect } from 'react';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Device } from '@/types/device';
import { Preset, CreatePresetData, EnvironmentalMonitorSettings, LiquidMonitorSettings } from '@/types/preset';
import { Clock, Lightbulb, Droplets, Zap } from 'lucide-react';
import { cn } from '@/lib/utils';

interface PresetFormProps {
  device: Device;
  initialPreset?: Preset | null;
  onSubmit: (data: CreatePresetData) => void;
  onCancel: () => void;
  mode: 'create' | 'edit';
}

export function PresetForm({ device, initialPreset, onSubmit, onCancel, mode }: PresetFormProps) {
  const [name, setName] = useState(initialPreset?.name || '');
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  const isEnvironmentalMonitor = device.device_type?.includes('Environmental Monitor');
  const isLiquidMonitor = device.device_type?.includes('Liquid Monitor');

  // Environmental Monitor Settings
  const [lightsOnAt, setLightsOnAt] = useState('08:00');
  const [lightsOffAt, setLightsOffAt] = useState('20:00');
  const [sprayOnFor, setSprayOnFor] = useState(10);
  const [sprayOffFor, setSprayOffFor] = useState(30);

  // Liquid Monitor Settings
  const [pump1Duration, setPump1Duration] = useState(0);
  const [pump2Duration, setPump2Duration] = useState(0);
  const [pump3Duration, setPump3Duration] = useState(0);
  const [pump4Duration, setPump4Duration] = useState(0);
  const [pump5Duration, setPump5Duration] = useState(0);

  // Initialize form with existing preset data
  useEffect(() => {
    if (initialPreset && mode === 'edit') {
      setName(initialPreset.name);
      
      if (isEnvironmentalMonitor) {
        const settings = initialPreset.settings as EnvironmentalMonitorSettings;
        if (settings.lights) {
          setLightsOnAt(settings.lights.on_at.replace('hrs', ''));
          setLightsOffAt(settings.lights.off_at.replace('hrs', ''));
        }
        if (settings.spray) {
          setSprayOnFor(settings.spray.on_for);
          setSprayOffFor(settings.spray.off_for);
        }
      } else if (isLiquidMonitor) {
        const settings = initialPreset.settings as LiquidMonitorSettings;
        setPump1Duration(settings.pump1?.duration || 0);
        setPump2Duration(settings.pump2?.duration || 0);
        setPump3Duration(settings.pump3?.duration || 0);
        setPump4Duration(settings.pump4?.duration || 0);
        setPump5Duration(settings.pump5?.duration || 0);
      }
    }
  }, [initialPreset, mode, isEnvironmentalMonitor, isLiquidMonitor]);

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    // Validate name
    if (!name.trim()) {
      newErrors.name = 'Preset name is required';
    } else if (name.length < 3) {
      newErrors.name = 'Preset name must be at least 3 characters';
    }

    // Validate Environmental Monitor settings
    if (isEnvironmentalMonitor) {
      // Validate light times
      const onTime = new Date(`2000-01-01T${lightsOnAt}:00`);
      const offTime = new Date(`2000-01-01T${lightsOffAt}:00`);
      
      if (onTime >= offTime) {
        newErrors.lights = 'Lights on time must be before lights off time';
      }

      // Validate spray settings
      if (sprayOnFor <= 0) {
        newErrors.sprayOnFor = 'Spray on time must be greater than 0';
      }
      if (sprayOffFor <= 0) {
        newErrors.sprayOffFor = 'Spray off time must be greater than 0';
      }
    }

    // Validate Liquid Monitor settings
    if (isLiquidMonitor) {
      const totalPumps = [pump1Duration, pump2Duration, pump3Duration, pump4Duration, pump5Duration]
        .filter(duration => duration > 0).length;
      
      if (totalPumps === 0) {
        newErrors.pumps = 'At least one pump must have a duration greater than 0';
      }
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) return;

    setLoading(true);

    try {
      const data: CreatePresetData = {
        name: name.trim(),
        device_id: device.id,
        settings: {}
      };

      // Build settings based on device type
      if (isEnvironmentalMonitor) {
        data.settings = {
          lights: {
            on_at: `${lightsOnAt}hrs`,
            off_at: `${lightsOffAt}hrs`
          },
          spray: {
            on_for: sprayOnFor,
            off_for: sprayOffFor
          }
        } as EnvironmentalMonitorSettings;
      } else if (isLiquidMonitor) {
        data.settings = {
          pump1: { duration: pump1Duration },
          pump2: { duration: pump2Duration },
          pump3: { duration: pump3Duration },
          pump4: { duration: pump4Duration },
          pump5: { duration: pump5Duration }
        } as LiquidMonitorSettings;
      }

      await onSubmit(data);
    } catch (error) {
      console.error('Form submission error:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* Form Header */}
      <div className="text-center">
        <h3 className="text-lg font-semibold text-cosmic-text mb-2">
          {mode === 'create' ? 'Create Custom Preset' : 'Edit Preset'}
        </h3>
        <p className="text-cosmic-text-muted text-sm">
          Configure custom settings for your {device.device_type}
        </p>
      </div>

      {/* Preset Name */}
      <Input
        label="Preset Name"
        value={name}
        onChange={(e) => setName(e.target.value)}
        placeholder="Enter a descriptive name"
        error={errors.name}
        required
      />

      {/* Environmental Monitor Settings */}
      {isEnvironmentalMonitor && (
        <div className="space-y-4">
          <h4 className="flex items-center space-x-2 text-cosmic-text font-medium">
            <Lightbulb size={16} className="text-yellow-400" />
            <span>Lighting Schedule</span>
          </h4>
          
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-cosmic-text mb-2">
                Lights On At
              </label>
              <input
                type="time"
                value={lightsOnAt}
                onChange={(e) => setLightsOnAt(e.target.value)}
                className="w-full px-3 py-2 bg-space-secondary border border-space-border rounded-lg text-cosmic-text focus:outline-none focus:ring-2 focus:ring-stellar-accent"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-cosmic-text mb-2">
                Lights Off At
              </label>
              <input
                type="time"
                value={lightsOffAt}
                onChange={(e) => setLightsOffAt(e.target.value)}
                className="w-full px-3 py-2 bg-space-secondary border border-space-border rounded-lg text-cosmic-text focus:outline-none focus:ring-2 focus:ring-stellar-accent"
              />
            </div>
          </div>
          
          {errors.lights && (
            <p className="text-red-400 text-sm">{errors.lights}</p>
          )}

          <h4 className="flex items-center space-x-2 text-cosmic-text font-medium mt-6">
            <Droplets size={16} className="text-blue-400" />
            <span>Spray Cycle</span>
          </h4>
          
          <div className="grid grid-cols-2 gap-4">
            <Input
              label="Spray On Duration (seconds)"
              type="number"
              value={sprayOnFor}
              onChange={(e) => setSprayOnFor(parseInt(e.target.value) || 0)}
              min={1}
              max={300}
              error={errors.sprayOnFor}
            />
            
            <Input
              label="Spray Off Duration (seconds)"
              type="number"
              value={sprayOffFor}
              onChange={(e) => setSprayOffFor(parseInt(e.target.value) || 0)}
              min={1}
              max={3600}
              error={errors.sprayOffFor}
            />
          </div>
        </div>
      )}

      {/* Liquid Monitor Settings */}
      {isLiquidMonitor && (
        <div className="space-y-4">
          <h4 className="flex items-center space-x-2 text-cosmic-text font-medium">
            <Zap size={16} className="text-purple-400" />
            <span>Pump Durations</span>
          </h4>
          
          <div className="grid grid-cols-2 gap-4">
            {[1, 2, 3, 4, 5].map((pumpNum) => {
              const value = pumpNum === 1 ? pump1Duration :
                           pumpNum === 2 ? pump2Duration :
                           pumpNum === 3 ? pump3Duration :
                           pumpNum === 4 ? pump4Duration : pump5Duration;
              
              const setValue = pumpNum === 1 ? setPump1Duration :
                              pumpNum === 2 ? setPump2Duration :
                              pumpNum === 3 ? setPump3Duration :
                              pumpNum === 4 ? setPump4Duration : setPump5Duration;

              return (
                <Input
                  key={pumpNum}
                  label={`Pump ${pumpNum} Duration (seconds)`}
                  type="number"
                  value={value}
                  onChange={(e) => setValue(parseInt(e.target.value) || 0)}
                  min={0}
                  max={300}
                  helperText={value === 0 ? 'Pump disabled' : `${value}s dose`}
                />
              );
            })}
          </div>
          
          {errors.pumps && (
            <p className="text-red-400 text-sm">{errors.pumps}</p>
          )}
        </div>
      )}

      {/* Form Actions */}
      <div className="flex space-x-3 pt-4 border-t border-space-border">
        <Button
          type="button"
          variant="ghost"
          onClick={onCancel}
          disabled={loading}
          className="flex-1"
        >
          Cancel
        </Button>
        
        <Button
          type="submit"
          variant="cosmic"
          disabled={loading}
          className="flex-1"
        >
          {loading ? 'Saving...' : mode === 'create' ? 'Create Preset' : 'Update Preset'}
        </Button>
      </div>
    </form>
  );
}