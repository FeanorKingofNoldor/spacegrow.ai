'use client'

import { createContext, useContext, useEffect, useState, ReactNode } from 'react'

type Theme = 'light' | 'dark' | 'system'

interface ThemeContextType {
  theme: Theme
  setTheme: (theme: Theme) => void
  toggleTheme: () => void
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined)

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<Theme>('system')
  const [mounted, setMounted] = useState(false)

  console.log('🎨 ThemeProvider rendering...') // DEBUG LOG

  // Only run on client side
  useEffect(() => {
    console.log('🎨 ThemeProvider mounted') // DEBUG LOG
    setMounted(true)
    const stored = localStorage.getItem('theme') as Theme
    if (stored) {
      setTheme(stored)
      console.log('🎨 Found stored theme:', stored) // DEBUG LOG
    }
  }, [])

  // Apply theme to document
  useEffect(() => {
    if (!mounted) return

    console.log('🎨 Applying theme:', theme) // DEBUG LOG

    const root = window.document.documentElement
    root.classList.remove('light', 'dark')

    if (theme === 'system') {
      const systemTheme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
      root.classList.add(systemTheme)
      console.log('🎨 System theme applied:', systemTheme) // DEBUG LOG
    } else {
      root.classList.add(theme)
      console.log('🎨 Manual theme applied:', theme) // DEBUG LOG
    }

    localStorage.setItem('theme', theme)
  }, [theme, mounted])

  const toggleTheme = () => {
    // Only allow toggling after mounted
    if (!mounted) return
    
    setTheme(current => {
      const next = current === 'light' ? 'dark' : current === 'dark' ? 'system' : 'light'
      console.log('🎨 Theme toggled from', current, 'to', next) // DEBUG LOG
      return next
    })
  }

  // ✅ ALWAYS provide context - even before mounting
  const contextValue = {
    theme,
    setTheme,
    toggleTheme
  }

  console.log('🎨 ThemeProvider providing context with theme:', theme, 'mounted:', mounted) // DEBUG LOG

  return (
    <ThemeContext.Provider value={contextValue}>
      {children}
    </ThemeContext.Provider>
  )
}

export const useTheme = () => {
  const context = useContext(ThemeContext)
  console.log('🎨 useTheme called, context:', context) // DEBUG LOG
  
  if (context === undefined) {
    console.error('🎨 useTheme called outside ThemeProvider!') // DEBUG LOG
    throw new Error('useTheme must be used within a ThemeProvider')
  }
  return context
}