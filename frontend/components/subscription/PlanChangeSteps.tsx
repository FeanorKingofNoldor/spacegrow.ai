// components/subscription/PlanChangeSteps.tsx
'use client';

import { Button } from '@/components/ui/Button';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { 
  Plan, 
  PlanChangePreview, 
  DeviceSelectionData,
  ChangeStrategy 
} from '@/types/subscription';
import { subscriptionUtils } from '@/lib/api';
import { 
  TrendingUp, 
  TrendingDown, 
  AlertTriangle, 
  CheckCircle,
  Calendar,
  DollarSign,
  Users,
  Settings,
  Clock,
  Zap,
  Wifi,
  WifiOff,
  Star,
  Shield,
  Activity
} from 'lucide-react';
import { cn } from '@/lib/utils';

// Step 1: Plan Selection
interface PlanSelectionStepProps {
  plans: Plan[];
  currentPlan: Plan;
  selectedPlan: Plan | undefined;
  selectedInterval: 'month' | 'year';
  onPlanSelect: (plan: Plan) => void;
  onIntervalChange: (interval: 'month' | 'year') => void;
}

export function PlanSelectionStep({
  plans,
  currentPlan,
  selectedPlan,
  selectedInterval,
  onPlanSelect,
  onIntervalChange
}: PlanSelectionStepProps) {
  return (
    <div className="space-y-6">
      {/* Current Plan Info */}
      <div className="bg-space-secondary rounded-xl p-4">
        <div className="flex items-center space-x-3">
          <div className="w-10 h-10 bg-gradient-cosmic rounded-lg flex items-center justify-center">
            <Star size={20} className="text-white" />
          </div>
          <div>
            <h4 className="font-semibold text-cosmic-text">Current Plan: {currentPlan.name}</h4>
            <p className="text-cosmic-text-muted text-sm">
              ${currentPlan.monthly_price}/month • {currentPlan.device_limit} devices
            </p>
          </div>
        </div>
      </div>

      {/* Billing Interval Toggle */}
      <div className="flex justify-center">
        <div className="bg-space-secondary rounded-lg p-1">
          <button
            onClick={() => onIntervalChange('month')}
            className={cn(
              'px-4 py-2 rounded-md text-sm font-medium transition-all',
              selectedInterval === 'month'
                ? 'bg-stellar-accent text-cosmic-text'
                : 'text-cosmic-text-muted hover:text-cosmic-text'
            )}
          >
            Monthly
          </button>
          <button
            onClick={() => onIntervalChange('year')}
            className={cn(
              'px-4 py-2 rounded-md text-sm font-medium transition-all relative',
              selectedInterval === 'year'
                ? 'bg-stellar-accent text-cosmic-text'
                : 'text-cosmic-text-muted hover:text-cosmic-text'
            )}
          >
            Yearly
            <span className="absolute -top-1 -right-1 bg-green-500 text-white text-xs px-1.5 py-0.5 rounded-full">
              20% OFF
            </span>
          </button>
        </div>
      </div>

      {/* Plan Cards */}
      <div className="grid gap-4">
        {plans.map((plan) => {
          const isSelected = selectedPlan?.id === plan.id;
          const isCurrent = currentPlan.id === plan.id;
          const price = selectedInterval === 'month' ? plan.monthly_price : plan.yearly_price;
          const period = selectedInterval === 'month' ? 'month' : 'year';
          
          const changeType = plan.device_limit > currentPlan.device_limit ? 'upgrade' :
                           plan.device_limit < currentPlan.device_limit ? 'downgrade' : 'same';

          return (
            <div
              key={plan.id}
              onClick={() => !isCurrent && onPlanSelect(plan)}
              className={cn(
                'rounded-xl p-4 border transition-all duration-200 cursor-pointer',
                isSelected 
                  ? 'border-stellar-accent bg-stellar-accent/10' 
                  : isCurrent
                  ? 'border-space-border bg-space-secondary cursor-not-allowed opacity-60'
                  : 'border-space-border hover:border-stellar-accent/50 bg-space-glass backdrop-blur-md'
              )}
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <div className="w-12 h-12 bg-gradient-cosmic rounded-lg flex items-center justify-center">
                    {changeType === 'upgrade' ? (
                      <TrendingUp size={24} className="text-white" />
                    ) : changeType === 'downgrade' ? (
                      <TrendingDown size={24} className="text-white" />
                    ) : (
                      <Shield size={24} className="text-white" />
                    )}
                  </div>
                  <div>
                    <h3 className="font-semibold text-cosmic-text flex items-center space-x-2">
                      <span>{plan.name}</span>
                      {isCurrent && (
                        <span className="px-2 py-1 bg-green-500/20 text-green-400 text-xs rounded-full">
                          Current
                        </span>
                      )}
                    </h3>
                    <p className="text-cosmic-text-muted text-sm">
                      {plan.device_limit} devices • {plan.features.length} features
                    </p>
                  </div>
                </div>
                
                <div className="text-right">
                  <div className="text-xl font-bold text-cosmic-text">
                    ${price}
                  </div>
                  <div className="text-cosmic-text-muted text-sm">
                    /{period}
                  </div>
                </div>
              </div>

              {/* Change indicator */}
              {!isCurrent && (
                <div className="mt-3 pt-3 border-t border-space-border">
                  <div className={cn(
                    'text-sm font-medium',
                    changeType === 'upgrade' ? 'text-green-400' : 'text-orange-400'
                  )}>
                    {changeType === 'upgrade' 
                      ? `↗️ Upgrade (+${plan.device_limit - currentPlan.device_limit} devices)`
                      : `↘️ Downgrade (${currentPlan.device_limit - plan.device_limit} devices less)`
                    }
                  </div>
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}

// Step 2: Preview
interface PreviewStepProps {
  preview: PlanChangePreview;
  selectedPlan: Plan;
  selectedInterval: 'month' | 'year';
  loading: boolean;
}

export function PreviewStep({ preview, selectedPlan, selectedInterval, loading }: PreviewStepProps) {
  if (loading) {
    return (
      <div className="flex items-center justify-center py-8">
        <LoadingSpinner size="lg" text="Analyzing plan change..." />
      </div>
    );
  }

  const { current_plan, target_plan, device_impact, billing_impact, warnings } = preview;

  return (
    <div className="space-y-6">
      {/* Change Summary */}
      <div className="bg-space-secondary rounded-xl p-6">
        <h3 className="font-semibold text-cosmic-text mb-4 flex items-center">
          <DollarSign size={20} className="mr-2 text-cosmic-blue" />
          Plan Change Summary
        </h3>
        
        <div className="grid md:grid-cols-2 gap-6">
          {/* Current Plan */}
          <div>
            <h4 className="text-sm text-cosmic-text-muted mb-2">From</h4>
            <div className="bg-space-border/50 rounded-lg p-3">
              <div className="font-medium text-cosmic-text">
                {current_plan?.name || 'No Plan'}
              </div>
              <div className="text-cosmic-text-muted text-sm">
                ${current_plan?.monthly_price || 0}/month • {current_plan?.devices_used || 0}/{current_plan?.device_limit || 0} devices
              </div>
            </div>
          </div>

          {/* Target Plan */}
          <div>
            <h4 className="text-sm text-cosmic-text-muted mb-2">To</h4>
            <div className="bg-stellar-accent/20 rounded-lg p-3">
              <div className="font-medium text-cosmic-text">
                {target_plan.name}
              </div>
              <div className="text-cosmic-text-muted text-sm">
                ${selectedInterval === 'month' ? target_plan.monthly_price : Math.round(target_plan.yearly_price / 12)}/month • {target_plan.device_limit} devices
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Device Impact */}
      {device_impact.requires_device_selection && (
        <div className="bg-orange-500/10 border border-orange-500/20 rounded-xl p-6">
          <h3 className="font-semibold text-orange-400 mb-4 flex items-center">
            <AlertTriangle size={20} className="mr-2" />
            Device Impact
          </h3>
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-cosmic-text">Current devices:</span>
              <span className="font-medium text-cosmic-text">{device_impact.current_device_count}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-cosmic-text">New limit:</span>
              <span className="font-medium text-cosmic-text">{device_impact.target_device_limit}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-orange-400">Excess devices:</span>
              <span className="font-medium text-orange-400">{device_impact.excess_device_count}</span>
            </div>
            <p className="text-orange-300 text-sm mt-3">
              You'll need to choose which {device_impact.target_device_limit} devices to keep active.
            </p>
          </div>
        </div>
      )}

      {/* Billing Impact */}
      <div className="bg-space-secondary rounded-xl p-6">
        <h3 className="font-semibold text-cosmic-text mb-4 flex items-center">
          <DollarSign size={20} className="mr-2 text-green-400" />
          Billing Impact
        </h3>
        
        <div className="grid md:grid-cols-2 gap-6">
          <div>
            <div className="text-sm text-cosmic-text-muted mb-1">Current Monthly Cost</div>
            <div className="text-xl font-bold text-cosmic-text">
              ${(Number(billing_impact.current_monthly_cost) || 0).toFixed(2)}
            </div>
          </div>
          <div>
            <div className="text-sm text-cosmic-text-muted mb-1">New Monthly Cost</div>
            <div className="text-xl font-bold text-cosmic-text">
              ${(Number(billing_impact.target_monthly_cost) || 0).toFixed(2)}
            </div>
          </div>
        </div>
        
        <div className="mt-4 pt-4 border-t border-space-border">
          <div className="flex items-center justify-between">
            <span className="text-cosmic-text">Monthly difference:</span>
            <span className={cn(
              "font-semibold",
              billing_impact.cost_difference >= 0 ? "text-red-400" : "text-green-400"
            )}>
              {billing_impact.cost_difference >= 0 ? '+' : ''}${(Number(billing_impact.cost_difference) || 0).toFixed(2)}
            </span>
          </div>
          {billing_impact.cost_difference < 0 && (
            <p className="text-green-400 text-sm mt-2">
              💰 You'll save ${Math.abs(Number(billing_impact.cost_difference) || 0).toFixed(2)}/month with this change!
            </p>
          )}
        </div>
      </div>

      {/* Warnings */}
      {warnings.length > 0 && (
        <div className="bg-yellow-500/10 border border-yellow-500/20 rounded-xl p-4">
          <h4 className="font-medium text-yellow-400 mb-2">Important Notes:</h4>
          <ul className="space-y-1">
            {warnings.map((warning, index) => (
              <li key={index} className="text-yellow-300 text-sm flex items-start">
                <span className="mr-2">•</span>
                <span>{warning}</span>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}

// Step 3: Strategy Selection
interface StrategyStepProps {
  strategies: ChangeStrategy[];
  selectedStrategy: ChangeStrategy | null;
  onStrategySelect: (strategy: ChangeStrategy) => void;
  preview: PlanChangePreview;
}

export function StrategyStep({ strategies, selectedStrategy, onStrategySelect, preview }: StrategyStepProps) {
  return (
    <div className="space-y-4">
      <div className="text-center mb-6">
        <h3 className="text-lg font-semibold text-cosmic-text mb-2">
          How would you like to proceed?
        </h3>
        <p className="text-cosmic-text-muted">
          Choose the best approach for your plan change
        </p>
      </div>

      {strategies.map((strategy, index) => {
        const isSelected = selectedStrategy?.type === strategy.type;
        const isRecommended = strategy.recommended;
        
        const getStrategyIcon = (type: string) => {
          switch (type) {
            case 'immediate': return Zap;
            case 'immediate_with_selection': return Users;
            case 'end_of_period': return Calendar;
            case 'pay_for_extra': return DollarSign;
            default: return Settings;
          }
        };

        const StrategyIcon = getStrategyIcon(strategy.type);

        return (
          <div
            key={strategy.type}
            onClick={() => onStrategySelect(strategy)}
            className={cn(
              'rounded-xl p-4 border transition-all duration-200 cursor-pointer relative',
              isSelected 
                ? 'border-stellar-accent bg-stellar-accent/10' 
                : 'border-space-border hover:border-stellar-accent/50 bg-space-glass backdrop-blur-md'
            )}
          >
            {/* Recommended Badge */}
            {isRecommended && (
              <div className="absolute -top-2 -right-2">
                <div className="bg-green-500 text-white text-xs px-2 py-1 rounded-full flex items-center">
                  <Star size={12} className="mr-1" />
                  Recommended
                </div>
              </div>
            )}

            <div className="flex items-start space-x-4">
              <div className="w-12 h-12 bg-gradient-cosmic rounded-lg flex items-center justify-center flex-shrink-0">
                <StrategyIcon size={24} className="text-white" />
              </div>
              
              <div className="flex-1">
                <h4 className="font-semibold text-cosmic-text mb-1">
                  {strategy.name}
                </h4>
                <p className="text-cosmic-text-muted text-sm mb-2">
                  {strategy.description}
                </p>
                
                {/* Extra cost indicator */}
                {strategy.extra_monthly_cost && strategy.extra_monthly_cost > 0 && (
                  <div className="text-orange-400 text-sm font-medium">
                    +${strategy.extra_monthly_cost}/month additional cost
                  </div>
                )}
              </div>

              {/* Selection indicator */}
              <div className={cn(
                'w-6 h-6 rounded-full border-2 flex items-center justify-center',
                isSelected 
                  ? 'border-stellar-accent bg-stellar-accent' 
                  : 'border-space-border'
              )}>
                {isSelected && <CheckCircle size={16} className="text-cosmic-text" />}
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}

// In PlanChangeSteps.tsx - REPLACE the DeviceSelectionStep component

// Step 4: Device Selection (SIMPLIFIED)
interface DeviceSelectionStepProps {
  devices: DeviceSelectionData[];
  selectedDevices: number[];
  onDevicesChange: (deviceIds: number[]) => void;
  targetLimit: number;
}

export function DeviceSelectionStep({ 
  devices, 
  selectedDevices, 
  onDevicesChange, 
  targetLimit 
}: DeviceSelectionStepProps) {
  const handleDeviceToggle = (deviceId: number) => {
    const isSelected = selectedDevices.includes(deviceId);
    
    if (isSelected) {
      onDevicesChange(selectedDevices.filter(id => id !== deviceId));
    } else if (selectedDevices.length < targetLimit) {
      onDevicesChange([...selectedDevices, deviceId]);
    }
  };

  return (
    <div className="space-y-6">
      <div className="text-center">
        <h3 className="text-lg font-semibold text-cosmic-text mb-2">
          Choose {targetLimit} devices to keep active
        </h3>
        <p className="text-cosmic-text-muted">
          Selected: {selectedDevices.length}/{targetLimit}
        </p>
      </div>

      {/* ✅ SIMPLIFIED: Just a clean list of devices */}
      <div className="space-y-3">
        {devices.map(device => (
          <DeviceSelectionCard
            key={device.id}
            device={device}
            isSelected={selectedDevices.includes(device.id)}
            onToggle={() => handleDeviceToggle(device.id)}
            disabled={!selectedDevices.includes(device.id) && selectedDevices.length >= targetLimit}
          />
        ))}
      </div>
    </div>
  );
}

// ✅ SIMPLIFIED: Clean device selection card
interface DeviceSelectionCardProps {
  device: DeviceSelectionData;
  isSelected: boolean;
  onToggle: () => void;
  disabled: boolean;
}

function DeviceSelectionCard({ device, isSelected, onToggle, disabled }: DeviceSelectionCardProps) {
  return (
    <div
      onClick={disabled ? undefined : onToggle}
      className={cn(
        'rounded-lg p-4 border transition-all duration-200 cursor-pointer',
        isSelected 
          ? 'border-stellar-accent bg-stellar-accent/10' 
          : 'border-space-border bg-space-secondary',
        disabled ? 'opacity-50 cursor-not-allowed' : 'hover:border-stellar-accent/50'
      )}
    >
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-3">
          <div className="w-10 h-10 bg-gradient-cosmic rounded-lg flex items-center justify-center">
            <Settings size={20} className="text-white" />
          </div>
          
          <div>
            <h4 className="font-medium text-cosmic-text">{device.name}</h4>
            <p className="text-cosmic-text-muted text-sm">Device ID: {device.id}</p>
          </div>
        </div>

        {/* Selection Checkbox */}
        <div className={cn(
          'w-6 h-6 rounded border-2 flex items-center justify-center',
          isSelected 
            ? 'border-stellar-accent bg-stellar-accent' 
            : 'border-space-border'
        )}>
          {isSelected && <CheckCircle size={16} className="text-cosmic-text" />}
        </div>
      </div>
    </div>
  );
}

// Step 5: Confirmation
// In PlanChangeSteps.tsx - REPLACE the ConfirmationStep component

// Step 5: Confirmation (SIMPLIFIED)
interface ConfirmationStepProps {
  preview: PlanChangePreview;
  selectedPlan: Plan;
  selectedInterval: 'month' | 'year';
  selectedStrategy: ChangeStrategy;
  selectedDevices: number[];
  availableDevices: DeviceSelectionData[];
}

export function ConfirmationStep({
  preview,
  selectedPlan,
  selectedInterval,
  selectedStrategy,
  selectedDevices,
  availableDevices
}: ConfirmationStepProps) {
  // ✅ SIMPLIFIED: Just basic filtering by selected IDs
  const devicesToKeep = availableDevices.filter(d => selectedDevices.includes(d.id));
  const devicesTosuspend = availableDevices.filter(d => !selectedDevices.includes(d.id));

  return (
    <div className="space-y-6">
      <div className="text-center">
        <h3 className="text-lg font-semibold text-cosmic-text mb-2">
          Confirm Your Plan Change
        </h3>
        <p className="text-cosmic-text-muted">
          Review the details before proceeding
        </p>
      </div>

      {/* Plan Change Summary */}
      <div className="bg-space-secondary rounded-xl p-6">
        <h4 className="font-semibold text-cosmic-text mb-4">Plan Change Details</h4>
        
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-cosmic-text">Current Plan:</span>
            <span className="font-medium text-cosmic-text">{preview.current_plan?.name}</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-cosmic-text">New Plan:</span>
            <span className="font-medium text-stellar-accent">{selectedPlan.name}</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-cosmic-text">Billing:</span>
            <span className="font-medium text-cosmic-text">
              {selectedInterval === 'month' ? 'Monthly' : 'Yearly'}
            </span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-cosmic-text">Strategy:</span>
            <span className="font-medium text-cosmic-text">{selectedStrategy.name}</span>
          </div>
        </div>
      </div>

      {/* ✅ SIMPLIFIED: Device Changes (if applicable) */}
      {selectedStrategy.type === 'immediate_with_selection' && (
        <div className="bg-space-secondary rounded-xl p-6">
          <h4 className="font-semibold text-cosmic-text mb-4">Device Changes</h4>
          
          {devicesToKeep.length > 0 && (
            <div className="mb-4">
              <h5 className="text-sm font-medium text-green-400 mb-2">Devices to Keep Active:</h5>
              <div className="space-y-2">
                {devicesToKeep.map(device => (
                  <div key={device.id} className="flex items-center space-x-2 text-sm">
                    <CheckCircle size={16} className="text-green-400" />
                    <span className="text-cosmic-text">{device.name}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {devicesTosuspend.length > 0 && (
            <div>
              <h5 className="text-sm font-medium text-orange-400 mb-2">Devices to suspend:</h5>
              <div className="space-y-2">
                {devicesTosuspend.map(device => (
                  <div key={device.id} className="flex items-center space-x-2 text-sm">
                    <AlertTriangle size={16} className="text-orange-400" />
                    <span className="text-cosmic-text">{device.name}</span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {/* Billing Impact - Keep this unchanged */}
      <div className="bg-space-secondary rounded-xl p-6">
        <h4 className="font-semibold text-cosmic-text mb-4">Billing Impact</h4>
        
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-cosmic-text">New Monthly Cost:</span>
            <span className="font-medium text-cosmic-text">
              ${(Number(preview.billing_impact.target_monthly_cost) || 0).toFixed(2)}
            </span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-cosmic-text">Monthly Change:</span>
            <span className={cn(
              "font-medium",
              preview.billing_impact.cost_difference >= 0 ? "text-red-400" : "text-green-400"
            )}>
              {preview.billing_impact.cost_difference >= 0 ? '+' : ''}${(Number(preview.billing_impact.cost_difference) || 0).toFixed(2)}
            </span>
          </div>
          {selectedStrategy.extra_monthly_cost && (
            <div className="flex items-center justify-between">
              <span className="text-cosmic-text">Extra Device Cost:</span>
              <span className="font-medium text-orange-400">
                +${selectedStrategy.extra_monthly_cost}/month
              </span>
            </div>
          )}
        </div>
      </div>

      {/* What Happens Next - Keep this unchanged */}
      <div className="bg-blue-500/10 border border-blue-500/20 rounded-xl p-6">
        <h4 className="font-semibold text-blue-400 mb-3">What happens next:</h4>
        <ul className="space-y-2 text-blue-300 text-sm">
          {selectedStrategy.type === 'immediate' && (
            <>
              <li>• Your plan will change immediately</li>
              <li>• Billing will be updated for your next cycle</li>
              <li>• All devices remain active</li>
            </>
          )}
          {selectedStrategy.type === 'immediate_with_selection' && (
            <>
              <li>• Your plan will change immediately</li>
              <li>• Selected devices will remain active</li>
              <li>• {devicesTosuspend.length} devices will be suspended</li>
              <li>• You can wake suspended devices later</li>
            </>
          )}
          {/* Add other strategy types as needed */}
          <li>• No refund for the current billing period</li>
        </ul>
      </div>
    </div>
  );
}

// Step 6: Processing
export function ProcessingStep() {
  return (
    <div className="text-center py-8">
      <div className="flex justify-center mb-6">
        <div className="w-16 h-16 bg-gradient-cosmic rounded-full flex items-center justify-center animate-pulse">
          <Zap size={32} className="text-white" />
        </div>
      </div>
      
      <h3 className="text-xl font-semibold text-cosmic-text mb-4">
        Processing Your Plan Change...
      </h3>
      
      <div className="space-y-4 max-w-sm mx-auto">
        <div className="flex items-center space-x-3">
          <CheckCircle size={16} className="text-green-400" />
          <span className="text-cosmic-text text-sm">Plan updated</span>
        </div>
        <div className="flex items-center space-x-3">
          <LoadingSpinner size="sm" />
          <span className="text-cosmic-text text-sm">Updating devices...</span>
        </div>
        <div className="flex items-center space-x-3">
          <Clock size={16} className="text-cosmic-text-muted" />
          <span className="text-cosmic-text-muted text-sm">Updating billing...</span>
        </div>
      </div>
      
      <p className="text-cosmic-text-muted text-sm mt-6">
        This may take a few moments...
      </p>
    </div>
  );
}

// Step 7: Success
interface SuccessStepProps {
  selectedPlan: Plan;
  selectedStrategy: ChangeStrategy;
}

export function SuccessStep({ selectedPlan, selectedStrategy }: SuccessStepProps) {
  return (
    <div className="text-center py-8">
      <div className="flex justify-center mb-6">
        <div className="w-16 h-16 bg-green-500 rounded-full flex items-center justify-center">
          <CheckCircle size={32} className="text-white" />
        </div>
      </div>
      
      <h3 className="text-xl font-semibold text-cosmic-text mb-4">
        Plan Changed Successfully! 🎉
      </h3>
      
      <p className="text-cosmic-text-muted mb-6">
        You're now on the <span className="text-stellar-accent font-medium">{selectedPlan.name}</span> plan.
      </p>
      
      <div className="bg-green-500/10 border border-green-500/20 rounded-lg p-4 max-w-sm mx-auto">
        <p className="text-green-400 text-sm">
          {selectedStrategy.type === 'end_of_period' 
            ? 'Your plan change has been scheduled and will take effect at the end of your current billing period.'
            : 'Your new plan is now active and ready to use!'
          }
        </p>
      </div>
      
      <p className="text-cosmic-text-muted text-xs mt-4">
        Redirecting to dashboard...
      </p>
    </div>
  );
}