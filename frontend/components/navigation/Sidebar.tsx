'use client'

import { useState } from 'react'

export function Sidebar() {
  const [isCollapsed, setIsCollapsed] = useState(false)

  const navigation = [
    { name: 'Dashboard', href: '/dashboard', icon: '📊' },
    { name: 'Devices', href: '/devices', icon: '🔧' },
    { name: 'Analytics', href: '/analytics', icon: '📈' },
    { name: 'Shop', href: '/shop', icon: '🛒' },
    { name: 'Support', href: '/support', icon: '❓' },
    { name: 'Settings', href: '/settings', icon: '⚙️' },
  ]

  return (
    <div className={`bg-gray-900 text-white transition-all duration-300 ${isCollapsed ? 'w-16' : 'w-64'}`}>
      <div className="p-4">
        <div className="flex items-center justify-between">
          {!isCollapsed && <span className="text-lg font-bold">SpaceGrow.ai</span>}
          <button
            onClick={() => setIsCollapsed(!isCollapsed)}
            className="text-white hover:text-gray-300"
          >
            {isCollapsed ? '→' : '←'}
          </button>
        </div>
      </div>
      
<nav className="mt-8">
  {navigation.map((item) => (
    <a
      key={item.name}
      href={item.href}
      className="flex items-center px-4 py-3 text-sm hover:bg-gray-700 transition-colors"
    >
      <span className="text-lg">{item.icon}</span>
      {!isCollapsed && <span className="ml-3">{item.name}</span>}
    </a>
  ))}
</nav>
    </div>
  )
}