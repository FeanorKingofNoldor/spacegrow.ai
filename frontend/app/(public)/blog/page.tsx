'use client'

import { useState } from 'react'
import Link from 'next/link'
import { CalendarDaysIcon, ClockIcon, EyeIcon, ChatBubbleLeftIcon } from '@heroicons/react/24/outline'

const featuredPost = {
  id: 'featured',
  title: 'The Complete Guide to VPD: Optimizing Vapor Pressure Deficit for Maximum Yields',
  slug: 'complete-guide-vpd-vapor-pressure-deficit',
  excerpt: 'Master the science of VPD to dramatically improve your growing results. Learn how to calculate, monitor, and optimize vapor pressure deficit for different growth stages.',
  content: 'Understanding VPD is crucial for any serious grower. This comprehensive guide covers everything from basic calculations to advanced optimization techniques...',
  imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=800&h=400&fit=crop&crop=center&q=80',
  publishedAt: '2024-01-15',
  readTime: '12 min read',
  views: 15420,
  comments: 23,
  category: { 
    name: 'Growing Science', 
    slug: 'growing-science',
    color: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
  },
  author: {
    name: 'Dr. Sarah Chen',
    role: 'Plant Physiologist',
    imageUrl: 'https://images.unsplash.com/photo-1494790108755-2616b612b5bc?w=64&h=64&fit=crop&crop=face&q=80',
    bio: 'PhD in Plant Sciences with 15+ years researching optimal growing conditions'
  },
  tags: ['VPD', 'Environmental Control', 'Plant Science', 'Optimization']
}

