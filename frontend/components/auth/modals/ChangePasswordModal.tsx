// components/auth/modals/ChangePasswordModal.tsx - Updated with real API integration
'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/Button';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { api } from '@/lib/api'; // ✅ Import real API
import { 
  Lock, 
  Eye, 
  EyeOff, 
  Check, 
  X,
  AlertTriangle,
  Shield
} from 'lucide-react';
import { cn } from '@/lib/utils';

interface ChangePasswordModalProps {
  isOpen: boolean;
  onClose: () => void;
  onPasswordChanged: () => void;
}

interface PasswordValidation {
  length: boolean;
  uppercase: boolean;
  lowercase: boolean;
  number: boolean;
  special: boolean;
}

export function ChangePasswordModal({ isOpen, onClose, onPasswordChanged }: ChangePasswordModalProps) {
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPasswords, setShowPasswords] = useState({
    current: false,
    new: false,
    confirm: false
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  // ✅ Password validation matching backend requirements
  const validatePassword = (password: string): PasswordValidation => {
    return {
      length: password.length >= 8,
      uppercase: /[A-Z]/.test(password),
      lowercase: /[a-z]/.test(password),
      number: /\d/.test(password),
      special: /[!@#$%^&*(),.?":{}|<>]/.test(password)
    };
  };

  const validation = validatePassword(newPassword);
  const isPasswordValid = Object.values(validation).every(Boolean);
  const passwordsMatch = newPassword && confirmPassword && newPassword === confirmPassword;

  // ✅ REAL API INTEGRATION: Handle password change
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!currentPassword || !newPassword || !confirmPassword) {
      setError('Please fill in all fields');
      return;
    }

    if (!isPasswordValid) {
      setError('New password does not meet requirements');
      return;
    }

    if (!passwordsMatch) {
      setError('New passwords do not match');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      // ✅ Call real API endpoint
      await api.auth.changePassword(currentPassword, newPassword, confirmPassword);
      
      setSuccess(true);
      
      // Auto-close after success
      setTimeout(() => {
        handleClose();
        onPasswordChanged();
      }, 2000);
      
    } catch (err: any) {
      console.error('Failed to change password:', err);
      
      // ✅ Handle different error types from backend
      if (err.message.includes('401')) {
        setError('Session expired. Please log in again.');
      } else if (err.message.includes('422') || err.message.includes('current_password')) {
        setError('Current password is incorrect.');
      } else if (err.message.includes('Password change failed')) {
        setError('New password doesn\'t meet requirements or current password is incorrect.');
      } else {
        setError('Failed to change password. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    if (!loading) {
      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');
      setError(null);
      setSuccess(false);
      setShowPasswords({ current: false, new: false, confirm: false });
      onClose();
    }
  };

  const togglePasswordVisibility = (field: 'current' | 'new' | 'confirm') => {
    setShowPasswords(prev => ({
      ...prev,
      [field]: !prev[field]
    }));
  };

  if (!isOpen) return null;

  // ✅ SUCCESS STATE
  if (success) {
    return (
      <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
        <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-8 max-w-md w-full text-center">
          <div className="w-16 h-16 bg-green-500 rounded-full flex items-center justify-center mx-auto mb-6">
            <Check size={32} className="text-white" />
          </div>
          <h2 className="text-2xl font-bold text-white mb-4">Password Changed!</h2>
          <p className="text-gray-300 mb-6">
            Your password has been successfully updated. You'll be redirected shortly.
          </p>
          <div className="flex items-center justify-center space-x-2 text-green-400">
            <LoadingSpinner size="sm" />
            <span>Redirecting...</span>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-8 max-w-lg w-full">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-yellow-400/20 rounded-lg flex items-center justify-center">
              <Lock className="text-yellow-400" size={20} />
            </div>
            <h2 className="text-xl font-bold text-white">Change Password</h2>
          </div>
          <button
            onClick={handleClose}
            disabled={loading}
            className="text-gray-400 hover:text-white transition-colors"
          >
            <X size={24} />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Current Password */}
          <div>
            <label className="block text-sm font-medium text-white mb-2">
              Current Password
            </label>
            <div className="relative">
              <input
                type={showPasswords.current ? 'text' : 'password'}
                value={currentPassword}
                onChange={(e) => setCurrentPassword(e.target.value)}
                className="w-full rounded-lg bg-white/10 backdrop-blur-sm border border-white/20 px-4 py-3 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-yellow-400 focus:border-transparent pr-12"
                placeholder="Enter your current password"
                required
              />
              <button
                type="button"
                onClick={() => togglePasswordVisibility('current')}
                className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-white"
              >
                {showPasswords.current ? <EyeOff size={20} /> : <Eye size={20} />}
              </button>
            </div>
          </div>

          {/* New Password */}
          <div>
            <label className="block text-sm font-medium text-white mb-2">
              New Password
            </label>
            <div className="relative">
              <input
                type={showPasswords.new ? 'text' : 'password'}
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                className="w-full rounded-lg bg-white/10 backdrop-blur-sm border border-white/20 px-4 py-3 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-yellow-400 focus:border-transparent pr-12"
                placeholder="Enter new password"
                required
              />
              <button
                type="button"
                onClick={() => togglePasswordVisibility('new')}
                className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-white"
              >
                {showPasswords.new ? <EyeOff size={20} /> : <Eye size={20} />}
              </button>
            </div>
            
            {/* Password Requirements */}
            {newPassword && (
              <div className="mt-3 p-3 bg-white/5 rounded-lg">
                <div className="text-sm text-gray-300 mb-2">Password requirements:</div>
                <div className="grid grid-cols-1 gap-1 text-xs">
                  {Object.entries({
                    length: 'At least 8 characters',
                    uppercase: 'One uppercase letter',
                    lowercase: 'One lowercase letter',
                    number: 'One number',
                    special: 'One special character'
                  }).map(([key, label]) => (
                    <div key={key} className="flex items-center space-x-2">
                      {validation[key as keyof PasswordValidation] ? (
                        <Check size={14} className="text-green-400" />
                      ) : (
                        <X size={14} className="text-red-400" />
                      )}
                      <span className={validation[key as keyof PasswordValidation] ? 'text-green-300' : 'text-red-300'}>
                        {label}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Confirm Password */}
          <div>
            <label className="block text-sm font-medium text-white mb-2">
              Confirm New Password
            </label>
            <div className="relative">
              <input
                type={showPasswords.confirm ? 'text' : 'password'}
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                className="w-full rounded-lg bg-white/10 backdrop-blur-sm border border-white/20 px-4 py-3 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-yellow-400 focus:border-transparent pr-12"
                placeholder="Confirm new password"
                required
              />
              <button
                type="button"
                onClick={() => togglePasswordVisibility('confirm')}
                className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-white"
              >
                {showPasswords.confirm ? <EyeOff size={20} /> : <Eye size={20} />}
              </button>
            </div>
            
            {/* Password Match Indicator */}
            {confirmPassword && (
              <div className="mt-2 flex items-center space-x-2">
                {passwordsMatch ? (
                  <>
                    <Check size={14} className="text-green-400" />
                    <span className="text-green-300 text-xs">Passwords match</span>
                  </>
                ) : (
                  <>
                    <X size={14} className="text-red-400" />
                    <span className="text-red-300 text-xs">Passwords do not match</span>
                  </>
                )}
              </div>
            )}
          </div>

          {/* Error Message */}
          {error && (
            <div className="bg-red-500/20 border border-red-500/30 rounded-lg p-3 flex items-center space-x-2">
              <AlertTriangle size={16} className="text-red-400" />
              <span className="text-red-300 text-sm">{error}</span>
            </div>
          )}

          {/* Security Notice - Updated text since we're NOT invalidating tokens */}
          <div className="bg-blue-500/20 border border-blue-500/30 rounded-lg p-3">
            <div className="flex items-start space-x-2">
              <Shield size={16} className="text-blue-400 mt-0.5" />
              <div className="text-blue-300 text-xs">
                <strong>Security Note:</strong> Your password will be updated immediately. 
                For maximum security, consider logging out and back in on all your devices.
              </div>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex space-x-3 pt-4">
            <Button
              type="button"
              onClick={handleClose}
              disabled={loading}
              variant="ghost"
              className="flex-1"
            >
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={loading || !isPasswordValid || !passwordsMatch}
              variant="cosmic"
              className="flex-1 flex items-center justify-center"
            >
              {loading ? (
                <>
                  <LoadingSpinner size="sm" />
                  <span className="ml-2">Changing...</span>
                </>
              ) : (
                'Change Password'
              )}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}