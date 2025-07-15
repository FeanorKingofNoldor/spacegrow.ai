// components/auth/modals/EmailVerificationModal.tsx
'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/Button';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { 
  Mail, 
  X, 
  AlertTriangle, 
  Check, 
  Clock,
  ArrowRight
} from 'lucide-react';

interface EmailVerificationModalProps {
  isOpen: boolean;
  onClose: () => void;
  currentEmail: string;
  newEmail: string;
  onEmailChanged: (email: string) => void;
}

export function EmailVerificationModal({ 
  isOpen, 
  onClose, 
  currentEmail, 
  newEmail, 
  onEmailChanged 
}: EmailVerificationModalProps) {
  const [step, setStep] = useState<'change' | 'verify' | 'success'>('change');
  const [email, setEmail] = useState(newEmail);
  const [verificationCode, setVerificationCode] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSendVerification = async () => {
    if (!email || !isValidEmail(email)) {
      setError('Please enter a valid email address');
      return;
    }

    if (email === currentEmail) {
      setError('New email must be different from current email');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      // TODO: API call to send verification email
      // await api.auth.sendEmailVerification(email);
      
      // Mock API call
      await new Promise(resolve => setTimeout(resolve, 1500));
      
      setStep('verify');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to send verification email');
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyCode = async () => {
    if (!verificationCode || verificationCode.length !== 6) {
      setError('Please enter a valid 6-digit verification code');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      // TODO: API call to verify email change
      // await api.auth.verifyEmailChange(email, verificationCode);
      
      // Mock API call
      await new Promise(resolve => setTimeout(resolve, 1500));
      
      setStep('success');
      
      // Auto-complete after success
      setTimeout(() => {
        onEmailChanged(email);
        handleClose();
      }, 2000);
      
    } catch (err) {
      setError('Invalid verification code. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    if (!loading) {
      setStep('change');
      setEmail(newEmail);
      setVerificationCode('');
      setError(null);
      onClose();
    }
  };

  const isValidEmail = (email: string) => {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-8 max-w-md w-full">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-blue-500/20 rounded-lg flex items-center justify-center">
              <Mail className="text-blue-400" size={20} />
            </div>
            <h2 className="text-xl font-bold text-white">Change Email</h2>
          </div>
          <button
            onClick={handleClose}
            disabled={loading}
            className="text-gray-400 hover:text-white transition-colors"
          >
            <X size={24} />
          </button>
        </div>

        {/* Step 1: Enter New Email */}
        {step === 'change' && (
          <div className="space-y-6">
            <div>
              <div className="text-sm text-gray-300 mb-2">Current Email</div>
              <div className="w-full rounded-lg bg-white/5 border border-white/10 px-4 py-3 text-gray-400">
                {currentEmail}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-white mb-2">
                New Email Address
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full rounded-lg bg-white/10 backdrop-blur-sm border border-white/20 px-4 py-3 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-yellow-400 focus:border-transparent"
                placeholder="Enter new email address"
                required
              />
            </div>

            {error && (
              <div className="bg-red-500/20 border border-red-500/30 rounded-lg p-3 flex items-center space-x-2">
                <AlertTriangle size={16} className="text-red-400" />
                <span className="text-red-300 text-sm">{error}</span>
              </div>
            )}

            <div className="bg-blue-500/20 border border-blue-500/30 rounded-lg p-4">
              <div className="text-blue-300 text-sm">
                <strong>Important:</strong> We'll send a verification code to your new email address. 
                You'll need to verify it before the change takes effect.
              </div>
            </div>

            <div className="flex space-x-3">
              <Button
                onClick={handleClose}
                disabled={loading}
                variant="ghost"
                className="flex-1"
              >
                Cancel
              </Button>
              <Button
                onClick={handleSendVerification}
                disabled={loading || !email || !isValidEmail(email)}
                variant="cosmic"
                className="flex-1 flex items-center justify-center"
              >
                {loading ? (
                  <>
                    <LoadingSpinner size="sm" />
                    <span className="ml-2">Sending...</span>
                  </>
                ) : (
                  <>
                    Send Code
                    <ArrowRight size={16} className="ml-2" />
                  </>
                )}
              </Button>
            </div>
          </div>
        )}

        {/* Step 2: Verify Code */}
        {step === 'verify' && (
          <div className="space-y-6">
            <div className="text-center">
              <div className="w-16 h-16 bg-blue-500/20 rounded-full flex items-center justify-center mx-auto mb-4">
                <Mail className="text-blue-400" size={32} />
              </div>
              <h3 className="text-lg font-bold text-white mb-2">Check Your Email</h3>
              <p className="text-gray-300 text-sm">
                We've sent a 6-digit verification code to:
              </p>
              <div className="font-medium text-blue-400 mt-2">{email}</div>
            </div>

            <div>
              <label className="block text-sm font-medium text-white mb-2">
                Verification Code
              </label>
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

            <div className="text-center">
              <button
                onClick={handleSendVerification}
                disabled={loading}
                className="text-blue-400 hover:text-blue-300 text-sm underline"
              >
                Didn't receive the code? Resend
              </button>
            </div>

            <div className="flex space-x-3">
              <Button
                onClick={() => setStep('change')}
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
                  'Verify Email'
                )}
              </Button>
            </div>
          </div>
        )}

        {/* Step 3: Success */}
        {step === 'success' && (
          <div className="text-center space-y-6">
            <div className="w-16 h-16 bg-green-500 rounded-full flex items-center justify-center mx-auto">
              <Check size={32} className="text-white" />
            </div>
            
            <div>
              <h3 className="text-xl font-bold text-white mb-2">Email Changed!</h3>
              <p className="text-gray-300 mb-4">
                Your email address has been successfully updated to:
              </p>
              <div className="font-medium text-green-400">{email}</div>
            </div>

            <div className="bg-green-500/20 border border-green-500/30 rounded-lg p-4">
              <div className="text-green-300 text-sm">
                All future notifications and account communications will be sent to your new email address.
              </div>
            </div>

            <div className="flex items-center justify-center space-x-2 text-green-400">
              <LoadingSpinner size="sm" />
              <span>Updating your profile...</span>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}