const posts = [
  {
    id: 1,
    title: 'How to Calibrate pH Sensors for Accurate Hydroponic Monitoring',
    slug: 'calibrate-ph-sensors-hydroponic-monitoring',
    excerpt: 'Proper pH sensor calibration is essential for successful hydroponic systems. Learn the step-by-step process and common mistakes to avoid.',
    imageUrl: 'https://images.unsplash.com/photo-1530836369250-ef72a3f5cda8?w=400&h=300&fit=crop&crop=center&q=80',
    publishedAt: '2024-01-12',
    readTime: '8 min read',
    views: 8234,
    comments: 15,
    category: { 
      name: 'Hardware', 
      slug: 'hardware',
      color: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200'
    },
    author: {
      name: 'Mike Rodriguez',
      role: 'Technical Engineer',
      imageUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=64&h=64&fit=crop&crop=face&q=80'
    },
    tags: ['pH Sensors', 'Calibration', 'Hydroponics', 'Maintenance']
  },
  {
    id: 2,
    title: 'Setting Up Smart Alerts: Never Miss Critical Environmental Changes',
    slug: 'smart-alerts-environmental-monitoring',
    excerpt: 'Configure intelligent alert systems that notify you before problems occur. Learn about threshold settings, escalation procedures, and alert fatigue prevention.',
    imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=300&fit=crop&crop=center&q=80',
    publishedAt: '2024-01-10',
    readTime: '6 min read',
    views: 6543,
    comments: 12,
    category: { 
      name: 'Software', 
      slug: 'software',
      color: 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200'
    },
    author: {
      name: 'Alex Kumar',
      role: 'Software Developer',
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=64&h=64&fit=crop&crop=face&q=80'
    },
    tags: ['Alerts', 'Notifications', 'Automation', 'Software']
  },
  {
    id: 3,
    title: 'Winter Growing: Maintaining Optimal Conditions in Cold Weather',
    slug: 'winter-growing-optimal-conditions',
    excerpt: 'Cold weather presents unique challenges for indoor growing. Discover strategies for maintaining temperature, humidity, and energy efficiency during winter months.',
    imageUrl: 'https://images.unsplash.com/photo-1574781330855-d0db8cc6a79c?w=400&h=300&fit=crop&crop=center&q=80',
    publishedAt: '2024-01-08',
    readTime: '10 min read',
    views: 9876,
    comments: 28,
    category: { 
      name: 'Seasonal Growing', 
      slug: 'seasonal-growing',
      color: 'bg-cyan-100 text-cyan-800 dark:bg-cyan-900 dark:text-cyan-200'
    },
    author: {
      name: 'Emma Thompson',
      role: 'Master Grower',
      imageUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=64&h=64&fit=crop&crop=face&q=80'
    },
    tags: ['Winter Growing', 'Temperature Control', 'Energy Efficiency']
  },
  {
    id: 4,
    title: 'Data-Driven Growing: Using Analytics to Improve Your Yields',
    slug: 'data-driven-growing-analytics-yields',
    excerpt: 'Transform your growing operation with data analytics. Learn how to interpret sensor data, identify trends, and make informed decisions for better harvests.',
    imageUrl: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400&h=300&fit=crop&crop=center&q=80',
    publishedAt: '2024-01-05',
    readTime: '15 min read',
    views: 12340,
    comments: 19,
    category: { 
      name: 'Analytics', 
      slug: 'analytics',
      color: 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200'
    },
    author: {
      name: 'Dr. James Wilson',
      role: 'Data Scientist',
      imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=64&h=64&fit=crop&crop=face&q=80'
    },
    tags: ['Data Analytics', 'Yield Optimization', 'Trends', 'Decision Making']
  },
  {
    id: 5,
    title: 'Troubleshooting EC Sensor Drift: Common Causes and Solutions',
    slug: 'troubleshooting-ec-sensor-drift',
    excerpt: 'EC sensor drift can lead to inaccurate nutrient readings and poor plant health. Identify the causes and learn proven solutions to maintain accurate measurements.',
    imageUrl: 'https://images.unsplash.com/photo-1581833971358-2c8b550f87b3?w=400&h=300&fit=crop&crop=center&q=80',
    publishedAt: '2024-01-03',
    readTime: '7 min read',
    views: 5432,
    comments: 9,
    category: { 
      name: 'Troubleshooting', 
      slug: 'troubleshooting',
      color: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200'
    },
    author: {
      name: 'Lisa Park',
      role: 'Technical Support Lead',
      imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=64&h=64&fit=crop&crop=face&q=80'
    },
    tags: ['EC Sensors', 'Troubleshooting', 'Sensor Maintenance', 'Accuracy']
  },
  {
    id: 6,
    title: 'Building Custom Automations with the SpaceGrow API',
    slug: 'custom-automations-spacegrow-api',
    excerpt: 'Unlock the full potential of your growing system with custom automations. Learn to build sophisticated workflows using our comprehensive API.',
    imageUrl: 'https://images.unsplash.com/photo-1518432031352-d6fc5c10da5a?w=400&h=300&fit=crop&crop=center&q=80',
    publishedAt: '2024-01-01',
    readTime: '20 min read',
    views: 3456,
    comments: 14,
    category: { 
      name: 'API & Development', 
      slug: 'api-development',
      color: 'bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-200'
    },
    author: {
      name: 'David Chen',
      role: 'API Developer',
      imageUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=64&h=64&fit=crop&crop=face&q=80'
    },
    tags: ['API', 'Automation', 'Development', 'Integration']
  }
]

const categories = [
  { name: 'All Posts', slug: 'all', count: 42 },
  { name: 'Growing Science', slug: 'growing-science', count: 12 },
  { name: 'Hardware', slug: 'hardware', count: 8 },
  { name: 'Software', slug: 'software', count: 6 },
  { name: 'Troubleshooting', slug: 'troubleshooting', count: 5 },
  { name: 'Analytics', slug: 'analytics', count: 4 },
  { name: 'API & Development', slug: 'api-development', count: 3 },
  { name: 'Seasonal Growing', slug: 'seasonal-growing', count: 4 }
]

const trendingTags = [
  'VPD', 'pH Calibration', 'Automation', 'Winter Growing', 'Data Analytics', 
  'Sensor Maintenance', 'API Integration', 'Yield Optimization', 'Alerts', 'Hydroponics'
]

