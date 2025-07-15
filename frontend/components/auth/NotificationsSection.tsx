// components/auth/NotificationsSection.tsx
'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/Button';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { 
  Bell, 
  AlertTriangle, 
  CreditCard, 
  Settings2,
  Smartphone,
  Mail,
  CheckCircle
} from 'lucide-react';
import { cn } from '@/lib/utils';

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

interface NotificationsSectionProps {
  profile: UserProfile;
  onUpdate: (updates: Partial<UserProfile>) => void;
}

interface NotificationPreference {
  key: keyof UserProfile['notification_preferences'];
  title: string;
  description: string;
  icon: React.ComponentType<{ size?: number; className?: string }>;
  color: string;
  important?: boolean;
}

export function NotificationsSection({ profile, onUpdate }: NotificationsSectionProps) {
  const [loading, setLoading] = useState<string | null>(null);
  const [hasChanges, setHasChanges] = useState(false);
  const [tempPreferences, setTempPreferences] = useState(profile.notification_preferences);

  const notificationTypes: NotificationPreference[] = [
    {
      key: 'device_alerts',
      title: 'Device Alerts',
      description: 'Get notified when devices go offline, have sensor warnings, or encounter errors',
      icon: AlertTriangle,
      color: 'text-orange-400',
      important: true
    },
    {
      key: 'billing_notifications',
      title: 'Billing Notifications',
      description: 'Payment confirmations, subscription changes, and invoice reminders',
      icon: CreditCard,
      color: 'text-blue-400',
      important: true
    },
    {
      key: 'system_updates',
      title: 'System Updates',
      description: 'New features, maintenance notifications, and platform improvements',
      icon: Settings2,
      color: 'text-purple-400'
    }
  ];

  const handleToggle = (key: keyof UserProfile['notification_preferences']) => {
    const newPreferences = {
      ...tempPreferences,
      [key]: !tempPreferences[key]
    };
    setTempPreferences(newPreferences);
    setHasChanges(JSON.stringify(newPreferences) !== JSON.stringify(profile.notification_preferences));
  };

  const handleSave = async () => {
    setLoading('save');
    try {
      // TODO: API call to update notification preferences
      // await api.auth.updateNotificationPreferences(tempPreferences);
      
      // Mock API call
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      onUpdate({ notification_preferences: tempPreferences });
      setHasChanges(false);
    } catch (error) {
      console.error('Failed to update notification preferences:', error);
      // Reset to original preferences on error
      setTempPreferences(profile.notification_preferences);
      setHasChanges(false);
    } finally {
      setLoading(null);
    }
  };

  const handleReset = () => {
    setTempPreferences(profile.notification_preferences);
    setHasChanges(false);
  };

  const getToggleColor = (enabled: boolean, color: string) => {
    if (enabled) {
      return 'bg-green-500';
    }
    return 'bg-gray-600';
  };

  return (
    <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-8">
      <h3 className="text-xl font-bold text-white mb-6 flex items-center">
        <Bell className="mr-3 text-yellow-400" size={24} />
        Notification Preferences
      </h3>

      <div className="space-y-6">
        {/* Notification Types */}
        {notificationTypes.map((notif) => {
          const Icon = notif.icon;
          const isEnabled = tempPreferences[notif.key];
          
          return (
            <div key={notif.key} className="flex items-start justify-between gap-4">
              <div className="flex items-start space-x-3 flex-1">
                <div className={cn(
                  'w-10 h-10 rounded-lg flex items-center justify-center mt-1',
                  isEnabled ? 'bg-green-500/20' : 'bg-gray-500/20'
                )}>
                  <Icon size={20} className={isEnabled ? 'text-green-400' : 'text-gray-400'} />
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-white font-medium">{notif.title}</span>
                    {notif.important && (
                      <span className="px-2 py-0.5 bg-orange-500/20 text-orange-400 text-xs rounded-full">
                        Important
                      </span>
                    )}
                  </div>
                  <p className="text-gray-300 text-sm">{notif.description}</p>
                </div>
              </div>
              
              {/* Toggle Switch */}
              <button
                onClick={() => handleToggle(notif.key)}
                className={cn(
                  'relative w-12 h-6 rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-yellow-400',
                  getToggleColor(isEnabled, notif.color)
                )}
              >
                <div className={cn(
                  'absolute top-0.5 w-5 h-5 bg-white rounded-full transition-transform',
                  isEnabled ? 'left-6' : 'left-0.5'
                )} />
              </button>
            </div>
          );
        })}

        {/* Delivery Method */}
        <div className="border-t border-white/10 pt-6">
          <h4 className="text-white font-medium mb-4 flex items-center">
            <Mail className="mr-2 text-gray-400" size={18} />
            Delivery Method
          </h4>
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <Mail className="text-blue-400" size={18} />
                <div>
                  <div className="text-white text-sm font-medium">Email Notifications</div>
                  <div className="text-gray-400 text-xs">{profile.email}</div>
                </div>
              </div>
              <CheckCircle className="text-green-400" size={18} />
            </div>
            <div className="flex items-center justify-between opacity-50">
              <div className="flex items-center space-x-3">
                <Smartphone className="text-purple-400" size={18} />
                <div>
                  <div className="text-white text-sm font-medium">Push Notifications</div>
                  <div className="text-gray-400 text-xs">Coming soon</div>
                </div>
              </div>
              <span className="px-2 py-1 bg-gray-500/20 text-gray-400 text-xs rounded-full">
                Soon
              </span>
            </div>
          </div>
        </div>

        {/* Save/Reset Actions */}
        {hasChanges && (
          <div className="border-t border-white/10 pt-6">
            <div className="flex items-center justify-between bg-yellow-500/20 border border-yellow-500/30 rounded-xl p-4">
              <div className="flex items-center space-x-3">
                <AlertTriangle className="text-yellow-400" size={20} />
                <div>
                  <div className="text-yellow-400 font-medium">Unsaved Changes</div>
                  <div className="text-yellow-300 text-sm">You have unsaved notification preferences</div>
                </div>
              </div>
              <div className="flex gap-2">
                <Button
                  onClick={handleReset}
                  disabled={loading === 'save'}
                  variant="ghost"
                  size="sm"
                >
                  Reset
                </Button>
                <Button
                  onClick={handleSave}
                  disabled={loading === 'save'}
                  variant="cosmic"
                  size="sm"
                  className="flex items-center"
                >
                  {loading === 'save' ? (
                    <>
                      <LoadingSpinner size="sm" />
                      <span className="ml-2">Saving...</span>
                    </>
                  ) : (
                    'Save Changes'
                  )}
                </Button>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Info Box */}
      <div className="mt-6 p-4 bg-blue-500/20 border border-blue-500/30 rounded-xl">
        <div className="text-blue-300 text-sm">
          <strong>Privacy Note:</strong> We'll only send you notifications you've opted into. 
          You can change these preferences anytime. Important security and billing notifications may still be sent regardless of these settings.
        </div>
      </div>
    </div>
  );
}