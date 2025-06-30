'use client'

import { createContext, useContext, useEffect, useState, ReactNode } from 'react'

// Types for our auth system
interface User {
  id: number
  email: string
  role: 'user' | 'pro' | 'admin'
  created_at: string
  devices_count: number
}

interface AuthResponse {
  status: {
    code: number
    message: string
  }
  data: User
  token: string
}

interface AuthContextType {
  user: User | null
  loading: boolean
  login: (email: string, password: string) => Promise<boolean>
  signup: (email: string, password: string, passwordConfirmation: string) => Promise<boolean>
  logout: () => void
  refreshToken: () => Promise<boolean>
  getCurrentUser: () => Promise<boolean>
  setUser: (user: User | null) => void  // ✅ Added this
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
      // Try to get current user info
      const success = await getCurrentUser()
      if (!success) {
        // Token is invalid, clear it
        clearAuth()
      }
    }
    setLoading(false)
  }

  // Get current user from API
  const getCurrentUser = async (): Promise<boolean> => {
    const token = getStoredToken()
    if (!token) return false

    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/auth/me`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      })

      if (response.ok) {
        const data = await response.json()
        setUser(data.data)
        return true
      } else {
        clearAuth()
        return false
      }
    } catch (error) {
      console.error('Get current user failed:', error)
      clearAuth()
      return false
    }
  }

  // Login function
  const login = async (email: string, password: string): Promise<boolean> => {
    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ 
          user: { 
            email, 
            password 
          } 
        }),
      })

      if (response.ok) {
        const data: AuthResponse = await response.json()
        setUser(data.data)
        storeToken(data.token)
        return true
      } else {
        const errorData = await response.json()
        console.error('Login failed:', errorData.status?.message || 'Unknown error')
        return false
      }
    } catch (error) {
      console.error('Login failed:', error)
      return false
    }
  }

  // Signup function
  const signup = async (email: string, password: string, passwordConfirmation: string): Promise<boolean> => {
    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/auth/signup`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ 
          user: { 
            email, 
            password,
            password_confirmation: passwordConfirmation
          } 
        }),
      })

      if (response.ok) {
        const data: AuthResponse = await response.json()
        setUser(data.data)
        storeToken(data.token)
        return true
      } else {
        const errorData = await response.json()
        console.error('Signup failed:', errorData.status?.message || 'Unknown error')
        return false
      }
    } catch (error) {
      console.error('Signup failed:', error)
      return false
    }
  }

  // Refresh JWT token
  const refreshToken = async (): Promise<boolean> => {
    const token = getStoredToken()
    if (!token) return false

    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/auth/refresh`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      })

      if (response.ok) {
        const data: AuthResponse = await response.json()
        setUser(data.data)
        storeToken(data.token)
        return true
      } else {
        clearAuth()
        return false
      }
    } catch (error) {
      console.error('Token refresh failed:', error)
      clearAuth()
      return false
    }
  }

  // Logout function
  const logout = async () => {
    const token = getStoredToken()
    
    // Call backend logout endpoint
    if (token) {
      try {
        await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/auth/logout`, {
          method: 'DELETE',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        })
      } catch (error) {
        console.error('Logout API call failed:', error)
        // Continue with local logout even if API call fails
      }
    }
    
    clearAuth()
  }

  // Helper functions for token management
  const getStoredToken = (): string | null => {
    if (typeof window === 'undefined') return null
    return localStorage.getItem('auth_token')
  }

  const storeToken = (token: string) => {
    if (typeof window === 'undefined') return
    localStorage.setItem('auth_token', token)
  }

  const clearAuth = () => {
    setUser(null)
    if (typeof window !== 'undefined') {
      localStorage.removeItem('auth_token')
    }
  }

  // Auto-refresh token before expiration (optional enhancement)
  useEffect(() => {
    if (!user) return

    // Set up token refresh interval (refresh every 23 hours for 24h tokens)
    const refreshInterval = setInterval(() => {
      refreshToken()
    }, 23 * 60 * 60 * 1000) // 23 hours

    return () => clearInterval(refreshInterval)
  }, [user])

  const value: AuthContextType = {
    user,
    loading,
    login,
    signup,
    logout,
    refreshToken,
    getCurrentUser,
    setUser,  // ✅ Added this
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