const newsletter = {
  title: 'Stay Updated with Growing Tips',
  description: 'Get weekly insights, latest research, and expert tips delivered to your inbox.',
  subscribers: '12,000+'
}

export default function BlogPage() {
  const [selectedCategory, setSelectedCategory] = useState('all')
  const [searchQuery, setSearchQuery] = useState('')

  const filteredPosts = posts.filter(post => {
    const matchesCategory = selectedCategory === 'all' || post.category.slug === selectedCategory
    const matchesSearch = searchQuery === '' || 
      post.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      post.excerpt.toLowerCase().includes(searchQuery.toLowerCase()) ||
      post.tags.some(tag => tag.toLowerCase().includes(searchQuery.toLowerCase()))
    
    return matchesCategory && matchesSearch
  })

  return (
    <div className="bg-white dark:bg-gray-900 min-h-screen">
      {/* Header */}
      <div className="bg-gray-50 dark:bg-gray-800 py-16 sm:py-24">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl text-center">
            <h1 className="text-4xl font-bold tracking-tight text-gray-900 dark:text-white sm:text-6xl">
              Growing Knowledge Hub
            </h1>
            <p className="mt-6 text-lg leading-8 text-gray-600 dark:text-gray-300">
              Expert insights, research-backed techniques, and practical guides to help you master the art and science of growing.
            </p>
          </div>

          {/* Search and Categories */}
          <div className="mx-auto mt-16 max-w-4xl">
            {/* Search Bar */}
            <div className="mb-8">
              <div className="relative">
                <input
                  type="text"
                  placeholder="Search articles, guides, and tips..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full rounded-full border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-6 py-4 pl-12 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                <div className="absolute inset-y-0 left-0 flex items-center pl-4">
                  <svg className="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                  </svg>
                </div>
              </div>
            </div>

            {/* Category Filter */}
            <div className="flex flex-wrap gap-2 justify-center">
              {categories.map((category) => (
                <button
                  key={category.slug}
                  onClick={() => setSelectedCategory(category.slug)}
                  className={`rounded-full px-4 py-2 text-sm font-medium transition-colors ${
                    selectedCategory === category.slug
                      ? 'bg-blue-600 text-white'
                      : 'bg-white dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-600 border border-gray-300 dark:border-gray-600'
                  }`}
                >
                  {category.name}
                  <span className="ml-1 text-xs opacity-75">({category.count})</span>
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>

      <div className="mx-auto max-w-7xl px-6 lg:px-8 py-16">
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-12">
          {/* Main Content */}
          <div className="lg:col-span-3">
            {/* Featured Post */}
            {selectedCategory === 'all' && searchQuery === '' && (
              <div className="mb-16">
                <div className="flex items-center gap-2 mb-6">
                  <div className="h-1 w-8 bg-blue-600 rounded"></div>
                  <span className="text-sm font-semibold text-blue-600 dark:text-blue-400 uppercase tracking-wide">Featured Article</span>
                </div>
                
                <article className="relative group">
                  <div className="relative aspect-[2/1] w-full overflow-hidden rounded-2xl bg-gray-100 dark:bg-gray-800">
                    <img
                      src={featuredPost.imageUrl}
                      alt={featuredPost.title}
                      className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent"></div>
                    <div className="absolute bottom-6 left-6 right-6">
                      <div className="flex items-center gap-4 mb-4">
                        <span className={`inline-flex items-center rounded-full px-3 py-1 text-xs font-medium ${featuredPost.category.color}`}>
                          {featuredPost.category.name}
                        </span>
                        <div className="flex items-center text-white/80 text-sm">
                          <CalendarDaysIcon className="h-4 w-4 mr-1" />
                          {new Date(featuredPost.publishedAt).toLocaleDateString('en-US', { 
                            year: 'numeric', 
                            month: 'long', 
                            day: 'numeric' 
                          })}
                        </div>
                      </div>
                      <h2 className="text-2xl font-bold text-white mb-3 group-hover:text-blue-200 transition-colors">
                        <Link href={`/blog/${featuredPost.slug}`}>
                          {featuredPost.title}
                        </Link>
                      </h2>
                      <p className="text-gray-200 mb-4 line-clamp-2">
                        {featuredPost.excerpt}
                      </p>
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-3">
                          <img
                            src={featuredPost.author.imageUrl}
                            alt={featuredPost.author.name}
                            className="h-8 w-8 rounded-full"
                          />
                          <div>
                            <p className="text-white font-medium text-sm">{featuredPost.author.name}</p>
                            <p className="text-white/60 text-xs">{featuredPost.author.role}</p>
                          </div>
                        </div>
                        <div className="flex items-center gap-4 text-white/60 text-sm">
                          <div className="flex items-center gap-1">
                            <ClockIcon className="h-4 w-4" />
                            {featuredPost.readTime}
                          </div>
                          <div className="flex items-center gap-1">
                            <EyeIcon className="h-4 w-4" />
                            {featuredPost.views.toLocaleString()}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </article>
              </div>
            )}

            {/* Posts Grid */}
            <div className="space-y-12">
              <div className="flex items-center justify-between">
                <h2 className="text-2xl font-bold text-gray-900 dark:text-white">
                  {selectedCategory === 'all' ? 'Latest Articles' : `${categories.find(c => c.slug === selectedCategory)?.name} Articles`}
                </h2>
                <span className="text-sm text-gray-500 dark:text-gray-400">
                  {filteredPosts.length} article{filteredPosts.length !== 1 ? 's' : ''}
                </span>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                {filteredPosts.map((post) => (
                  <article key={post.id} className="group">
                    <div className="relative aspect-[3/2] w-full overflow-hidden rounded-xl bg-gray-100 dark:bg-gray-800 mb-6">
                      <img
                        src={post.imageUrl}
                        alt={post.title}
                        className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
                      />
                      <div className="absolute top-4 left-4">
                        <span className={`inline-flex items-center rounded-full px-3 py-1 text-xs font-medium ${post.category.color}`}>
                          {post.category.name}
                        </span>
                      </div>
                    </div>

                    <div className="space-y-4">
                      <div className="flex items-center gap-4 text-sm text-gray-500 dark:text-gray-400">
                        <div className="flex items-center gap-1">
                          <CalendarDaysIcon className="h-4 w-4" />
                          {new Date(post.publishedAt).toLocaleDateString('en-US', { 
                            month: 'short', 
                            day: 'numeric' 
                          })}
                        </div>
                        <div className="flex items-center gap-1">
                          <ClockIcon className="h-4 w-4" />
                          {post.readTime}
                        </div>
                        <div className="flex items-center gap-1">
                          <EyeIcon className="h-4 w-4" />
                          {post.views.toLocaleString()}
                        </div>
                      </div>

                      <h3 className="text-xl font-semibold text-gray-900 dark:text-white group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors line-clamp-2">
                        <Link href={`/blog/${post.slug}`}>
                          {post.title}
                        </Link>
                      </h3>

                      <p className="text-gray-600 dark:text-gray-400 line-clamp-3">
                        {post.excerpt}
                      </p>

                      <div className="flex flex-wrap gap-2">
                        {post.tags.slice(0, 3).map((tag) => (
                          <span
                            key={tag}
                            className="inline-flex items-center rounded-md bg-gray-100 dark:bg-gray-700 px-2 py-1 text-xs font-medium text-gray-600 dark:text-gray-300"
                          >
                            #{tag}
                          </span>
                        ))}
                      </div>

                      <div className="flex items-center justify-between pt-4 border-t border-gray-200 dark:border-gray-700">
                        <div className="flex items-center gap-3">
                          <img
                            src={post.author.imageUrl}
                            alt={post.author.name}
                            className="h-8 w-8 rounded-full"
                          />
                          <div>
                            <p className="text-sm font-medium text-gray-900 dark:text-white">{post.author.name}</p>
                            <p className="text-xs text-gray-500 dark:text-gray-400">{post.author.role}</p>
                          </div>
                        </div>
                        <div className="flex items-center gap-1 text-gray-500 dark:text-gray-400">
                          <ChatBubbleLeftIcon className="h-4 w-4" />
                          <span className="text-sm">{post.comments}</span>
                        </div>
                      </div>
                    </div>
                  </article>
                ))}
              </div>

              {filteredPosts.length === 0 && (
                <div className="text-center py-12">
                  <div className="text-gray-400 dark:text-gray-500 mb-4">
                    <svg className="mx-auto h-12 w-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.172 16.172a4 4 0 015.656 0M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                    </svg>
                  </div>
                  <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">No articles found</h3>
                  <p className="text-gray-500 dark:text-gray-400">Try adjusting your search or category filter.</p>
                </div>
              )}
            </div>
          </div>

          {/* Sidebar */}
          <div className="lg:col-span-1 space-y-8">
            {/* Newsletter Signup */}
            <div className="bg-blue-50 dark:bg-blue-900/20 rounded-2xl p-6 border border-blue-200 dark:border-blue-800">
              <h3 className="text-lg font-semibold text-blue-900 dark:text-blue-100 mb-2">
                {newsletter.title}
              </h3>
              <p className="text-sm text-blue-700 dark:text-blue-300 mb-4">
                {newsletter.description}
              </p>
              <div className="space-y-3">
                <input
                  type="email"
                  placeholder="Enter your email"
                  className="w-full rounded-lg border border-blue-300 dark:border-blue-600 bg-white dark:bg-blue-900/40 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                />
                <button className="w-full rounded-lg bg-blue-600 px-3 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors">
                  Subscribe
                </button>
                <p className="text-xs text-blue-600 dark:text-blue-400 text-center">
                  Join {newsletter.subscribers} growers getting weekly tips
                </p>
              </div>
            </div>

            {/* Trending Tags */}
            <div className="bg-gray-50 dark:bg-gray-800 rounded-2xl p-6">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                Trending Topics
              </h3>
              <div className="flex flex-wrap gap-2">
                {trendingTags.map((tag) => (
                  <button
                    key={tag}
                    onClick={() => setSearchQuery(tag)}
                    className="inline-flex items-center rounded-lg bg-white dark:bg-gray-700 px-3 py-1 text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-600 border border-gray-200 dark:border-gray-600 transition-colors"
                  >
                    #{tag}
                  </button>
                ))}
              </div>
            </div>

            {/* Popular Articles */}
            <div className="bg-gray-50 dark:bg-gray-800 rounded-2xl p-6">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                Most Popular
              </h3>
              <div className="space-y-4">
                {posts.slice(0, 3).map((post, index) => (
                  <div key={post.id} className="flex gap-3">
                    <div className="flex-shrink-0 w-6 h-6 rounded-full bg-blue-600 text-white text-xs font-bold flex items-center justify-center">
                      {index + 1}
                    </div>
                    <div>
                      <h4 className="text-sm font-medium text-gray-900 dark:text-white line-clamp-2 hover:text-blue-600 dark:hover:text-blue-400 transition-colors">
                        <Link href={`/blog/${post.slug}`}>
                          {post.title}
                        </Link>
                      </h4>
                      <div className="flex items-center gap-2 mt-1 text-xs text-gray-500 dark:text-gray-400">
                        <EyeIcon className="h-3 w-3" />
                        {post.views.toLocaleString()} views
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Quick Links */}
            <div className="bg-gray-50 dark:bg-gray-800 rounded-2xl p-6">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                Quick Links
              </h3>
              <div className="space-y-3">
                <Link href="/docs" className="block text-sm text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 transition-colors">
                  📖 Documentation Hub
                </Link>
                <Link href="/troubleshooting" className="block text-sm text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 transition-colors">
                  🔧 Troubleshooting Guide
                </Link>
                <Link href="/support#community" className="block text-sm text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 transition-colors">
                  💬 Community Forum
                </Link>
                <Link href="/api" className="block text-sm text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 transition-colors">
                  ⚡ API Reference
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}