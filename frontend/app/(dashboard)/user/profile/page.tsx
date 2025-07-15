// app/user/profile/page.tsx - Updated to include active_sessions_count
'use client';

import { useState, useEffect } from 'react';
import { DashboardLayoutWrapper } from '@/components/dashboard/DashboardLayoutWrapper';
import { ProfileHeader } from '@/components/auth/ProfileHeader';
import { AccountSection } from '@/components/auth/AccountSection';
import { SecuritySection } from '@/components/auth/SecuritySection';
import { NotificationsSection } from '@/components/auth/NotificationsSection';
import { DataSection } from '@/components/auth/DataSection';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { useAuth } from '@/contexts/AuthContext';
import { api } from '@/lib/api';

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
  active_sessions_count: number; // ✅ This will now come from the backend
}

export default function ProfilePage() {
  const { user, loading: authLoading } = useAuth();
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Fetch complete profile data
  const fetchProfile = async () => {
    if (!user) return;

    try {
      setLoading(true);
      setError(null);
      
      // ✅ Get user data from auth/me endpoint which now includes active_sessions_count
      const userResponse = await api.auth.me();
      console.log('🔍 User data from API:', userResponse);

      // Assert the type of userResponse
      const typedUserResponse = userResponse as {
        data: {
          id: number;
          email: string;
          display_name?: string;
          timezone?: string;
          created_at: string;
          active_sessions_count?: number;
        };
      };
      
      // ✅ Build profile from API response
      const profileData: UserProfile = {
        id: typedUserResponse.data.id,
        email: typedUserResponse.data.email,
        display_name: typedUserResponse.data.display_name || '',
        timezone: typedUserResponse.data.timezone || 'America/New_York',
        notification_preferences: {
          device_alerts: true,
          billing_notifications: true,
          system_updates: false
        },
        two_factor_enabled: false, // TODO: Implement 2FA
        created_at: typedUserResponse.data.created_at,
        active_sessions_count: typedUserResponse.data.active_sessions_count || 1 // ✅ From API
      };
      
      console.log('✅ Profile data constructed:', profileData);
      setProfile(profileData);
      
    } catch (err) {
      console.error('❌ Failed to fetch profile:', err);
      setError(err instanceof Error ? err.message : 'Failed to load profile');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (user && !authLoading) {
      fetchProfile();
    }
  }, [user, authLoading]);

  // Handle profile updates
  const handleProfileUpdate = async (updates: Partial<UserProfile>) => {
    setProfile(prev => prev ? { ...prev, ...updates } : null);
    
    // ✅ If display_name or timezone were updated, sync with backend
    if (updates.display_name !== undefined || updates.timezone !== undefined) {
      try {
        await api.auth.updateProfile({
          display_name: updates.display_name ?? profile?.display_name ?? '',
          timezone: updates.timezone ?? profile?.timezone ?? 'UTC'
        });
        console.log('✅ Profile synced with backend');
      } catch (error) {
        console.error('❌ Failed to sync profile with backend:', error);
        // Could show an error toast here
      }
    }
  };

  if (authLoading || loading) {
    return (
      <DashboardLayoutWrapper>
        <div className="flex items-center justify-center min-h-[400px]">
          <LoadingSpinner size="lg" text="Loading profile..." />
        </div>
      </DashboardLayoutWrapper>
    );
  }

  if (error) {
    return (
      <DashboardLayoutWrapper>
        <div className="max-w-4xl mx-auto">
          <div className="bg-red-500/20 border border-red-500/30 rounded-3xl p-8 text-center">
            <h2 className="text-xl font-bold text-red-300 mb-2">Error Loading Profile</h2>
            <p className="text-red-200">{error}</p>
          </div>
        </div>
      </DashboardLayoutWrapper>
    );
  }

  if (!profile) {
    return (
      <DashboardLayoutWrapper>
        <div className="max-w-4xl mx-auto">
          <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-8 text-center">
            <h2 className="text-xl font-bold text-white mb-2">Profile Not Found</h2>
            <p className="text-gray-300">Unable to load your profile information.</p>
          </div>
        </div>
      </DashboardLayoutWrapper>
    );
  }

  return (
    <DashboardLayoutWrapper>
      <div className="max-w-4xl mx-auto space-y-8">
        {/* Floating decorative elements */}
        <div className="absolute top-20 left-10 w-32 h-32 bg-gradient-radial from-yellow-400/20 to-transparent rounded-full blur-2xl animate-slow-float" />
        <div className="absolute top-40 right-20 w-24 h-24 bg-gradient-radial from-purple-500/20 to-transparent rounded-full blur-xl animate-slow-float-reverse" />
        
        {/* Header */}
        <div className="text-center relative z-10">
          <h1 className="text-4xl font-bold text-white mb-4">
            Profile Settings
          </h1>
          <p className="text-gray-300">
            Manage your account information, security, and preferences
          </p>
        </div>

        {/* Profile sections */}
        <div className="space-y-6 relative z-10">
          <ProfileHeader 
            profile={profile}
            onUpdate={handleProfileUpdate}
          />
          
          <AccountSection 
            profile={profile}
            onUpdate={handleProfileUpdate}
          />
          
          <SecuritySection 
            profile={profile}
            onUpdate={handleProfileUpdate}
          />
          
          <NotificationsSection 
            profile={profile}
            onUpdate={handleProfileUpdate}
          />
          
          <DataSection 
            profile={profile}
            onUpdate={handleProfileUpdate}
          />
        </div>

        {/* Footer info */}
        <div className="text-center text-gray-400 text-sm relative z-10">
          <p>Account created: {new Date(profile.created_at).toLocaleDateString()}</p>
          <p className="mt-2">🔐 Active sessions are tracked for your security</p>
        </div>
      </div>
    </DashboardLayoutWrapper>
  );
}