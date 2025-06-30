'use client'

import Link from 'next/link'
import StaticPageTemplate from '@/components/templates/StaticPageTemplate'

const supportChannels = [
  {
    id: 'live-chat',
    title: 'Live Chat',
    icon: '💬',
    availability: '24/7',
    responseTime: 'Instant',
    description: 'Get immediate help from our support team via live chat.',
    bestFor: ['Urgent technical issues', 'Setup assistance', 'Quick questions'],
    action: 'Start Chat',
    href: '#chat'
  },
  {
    id: 'email',
    title: 'Email Support',
    icon: '📧',
    availability: 'Business hours',
    responseTime: '< 4 hours',
    description: 'Send detailed questions and get comprehensive written responses.',
    bestFor: ['Complex technical issues', 'Account problems', 'Feature requests'],
    action: 'Send Email',
    href: 'mailto:support@spacegrow.ai'
  },
  {
    id: 'phone',
    title: 'Phone Support',
    icon: '📞',
    availability: 'Mon-Fri 9AM-6PM PST',
    responseTime: 'Immediate',
    description: 'Speak directly with our technical experts.',
    bestFor: ['Critical system issues', 'Emergency support', 'Complex troubleshooting'],
    action: 'Call Now',
    href: 'tel:+1-555-SPACEGROW'
  },
  {
    id: 'emergency',
    title: 'Emergency Line',
    icon: '🚨',
    availability: '24/7',
    responseTime: 'Immediate',
    description: 'For critical issues affecting your growing operation.',
    bestFor: ['System failures', 'Data loss', 'Production emergencies'],
    action: 'Emergency Call',
    href: 'tel:+1-555-GROW-911'
  }
]

const communityResources = [
  {
    title: 'Discord Community',
    icon: '💬',
    description: 'Join thousands of growers sharing tips, troubleshooting, and success stories.',
    members: '5,000+',
    activity: 'Very Active',
    link: '#discord'
  },
  {
    title: 'YouTube Channel',
    icon: '🎥',
    description: 'Video tutorials, setup guides, and growing tips from experts.',
    subscribers: '12,000+',
    activity: 'Weekly uploads',
    link: '#youtube'
  },
  {
    title: 'Knowledge Base',
    icon: '📚',
    description: 'Comprehensive articles covering every aspect of device operation.',
    articles: '200+',
    activity: 'Updated weekly',
    link: '/docs'
  },
  {
    title: 'User Forum',
    icon: '💭',
    description: 'Ask questions and get answers from experienced community members.',
    posts: '10,000+',
    activity: 'Daily posts',
    link: '#forum'
  }
]

const videoSeries = [
  {
    title: 'Device Setup & Installation',
    duration: '45 min',
    videos: 8,
    topics: ['Unboxing', 'WiFi setup', 'Sensor placement', 'Initial calibration'],
    thumbnail: '/api/placeholder/300/200'
  },
  {
    title: 'Sensor Calibration Masterclass',
    duration: '30 min',
    videos: 5,
    topics: ['pH calibration', 'EC standards', 'Temperature accuracy', 'Maintenance schedule'],
    thumbnail: '/api/placeholder/300/200'
  },
  {
    title: 'Advanced Growing Techniques',
    duration: '60 min',
    videos: 12,
    topics: ['VPD optimization', 'Automated scheduling', 'Data analysis', 'Yield optimization'],
    thumbnail: '/api/placeholder/300/200'
  },
  {
    title: 'Troubleshooting Common Issues',
    duration: '25 min',
    videos: 6,
    topics: ['Connection problems', 'Sensor drift', 'Alert setup', 'Data gaps'],
    thumbnail: '/api/placeholder/300/200'
  }
]

