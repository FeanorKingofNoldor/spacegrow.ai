'use client'

import { createContext, useContext, useEffect, useState, ReactNode } from 'react'
import Cookies from 'js-cookie'
import { User } from '@/types/api'

interface AuthContextType {
  user: User | null
  login: (email: string, password: string) => Promise<boolean>
  logout: () => void
  loading: boolean
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  // Check if user is already logged in on app start
  useEffect(() => {
    checkAuth()
  }, [])

  const checkAuth = async () => {
    const token = Cookies.get('auth_token')
    if (token) {
      try {
        // Verify token is still valid by calling a protected endpoint
        const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/frontend/dashboard`, {
          credentials: 'include', // Send cookies
          headers: {
            'Authorization': `Bearer ${token}`,
          },
        })
        
        if (response.ok) {
          // Token is valid - you could extract user info from the response
          // For now, we'll just mark as authenticated
          setUser({ id: 1, email: 'temp', role: 'user', created_at: '', devices_count: 0 })
        } else {
          // Token invalid, clear it
          Cookies.remove('auth_token')
        }
      } catch (error) {
        console.error('Auth check failed:', error)
        Cookies.remove('auth_token')
      }
    }
    setLoading(false)
  }

  const login = async (email: string, password: string): Promise<boolean> => {
    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ user: { email, password } }),
      })

      if (response.ok) {
        const data = await response.json()
        setUser(data.data)
        
        // Store JWT in httpOnly cookie (secure)
        Cookies.set('auth_token', data.token, {
          httpOnly: false, // Note: js-cookie can't set httpOnly, we'll improve this later
          secure: process.env.NODE_ENV === 'production',
          sameSite: 'strict',
          expires: 7 // 7 days
        })
        
        return true
      }
      return false
    } catch (error) {
      console.error('Login failed:', error)
      return false
    }
  }

  const logout = () => {
    setUser(null)
    Cookies.remove('auth_token')
  }

  return (
    <AuthContext.Provider value={{ user, login, logout, loading }}>
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