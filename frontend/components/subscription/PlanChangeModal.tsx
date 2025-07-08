// components/subscription/PlanChangeModal.tsx
'use client';

import { useState, useEffect } from 'react';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { useSubscription } from '@/contexts/SubscriptionContext';
import { 
  Plan, 
  PlanChangePreview, 
  PlanChangeRequest,
  DeviceSelectionData,
  ChangeStrategy 
} from '@/types/subscription';
import { subscriptionUtils } from '@/lib/api';
import { 
  ArrowRight, 
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
  X
} from 'lucide-react';
import { cn } from '@/lib/utils';

type ModalStep = 'plan_selection' | 'preview' | 'strategy' | 'device_selection' | 'confirmation' | 'processing' | 'success';

interface PlanChangeModalProps {
  isOpen: boolean;
  onClose: () => void;
  onComplete?: () => void;
  preselectedPlan?: Plan | undefined;
}

export function PlanChangeModal({ 
  isOpen, 
  onClose, 
  onComplete,
  preselectedPlan 
}: PlanChangeModalProps) {
  const { 
    subscription, 
    plans, 
    previewPlanChange, 
    changePlan, 
    getDevicesForSelection,
    loading: contextLoading 
  } = useSubscription();

  const [currentStep, setCurrentStep] = useState<ModalStep>('plan_selection');
  const [selectedPlan, setSelectedPlan] = useState<Plan | undefined>(preselectedPlan || undefined);
  const [selectedInterval, setSelectedInterval] = useState<'month' | 'year'>('month');
  const [preview, setPreview] = useState<PlanChangePreview | null>(null);
  const [selectedStrategy, setSelectedStrategy] = useState<ChangeStrategy | null>(null);
  const [selectedDevices, setSelectedDevices] = useState<number[]>([]);
  const [availableDevices, setAvailableDevices] = useState<DeviceSelectionData[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Reset state when modal opens/closes
  useEffect(() => {
    if (isOpen) {
      setCurrentStep(preselectedPlan ? 'preview' : 'plan_selection');
      setSelectedPlan(preselectedPlan || undefined);
      setSelectedInterval('month');
      setPreview(null);
      setSelectedStrategy(null);
      setSelectedDevices([]);
      setAvailableDevices([]);
      setError(null);
    }
  }, [isOpen, preselectedPlan]);

  // Auto-preview when plan is selected
  useEffect(() => {
    if (selectedPlan && currentStep === 'preview') {
      handlePreviewChange();
    }
  }, [selectedPlan, selectedInterval, currentStep]);

  const handlePreviewChange = async () => {
    if (!selectedPlan) return;

    setLoading(true);
    setError(null);

    try {
      const previewData = await previewPlanChange(selectedPlan.id, selectedInterval);
      setPreview(previewData);
      
      // Auto-select recommended strategy
      const recommendedStrategy = previewData.available_strategies.find(s => s.recommended);
      if (recommendedStrategy) {
        setSelectedStrategy(recommendedStrategy);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to preview plan change');
    } finally {
      setLoading(false);
    }
  };

  const handleStrategySelect = async (strategy: ChangeStrategy) => {
    setSelectedStrategy(strategy);
    
    if (strategy.type === 'immediate_with_selection') {
      setLoading(true);
      try {
        const devices = await getDevicesForSelection();
        setAvailableDevices(devices);
        setSelectedDevices([]);
        setCurrentStep('device_selection');
        
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load devices');
      } finally {
        setLoading(false);
      }
    } else {
      setCurrentStep('confirmation');
    }
  };

  const handleConfirmChange = async () => {
    if (!selectedPlan || !selectedStrategy || !preview) return;

    setCurrentStep('processing');
    setLoading(true);

    try {
      const request: PlanChangeRequest = {
        plan_id: selectedPlan.id,
        interval: selectedInterval,
        strategy: selectedStrategy.type,
        selected_device_ids: selectedStrategy.type === 'immediate_with_selection' ? selectedDevices : undefined
      };

      await changePlan(request);
      setCurrentStep('success');
      
      // Auto-close after success
      setTimeout(() => {
        onComplete?.();
        onClose();
      }, 3000);
      
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to change plan');
      setCurrentStep('confirmation');
    } finally {
      setLoading(false);
    }
  };

  const getModalTitle = () => {
    switch (currentStep) {
      case 'plan_selection': return 'Change Your Plan';
      case 'preview': return 'Plan Change Preview';
      case 'strategy': return 'Choose Change Strategy';
      case 'device_selection': return 'Select Devices to Keep';
      case 'confirmation': return 'Confirm Plan Change';
      case 'processing': return 'Processing Change...';
      case 'success': return 'Plan Changed Successfully!';
      default: return 'Change Plan';
    }
  };

  const canProceed = () => {
    switch (currentStep) {
      case 'plan_selection': return selectedPlan && selectedPlan.id !== subscription?.plan.id;
      case 'preview': return preview && !loading;
      case 'strategy': return selectedStrategy;
      case 'device_selection': 
        return selectedDevices.length === (preview?.device_impact.target_device_limit || 0);
      case 'confirmation': return true;
      default: return false;
    }
  };

  const handleNext = () => {
    switch (currentStep) {
      case 'plan_selection':
        setCurrentStep('preview');
        break;
      case 'preview':
        setCurrentStep('strategy');
        break;
      case 'strategy':
        if (selectedStrategy?.type === 'immediate_with_selection') {
          handleStrategySelect(selectedStrategy);
        } else {
          setCurrentStep('confirmation');
        }
        break;
      case 'device_selection':
        setCurrentStep('confirmation');
        break;
      case 'confirmation':
        handleConfirmChange();
        break;
    }
  };

  const handleBack = () => {
    switch (currentStep) {
      case 'preview':
        setCurrentStep('plan_selection');
        break;
      case 'strategy':
        setCurrentStep('preview');
        break;
      case 'device_selection':
        setCurrentStep('strategy');
        break;
      case 'confirmation':
        if (selectedStrategy?.type === 'immediate_with_selection') {
          setCurrentStep('device_selection');
        } else {
          setCurrentStep('strategy');
        }
        break;
    }
  };

  if (!subscription) {
    return null;
  }

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={getModalTitle()}
      size="lg"
      className="max-h-[90vh] flex flex-col" // ✅ FIXED: Add flex layout
    >
      {/* ✅ FIXED: Proper scrollable structure matching PresetModal */}
      <div className="flex flex-col h-full max-h-[80vh]">
        
        {/* ✅ FIXED: Fixed Header Section */}
        <div className="flex-shrink-0 space-y-4">
          {/* Progress Indicator */}
          <div className="flex items-center space-x-2 text-sm">
            {['plan_selection', 'preview', 'strategy', 'confirmation'].map((step, index) => (
              <div key={step} className="flex items-center">
                <div className={cn(
                  'w-8 h-8 rounded-full flex items-center justify-center text-xs font-medium',
                  currentStep === step 
                    ? 'bg-stellar-accent text-cosmic-text' 
                    : ['plan_selection', 'preview', 'strategy', 'confirmation'].indexOf(currentStep) > index
                    ? 'bg-green-500 text-white'
                    : 'bg-space-secondary text-cosmic-text-muted'
                )}>
                  {['plan_selection', 'preview', 'strategy', 'confirmation'].indexOf(currentStep) > index ? (
                    <CheckCircle size={16} />
                  ) : (
                    index + 1
                  )}
                </div>
                {index < 3 && (
                  <ArrowRight size={16} className="mx-2 text-cosmic-text-muted" />
                )}
              </div>
            ))}
          </div>

          {/* Error Display */}
          {error && (
            <div className="bg-red-500/10 border border-red-500/20 rounded-lg p-4">
              <div className="flex items-center space-x-2">
                <AlertTriangle size={16} className="text-red-400" />
                <p className="text-red-400 text-sm">{error}</p>
              </div>
            </div>
          )}
        </div>

        {/* ✅ FIXED: Scrollable Content Area with transparent background */}
        <div className="flex-1 overflow-y-auto min-h-0 bg-transparent">
          <div className="p-1 bg-transparent"> {/* ✅ FIXED: Consistent padding and background */}
            {/* Step Content */}
            {currentStep === 'plan_selection' && (
              <PlanSelectionStep
                plans={plans}
                currentPlan={subscription.plan}
                selectedPlan={selectedPlan}
                selectedInterval={selectedInterval}
                onPlanSelect={setSelectedPlan}
                onIntervalChange={setSelectedInterval}
              />
            )}

            {currentStep === 'preview' && preview && (
              <PreviewStep
                preview={preview}
                selectedPlan={selectedPlan!}
                selectedInterval={selectedInterval}
                loading={loading}
              />
            )}

            {currentStep === 'strategy' && preview && (
              <StrategyStep
                strategies={preview.available_strategies}
                selectedStrategy={selectedStrategy}
                onStrategySelect={setSelectedStrategy}
                preview={preview}
              />
            )}

            {currentStep === 'device_selection' && (
              <DeviceSelectionStep
                devices={availableDevices}
                selectedDevices={selectedDevices}
                onDevicesChange={setSelectedDevices}
                targetLimit={preview?.device_impact.target_device_limit || 0}
              />
            )}

            {currentStep === 'confirmation' && preview && selectedStrategy && (
              <ConfirmationStep
                preview={preview}
                selectedPlan={selectedPlan!}
                selectedInterval={selectedInterval}
                selectedStrategy={selectedStrategy}
                selectedDevices={selectedDevices}
                availableDevices={availableDevices}
              />
            )}

            {currentStep === 'processing' && (
              <ProcessingStep />
            )}

            {currentStep === 'success' && (
              <SuccessStep
                selectedPlan={selectedPlan!}
                selectedStrategy={selectedStrategy!}
              />
            )}
          </div>
        </div>

        {/* ✅ FIXED: Fixed Footer Section */}
        {!['processing', 'success'].includes(currentStep) && (
          <div className="flex-shrink-0 border-t border-space-border pt-4 mt-4">
            <div className="flex space-x-3">
              <Button
                variant="ghost"
                onClick={currentStep === 'plan_selection' ? onClose : handleBack}
                disabled={loading}
                className="flex-1"
              >
                {currentStep === 'plan_selection' ? 'Cancel' : 'Back'}
              </Button>
              
              <Button
                variant="cosmic"
                onClick={handleNext}
                disabled={!canProceed() || loading}
                className="flex-1"
              >
                {loading ? (
                  <>
                    <LoadingSpinner size="sm" />
                    <span className="ml-2">Loading...</span>
                  </>
                ) : currentStep === 'confirmation' ? (
                  'Confirm Change'
                ) : (
                  'Continue'
                )}
              </Button>
            </div>
          </div>
        )}
      </div>
    </Modal>
  );
}

// Import the step components
import {
  PlanSelectionStep,
  PreviewStep,
  StrategyStep,
  DeviceSelectionStep,
  ConfirmationStep,
  ProcessingStep,
  SuccessStep
} from './PlanChangeSteps';

export default PlanChangeModal;