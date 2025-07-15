// components/auth/modals/DeleteAccountModal.tsx
'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/Button';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { 
  Trash2, 
  X, 
  AlertTriangle, 
  Lock, 
  Eye, 
  EyeOff,
  Clock,
  FileText,
  CreditCard,
  Database,
  Shield
} from 'lucide-react';

interface UserProfile {
  id: number;
  email: string;
  display_name?: string;
  timezone: string;
  notification_preferences: {
    device_alerts: boolean;
    billing_notifications: boolean;
    system_updates: boolean;
  };
  two_factor_enabled: boolean;
  created_at: string;
  active_sessions_count: number;
}

interface DeleteAccountModalProps {
  isOpen: boolean;
  onClose: () => void;
  profile: UserProfile;
  onAccountDeleted: () => void;
}

export function DeleteAccountModal({ 
  isOpen, 
  onClose, 
  profile, 
  onAccountDeleted 
}: DeleteAccountModalProps) {
  const [step, setStep] = useState<'warning' | 'confirm' | 'auth' | 'deleting' | 'complete'>('warning');
  const [confirmText, setConfirmText] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [twoFactorCode, setTwoFactorCode] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const requiredConfirmText = 'DELETE MY ACCOUNT';

  const handleClose = () => {
    if (!loading) {
      setStep('warning');
      setConfirmText('');
      setPassword('');
      setTwoFactorCode('');
      setError(null);
      onClose();
    }
  };

  const handleContinue = () => {
    setStep('confirm');
  };

  const handleConfirm = () => {
    if (confirmText !== requiredConfirmText) {
      setError(`Please type "${requiredConfirmText}" exactly to confirm`);
      return;
    }
    setError(null);
    setStep('auth');
  };

  const handleAuthenticate = async () => {
    if (!password) {
      setError('Please enter your password');
      return;
    }

    if (profile.two_factor_enabled && (!twoFactorCode || twoFactorCode.length !== 6)) {
      setError('Please enter your 6-digit 2FA code');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      // TODO: Verify password and 2FA, then delete account
      // await api.auth.verifyForAccountDeletion(password, twoFactorCode);
      
      // Mock authentication
      await new Promise(resolve => setTimeout(resolve, 1500));
      
      setStep('deleting');
      await handleDeleteAccount();
      
    } catch (err) {
      setError('Authentication failed. Please check your credentials.');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteAccount = async () => {
    try {
      // TODO: API call to delete account
      // await api.auth.deleteAccount();
      
      // Mock deletion process
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      setStep('complete');
      
      // Auto-redirect after completion
      setTimeout(() => {
        onAccountDeleted();
      }, 3000);
      
    } catch (err) {
      setError('Failed to delete account. Please try again.');
      setStep('auth');
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-8 max-w-lg w-full">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-red-500/20 rounded-lg flex items-center justify-center">
              <Trash2 className="text-red-400" size={20} />
            </div>
            <h2 className="text-xl font-bold text-white">Delete Account</h2>
          </div>
          <button
            onClick={handleClose}
            disabled={loading}
            className="text-gray-400 hover:text-white transition-colors"
          >
            <X size={24} />
          </button>
        </div>

        {/* Step 1: Warning */}
        {step === 'warning' && (
          <div className="space-y-6">
            <div className="text-center">
              <div className="w-16 h-16 bg-red-500/20 rounded-full flex items-center justify-center mx-auto mb-4">
                <AlertTriangle className="text-red-400" size={32} />
              </div>
              <h3 className="text-lg font-bold text-white mb-2">This Action Cannot Be Undone</h3>
              <p className="text-gray-300 text-sm">
                Deleting your account will permanently remove all your data and cancel any active subscriptions.
              </p>
            </div>

            <div className="space-y-4">
              <h4 className="text-white font-semibold">What will be deleted:</h4>
              
              <div className="space-y-3">
                <div className="flex items-start space-x-3">
                  <Database className="text-red-400 mt-1" size={18} />
                  <div>
                    <div className="text-white text-sm font-medium">All Personal Data</div>
                    <div className="text-gray-400 text-xs">
                      Profile, preferences, device configurations, and sensor data
                    </div>
                  </div>
                </div>
                
                <div className="flex items-start space-x-3">
                  <CreditCard className="text-red-400 mt-1" size={18} />
                  <div>
                    <div className="text-white text-sm font-medium">Active Subscriptions</div>
                    <div className="text-gray-400 text-xs">
                      All subscriptions will be canceled immediately
                    </div>
                  </div>
                </div>
                
                <div className="flex items-start space-x-3">
                  <Clock className="text-red-400 mt-1" size={18} />
                  <div>
                    <div className="text-white text-sm font-medium">Device Connections</div>
                    <div className="text-gray-400 text-xs">
                      All devices will be disconnected and stop reporting data
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="bg-yellow-500/20 border border-yellow-500/30 rounded-xl p-4">
              <h4 className="font-semibold text-yellow-400 mb-2">What's Retained (Legal Requirements):</h4>
              <ul className="text-yellow-300 text-sm space-y-1">
                <li>• Billing records (up to 7 years for tax purposes)</li>
                <li>• Transaction history for fraud prevention</li>
                <li>• Basic audit logs for security compliance</li>
              </ul>
            </div>

            <div className="bg-blue-500/20 border border-blue-500/30 rounded-xl p-4">
              <div className="flex items-start space-x-3">
                <FileText className="text-blue-400 mt-0.5" size={16} />
                <div className="text-blue-300 text-sm">
                  <strong>Consider Exporting First:</strong> You may want to export your data 
                  before deletion. This action will be available until your account is deleted.
                </div>
              </div>
            </div>

            <div className="flex space-x-3">
              <Button
                onClick={handleClose}
                variant="ghost"
                className="flex-1"
              >
                Cancel
              </Button>
              <Button
                onClick={handleContinue}
                variant="outline"
                className="flex-1 border-red-500 text-red-400 hover:bg-red-500/20"
              >
                I Understand, Continue
              </Button>
            </div>
          </div>
        )}

        {/* Step 2: Confirmation */}
        {step === 'confirm' && (
          <div className="space-y-6">
            <div className="text-center">
              <h3 className="text-lg font-bold text-white mb-2">Final Confirmation</h3>
              <p className="text-gray-300 text-sm">
                Type the following text exactly to confirm account deletion:
              </p>
            </div>

            <div className="text-center">
              <div className="bg-red-500/20 border border-red-500/30 rounded-lg p-3 mb-4">
                <code className="text-red-300 font-mono text-lg">{requiredConfirmText}</code>
              </div>
              
              <input
                type="text"
                value={confirmText}
                onChange={(e) => setConfirmText(e.target.value)}
                className="w-full rounded-lg bg-white/10 backdrop-blur-sm border border-white/20 px-4 py-3 text-white text-center font-mono focus:outline-none focus:ring-2 focus:ring-red-400 focus:border-transparent"
                placeholder="Type the confirmation text here"
              />
            </div>

            {error && (
              <div className="bg-red-500/20 border border-red-500/30 rounded-lg p-3 flex items-center space-x-2">
                <AlertTriangle size={16} className="text-red-400" />
                <span className="text-red-300 text-sm">{error}</span>
              </div>
            )}

            <div className="flex space-x-3">
              <Button
                onClick={() => setStep('warning')}
                variant="ghost"
                className="flex-1"
              >
                Back
              </Button>
              <Button
                onClick={handleConfirm}
                disabled={confirmText !== requiredConfirmText}
                variant="outline"
                className="flex-1 border-red-500 text-red-400 hover:bg-red-500/20"
              >
                Confirm Deletion
              </Button>
            </div>
          </div>
        )}

        {/* Step 3: Authentication */}
        {step === 'auth' && (
          <div className="space-y-6">
            <div className="text-center">
              <div className="w-16 h-16 bg-red-500/20 rounded-full flex items-center justify-center mx-auto mb-4">
                <Lock className="text-red-400" size={32} />
              </div>
              <h3 className="text-lg font-bold text-white mb-2">Authenticate to Delete</h3>
              <p className="text-gray-300 text-sm">
                Please verify your identity one final time
              </p>
            </div>

            <div>
              <label className="block text-sm font-medium text-white mb-2">
                Password
              </label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full rounded-lg bg-white/10 backdrop-blur-sm border border-white/20 px-4 py-3 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-red-400 focus:border-transparent pr-12"
                  placeholder="Enter your password"
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-white"
                >
                  {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
                </button>
              </div>
            </div>

            {profile.two_factor_enabled && (
              <div>
                <label className="block text-sm font-medium text-white mb-2">
                  Two-Factor Authentication Code
                </label>
                <input
                  type="text"
                  value={twoFactorCode}
                  onChange={(e) => setTwoFactorCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                  className="w-full rounded-lg bg-white/10 backdrop-blur-sm border border-white/20 px-4 py-3 text-white text-center text-xl font-mono tracking-wider focus:outline-none focus:ring-2 focus:ring-red-400 focus:border-transparent"
                  placeholder="000000"
                  maxLength={6}
                />
              </div>
            )}

            {error && (
              <div className="bg-red-500/20 border border-red-500/30 rounded-lg p-3 flex items-center space-x-2">
                <AlertTriangle size={16} className="text-red-400" />
                <span className="text-red-300 text-sm">{error}</span>
              </div>
            )}

            <div className="bg-red-500/20 border border-red-500/30 rounded-xl p-4">
              <div className="flex items-start space-x-3">
                <AlertTriangle className="text-red-400 mt-0.5" size={16} />
                <div className="text-red-300 text-sm">
                  <strong>Final Warning:</strong> After clicking "Delete Account", your account 
                  and all associated data will be permanently deleted. This cannot be reversed.
                </div>
              </div>
            </div>

            <div className="flex space-x-3">
              <Button
                onClick={() => setStep('confirm')}
                disabled={loading}
                variant="ghost"
                className="flex-1"
              >
                Back
              </Button>
              <Button
                onClick={handleAuthenticate}
                disabled={loading || !password || (profile.two_factor_enabled && twoFactorCode.length !== 6)}
                variant="outline"
                className="flex-1 border-red-500 text-red-400 hover:bg-red-500/20 flex items-center justify-center"
              >
                {loading ? (
                  <>
                    <LoadingSpinner size="sm" />
                    <span className="ml-2">Verifying...</span>
                  </>
                ) : (
                  'Delete Account'
                )}
              </Button>
            </div>
          </div>
        )}

        {/* Step 4: Deleting */}
        {step === 'deleting' && (
          <div className="text-center space-y-6">
            <div className="w-16 h-16 bg-red-500/20 rounded-full flex items-center justify-center mx-auto">
              <LoadingSpinner size="lg" />
            </div>
            
            <div>
              <h3 className="text-lg font-bold text-white mb-2">Deleting Your Account</h3>
              <p className="text-gray-300 text-sm">
                Please wait while we process your account deletion...
              </p>
            </div>

            <div className="space-y-2 text-sm text-gray-400">
              <div>✓ Canceling active subscriptions</div>
              <div>✓ Disconnecting devices</div>
              <div>⏳ Removing personal data</div>
              <div>⏳ Finalizing deletion</div>
            </div>
          </div>
        )}

        {/* Step 5: Complete */}
        {step === 'complete' && (
          <div className="text-center space-y-6">
            <div className="w-16 h-16 bg-gray-500 rounded-full flex items-center justify-center mx-auto">
              <Trash2 size={32} className="text-white" />
            </div>
            
            <div>
              <h3 className="text-lg font-bold text-white mb-2">Account Deleted</h3>
              <p className="text-gray-300 text-sm">
                Your SpaceGrow.ai account has been permanently deleted.
              </p>
            </div>

            <div className="bg-gray-500/20 border border-gray-500/30 rounded-xl p-4">
              <div className="text-gray-300 text-sm space-y-1">
                <div>• All personal data has been removed</div>
                <div>• Subscriptions have been canceled</div>
                <div>• Devices have been disconnected</div>
                <div>• You will be redirected to the homepage</div>
              </div>
            </div>

            <div className="flex items-center justify-center space-x-2 text-gray-400">
              <LoadingSpinner size="sm" />
              <span>Redirecting...</span>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}