const supportTiers = [
  {
    name: 'Basic Support',
    description: 'Included with all devices',
    features: [
      'Email support (business hours)',
      'Community forum access',
      'Knowledge base access',
      'Video tutorial library',
      'Basic troubleshooting guides'
    ],
    responseTime: '< 24 hours',
    price: 'Free'
  },
  {
    name: 'Priority Support',
    description: 'For professional growers',
    features: [
      'Priority email support (< 4 hours)',
      'Live chat support',
      'Phone support (business hours)',
      'Advanced troubleshooting',
      'Firmware beta access',
      'Custom alert configuration'
    ],
    responseTime: '< 4 hours',
    price: '$19/month'
  },
  {
    name: 'Enterprise Support',
    description: 'For commercial operations',
    features: [
      '24/7 phone and chat support',
      'Dedicated account manager',
      'On-site installation support',
      'Custom integration assistance',
      'Priority firmware releases',
      'Advanced analytics access'
    ],
    responseTime: '< 1 hour',
    price: 'Custom pricing'
  }
]

export default function SupportPage() {
  return (
    <StaticPageTemplate
      title="Support Center"
      description="Get help with your SpaceGrow.ai devices, find answers to common questions, and connect with our community."
    >
      {/* Quick Help */}
      <div className="not-prose mb-16">
        <div className="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-xl p-6">
          <h3 className="font-semibold text-green-800 dark:text-green-200 mb-4">
            Need immediate help? Start here:
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <Link 
              href="/troubleshooting"
              className="flex items-center space-x-3 p-4 bg-white dark:bg-green-900/40 rounded-lg hover:shadow-md transition-shadow"
            >
              <span className="text-2xl">🔧</span>
              <div>
                <div className="font-medium text-green-900 dark:text-green-100">Troubleshooting Guide</div>
                <div className="text-sm text-green-700 dark:text-green-300">Quick fixes for common issues</div>
              </div>
            </Link>
            <Link 
              href="/docs"
              className="flex items-center space-x-3 p-4 bg-white dark:bg-green-900/40 rounded-lg hover:shadow-md transition-shadow"
            >
              <span className="text-2xl">📖</span>
              <div>
                <div className="font-medium text-green-900 dark:text-green-100">Documentation</div>
                <div className="text-sm text-green-700 dark:text-green-300">Complete setup and usage guides</div>
              </div>
            </Link>
            <button 
              onClick={() => {
                // Handle live chat opening
                console.log('Opening live chat...')
              }}
              className="flex items-center space-x-3 p-4 bg-white dark:bg-green-900/40 rounded-lg hover:shadow-md transition-shadow text-left w-full"
            >
              <span className="text-2xl">💬</span>
              <div>
                <div className="font-medium text-green-900 dark:text-green-100">Start Live Chat</div>
                <div className="text-sm text-green-700 dark:text-green-300">Chat with support instantly</div>
              </div>
            </button>
          </div>
        </div>
      </div>

      {/* Contact Support */}
      <section id="contact" className="mb-16">
        <h2>Contact Support</h2>
        <p>Choose the support channel that works best for your situation:</p>

        <div className="not-prose my-8 grid grid-cols-1 md:grid-cols-2 gap-6">
          {supportChannels.map((channel) => (
            <div key={channel.id} className="border dark:border-gray-700 rounded-xl p-6 hover:shadow-lg transition-shadow">
              <div className="flex items-start space-x-4">
                <div className="text-3xl">{channel.icon}</div>
                <div className="flex-1">
                  <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
                    {channel.title}
                  </h3>
                  <p className="text-gray-600 dark:text-gray-300 mb-4">
                    {channel.description}
                  </p>
                  
                  <div className="grid grid-cols-2 gap-4 mb-4 text-sm">
                    <div>
                      <span className="text-gray-500 dark:text-gray-400">Availability:</span>
                      <div className="font-medium text-gray-900 dark:text-white">{channel.availability}</div>
                    </div>
                    <div>
                      <span className="text-gray-500 dark:text-gray-400">Response:</span>
                      <div className="font-medium text-gray-900 dark:text-white">{channel.responseTime}</div>
                    </div>
                  </div>

                  <div className="mb-4">
                    <span className="text-sm text-gray-500 dark:text-gray-400">Best for:</span>
                    <ul className="mt-1 space-y-1">
                      {channel.bestFor.map((item) => (
                        <li key={item} className="text-sm text-gray-600 dark:text-gray-400 flex items-center space-x-2">
                          <span className="text-green-500">•</span>
                          <span>{item}</span>
                        </li>
                      ))}
                    </ul>
                  </div>

                  <a
                    href={channel.href}
                    className={`inline-flex items-center justify-center px-4 py-2 rounded-md font-medium transition-colors ${
                      channel.id === 'emergency' 
                        ? 'bg-red-600 text-white hover:bg-red-700' 
                        : 'bg-blue-600 text-white hover:bg-blue-700'
                    }`}
                  >
                    {channel.action}
                  </a>
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Support Tiers */}
      <section className="mb-16">
        <h2>Support Plans</h2>
        <p>Choose the level of support that matches your operation's needs:</p>

        <div className="not-prose my-8 grid grid-cols-1 md:grid-cols-3 gap-6">
          {supportTiers.map((tier, index) => (
            <div key={tier.name} className={`border-2 rounded-xl p-6 ${
              index === 1 ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20' : 'border-gray-200 dark:border-gray-700'
            }`}>
              {index === 1 && (
                <div className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-600 text-white mb-4">
                  Most Popular
                </div>
              )}
              
              <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
                {tier.name}
              </h3>
              <p className="text-gray-600 dark:text-gray-300 mb-4">
                {tier.description}
              </p>
              
              <div className="mb-6">
                <div className="text-3xl font-bold text-gray-900 dark:text-white mb-1">
                  {tier.price}
                </div>
                <div className="text-sm text-gray-500 dark:text-gray-400">
                  Response time: {tier.responseTime}
                </div>
              </div>

              <ul className="space-y-3 mb-6">
                {tier.features.map((feature) => (
                  <li key={feature} className="flex items-start space-x-2">
                    <span className="text-green-500 mt-1">✓</span>
                    <span className="text-sm text-gray-600 dark:text-gray-400">{feature}</span>
                  </li>
                ))}
              </ul>

                <button 
                  onClick={() => {
                    // Handle upgrade/contact
                    console.log(`Handling ${tier.name} plan...`)
                  }}
                  className={`w-full py-2 px-4 rounded-md font-medium transition-colors ${
                    index === 1 
                      ? 'bg-blue-600 text-white hover:bg-blue-700'
                      : 'border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-800'
                  }`}
                >
                {tier.price === 'Free' ? 'Included' : tier.price === 'Custom pricing' ? 'Contact Sales' : 'Upgrade'}
              </button>
            </div>
          ))}
        </div>
      </section>

      {/* Community Resources */}
      <section id="community" className="mb-16">
        <h2>Community Resources</h2>
        <p>Connect with other growers and learn from the SpaceGrow.ai community:</p>

        <div className="not-prose my-8 grid grid-cols-1 md:grid-cols-2 gap-6">
          {communityResources.map((resource) => (
            <div key={resource.title} className="border dark:border-gray-700 rounded-xl p-6 hover:shadow-lg transition-shadow">
              <div className="flex items-start space-x-4">
                <div className="text-3xl">{resource.icon}</div>
                <div className="flex-1">
                  <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
                    {resource.title}
                  </h3>
                  <p className="text-gray-600 dark:text-gray-300 mb-4">
                    {resource.description}
                  </p>
                  
                  <div className="flex items-center space-x-6 mb-4 text-sm">
                    <div>
                      <span className="text-gray-500 dark:text-gray-400">
                        {resource.members ? 'Members:' : resource.subscribers ? 'Subscribers:' : resource.articles ? 'Articles:' : 'Posts:'}
                      </span>
                      <div className="font-medium text-gray-900 dark:text-white">
                        {resource.members || resource.subscribers || resource.articles || resource.posts}
                      </div>
                    </div>
                    <div>
                      <span className="text-gray-500 dark:text-gray-400">Activity:</span>
                      <div className="font-medium text-gray-900 dark:text-white">{resource.activity}</div>
                    </div>
                  </div>

                  <Link
                    href={resource.link}
                    className="inline-flex items-center text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 font-medium"
                  >
                    Join Community →
                  </Link>
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Video Tutorials */}
      <section id="videos" className="mb-16">
        <h2>Video Tutorial Library</h2>
        <p>Learn through our comprehensive video guides covering every aspect of device operation:</p>

        <div className="not-prose my-8 grid grid-cols-1 md:grid-cols-2 gap-6">
          {videoSeries.map((series) => (
            <div key={series.title} className="border dark:border-gray-700 rounded-xl overflow-hidden hover:shadow-lg transition-shadow">
              <div className="aspect-video bg-gray-200 dark:bg-gray-700">
                <img 
                  src={series.thumbnail} 
                  alt={series.title}
                  className="w-full h-full object-cover"
                />
              </div>
              <div className="p-6">
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
                  {series.title}
                </h3>
                
                <div className="flex items-center space-x-4 mb-4 text-sm text-gray-600 dark:text-gray-400">
                  <span>{series.videos} videos</span>
                  <span>•</span>
                  <span>{series.duration} total</span>
                </div>

                <div className="mb-4">
                  <span className="text-sm text-gray-500 dark:text-gray-400 mb-2 block">Topics covered:</span>
                  <div className="flex flex-wrap gap-1">
                    {series.topics.map((topic) => (
                      <span 
                        key={topic}
                        className="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300"
                      >
                        {topic}
                      </span>
                    ))}
                  </div>
                </div>

                <button
                  onClick={() => {
                    // Handle watch series
                    console.log('Opening video series...')
                  }}
                  className="w-full bg-blue-600 text-white py-2 rounded-md hover:bg-blue-700 transition-colors font-medium"
                >
                  Watch Series
                </button>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* System Status */}
      <section id="status" className="mb-16">
        <h2>System Status</h2>
        <p>Check the current status of SpaceGrow.ai services and get notified of any issues:</p>

        <div className="not-prose my-8">
          <div className="border dark:border-gray-700 rounded-xl p-6">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                Current System Status
              </h3>
              <div className="flex items-center space-x-2">
                <div className="w-3 h-3 bg-green-500 rounded-full"></div>
                <span className="text-green-600 dark:text-green-400 font-medium">All Systems Operational</span>
              </div>
            </div>

            <div className="space-y-4">
              {[
                { service: 'Device API', status: 'operational' },
                { service: 'Web Dashboard', status: 'operational' },
                { service: 'Mobile App', status: 'operational' },
                { service: 'Data Processing', status: 'operational' },
                { service: 'Notifications', status: 'operational' },
                { service: 'Cloud Storage', status: 'operational' }
              ].map((service) => (
                <div key={service.service} className="flex items-center justify-between py-2 border-b border-gray-200 dark:border-gray-700 last:border-0">
                  <span className="font-medium text-gray-900 dark:text-white">{service.service}</span>
                  <div className="flex items-center space-x-2">
                    <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                    <span className="text-sm text-green-600 dark:text-green-400 capitalize">{service.status}</span>
                  </div>
                </div>
              ))}
            </div>

            <div className="mt-6 flex items-center justify-between">
              <div className="text-sm text-gray-600 dark:text-gray-400">
                Last updated: {new Date().toLocaleString()}
              </div>
              <Link
                href="#status-page"
                className="text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 text-sm font-medium"
              >
                View Status Page →
              </Link>
            </div>
          </div>

          {/* Status Subscribe */}
          <div className="mt-6 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-xl p-6">
            <h4 className="font-semibold text-blue-800 dark:text-blue-200 mb-2">
              Stay Updated on System Status
            </h4>
            <p className="text-blue-700 dark:text-blue-300 mb-4 text-sm">
              Subscribe to get notified immediately when there are service interruptions or maintenance windows.
            </p>
            <div className="flex flex-col sm:flex-row gap-3">
              <input 
                type="email" 
                placeholder="Enter your email"
                className="flex-1 px-3 py-2 border border-blue-300 dark:border-blue-600 rounded-md bg-white dark:bg-blue-900/40 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400"
              />
              <button 
                onClick={() => {
                  // Handle status subscription
                  console.log('Subscribing to status updates...')
                }}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors font-medium"
              >
                Subscribe
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* Contact Form */}
      <section className="mb-16">
        <h2>Send Us a Message</h2>
        <p>Can't find what you're looking for? Send us a detailed message and we'll get back to you:</p>

        <div className="not-prose my-8">
          <div className="border dark:border-gray-700 rounded-xl p-6">
            <form 
              onSubmit={(e) => {
                e.preventDefault()
                // Handle form submission
                console.log('Form submitted')
              }}
              className="space-y-6"
            >
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label htmlFor="name" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Name *
                  </label>
                  <input
                    type="text"
                    id="name"
                    name="name"
                    required
                    className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400"
                    placeholder="Your full name"
                  />
                </div>
                <div>
                  <label htmlFor="email" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Email *
                  </label>
                  <input
                    type="email"
                    id="email"
                    name="email"
                    required
                    className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400"
                    placeholder="your.email@example.com"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label htmlFor="device" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Device Type
                  </label>
                  <select
                    id="device"
                    name="device"
                    className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                  >
                    <option value="">Select device type</option>
                    <option value="environmental-monitor">Environmental Monitor V1</option>
                    <option value="liquid-monitor">Liquid Monitor V1</option>
                    <option value="multiple">Multiple devices</option>
                    <option value="other">Other/General question</option>
                  </select>
                </div>
                <div>
                  <label htmlFor="priority" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Priority Level
                  </label>
                  <select
                    id="priority"
                    name="priority"
                    className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                  >
                    <option value="low">Low - General question</option>
                    <option value="medium">Medium - Technical issue</option>
                    <option value="high">High - System down</option>
                    <option value="urgent">Urgent - Production emergency</option>
                  </select>
                </div>
              </div>

              <div>
                <label htmlFor="subject" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Subject *
                </label>
                <input
                  type="text"
                  id="subject"
                  name="subject"
                  required
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400"
                  placeholder="Brief description of your issue or question"
                />
              </div>

              <div>
                <label htmlFor="message" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Message *
                </label>
                <textarea
                  id="message"
                  name="message"
                  rows={6}
                  required
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400"
                  placeholder="Please provide as much detail as possible about your issue, including any error messages, steps you've already tried, and your device setup..."
                ></textarea>
              </div>

              <div className="flex items-center">
                <input
                  id="diagnostics"
                  name="diagnostics"
                  type="checkbox"
                  className="h-4 w-4 text-blue-600 border-gray-300 rounded"
                />
                <label htmlFor="diagnostics" className="ml-2 text-sm text-gray-600 dark:text-gray-400">
                  Include device diagnostic data to help with troubleshooting
                </label>
              </div>

              <div className="flex items-center justify-between">
                <div className="text-sm text-gray-500 dark:text-gray-400">
                  * Required fields
                </div>
                <button
                  type="submit"
                  className="px-6 py-3 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors font-medium"
                >
                  Send Message
                </button>
              </div>
            </form>
          </div>
        </div>
      </section>

      {/* Support Hours */}
      <section className="mb-16">
        <h2>Support Hours & Response Times</h2>
        <p>Our support team operates across multiple time zones to provide you with timely assistance:</p>

        <div className="not-prose my-8 grid grid-cols-1 md:grid-cols-2 gap-8">
          <div className="border dark:border-gray-700 rounded-xl p-6">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              Regional Support Centers
            </h3>
            <div className="space-y-4">
              <div className="flex justify-between items-center py-2 border-b border-gray-200 dark:border-gray-700">
                <div>
                  <div className="font-medium text-gray-900 dark:text-white">North America</div>
                  <div className="text-sm text-gray-600 dark:text-gray-400">PST/EST coverage</div>
                </div>
                <div className="text-right">
                  <div className="text-sm font-medium text-green-600 dark:text-green-400">Online</div>
                  <div className="text-xs text-gray-500 dark:text-gray-400">6 AM - 10 PM PST</div>
                </div>
              </div>
              <div className="flex justify-between items-center py-2 border-b border-gray-200 dark:border-gray-700">
                <div>
                  <div className="font-medium text-gray-900 dark:text-white">Europe</div>
                  <div className="text-sm text-gray-600 dark:text-gray-400">GMT/CET coverage</div>
                </div>
                <div className="text-right">
                  <div className="text-sm font-medium text-green-600 dark:text-green-400">Online</div>
                  <div className="text-xs text-gray-500 dark:text-gray-400">8 AM - 6 PM GMT</div>
                </div>
              </div>
              <div className="flex justify-between items-center py-2">
                <div>
                  <div className="font-medium text-gray-900 dark:text-white">Asia Pacific</div>
                  <div className="text-sm text-gray-600 dark:text-gray-400">JST/AEST coverage</div>
                </div>
                <div className="text-right">
                  <div className="text-sm font-medium text-orange-600 dark:text-orange-400">Limited</div>
                  <div className="text-xs text-gray-500 dark:text-gray-400">9 AM - 5 PM JST</div>
                </div>
              </div>
            </div>
          </div>

          <div className="border dark:border-gray-700 rounded-xl p-6">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              Response Time Commitments
            </h3>
            <div className="space-y-4">
              <div className="flex items-center space-x-3 p-3 bg-red-50 dark:bg-red-900/20 rounded-lg">
                <div className="w-3 h-3 bg-red-500 rounded-full"></div>
                <div>
                  <div className="font-medium text-red-900 dark:text-red-100">Emergency</div>
                  <div className="text-sm text-red-700 dark:text-red-300">&lt; 15 minutes (24/7)</div>
                </div>
              </div>
              <div className="flex items-center space-x-3 p-3 bg-orange-50 dark:bg-orange-900/20 rounded-lg">
                <div className="w-3 h-3 bg-orange-500 rounded-full"></div>
                <div>
                  <div className="font-medium text-orange-900 dark:text-orange-100">High Priority</div>
                  <div className="text-sm text-orange-700 dark:text-orange-300">&lt; 1 hour (business hours)</div>
                </div>
              </div>
              <div className="flex items-center space-x-3 p-3 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg">
                <div className="w-3 h-3 bg-yellow-500 rounded-full"></div>
                <div>
                  <div className="font-medium text-yellow-900 dark:text-yellow-100">Medium Priority</div>
                  <div className="text-sm text-yellow-700 dark:text-yellow-300">&lt; 4 hours (business hours)</div>
                </div>
              </div>
              <div className="flex items-center space-x-3 p-3 bg-green-50 dark:bg-green-900/20 rounded-lg">
                <div className="w-3 h-3 bg-green-500 rounded-full"></div>
                <div>
                  <div className="font-medium text-green-900 dark:text-green-100">Low Priority</div>
                  <div className="text-sm text-green-700 dark:text-green-300">&lt; 24 hours (business days)</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer CTA */}
      <div className="not-prose mt-16">
        <div className="bg-gray-50 dark:bg-gray-800 rounded-2xl p-8 text-center">
          <h3 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
            Still have questions?
          </h3>
          <p className="text-gray-600 dark:text-gray-300 mb-8 max-w-2xl mx-auto">
            Our support team is here to help you succeed with your SpaceGrow.ai devices. 
            Don't hesitate to reach out - we're passionate about helping you grow!
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <button 
              onClick={() => {
                // Handle live chat opening
                console.log('Opening live chat...')
              }}
              className="inline-flex items-center justify-center px-8 py-4 border border-transparent text-lg font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 transition-colors"
            >
              Start Live Chat
            </button>
            <Link
              href="mailto:support@spacegrow.ai"
              className="inline-flex items-center justify-center px-8 py-4 border border-gray-300 dark:border-gray-600 text-lg font-medium rounded-md text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
            >
              Send Email
            </Link>
          </div>
        </div>
      </div>
    </StaticPageTemplate>
  )
}