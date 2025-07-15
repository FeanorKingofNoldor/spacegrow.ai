// components/auth/SecuritySection.tsx
'use client';

import { useState, useEffect } from 'react';
import { Button } from '@/components/ui/Button';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { Modal } from '@/components/ui/Modal';
import { ChangePasswordModal } from '@/components/auth/modals/ChangePasswordModal';
import { TwoFactorModal } from '@/components/auth/modals/TwoFactorModal';
import { api, UserSession } from '@/lib/api';
import { 
  Shield, 
  Lock, 
  Smartphone, 
  Monitor, 
  MapPin,
  Clock,
  CheckCircle,
  AlertTriangle,
  ChevronRight,
  LogOut,
  Trash2
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

interface SecuritySectionProps {
  profile: UserProfile;
  onUpdate: (updates: Partial<UserProfile>) => void;
}

export function SecuritySection({ profile, onUpdate }: SecuritySectionProps) {
  const [showPasswordModal, setShowPasswordModal] = useState(false);
  const [showTwoFactorModal, setShowTwoFactorModal] = useState(false);
  const [showSessions, setShowSessions] = useState(false);
  const [sessions, setSessions] = useState<UserSession[]>([]);
  const [sessionsLoading, setSessionsLoading] = useState(false);
  const [sessionError, setSessionError] = useState<string | null>(null);
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  
  // Confirmation modals
  const [showLogoutAllModal, setShowLogoutAllModal] = useState(false);
  const [sessionToLogout, setSessionToLogout] = useState<string | null>(null);

  // Fetch sessions when expanding the section
  const fetchSessions = async () => {
    setSessionsLoading(true);
    setSessionError(null);
    
    try {
      console.log('🔍 Fetching active sessions...');
      const response = await api.auth.getSessions();
      console.log('✅ Sessions fetched:', response.data);
      
      setSessions(response.data.sessions);
      
      // Update profile with current session count
      onUpdate({ active_sessions_count: response.data.total_count });
      
    } catch (error) {
      console.error('❌ Failed to fetch sessions:', error);
      setSessionError(error instanceof Error ? error.message : 'Failed to load sessions');
    } finally {
      setSessionsLoading(false);
    }
  };

  // Load sessions when section is expanded
  useEffect(() => {
    if (showSessions && sessions.length === 0) {
      fetchSessions();
    }
  }, [showSessions]);

  const handlePasswordChanged = () => {
    setShowPasswordModal(false);
    // Could show a success toast here
  };

  const handleLogoutSession = async (jti: string) => {
    if (!jti) return;
    
    setActionLoading(`logout-${jti}`);
    try {
      console.log('🔄 Logging out session:', jti);
      await api.auth.logoutSession(jti);
      console.log('✅ Session logged out successfully');
      
      // Remove session from local state
      setSessions(prev => prev.filter(session => session.jti !== jti));
      
      // Update profile session count
      onUpdate({ active_sessions_count: profile.active_sessions_count - 1 });
      
    } catch (error) {
      console.error('❌ Failed to logout session:', error);
      setSessionError(error instanceof Error ? error.message : 'Failed to logout session');
    } finally {
      setActionLoading(null);
      setSessionToLogout(null);
    }
  };

  const handleLogoutAllSessions = async () => {
    setActionLoading('logout_all');
    try {
      console.log('🔄 Logging out all other sessions...');
      await api.auth.logoutAllSessions();
      console.log('✅ All other sessions logged out successfully');
      
      // Keep only current session
      setSessions(prev => prev.filter(session => session.is_current));
      
      // Update profile session count (should be 1 - just current session)
      onUpdate({ active_sessions_count: 1 });
      
    } catch (error) {
      console.error('❌ Failed to logout all sessions:', error);
      setSessionError(error instanceof Error ? error.message : 'Failed to logout all sessions');
    } finally {
      setActionLoading(null);
      setShowLogoutAllModal(false);
    }
  };

  const formatLastActive = (lastActive: string) => {
    // The backend already formats this for us
    return lastActive;
  };

  const getDeviceIcon = (deviceType: string) => {
    const type = deviceType.toLowerCase();
    if (type.includes('iphone') || type.includes('android') || type.includes('mobile')) {
      return Smartphone;
    }
    return Monitor;
  };

  const getSessionStatusColor = (session: UserSession) => {
    if (session.is_current) return 'text-green-400';
    if (session.last_active === 'Active now') return 'text-green-400';
    return 'text-cosmic-text-muted';
  };

  return (
    <>
      <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-8">
        <h3 className="text-xl font-bold text-white mb-6 flex items-center">
          <Shield className="mr-3 text-yellow-400" size={24} />
          Security & Authentication
        </h3>

        <div className="space-y-6">
          {/* Password */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div className="flex items-center space-x-3">
              <Lock className="text-gray-400" size={20} />
              <div>
                <div className="text-white font-medium">Password</div>
                <div className="text-gray-300 text-sm">
                  Last changed: {new Date(profile.created_at).toLocaleDateString()}
                </div>
              </div>
            </div>
            <Button
              onClick={() => setShowPasswordModal(true)}
              variant="outline"
              size="sm"
              className="flex items-center"
            >
              <Lock size={16} className="mr-2" />
              Change Password
            </Button>
          </div>

          {/* Two-Factor Authentication */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div className="flex items-center space-x-3">
              <Smartphone className="text-gray-400" size={20} />
              <div>
                <div className="text-white font-medium flex items-center gap-2">
                  Two-Factor Authentication
                  {profile.two_factor_enabled ? (
                    <CheckCircle className="text-green-400" size={16} />
                  ) : (
                    <AlertTriangle className="text-orange-400" size={16} />
                  )}
                </div>
                <div className={cn(
                  "text-sm",
                  profile.two_factor_enabled ? "text-green-300" : "text-orange-300"
                )}>
                  {profile.two_factor_enabled 
                    ? "Extra security layer enabled" 
                    : "Add extra security to your account"
                  }
                </div>
              </div>
            </div>
            <Button
              onClick={() => setShowTwoFactorModal(true)}
              variant={profile.two_factor_enabled ? "outline" : "cosmic"}
              size="sm"
              className="flex items-center"
            >
              <Smartphone size={16} className="mr-2" />
              {profile.two_factor_enabled ? "Manage 2FA" : "Setup 2FA"}
            </Button>
          </div>

          {/* Active Sessions */}
          <div className="border-t border-white/10 pt-6">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center space-x-3">
                <Monitor className="text-gray-400" size={20} />
                <div>
                  <div className="text-white font-medium">Active Sessions</div>
                  <div className="text-gray-300 text-sm">
                    {profile.active_sessions_count} active session{profile.active_sessions_count > 1 ? 's' : ''} • Manage your logged in devices
                  </div>
                </div>
              </div>
              <Button
                onClick={() => setShowSessions(!showSessions)}
                variant="ghost"
                size="sm"
                className="flex items-center"
                disabled={sessionsLoading}
              >
                {sessionsLoading ? (
                  <LoadingSpinner size="sm" />
                ) : (
                  <>
                    View Sessions
                    <ChevronRight 
                      size={16} 
                      className={cn(
                        "ml-2 transition-transform",
                        showSessions && "rotate-90"
                      )} 
                    />
                  </>
                )}
              </Button>
            </div>

            {/* Sessions List */}
            {showSessions && (
              <div className="space-y-3 bg-white/5 rounded-xl p-4">
                {/* Error State */}
                {sessionError && (
                  <div className="bg-red-500/20 border border-red-500/30 rounded-lg p-3">
                    <div className="text-red-400 text-sm">{sessionError}</div>
                    <Button 
                      onClick={fetchSessions}
                      variant="ghost" 
                      size="sm" 
                      className="mt-2 text-red-300 hover:text-red-200"
                    >
                      Try Again
                    </Button>
                  </div>
                )}

                {/* Loading State */}
                {sessionsLoading && (
                  <div className="flex items-center justify-center py-8">
                    <LoadingSpinner size="sm" text="Loading sessions..." />
                  </div>
                )}

                {/* Sessions */}
                {!sessionsLoading && !sessionError && sessions.length > 0 && (
                  <>
                    {/* Logout All Button */}
                    {sessions.filter(s => !s.is_current).length > 0 && (
                      <div className="flex justify-end mb-3">
                        <Button
                          onClick={() => setShowLogoutAllModal(true)}
                          disabled={actionLoading === 'logout_all'}
                          variant="outline"
                          size="sm"
                          className="text-orange-400 border-orange-400 hover:bg-orange-500/20"
                        >
                          {actionLoading === 'logout_all' ? (
                            <>
                              <LoadingSpinner size="sm" />
                              <span className="ml-2">Logging out...</span>
                            </>
                          ) : (
                            <>
                              <LogOut size={14} className="mr-2" />
                              Logout All Other Sessions
                            </>
                          )}
                        </Button>
                      </div>
                    )}

                    {sessions.map((session) => {
                      const DeviceIcon = getDeviceIcon(session.device_type);
                      const isLoading = actionLoading === `logout-${session.jti}`;
                      
                      return (
                        <div key={session.jti} className="flex items-center justify-between bg-white/5 rounded-lg p-3">
                          <div className="flex items-center space-x-3">
                            <DeviceIcon className="text-gray-400" size={18} />
                            <div>
                              <div className="text-white text-sm font-medium flex items-center gap-2">
                                {session.device_type}
                                {session.is_current && (
                                  <span className="px-2 py-0.5 bg-green-500/20 text-green-400 text-xs rounded-full">
                                    This Device
                                  </span>
                                )}
                              </div>
                              <div className="text-gray-400 text-xs flex items-center gap-4">
                                <span className="flex items-center gap-1">
                                  <MapPin size={12} />
                                  {session.ip_address}
                                </span>
                                <span className={cn(
                                  "flex items-center gap-1",
                                  getSessionStatusColor(session)
                                )}>
                                  <Clock size={12} />
                                  {formatLastActive(session.last_active)}
                                </span>
                              </div>
                            </div>
                          </div>
                          
                          {/* Logout Button - Hidden for current session */}
                          {!session.is_current && (
                            <Button
                              onClick={() => setSessionToLogout(session.jti)}
                              disabled={isLoading}
                              variant="ghost"
                              size="sm"
                              className="text-red-400 hover:text-red-300 hover:bg-red-500/20"
                            >
                              {isLoading ? (
                                <LoadingSpinner size="sm" />
                              ) : (
                                <>
                                  <LogOut size={14} className="mr-1" />
                                  Logout
                                </>
                              )}
                            </Button>
                          )}
                        </div>
                      );
                    })}
                  </>
                )}

                {/* Empty State */}
                {!sessionsLoading && !sessionError && sessions.length === 0 && (
                  <div className="text-center py-6">
                    <Monitor className="w-12 h-12 text-gray-400 mx-auto mb-2" />
                    <div className="text-gray-300 text-sm">No active sessions found</div>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>

        {/* Security Tips */}
        <div className="mt-6 p-4 bg-blue-500/20 border border-blue-500/30 rounded-xl">
          <h4 className="font-semibold text-blue-300 mb-2">Security Tips</h4>
          <ul className="text-blue-200 text-sm space-y-1">
            <li>• Use a strong, unique password for your account</li>
            <li>• Enable two-factor authentication for extra security</li>
            <li>• Regularly review your active sessions</li>
            <li>• Logout from devices you no longer use</li>
          </ul>
        </div>
      </div>

      {/* Modals */}
      <ChangePasswordModal
        isOpen={showPasswordModal}
        onClose={() => setShowPasswordModal(false)}
        onPasswordChanged={handlePasswordChanged}
      />

      <TwoFactorModal
        isOpen={showTwoFactorModal}
        onClose={() => setShowTwoFactorModal(false)}
        twoFactorEnabled={profile.two_factor_enabled}
        onTwoFactorChanged={(enabled) => onUpdate({ two_factor_enabled: enabled })}
      />

      {/* Logout All Confirmation Modal */}
      <Modal
        isOpen={showLogoutAllModal}
        onClose={() => setShowLogoutAllModal(false)}
        title="Logout All Other Sessions"
        size="sm"
      >
        <div className="space-y-4">
          <div className="flex items-start space-x-3">
            <div className="w-12 h-12 bg-orange-500/20 rounded-xl flex items-center justify-center flex-shrink-0">
              <LogOut className="w-6 h-6 text-orange-400" />
            </div>
            <div>
              <h3 className="text-lg font-semibold text-cosmic-text mb-2">
                Logout All Other Sessions?
              </h3>
              <p className="text-cosmic-text-muted text-sm">
                This will log you out from all other devices and browsers. Your current session will remain active.
              </p>
            </div>
          </div>
          
          <div className="flex space-x-3">
            <Button 
              variant="ghost"
              onClick={() => setShowLogoutAllModal(false)}
              disabled={actionLoading === 'logout_all'}
              className="flex-1"
            >
              Cancel
            </Button>
            <Button 
              variant="cosmic"
              onClick={handleLogoutAllSessions}
              disabled={actionLoading === 'logout_all'}
              className="flex-1 bg-orange-500 hover:bg-orange-600"
            >
              {actionLoading === 'logout_all' ? (
                <>
                  <LoadingSpinner size="sm" />
                  <span className="ml-2">Logging out...</span>
                </>
              ) : (
                'Logout All Others'
              )}
            </Button>
          </div>
        </div>
      </Modal>

      {/* Single Session Logout Confirmation */}
      <Modal
        isOpen={!!sessionToLogout}
        onClose={() => setSessionToLogout(null)}
        title="Logout Session"
        size="sm"
      >
        <div className="space-y-4">
          <div className="flex items-start space-x-3">
            <div className="w-12 h-12 bg-red-500/20 rounded-xl flex items-center justify-center flex-shrink-0">
              <LogOut className="w-6 h-6 text-red-400" />
            </div>
            <div>
              <h3 className="text-lg font-semibold text-cosmic-text mb-2">
                Logout This Session?
              </h3>
              <p className="text-cosmic-text-muted text-sm">
                This will immediately log out this device/browser session.
              </p>
            </div>
          </div>
          
          <div className="flex space-x-3">
            <Button 
              variant="ghost"
              onClick={() => setSessionToLogout(null)}
              disabled={!!actionLoading}
              className="flex-1"
            >
              Cancel
            </Button>
            <Button 
              variant="cosmic"
              onClick={() => sessionToLogout && handleLogoutSession(sessionToLogout)}
              disabled={!!actionLoading}
              className="flex-1 bg-red-500 hover:bg-red-600"
            >
              Logout Session
            </Button>
          </div>
        </div>
      </Modal>
    </>
  );
}