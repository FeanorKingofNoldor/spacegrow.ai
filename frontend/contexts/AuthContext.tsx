'use client'

import { createContext, useContext, useEffect, useState, ReactNode } from 'react'
import { api } from '@/lib/api' // ✅ Import the new API client
import { Subscription } from '@/types/subscription'

// ✅ UPDATED: Types for our auth system with display_name
interface User {
  id: number
  email: string
  display_name: string // ✅ NEW: Added display_name
  timezone?: string    // ✅ NEW: Added timezone
  role: 'user' | 'pro' | 'admin'
  created_at: string
  devices_count: number
  subscription?: Subscription
}

interface AuthResponse {
  status: {
    code: number
    message: string
  }
  data: User
  token: string
}

// ✅ UPDATED: AuthContextType with display_name support
interface AuthContextType {
  user: User | null
  loading: boolean
  login: (email: string, password: string) => Promise<boolean>
  signup: (email: string, password: string, passwordConfirmation: string, displayName?: string) => Promise<boolean> // ✅ NEW: Optional display_name
  logout: () => void
  refreshToken: () => Promise<boolean>
  getCurrentUser: () => Promise<boolean>
  setUser: (user: User | null) => void
  updateProfile: (updates: { display_name?: string; timezone?: string }) => Promise<boolean> // ✅ NEW: Profile update method
  isAuthenticated: boolean
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  // Check if user is authenticated on app start
  useEffect(() => {
    checkAuth()
  }, [])

  // Check authentication status
  const checkAuth = async () => {
    const token = getStoredToken()
    if (token) {
      console.log('🔐 Found stored token, checking auth...', token.substring(0, 10) + '...')
      // Try to get current user info
      const success = await getCurrentUser()
      if (!success) {
        // Token is invalid, clear it
        console.log('🔐 Token invalid, clearing auth')
        clearAuth()
      }
    } else {
      console.log('🔐 No stored token found')
    }
    setLoading(false)
  }

  // Get current user from API
  const getCurrentUser = async (): Promise<boolean> => {
    const token = getStoredToken()
    if (!token) return false

    try {
      console.log('🔐 Getting current user from API...')
      
      // ✅ Use the new API client
      const data = await api.auth.me() as AuthResponse
      console.log('🔐 Current user response:', data)
      
      if (data.data) {
        setUser(data.data)
        return true
      } else {
        console.warn('🔐 No user data in response')
        clearAuth()
        return false
      }
    } catch (error) {
      console.error('🚨 Get current user failed:', error)
      clearAuth()
      return false
    }
  }

  // Login function
  const login = async (email: string, password: string): Promise<boolean> => {
    try {
      console.log('🔐 Attempting login for:', email)
      
      // ✅ Use the new API client
      const data = await api.auth.login(email, password) as AuthResponse
      console.log('🔐 Login response:', data)
      
      if (data.data && data.token) {
        setUser(data.data)
        storeToken(data.token)
        console.log('✅ Login successful')
        return true
      } else {
        console.error('🚨 Login failed: Invalid response structure')
        return false
      }
    } catch (error) {
      console.error('🚨 Login failed:', error)
      return false
    }
  }

  // ✅ UPDATED: Signup function with display_name support
  const signup = async (
    email: string, 
    password: string, 
    passwordConfirmation: string,
    displayName?: string // ✅ NEW: Optional display name
  ): Promise<boolean> => {
    try {
      console.log('🔐 Attempting signup for:', email)
      
      // ✅ Use the new API client with display_name
      const data = await api.auth.signup(email, password, passwordConfirmation, displayName) as AuthResponse
      console.log('🔐 Signup response:', data)
      
      if (data.data && data.token) {
        setUser(data.data)
        storeToken(data.token)
        console.log('✅ Signup successful')
        return true
      } else {
        console.error('🚨 Signup failed: Invalid response structure')
        return false
      }
    } catch (error) {
      console.error('🚨 Signup failed:', error)
      return false
    }
  }

  // ✅ NEW: Profile update function
  const updateProfile = async (updates: { display_name?: string; timezone?: string }): Promise<boolean> => {
    try {
      console.log('🔐 Updating profile:', updates)
      
      const data = await api.auth.updateProfile(updates) as AuthResponse
      console.log('🔐 Profile update response:', data)
      
      if (data.data) {
        setUser(data.data)
        console.log('✅ Profile updated successfully')
        return true
      } else {
        console.error('🚨 Profile update failed: Invalid response structure')
        return false
      }
    } catch (error) {
      console.error('🚨 Profile update failed:', error)
      return false
    }
  }

  // Refresh JWT token
  const refreshToken = async (): Promise<boolean> => {
    const token = getStoredToken()
    if (!token) return false

    try {
      console.log('🔐 Refreshing token...')
      
      // ✅ Use the new API client
      const data = await api.auth.refresh() as AuthResponse
      console.log('🔐 Token refresh response:', data)
      
      if (data.data && data.token) {
        setUser(data.data)
        storeToken(data.token)
        console.log('✅ Token refresh successful')
        return true
      } else {
        console.error('🚨 Token refresh failed: Invalid response structure')
        clearAuth()
        return false
      }
    } catch (error) {
      console.error('🚨 Token refresh failed:', error)
      clearAuth()
      return false
    }
  }

  // Logout function
  const logout = async () => {
    const token = getStoredToken()
    
    console.log('🔐 Logging out...')
    
    // Call backend logout endpoint
    if (token) {
      try {
        // ✅ Use the new API client
        await api.auth.logout()
        console.log('✅ Backend logout successful')
      } catch (error) {
        console.error('🚨 Logout API call failed:', error)
        // Continue with local logout even if API call fails
      }
    }
    
    clearAuth()
    console.log('✅ Local logout complete')
  }

  // Helper functions for token management
  const getStoredToken = (): string | null => {
    if (typeof window === 'undefined') return null
    return localStorage.getItem('auth_token')
  }

  const storeToken = (token: string) => {
    if (typeof window === 'undefined') return
    console.log('🔐 Storing token:', token.substring(0, 10) + '...')
    localStorage.setItem('auth_token', token)
  }

  const clearAuth = () => {
    console.log('🔐 Clearing auth data')
    setUser(null)
    if (typeof window !== 'undefined') {
      localStorage.removeItem('auth_token')
    }
  }

  // Auto-refresh token before expiration (optional enhancement)
  useEffect(() => {
    if (!user) return

    console.log('🔐 Setting up token refresh interval for user:', user.email)
    
    // Set up token refresh interval (refresh every 23 hours for 24h tokens)
    const refreshInterval = setInterval(() => {
      console.log('🔐 Auto-refreshing token...')
      refreshToken()
    }, 23 * 60 * 60 * 1000) // 23 hours

    return () => {
      console.log('🔐 Clearing token refresh interval')
      clearInterval(refreshInterval)
    }
  }, [user])

  // ✅ UPDATED: Context value with new methods
  const value: AuthContextType = {
    user,
    loading,
    login,
    signup,
    logout,
    refreshToken,
    getCurrentUser,
    setUser,
    updateProfile, // ✅ NEW: Profile update method
    isAuthenticated: !!user,
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}