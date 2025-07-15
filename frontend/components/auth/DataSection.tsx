// components/auth/DataSection.tsx
'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/Button';
import { ExportDataModal } from '@/components/auth/modals/ExportDataModal';
import { DeleteAccountModal } from '@/components/auth/modals/DeleteAccountModal';
import { 
  Database, 
  Download, 
  Trash2, 
  Shield, 
  AlertTriangle,
  FileText,
  Lock,
  Clock,
  HardDrive
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

interface DataSectionProps {
  profile: UserProfile;
  onUpdate: (updates: Partial<UserProfile>) => void;
}

export function DataSection({ profile, onUpdate }: DataSectionProps) {
  const [showExportModal, setShowExportModal] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);

  // Mock data usage info
  const dataInfo = {
    account_age_days: Math.floor((Date.now() - new Date(profile.created_at).getTime()) / (1000 * 60 * 60 * 24)),
    estimated_size_mb: 2.4,
    last_backup: '2024-01-15T10:30:00Z',
    includes: [
      'Profile information',
      'Device configurations',
      'Notification preferences',
      'Sensor data (last 30 days)',
      'Subscription history'
    ]
  };

  const formatFileSize = (mb: number) => {
    if (mb < 1) {
      return `${Math.round(mb * 1000)} KB`;
    }
    return `${mb.toFixed(1)} MB`;
  };

  const formatLastBackup = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  };

  return (
    <>
      <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-8">
        <h3 className="text-xl font-bold text-white mb-6 flex items-center">
          <Database className="mr-3 text-yellow-400" size={24} />
          Data & Privacy
        </h3>

        <div className="space-y-8">
          {/* Data Overview */}
          <div className="grid md:grid-cols-2 gap-6">
            <div className="bg-white/5 rounded-xl p-4">
              <div className="flex items-center space-x-3 mb-3">
                <HardDrive className="text-blue-400" size={20} />
                <h4 className="text-white font-medium">Your Data</h4>
              </div>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-300">Account age:</span>
                  <span className="text-white">{dataInfo.account_age_days} days</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-300">Estimated size:</span>
                  <span className="text-white">{formatFileSize(dataInfo.estimated_size_mb)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-300">Last backup:</span>
                  <span className="text-white">{formatLastBackup(dataInfo.last_backup)}</span>
                </div>
              </div>
            </div>

            <div className="bg-white/5 rounded-xl p-4">
              <div className="flex items-center space-x-3 mb-3">
                <FileText className="text-green-400" size={20} />
                <h4 className="text-white font-medium">Export Includes</h4>
              </div>
              <ul className="space-y-1 text-sm text-gray-300">
                {dataInfo.includes.map((item, index) => (
                  <li key={index} className="flex items-center space-x-2">
                    <div className="w-1.5 h-1.5 bg-green-400 rounded-full" />
                    <span>{item}</span>
                  </li>
                ))}
              </ul>
            </div>
          </div>

          {/* Export Data */}
          <div className="border border-green-500/30 bg-green-500/10 rounded-xl p-6">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
              <div className="flex items-start space-x-4">
                <div className="w-12 h-12 bg-green-500/20 rounded-xl flex items-center justify-center">
                  <Download className="text-green-400" size={24} />
                </div>
                <div>
                  <h4 className="text-white font-semibold mb-2 flex items-center gap-2">
                    Export My Data
                    <Lock className="text-yellow-400" size={16}>
                      <title>2FA Protected</title>
                    </Lock>
                  </h4>
                  <p className="text-green-200 text-sm mb-2">
                    Download a complete copy of your personal data in JSON format. This includes all your 
                    profile information, device configurations, and settings.
                  </p>
                  <div className="flex items-center space-x-2 text-xs text-green-300">
                    <Shield size={14} />
                    <span>Data is encrypted and includes verification checksums</span>
                  </div>
                </div>
              </div>
              <Button
                onClick={() => setShowExportModal(true)}
                variant="cosmic"
                className="bg-green-500 hover:bg-green-600 flex items-center"
              >
                <Download size={16} className="mr-2" />
                Export Data
              </Button>
            </div>
          </div>

          {/* Account Deletion */}
          <div className="border border-red-500/30 bg-red-500/10 rounded-xl p-6">
            <div className="flex flex-col md:flex-row md:items-start justify-between gap-4">
              <div className="flex items-start space-x-4">
                <div className="w-12 h-12 bg-red-500/20 rounded-xl flex items-center justify-center">
                  <Trash2 className="text-red-400" size={24} />
                </div>
                <div>
                  <h4 className="text-white font-semibold mb-2 flex items-center gap-2">
                    Delete Account
                    <Lock className="text-yellow-400" size={16}>
                      <title>2FA Protected</title>
                    </Lock>
                  </h4>
                  <p className="text-red-200 text-sm mb-3">
                    Permanently delete your account and all associated data. This action cannot be undone 
                    and will immediately cancel any active subscriptions.
                  </p>
                  
                  {/* Warning Items */}
                  <div className="space-y-2">
                    <div className="flex items-center space-x-2 text-xs text-red-300">
                      <AlertTriangle size={14} />
                      <span>All devices will be disconnected immediately</span>
                    </div>
                    <div className="flex items-center space-x-2 text-xs text-red-300">
                      <Clock size={14} />
                      <span>Data deletion completes within 30 days</span>
                    </div>
                    <div className="flex items-center space-x-2 text-xs text-red-300">
                      <FileText size={14} />
                      <span>Billing records retained for legal requirements</span>
                    </div>
                  </div>
                </div>
              </div>
              <Button
                onClick={() => setShowDeleteModal(true)}
                variant="outline"
                className="border-red-500 text-red-400 hover:bg-red-500/20 flex items-center"
              >
                <Trash2 size={16} className="mr-2" />
                Delete Account
              </Button>
            </div>
          </div>
        </div>

        {/* Privacy Information */}
        <div className="mt-8 p-4 bg-blue-500/20 border border-blue-500/30 rounded-xl">
          <h4 className="font-semibold text-blue-300 mb-2">Your Privacy Rights</h4>
          <div className="text-blue-200 text-sm space-y-1">
            <p>• <strong>Right to Access:</strong> Export your data anytime</p>
            <p>• <strong>Right to Rectification:</strong> Update your information in profile settings</p>
            <p>• <strong>Right to Erasure:</strong> Delete your account and data</p>
            <p>• <strong>Data Portability:</strong> Export data in machine-readable JSON format</p>
            <p>• <strong>Minimal Collection:</strong> We only collect data necessary for our service</p>
          </div>
        </div>

        {/* Security Notice */}
        <div className="mt-4 p-4 bg-yellow-500/20 border border-yellow-500/30 rounded-xl">
          <div className="flex items-start space-x-3">
            <Shield className="text-yellow-400 mt-0.5" size={18} />
            <div className="text-yellow-200 text-sm">
              <strong>Enhanced Security:</strong> Actions marked with 🔒 require additional verification. 
              When two-factor authentication is enabled, these actions will require your authenticator code 
              for maximum security.
            </div>
          </div>
        </div>
      </div>

      {/* Modals */}
      <ExportDataModal
        isOpen={showExportModal}
        onClose={() => setShowExportModal(false)}
        profile={profile}
        dataInfo={dataInfo}
      />

      <DeleteAccountModal
        isOpen={showDeleteModal}
        onClose={() => setShowDeleteModal(false)}
        profile={profile}
        onAccountDeleted={() => {
          // Handle account deletion - redirect to goodbye page
          window.location.href = '/';
        }}
      />
    </>
  );
}