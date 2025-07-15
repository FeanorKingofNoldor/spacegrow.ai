// components/profile/AccountSection.tsx - FIXED with comprehensive timezone list
'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/Button';
import { Modal } from '@/components/ui/Modal';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { User, Mail, Globe, Calendar, Check } from 'lucide-react';
import { cn } from '@/lib/utils';

interface AccountSectionProps {
  profile?: {
    id: number;
    email: string;
    display_name?: string;
    timezone?: string;
    created_at: string;
  };
  onUpdate: (updates: any) => void;
}

// ✅ COMPREHENSIVE TIMEZONE LIST - All major timezones organized by region
const timezoneGroups = [
  {
    label: 'North America',
    timezones: [
      { value: 'America/New_York', label: 'Eastern Time (ET)' },
      { value: 'America/Chicago', label: 'Central Time (CT)' },
      { value: 'America/Denver', label: 'Mountain Time (MT)' },
      { value: 'America/Los_Angeles', label: 'Pacific Time (PT)' },
      { value: 'America/Anchorage', label: 'Alaska Time (AKT)' },
      { value: 'Pacific/Honolulu', label: 'Hawaii Time (HST)' },
      { value: 'America/Toronto', label: 'Toronto (Eastern)' },
      { value: 'America/Vancouver', label: 'Vancouver (Pacific)' },
      { value: 'America/Montreal', label: 'Montreal (Eastern)' },
      { value: 'America/Phoenix', label: 'Phoenix (MST - No DST)' },
      { value: 'America/Halifax', label: 'Halifax (Atlantic)' },
      { value: 'America/St_Johns', label: 'Newfoundland' },
    ]
  },
  {
    label: 'Europe',
    timezones: [
      { value: 'Europe/London', label: 'London (GMT/BST)' },
      { value: 'Europe/Paris', label: 'Paris (CET)' },
      { value: 'Europe/Berlin', label: 'Berlin (CET)' },
      { value: 'Europe/Rome', label: 'Rome (CET)' },
      { value: 'Europe/Madrid', label: 'Madrid (CET)' },
      { value: 'Europe/Amsterdam', label: 'Amsterdam (CET)' },
      { value: 'Europe/Brussels', label: 'Brussels (CET)' },
      { value: 'Europe/Vienna', label: 'Vienna (CET)' },
      { value: 'Europe/Zurich', label: 'Zurich (CET)' },
      { value: 'Europe/Stockholm', label: 'Stockholm (CET)' },
      { value: 'Europe/Helsinki', label: 'Helsinki (EET)' },
      { value: 'Europe/Athens', label: 'Athens (EET)' },
      { value: 'Europe/Moscow', label: 'Moscow (MSK)' },
      { value: 'Europe/Istanbul', label: 'Istanbul (TRT)' },
      { value: 'Europe/Dublin', label: 'Dublin (GMT/IST)' },
      { value: 'Europe/Oslo', label: 'Oslo (CET)' },
      { value: 'Europe/Copenhagen', label: 'Copenhagen (CET)' },
      { value: 'Europe/Warsaw', label: 'Warsaw (CET)' },
      { value: 'Europe/Prague', label: 'Prague (CET)' },
      { value: 'Europe/Budapest', label: 'Budapest (CET)' },
    ]
  },
  {
    label: 'Asia Pacific',
    timezones: [
      { value: 'Asia/Tokyo', label: 'Tokyo (JST)' },
      { value: 'Asia/Shanghai', label: 'Shanghai (CST)' },
      { value: 'Asia/Hong_Kong', label: 'Hong Kong (HKT)' },
      { value: 'Asia/Singapore', label: 'Singapore (SGT)' },
      { value: 'Asia/Seoul', label: 'Seoul (KST)' },
      { value: 'Asia/Taipei', label: 'Taipei (CST)' },
      { value: 'Asia/Bangkok', label: 'Bangkok (ICT)' },
      { value: 'Asia/Jakarta', label: 'Jakarta (WIB)' },
      { value: 'Asia/Manila', label: 'Manila (PHT)' },
      { value: 'Asia/Kuala_Lumpur', label: 'Kuala Lumpur (MYT)' },
      { value: 'Asia/Ho_Chi_Minh', label: 'Ho Chi Minh City (ICT)' },
      { value: 'Asia/Colombo', label: 'Colombo (IST)' },
      { value: 'Asia/Dhaka', label: 'Dhaka (BST)' },
      { value: 'Asia/Karachi', label: 'Karachi (PKT)' },
      { value: 'Asia/Kolkata', label: 'Mumbai/Delhi (IST)' },
      { value: 'Asia/Dubai', label: 'Dubai (GST)' },
      { value: 'Asia/Tehran', label: 'Tehran (IRST)' },
      { value: 'Asia/Jerusalem', label: 'Jerusalem (IST)' },
      { value: 'Asia/Riyadh', label: 'Riyadh (AST)' },
    ]
  },
  {
    label: 'Australia & New Zealand',
    timezones: [
      { value: 'Australia/Sydney', label: 'Sydney (AEST)' },
      { value: 'Australia/Melbourne', label: 'Melbourne (AEST)' },
      { value: 'Australia/Brisbane', label: 'Brisbane (AEST)' },
      { value: 'Australia/Perth', label: 'Perth (AWST)' },
      { value: 'Australia/Adelaide', label: 'Adelaide (ACST)' },
      { value: 'Australia/Darwin', label: 'Darwin (ACST)' },
      { value: 'Australia/Hobart', label: 'Hobart (AEST)' },
      { value: 'Pacific/Auckland', label: 'Auckland (NZST)' },
      { value: 'Pacific/Fiji', label: 'Fiji (FJT)' },
    ]
  },
  {
    label: 'South America',
    timezones: [
      { value: 'America/Sao_Paulo', label: 'São Paulo (BRT)' },
      { value: 'America/Argentina/Buenos_Aires', label: 'Buenos Aires (ART)' },
      { value: 'America/Santiago', label: 'Santiago (CLT)' },
      { value: 'America/Lima', label: 'Lima (PET)' },
      { value: 'America/Bogota', label: 'Bogotá (COT)' },
      { value: 'America/Caracas', label: 'Caracas (VET)' },
      { value: 'America/Mexico_City', label: 'Mexico City (CST)' },
      { value: 'America/Montevideo', label: 'Montevideo (UYT)' },
    ]
  },
  {
    label: 'Africa & Middle East',
    timezones: [
      { value: 'Africa/Cairo', label: 'Cairo (EET)' },
      { value: 'Africa/Johannesburg', label: 'Johannesburg (SAST)' },
      { value: 'Africa/Lagos', label: 'Lagos (WAT)' },
      { value: 'Africa/Nairobi', label: 'Nairobi (EAT)' },
      { value: 'Africa/Casablanca', label: 'Casablanca (WET)' },
      { value: 'Africa/Tunis', label: 'Tunis (CET)' },
      { value: 'Africa/Algiers', label: 'Algiers (CET)' },
    ]
  },
  {
    label: 'UTC Offsets',
    timezones: [
      { value: 'UTC', label: 'UTC (Coordinated Universal Time)' },
      { value: 'Etc/GMT+12', label: 'UTC-12' },
      { value: 'Etc/GMT+11', label: 'UTC-11' },
      { value: 'Etc/GMT+10', label: 'UTC-10' },
      { value: 'Etc/GMT+9', label: 'UTC-9' },
      { value: 'Etc/GMT+8', label: 'UTC-8' },
      { value: 'Etc/GMT+7', label: 'UTC-7' },
      { value: 'Etc/GMT+6', label: 'UTC-6' },
      { value: 'Etc/GMT+5', label: 'UTC-5' },
      { value: 'Etc/GMT+4', label: 'UTC-4' },
      { value: 'Etc/GMT+3', label: 'UTC-3' },
      { value: 'Etc/GMT+2', label: 'UTC-2' },
      { value: 'Etc/GMT+1', label: 'UTC-1' },
      { value: 'Etc/GMT-1', label: 'UTC+1' },
      { value: 'Etc/GMT-2', label: 'UTC+2' },
      { value: 'Etc/GMT-3', label: 'UTC+3' },
      { value: 'Etc/GMT-4', label: 'UTC+4' },
      { value: 'Etc/GMT-5', label: 'UTC+5' },
      { value: 'Etc/GMT-6', label: 'UTC+6' },
      { value: 'Etc/GMT-7', label: 'UTC+7' },
      { value: 'Etc/GMT-8', label: 'UTC+8' },
      { value: 'Etc/GMT-9', label: 'UTC+9' },
      { value: 'Etc/GMT-10', label: 'UTC+10' },
      { value: 'Etc/GMT-11', label: 'UTC+11' },
      { value: 'Etc/GMT-12', label: 'UTC+12' },
    ]
  }
];

