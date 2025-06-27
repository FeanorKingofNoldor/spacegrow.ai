'use client'

import { useAuth } from '@/contexts/AuthContext'
import { ThemeToggle } from '@/components/ui/ThemeToggle'

interface AuthenticatedHeaderProps {
  toggleSidebar: () => void
}

export function AuthenticatedHeader({ toggleSidebar }: AuthenticatedHeaderProps) {
  const { user, logout } = useAuth()

  return (
    <header className="bg-white dark:bg-gray-900 border-b border-gray-200 dark:border-gray-700 px-6 py-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center">
          <button
            onClick={toggleSidebar}
            className="text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 lg:hidden"
          >
            <span className="sr-only">Toggle sidebar</span>
            <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </button>
          <h1 className="text-xl font-semibold text-gray-900 dark:text-white ml-4 lg:ml-0">
            Dashboard
          </h1>
        </div>

        <div className="flex items-center space-x-4">
          <ThemeToggle />
          
          <div className="flex items-center space-x-2">
            <span className="text-sm text-gray-700 dark:text-gray-300">
              {user?.email}
            </span>
            <button
              onClick={logout}
              className="text-sm text-red-600 dark:text-red-400 hover:text-red-800 dark:hover:text-red-300"
            >
              Logout
            </button>
          </div>
        </div>
      </div>
    </header>
  )
}