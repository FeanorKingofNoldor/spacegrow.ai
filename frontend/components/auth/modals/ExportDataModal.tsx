// components/auth/modals/ExportDataModal.tsx
'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/Button';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { 
  Download, 
  X, 
  Lock, 
  Shield, 
  FileText, 
  Check,
  AlertTriangle,
  Eye,
  EyeOff
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

interface DataInfo {
  account_age_days: number;
  estimated_size_mb: number;
  last_backup: string;
  includes: string[];
}

interface ExportDataModalProps {
  isOpen: boolean;
  onClose: () => void;
  profile: UserProfile;
  dataInfo: DataInfo;
}

export function ExportDataModal({ isOpen, onClose, profile, dataInfo }: ExportDataModalProps) {
  const [step, setStep] = useState<'confirm' | 'auth' | 'exporting' | 'complete'>('confirm');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [twoFactorCode, setTwoFactorCode] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [downloadUrl, setDownloadUrl] = useState<string | null>(null);

  const handleClose = () => {
    if (!loading) {
      setStep('confirm');
      setPassword('');
      setTwoFactorCode('');
      setError(null);
      setDownloadUrl(null);
      onClose();
    }
  };

  const handleContinue = () => {
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
      // TODO: Verify password and 2FA, then start export
      // await api.auth.verifyForDataExport(password, twoFactorCode);
      
      // Mock authentication
      await new Promise(resolve => setTimeout(resolve, 1500));
      
      setStep('exporting');
      await handleExportData();
      
    } catch (err) {
      setError('Authentication failed. Please check your credentials.');
    } finally {
      setLoading(false);
    }
  };

  const handleExportData = async () => {
    try {
      // TODO: API call to export user data
      // const exportResult = await api.auth.exportUserData();
      
      // Mock export process
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      // Mock download URL (in real implementation, this would be a secure temporary URL)
      const mockData = {
        export_info: {
          generated_at: new Date().toISOString(),
          user_id: profile.id,
          format: 'JSON',
          version: '1.0'
        },
        profile: {
          email: profile.email,
          display_name: profile.display_name,
          timezone: profile.timezone,
          created_at: profile.created_at,
          notification_preferences: profile.notification_preferences
        },
        devices: [],
        sensor_data: [],
        subscription_history: [],
        settings: {}
      };
      
      const blob = new Blob([JSON.stringify(mockData, null, 2)], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      setDownloadUrl(url);
      setStep('complete');
      
    } catch (err) {
      setError('Failed to export data. Please try again.');
      setStep('auth');
    }
  };

  const handleDownload = () => {
    if (downloadUrl) {
      const link = document.createElement('a');
      link.href = downloadUrl;
      link.download = `spacegrow-data-export-${new Date().toISOString().split('T')[0]}.json`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    }
  };

  const formatFileSize = (mb: number) => {
    if (mb < 1) {
      return `${Math.round(mb * 1000)} KB`;
    }
    return `${mb.toFixed(1)} MB`;
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-8 max-w-lg w-full">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-green-500/20 rounded-lg flex items-center justify-center">
              <Download className="text-green-400" size={20} />
            </div>
            <h2 className="text-xl font-bold text-white">Export My Data</h2>
          </div>
          <button
            onClick={handleClose}
            disabled={loading}
            className="text-gray-400 hover:text-white transition-colors"
          >
            <X size={24} />
          </button>
        </div>

        {/* Step 1: Confirmation */}
        {step === 'confirm' && (
          <div className="space-y-6">
            <div>
              <h3 className="text-lg font-semibold text-white mb-3">Data Export Details</h3>
              <div className="space-y-3">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-300">Estimated size:</span>
                  <span className="text-white">{formatFileSize(dataInfo.estimated_size_mb)}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-300">Format:</span>
                  <span className="text-white">JSON</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-300">Last export:</span>
                  <span className="text-white">
                    {new Date(dataInfo.last_backup).toLocaleDateString()}
                  </span>
                </div>
              </div>
            </div>

            <div>
              <h4 className="text-white font-semibold mb-2">Export Includes:</h4>
              <div className="space-y-1">
                {dataInfo.includes.map((item, index) => (
                  <div key={index} className="flex items-center space-x-2 text-sm">
                    <Check size={14} className="text-green-400" />
                    <span className="text-gray-300">{item}</span>
                  </div>
                ))}
              </div>
            </div>

            <div className="bg-blue-500/20 border border-blue-500/30 rounded-xl p-4">
              <div className="flex items-start space-x-3">
                <Shield className="text-blue-400 mt-0.5" size={16} />
                <div className="text-blue-300 text-sm">
                  <strong>Security Note:</strong> Your data export will be encrypted and include 
                  verification checksums. The download link will be valid for 24 hours only.
                </div>
              </div>
            </div>

            {profile.two_factor_enabled && (
              <div className="bg-yellow-500/20 border border-yellow-500/30 rounded-xl p-4">
                <div className="flex items-center space-x-3">
                  <Lock className="text-yellow-400" size={16} />
                  <div className="text-yellow-300 text-sm">
                    <strong>2FA Required:</strong> This action requires two-factor authentication 
                    for additional security.
                  </div>
                </div>
              </div>
            )}

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
                variant="cosmic"
                className="flex-1 bg-green-500 hover:bg-green-600"
              >
                Continue
              </Button>
            </div>
          </div>
        )}

        {/* Step 2: Authentication */}
        {step === 'auth' && (
          <div className="space-y-6">
            <div className="text-center">
              <div className="w-16 h-16 bg-yellow-500/20 rounded-full flex items-center justify-center mx-auto mb-4">
                <Lock className="text-yellow-400" size={32} />
              </div>
              <h3 className="text-lg font-bold text-white mb-2">Verify Your Identity</h3>
              <p className="text-gray-300 text-sm">
                Please confirm your identity to proceed with data export
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
                  className="w-full rounded-lg bg-white/10 backdrop-blur-sm border border-white/20 px-4 py-3 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-yellow-400 focus:border-transparent pr-12"
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
                  className="w-full rounded-lg bg-white/10 backdrop-blur-sm border border-white/20 px-4 py-3 text-white text-center text-xl font-mono tracking-wider focus:outline-none focus:ring-2 focus:ring-yellow-400 focus:border-transparent"
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
                variant="cosmic"
                className="flex-1 flex items-center justify-center bg-green-500 hover:bg-green-600"
              >
                {loading ? (
                  <>
                    <LoadingSpinner size="sm" />
                    <span className="ml-2">Verifying...</span>
                  </>
                ) : (
                  'Start Export'
                )}
              </Button>
            </div>
          </div>
        )}

        {/* Step 3: Exporting */}
        {step === 'exporting' && (
          <div className="text-center space-y-6">
            <div className="w-16 h-16 bg-blue-500/20 rounded-full flex items-center justify-center mx-auto">
              <LoadingSpinner size="lg" />
            </div>
            
            <div>
              <h3 className="text-lg font-bold text-white mb-2">Preparing Your Data</h3>
              <p className="text-gray-300 text-sm">
                We're gathering and encrypting your data. This may take a few moments...
              </p>
            </div>

            <div className="space-y-2 text-sm text-gray-400">
              <div>✓ Collecting profile information</div>
              <div>✓ Gathering device configurations</div>
              <div>⏳ Processing sensor data</div>
              <div>⏳ Encrypting export file</div>
            </div>
          </div>
        )}

        {/* Step 4: Complete */}
        {step === 'complete' && (
          <div className="text-center space-y-6">
            <div className="w-16 h-16 bg-green-500 rounded-full flex items-center justify-center mx-auto">
              <Check size={32} className="text-white" />
            </div>
            
            <div>
              <h3 className="text-lg font-bold text-white mb-2">Export Ready!</h3>
              <p className="text-gray-300 text-sm">
                Your data has been successfully prepared and encrypted. Download it now.
              </p>
            </div>

            <div className="bg-green-500/20 border border-green-500/30 rounded-xl p-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <FileText className="text-green-400" size={20} />
                  <div className="text-left">
                    <div className="text-green-300 font-medium">spacegrow-data-export.json</div>
                    <div className="text-green-400 text-xs">{formatFileSize(dataInfo.estimated_size_mb)}</div>
                  </div>
                </div>
                <Button
                  onClick={handleDownload}
                  variant="cosmic"
                  size="sm"
                  className="bg-green-500 hover:bg-green-600"
                >
                  <Download size={16} className="mr-2" />
                  Download
                </Button>
              </div>
            </div>

            <div className="bg-yellow-500/20 border border-yellow-500/30 rounded-xl p-4">
              <div className="text-yellow-300 text-xs">
                <strong>Important:</strong> This download link will expire in 24 hours. 
                Store your data securely and do not share the exported file.
              </div>
            </div>

            <Button
              onClick={handleClose}
              variant="ghost"
              className="w-full"
            >
              Close
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}