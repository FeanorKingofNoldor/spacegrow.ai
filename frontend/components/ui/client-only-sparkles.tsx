'use client'

import { useEffect, useState } from 'react'
import { Sparkles } from 'lucide-react'

interface SparkleData {
  id: number
  left: number
  top: number
  animationDelay: number
  animationDuration: number
  hueRotate: number
  opacity?: number
}

interface SparkleBackgroundProps {
  count?: number
  className?: string
}

// For simple dot sparkles (like in shop page)
export function ClientOnlyDotSparkles({ count = 50, className = "" }: SparkleBackgroundProps) {
  const [sparkles, setSparkles] = useState<SparkleData[]>([])
  const [isMounted, setIsMounted] = useState(false)

  useEffect(() => {
    setIsMounted(true)
    
    const generateSparkles = () => {
      return Array.from({ length: count }, (_, i) => ({
        id: i,
        left: Math.random() * 100,
        top: Math.random() * 100,
        animationDelay: Math.random() * 5,
        animationDuration: 1 + Math.random() * 3,
        hueRotate: Math.random() * 360,
        opacity: Math.random() * 0.8 + 0.2
      }))
    }

    setSparkles(generateSparkles())
  }, [count])

  if (!isMounted) {
    return null
  }

  return (
    <div className={className}>
      {sparkles.map((sparkle) => (
        <div
          key={sparkle.id}
          className="absolute animate-pulse"
          style={{
            left: `${sparkle.left}%`,
            top: `${sparkle.top}%`,
            animationDelay: `${sparkle.animationDelay}s`,
            animationDuration: `${sparkle.animationDuration}s`
          }}
        >
          <div 
            className="w-1 h-1 bg-white rounded-full"
            style={{
              filter: `hue-rotate(${sparkle.hueRotate}deg)`,
              opacity: sparkle.opacity
            }}
          />
        </div>
      ))}
    </div>
  )
}

// For Lucide icon sparkles (like in header)
export function ClientOnlyIconSparkles({ 
  count = 50, 
  className = "",
  iconClassName = "w-2 h-2 text-white/20"
}: SparkleBackgroundProps & { iconClassName?: string }) {
  const [sparkles, setSparkles] = useState<SparkleData[]>([])
  const [isMounted, setIsMounted] = useState(false)

  useEffect(() => {
    setIsMounted(true)
    
    const generateSparkles = () => {
      return Array.from({ length: count }, (_, i) => ({
        id: i,
        left: Math.random() * 100,
        top: Math.random() * 100,
        animationDelay: Math.random() * 3,
        animationDuration: 2 + Math.random() * 4,
        hueRotate: Math.random() * 360
      }))
    }

    setSparkles(generateSparkles())
  }, [count])

  if (!isMounted) {
    return null
  }

  return (
    <div className={className}>
      {sparkles.map((sparkle) => (
        <div
          key={sparkle.id}
          className="absolute animate-pulse"
          style={{
            left: `${sparkle.left}%`,
            top: `${sparkle.top}%`,
            animationDelay: `${sparkle.animationDelay}s`,
            animationDuration: `${sparkle.animationDuration}s`
          }}
        >
          <Sparkles 
            className={iconClassName}
            style={{
              filter: `hue-rotate(${sparkle.hueRotate}deg)`
            }}
          />
        </div>
      ))}
    </div>
  )
}