// ✅ Flatten all timezones for search functionality
const allTimezones = timezoneGroups.flatMap(group => group.timezones);

export function AccountSection({ profile, onUpdate }: AccountSectionProps) {
  const [isEditing, setIsEditing] = useState(false);
  const [displayName, setDisplayName] = useState(profile?.display_name || '');
  const [selectedTimezone, setSelectedTimezone] = useState(profile?.timezone || 'UTC');
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);

  // ✅ Show loading state if profile is not loaded yet
  if (!profile) {
    return (
      <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
        <div className="flex items-center justify-center h-32">
          <LoadingSpinner />
        </div>
      </div>
    );
  }

  // ✅ Filter timezones based on search
  const filteredTimezones = searchTerm
    ? allTimezones.filter(tz => 
        tz.label.toLowerCase().includes(searchTerm.toLowerCase()) ||
        tz.value.toLowerCase().includes(searchTerm.toLowerCase())
      )
    : null;

  const handleSave = async () => {
    setLoading(true);
    try {
      // ✅ Update the profile using the onUpdate callback
      onUpdate({
        display_name: displayName || undefined,
        timezone: selectedTimezone
      });
      
      // TODO: Add actual API call when backend endpoint is ready
      // await api.auth.updateProfile({ display_name: displayName, timezone: selectedTimezone });
      
      setIsEditing(false);
    } catch (error) {
      console.error('Failed to update profile:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCancel = () => {
    setDisplayName(profile?.display_name || '');
    setSelectedTimezone(profile?.timezone || 'UTC');
    setSearchTerm('');
    setIsDropdownOpen(false);
    setIsEditing(false);
  };

  // ✅ Handle timezone selection and close dropdown
  const handleTimezoneSelect = (timezoneValue: string) => {
    setSelectedTimezone(timezoneValue);
    setSearchTerm('');
    setIsDropdownOpen(false);
  };

  // ✅ Get current timezone display
  const currentTimezoneDisplay = allTimezones.find(tz => tz.value === selectedTimezone)?.label || selectedTimezone;

  return (
    <>
      <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-gradient-cosmic rounded-lg flex items-center justify-center">
              <User size={20} className="text-white" />
            </div>
            <div>
              <h3 className="text-lg font-semibold text-cosmic-text">Account Information</h3>
              <p className="text-cosmic-text-muted text-sm">Manage your basic account details</p>
            </div>
          </div>
          
          {!isEditing && (
            <Button variant="outline" onClick={() => setIsEditing(true)} size="sm">
              Edit Profile
            </Button>
          )}
        </div>

        <div className="space-y-4">
          {/* Email (Read-only) */}
          <div>
            <label className="flex items-center text-sm font-medium text-cosmic-text mb-2">
              <Mail size={16} className="mr-2" />
              Email Address
            </label>
            <div className="bg-space-secondary border border-space-border rounded-lg px-3 py-2">
              <span className="text-cosmic-text">{profile.email}</span>
              <span className="text-cosmic-text-muted text-xs ml-2">(cannot be changed)</span>
            </div>
          </div>

          {/* Display Name */}
          <div>
            <label className="flex items-center text-sm font-medium text-cosmic-text mb-2">
              <User size={16} className="mr-2" />
              Display Name
            </label>
            {isEditing ? (
              <input
                type="text"
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
                placeholder="Enter your display name"
                className="w-full bg-space-secondary border border-space-border rounded-lg px-3 py-2 text-cosmic-text placeholder-cosmic-text-muted focus:outline-none focus:ring-2 focus:ring-stellar-accent"
              />
            ) : (
              <div className="bg-space-secondary border border-space-border rounded-lg px-3 py-2">
                <span className="text-cosmic-text">
                  {profile.display_name || 'Not set'}
                </span>
              </div>
            )}
          </div>

          {/* Timezone */}
          <div>
            <label className="flex items-center text-sm font-medium text-cosmic-text mb-2">
              <Globe size={16} className="mr-2" />
              Timezone
            </label>
            {isEditing ? (
              <div className="relative">
                <input
                  type="text"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  onFocus={() => setIsDropdownOpen(true)}
                  placeholder="Search timezones..."
                  className="w-full bg-space-secondary border border-space-border rounded-lg px-3 py-2 text-cosmic-text placeholder-cosmic-text-muted focus:outline-none focus:ring-2 focus:ring-stellar-accent"
                />
                
                {isDropdownOpen && (
                  <div className="absolute top-full left-0 right-0 mt-1 bg-space-glass backdrop-blur-md border border-space-border rounded-lg max-h-60 overflow-y-auto z-50">
                    {searchTerm && filteredTimezones ? (
                      filteredTimezones.length > 0 ? (
                        filteredTimezones.map((timezone) => (
                          <button
                            key={timezone.value}
                            onClick={() => handleTimezoneSelect(timezone.value)}
                            className="w-full text-left px-3 py-2 hover:bg-space-secondary transition-colors flex items-center justify-between"
                          >
                            <span className="text-cosmic-text">{timezone.label}</span>
                            {selectedTimezone === timezone.value && (
                              <Check size={16} className="text-green-400" />
                            )}
                          </button>
                        ))
                      ) : (
                        <div className="px-3 py-2 text-cosmic-text-muted text-sm">
                          No timezones found
                        </div>
                      )
                    ) : (
                      timezoneGroups.map((group) => (
                        <div key={group.label}>
                          <div className="px-3 py-2 bg-space-secondary text-cosmic-text-muted text-xs font-medium border-b border-space-border">
                            {group.label}
                          </div>
                          {group.timezones.map((timezone) => (
                            <button
                              key={timezone.value}
                              onClick={() => handleTimezoneSelect(timezone.value)}
                              className="w-full text-left px-3 py-2 hover:bg-space-secondary transition-colors flex items-center justify-between"
                            >
                              <span className="text-cosmic-text">{timezone.label}</span>
                              {selectedTimezone === timezone.value && (
                                <Check size={16} className="text-green-400" />
                              )}
                            </button>
                          ))}
                        </div>
                      ))
                    )}
                  </div>
                )}
              </div>
            ) : (
              <div className="bg-space-secondary border border-space-border rounded-lg px-3 py-2">
                <span className="text-cosmic-text">{currentTimezoneDisplay}</span>
              </div>
            )}
          </div>

          {/* Account Created */}
          <div>
            <label className="flex items-center text-sm font-medium text-cosmic-text mb-2">
              <Calendar size={16} className="mr-2" />
              Account Created
            </label>
            <div className="bg-space-secondary border border-space-border rounded-lg px-3 py-2">
              <span className="text-cosmic-text">
                {new Date(profile.created_at).toLocaleDateString('en-US', {
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric'
                })}
              </span>
            </div>
          </div>

          {/* Action Buttons */}
          {isEditing && (
            <div className="flex space-x-3 pt-4">
              <Button
                variant="cosmic"
                onClick={handleSave}
                disabled={loading}
                className="flex-1"
              >
                {loading ? (
                  <>
                    <LoadingSpinner size="sm" />
                    <span className="ml-2">Saving...</span>
                  </>
                ) : (
                  'Save Changes'
                )}
              </Button>
              <Button
                variant="ghost"
                onClick={handleCancel}
                disabled={loading}
                className="flex-1"
              >
                Cancel
              </Button>
            </div>
          )}
        </div>
      </div>
    </>
  );
}