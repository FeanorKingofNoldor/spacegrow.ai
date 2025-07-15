// components/auth/ProfileHeader.tsx
'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/Button';
import { useAuth } from '@/contexts/AuthContext'; // ✅ NEW: Import useAuth
import { 
  User, 
  Shield, 
  CheckCircle, 
  AlertTriangle,
  Crown,
  Star,
  Zap
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

interface ProfileHeaderProps {
  profile: UserProfile;
  onUpdate: (updates: Partial<UserProfile>) => void;
}

export function ProfileHeader({ profile, onUpdate }: ProfileHeaderProps) {
  const [isEditing, setIsEditing] = useState(false);
  const [displayName, setDisplayName] = useState(profile.display_name || '');
  const [loading, setLoading] = useState(false);

  // ✅ NEW: Get updateProfile from AuthContext
  const { updateProfile } = useAuth();

  // Generate avatar initials
  const getAvatarInitials = () => {
    if (profile.display_name) {
      return profile.display_name.substring(0, 2).toUpperCase();
    }
    return profile.email.substring(0, 2).toUpperCase();
  };

  // Get account tier info (mock data for now)
  const getAccountTier = () => {
    // This would come from subscription data in real implementation
    return {
      name: 'Professional',
      icon: Star,
      color: 'text-yellow-400',
      bgColor: 'bg-yellow-400/20'
    };
  };

  const handleSaveDisplayName = async () => {
    setLoading(true);
    try {
      // ✅ FIXED: Use real API call from AuthContext
      await updateProfile({ display_name: displayName });
      
      onUpdate({ display_name: displayName });
      setIsEditing(false);
    } catch (error) {
      console.error('Failed to update display name:', error);
      // Reset to original value on error
      setDisplayName(profile.display_name || '');
    } finally {
      setLoading(false);
    }
  };

  const handleCancel = () => {
    setDisplayName(profile.display_name || '');
    setIsEditing(false);
  };

  const tier = getAccountTier();
  const TierIcon = tier.icon;

  return (
    <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-8">
      <div className="flex flex-col md:flex-row items-center md:items-start space-y-6 md:space-y-0 md:space-x-6">
        {/* Avatar */}
        <div className="relative">
          <div className="w-24 h-24 bg-gradient-cosmic rounded-full flex items-center justify-center text-white text-2xl font-bold shadow-lg">
            {getAvatarInitials()}
          </div>
          
          {/* Account tier badge */}
          <div className={cn(
            'absolute -bottom-2 -right-2 w-8 h-8 rounded-full flex items-center justify-center',
            tier.bgColor, 'border-2 border-white/20'
          )}>
            <TierIcon size={16} className={tier.color} />
          </div>
        </div>

        {/* User Info */}
        <div className="flex-1 text-center md:text-left">
          {/* Display Name */}
          <div className="mb-2">
            {isEditing ? (
              <div className="flex flex-col sm:flex-row gap-3 items-center">
                <input
                  type="text"
                  value={displayName}
                  onChange={(e) => setDisplayName(e.target.value)}
                  placeholder="Enter display name"
                  className="w-full sm:w-auto rounded-lg bg-white/10 backdrop-blur-sm border border-white/20 px-4 py-2 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-yellow-400 focus:border-transparent"
                  maxLength={50}
                />
                <div className="flex gap-2">
                  <Button
                    onClick={handleSaveDisplayName}
                    disabled={loading}
                    variant="cosmic"
                    size="sm"
                  >
                    {loading ? 'Saving...' : 'Save'}
                  </Button>
                  <Button
                    onClick={handleCancel}
                    disabled={loading}
                    variant="ghost"
                    size="sm"
                  >
                    Cancel
                  </Button>
                </div>
              </div>
            ) : (
              <div className="flex flex-col sm:flex-row items-center sm:items-start gap-2">
                <h2 className="text-2xl font-bold text-white">
                  {profile.display_name || 'Anonymous User'}
                </h2>
                <Button
                  onClick={() => setIsEditing(true)}
                  variant="ghost"
                  size="sm"
                  className="text-gray-400 hover:text-white"
                >
                  Edit
                </Button>
              </div>
            )}
          </div>

          {/* Email */}
          <p className="text-gray-300 mb-4">{profile.email}</p>

          {/* Account Status Badges */}
          <div className="flex flex-wrap gap-3 justify-center md:justify-start">
            {/* Account Tier */}
            <div className={cn(
              'flex items-center space-x-2 px-3 py-1 rounded-full text-sm font-medium',
              tier.bgColor, tier.color
            )}>
              <TierIcon size={14} />
              <span>{tier.name} Plan</span>
            </div>

            {/* Email Verified */}
            <div className="flex items-center space-x-2 px-3 py-1 rounded-full text-sm font-medium bg-green-500/20 text-green-400">
              <CheckCircle size={14} />
              <span>Verified</span>
            </div>

            {/* 2FA Status */}
            <div className={cn(
              'flex items-center space-x-2 px-3 py-1 rounded-full text-sm font-medium',
              profile.two_factor_enabled 
                ? 'bg-green-500/20 text-green-400' 
                : 'bg-orange-500/20 text-orange-400'
            )}>
              <Shield size={14} />
              <span>2FA {profile.two_factor_enabled ? 'Enabled' : 'Disabled'}</span>
            </div>
          </div>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-2 gap-4 text-center">
          <div className="backdrop-blur-sm bg-white/5 rounded-xl p-3">
            <div className="text-xl font-bold text-white">{profile.active_sessions_count}</div>
            <div className="text-xs text-gray-400">Active Sessions</div>
          </div>
          <div className="backdrop-blur-sm bg-white/5 rounded-xl p-3">
            <div className="text-xl font-bold text-white">
              {Math.floor((Date.now() - new Date(profile.created_at).getTime()) / (1000 * 60 * 60 * 24))}
            </div>
            <div className="text-xs text-gray-400">Days Member</div>
          </div>
        </div>
      </div>

      {/* Security Recommendations */}
      {!profile.two_factor_enabled && (
        <div className="mt-6 p-4 bg-orange-500/20 border border-orange-500/30 rounded-xl">
          <div className="flex items-start space-x-3">
            <AlertTriangle size={20} className="text-orange-400 mt-0.5 flex-shrink-0" />
            <div>
              <h4 className="font-semibold text-orange-400 mb-1">Enhance Your Security</h4>
              <p className="text-orange-300 text-sm">
                Enable two-factor authentication to add an extra layer of protection to your account. 
                This feature is coming soon!
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}