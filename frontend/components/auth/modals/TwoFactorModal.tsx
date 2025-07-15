// components/auth/modals/TwoFactorModal.tsx
'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/Button';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { 
  Smartphone, 
  QrCode, 
  Shield, 
  Key, 
  X,
  AlertTriangle,
  Clock,
  CheckCircle,
  Copy,
  Download
} from 'lucide-react';

interface TwoFactorModalProps {
  isOpen: boolean;
  onClose: () => void;
  twoFactorEnabled: boolean;
  onTwoFactorChanged: (enabled: boolean) => void;
}

export function TwoFactorModal({ 
  isOpen, 
  onClose, 
  twoFactorEnabled, 
  onTwoFactorChanged 
}: TwoFactorModalProps) {
  const [step, setStep] = useState<'info' | 'setup' | 'verify' | 'backup' | 'disable'>('info');
  const [loading, setLoading] = useState(false);
  const [verificationCode, setVerificationCode] = useState('');
  const [error, setError] = useState<string | null>(null);

  // Mock backup codes (would come from API in real implementation)
  const mockBackupCodes = [
    '1234-5678',
    '9876-5432',
    '1111-2222',
    '3333-4444',
    '5555-6666'
  ];

  const handleClose = () => {
    if (!loading) {
      setStep('info');
      setVerificationCode('');
      setError(null);
      onClose();
    }
  };

  const handleSetupClick = () => {
    if (twoFactorEnabled) {
      setStep('disable');
    } else {
      setStep('setup');
    }
  };

  const handleVerifyCode = async () => {
    if (!verificationCode || verificationCode.length !== 6) {
      setError('Please enter a valid 6-digit code');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      // TODO: Verify TOTP code with backend
      // await api.auth.verifyTwoFactor(verificationCode);
      
      // Mock verification
      await new Promise(resolve => setTimeout(resolve, 1500));
      
      onTwoFactorChanged(true);
      setStep('backup');
    } catch (err) {
      setError('Invalid verification code. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleDisable2FA = async () => {
    setLoading(true);
    setError(null);

    try {
      // TODO: Disable 2FA with backend
      // await api.auth.disableTwoFactor();
      
      // Mock disable
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      onTwoFactorChanged(false);
      handleClose();
    } catch (err) {
      setError('Failed to disable 2FA. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const copyBackupCodes = () => {
    const codesText = mockBackupCodes.join('\n');
    navigator.clipboard.writeText(codesText);
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-8 max-w-lg w-full">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-blue-500/20 rounded-lg flex items-center justify-center">
              <Smartphone className="text-blue-400" size={20} />
            </div>
            <h2 className="text-xl font-bold text-white">
              {twoFactorEnabled ? 'Manage 2FA' : 'Setup Two-Factor Authentication'}
            </h2>
          </div>
          <button
            onClick={handleClose}
            disabled={loading}
            className="text-gray-400 hover:text-white transition-colors"
          >
            <X size={24} />
          </button>
        </div>

        {/* Content based on step */}
        {step === 'info' && (
          <div className="space-y-6">
            {/* Coming Soon Banner */}
            <div className="bg-gradient-to-r from-purple-500/20 to-blue-500/20 border border-purple-500/30 rounded-xl p-6 text-center">
              <div className="w-16 h-16 bg-purple-500/20 rounded-full flex items-center justify-center mx-auto mb-4">
                <Clock className="text-purple-400" size={32} />
              </div>
              <h3 className="text-xl font-bold text-white mb-2">
                Two-Factor Authentication Coming Soon!
              </h3>
              <p className="text-gray-300 text-sm">
                We're working hard to bring you TOTP-based 2FA using popular authenticator apps like 
                Google Authenticator, Authy, and 1Password.
              </p>
            </div>

            {/* What to Expect */}
            <div className="space-y-4">
              <h4 className="text-white font-semibold">What to expect when 2FA is ready:</h4>
              
              <div className="space-y-3">
                <div className="flex items-start space-x-3">
                  <QrCode className="text-blue-400 mt-1" size={18} />
                  <div>
                    <div className="text-white text-sm font-medium">QR Code Setup</div>
                    <div className="text-gray-400 text-xs">
                      Scan a QR code with your authenticator app for easy setup
                    </div>
                  </div>
                </div>
                
                <div className="flex items-start space-x-3">
                  <Key className="text-green-400 mt-1" size={18} />
                  <div>
                    <div className="text-white text-sm font-medium">Backup Codes</div>
                    <div className="text-gray-400 text-xs">
                      Receive backup codes for account recovery
                    </div>
                  </div>
                </div>
                
                <div className="flex items-start space-x-3">
                  <Shield className="text-yellow-400 mt-1" size={18} />
                  <div>
                    <div className="text-white text-sm font-medium">Enhanced Security</div>
                    <div className="text-gray-400 text-xs">
                      Protect sensitive actions like data export and account deletion
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Supported Apps */}
            <div className="bg-white/5 rounded-xl p-4">
              <h4 className="text-white font-semibold mb-3">Supported Authenticator Apps:</h4>
              <div className="grid grid-cols-2 gap-3 text-sm text-gray-300">
                <div>• Google Authenticator</div>
                <div>• Microsoft Authenticator</div>
                <div>• Authy</div>
                <div>• 1Password</div>
                <div>• Bitwarden</div>
                <div>• Any TOTP app</div>
              </div>
            </div>

            {/* Demo Notice */}
            <div className="bg-blue-500/20 border border-blue-500/30 rounded-xl p-4">
              <div className="flex items-start space-x-3">
                <AlertTriangle className="text-blue-400 mt-0.5" size={16} />
                <div className="text-blue-300 text-sm">
                  <strong>Note:</strong> The button below shows a preview of the 2FA setup flow. 
                  Actual 2FA functionality is not yet active but will be available soon.
                </div>
              </div>
            </div>

            {/* Action Button */}
            <div className="flex space-x-3">
              <Button
                onClick={handleClose}
                variant="ghost"
                className="flex-1"
              >
                Close
              </Button>
              <Button
                onClick={handleSetupClick}
                variant="cosmic"
                className="flex-1 opacity-50"
                disabled
              >
                <Clock size={16} className="mr-2" />
                Preview Setup (Coming Soon)
              </Button>
            </div>
          </div>
        )}

        {/* Mock Setup Step (for preview) */}
        {step === 'setup' && (
          <div className="space-y-6">
            <div className="text-center">
              <h3 className="text-lg font-bold text-white mb-2">Scan QR Code</h3>
              <p className="text-gray-300 text-sm">
                Scan this QR code with your authenticator app
              </p>
            </div>

            {/* Mock QR Code */}
            <div className="bg-white rounded-xl p-6 mx-auto w-fit">
              <div className="w-48 h-48 bg-gradient-to-br from-gray-800 to-gray-600 rounded-lg flex items-center justify-center">
                <QrCode size={64} className="text-gray-400" />
              </div>
            </div>

            {/* Manual Entry */}
            <div className="bg-white/5 rounded-xl p-4">
              <div className="text-white text-sm font-medium mb-2">Manual Entry Key:</div>
              <div className="font-mono text-xs bg-black/30 rounded px-3 py-2 text-gray-300 break-all">
                JBSWY3DPEHPK3PXP JBSWY3DPEHPK3PXP
              </div>
            </div>

            <div className="flex space-x-3">
              <Button
                onClick={() => setStep('info')}
                variant="ghost"
                className="flex-1"
              >
                Back
              </Button>
              <Button
                onClick={() => setStep('verify')}
                variant="cosmic"
                className="flex-1"
              >
                Next: Verify
              </Button>
            </div>
          </div>
        )}

        {/* Mock Verification Step */}
        {step === 'verify' && (
          <div className="space-y-6">
            <div className="text-center">
              <h3 className="text-lg font-bold text-white mb-2">Enter Verification Code</h3>
              <p className="text-gray-300 text-sm">
                Enter the 6-digit code from your authenticator app
              </p>
            </div>

            <div>
              <input
                type="text"
                value={verificationCode}
                onChange={(e) => setVerificationCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                className="w-full rounded-lg bg-white/10 backdrop-blur-sm border border-white/20 px-4 py-3 text-white text-center text-2xl font-mono tracking-wider focus:outline-none focus:ring-2 focus:ring-yellow-400 focus:border-transparent"
                placeholder="000000"
                maxLength={6}
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
                onClick={() => setStep('setup')}
                disabled={loading}
                variant="ghost"
                className="flex-1"
              >
                Back
              </Button>
              <Button
                onClick={handleVerifyCode}
                disabled={loading || verificationCode.length !== 6}
                variant="cosmic"
                className="flex-1 flex items-center justify-center"
              >
                {loading ? (
                  <>
                    <LoadingSpinner size="sm" />
                    <span className="ml-2">Verifying...</span>
                  </>
                ) : (
                  'Verify & Enable'
                )}
              </Button>
            </div>
          </div>
        )}

        {/* Mock Backup Codes Step */}
        {step === 'backup' && (
          <div className="space-y-6">
            <div className="text-center">
              <div className="w-16 h-16 bg-green-500 rounded-full flex items-center justify-center mx-auto mb-4">
                <CheckCircle size={32} className="text-white" />
              </div>
              <h3 className="text-lg font-bold text-white mb-2">2FA Enabled!</h3>
              <p className="text-gray-300 text-sm">
                Save these backup codes in a secure location
              </p>
            </div>

            <div className="bg-white/5 rounded-xl p-4">
              <div className="flex items-center justify-between mb-3">
                <span className="text-white font-medium">Backup Codes</span>
                <Button
                  onClick={copyBackupCodes}
                  variant="ghost"
                  size="sm"
                  className="flex items-center"
                >
                  <Copy size={14} className="mr-1" />
                  Copy
                </Button>
              </div>
              <div className="font-mono text-sm space-y-1">
                {mockBackupCodes.map((code, index) => (
                  <div key={index} className="text-gray-300">{code}</div>
                ))}
              </div>
            </div>

            <div className="bg-yellow-500/20 border border-yellow-500/30 rounded-xl p-4">
              <div className="flex items-start space-x-3">
                <AlertTriangle className="text-yellow-400 mt-0.5" size={16} />
                <div className="text-yellow-300 text-sm">
                  <strong>Important:</strong> Store these codes safely. Each code can only be used once 
                  to access your account if you lose your authenticator device.
                </div>
              </div>
            </div>

            <Button
              onClick={handleClose}
              variant="cosmic"
              className="w-full"
            >
              Complete Setup
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}