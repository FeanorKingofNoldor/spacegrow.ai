'use client'

import { useTheme } from '@/contexts/ThemeContext'
import { useState, useEffect } from 'react'

export function ThemeToggle() {
  const [mounted, setMounted] = useState(false)
  
  // Only access theme context after mounting
  useEffect(() => {
    setMounted(true)
  }, [])

  if (!mounted) {
    // Return a placeholder button while loading
    return (
      <button className="p-2 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors">
        <span className="text-lg">💻</span>
      </button>
    )
  }

  return <ThemeToggleContent />
}

function ThemeToggleContent() {
  const { theme, toggleTheme } = useTheme()

  const getIcon = () => {
    switch (theme) {
      case 'light': return '☀️'
      case 'dark': return '🌙'
      case 'system': return '💻'
    }
  }

  return (
    <button
      onClick={toggleTheme}
      className="p-2 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
      title={`Current theme: ${theme}`}
    >
      <span className="text-lg">{getIcon()}</span>
    </button>
  )
}