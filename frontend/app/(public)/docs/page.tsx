import Link from 'next/link'
import StaticPageTemplate from '@/components/templates/StaticPageTemplate'

const documentationSections = [
  {
    title: 'Getting Started',
    description: 'Set up your first device and start monitoring your grow environment',
    icon: '🚀',
    links: [
      { name: 'Quick Start Guide', href: '/docs/quickstart' },
      { name: 'Device Setup', href: '/docs/setup' },
      { name: 'Account Configuration', href: '/docs/account' },
    ]
  },
  {
    title: 'API Reference',
    description: 'Complete API documentation for developers and integrations',
    icon: '⚡',
    links: [
      { name: 'Authentication', href: '/api#authentication' },
      { name: 'Endpoints', href: '/api#endpoints' },
      { name: 'Rate Limits', href: '/api#rate-limits' },
      { name: 'SDKs', href: '/api#sdks' },
    ]
  },
  {
    title: 'Device Information',
    description: 'Learn about our IoT devices and their capabilities',
    icon: '📱',
    links: [
      { name: 'Environmental Monitor V1', href: '/devices#environmental-monitor' },
      { name: 'Liquid Monitor V1', href: '/devices#liquid-monitor' },
      { name: 'Device Comparison', href: '/devices#comparison' },
      { name: 'Technical Specs', href: '/devices#specs' },
    ]
  },
  {
    title: 'Sensors & Data',
    description: 'Understanding sensor types, data ranges, and calibration',
    icon: '🌡️',
    links: [
      { name: 'Sensor Types', href: '/sensors#types' },
      { name: 'Data Ranges', href: '/sensors#ranges' },
      { name: 'Calibration Guide', href: '/sensors#calibration' },
      { name: 'Data Export', href: '/sensors#export' },
    ]
  },
  {
    title: 'Troubleshooting',
    description: 'Common issues and solutions for optimal device performance',
    icon: '🔧',
    links: [
      { name: 'Connection Issues', href: '/troubleshooting#connection' },
      { name: 'Sensor Problems', href: '/troubleshooting#sensors' },
      { name: 'Data Accuracy', href: '/troubleshooting#accuracy' },
      { name: 'Firmware Updates', href: '/troubleshooting#firmware' },
    ]
  },
  {
    title: 'Support',
    description: 'Get help from our team and community resources',
    icon: '💬',
    links: [
      { name: 'Contact Support', href: '/support#contact' },
      { name: 'Community Forum', href: '/support#community' },
      { name: 'Video Tutorials', href: '/support#videos' },
      { name: 'System Status', href: '/support#status' },
    ]
  }
]

export default function DocsPage() {
  return (
    <StaticPageTemplate
      title="Documentation"
      description="Everything you need to know about using SpaceGrow.ai to monitor and optimize your growing environment."
    >
      {/* Quick Links */}
      <div className="not-prose mb-12">
        <div className="rounded-2xl bg-blue-50 dark:bg-blue-900/20 p-8">
          <h2 className="text-xl font-semibold text-blue-900 dark:text-blue-100 mb-4">
            Popular Resources
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <Link 
              href="/docs/quickstart"
              className="block p-4 bg-white dark:bg-gray-800 rounded-lg shadow-sm hover:shadow-md transition-shadow border dark:border-gray-700"
            >
              <div className="font-medium text-gray-900 dark:text-white">Quick Start</div>
              <div className="text-sm text-gray-600 dark:text-gray-300 mt-1">Get up and running in 5 minutes</div>
            </Link>
            <Link 
              href="/api"
              className="block p-4 bg-white dark:bg-gray-800 rounded-lg shadow-sm hover:shadow-md transition-shadow border dark:border-gray-700"
            >
              <div className="font-medium text-gray-900 dark:text-white">API Reference</div>
              <div className="text-sm text-gray-600 dark:text-gray-300 mt-1">Complete API documentation</div>
            </Link>
            <Link 
              href="/troubleshooting"
              className="block p-4 bg-white dark:bg-gray-800 rounded-lg shadow-sm hover:shadow-md transition-shadow border dark:border-gray-700"
            >
              <div className="font-medium text-gray-900 dark:text-white">Troubleshooting</div>
              <div className="text-sm text-gray-600 dark:text-gray-300 mt-1">Solve common issues quickly</div>
            </Link>
          </div>
        </div>
      </div>

      {/* Documentation Sections */}
      <div className="not-prose grid grid-cols-1 md:grid-cols-2 gap-8">
        {documentationSections.map((section) => (
          <div key={section.title} className="border dark:border-gray-700 rounded-xl p-6 hover:shadow-lg transition-shadow">
            <div className="flex items-start space-x-4">
              <div className="text-3xl">{section.icon}</div>
              <div className="flex-1">
                <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
                  {section.title}
                </h3>
                <p className="text-gray-600 dark:text-gray-300 mb-4">
                  {section.description}
                </p>
                <ul className="space-y-2">
                  {section.links.map((link) => (
                    <li key={link.name}>
                      <Link 
                        href={link.href}
                        className="text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 font-medium transition-colors"
                      >
                        {link.name} →
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Search and Contact */}
      <div className="not-prose mt-16 text-center">
        <div className="bg-gray-50 dark:bg-gray-800 rounded-2xl p-8">
          <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
            Can't find what you're looking for?
          </h2>
          <p className="text-gray-600 dark:text-gray-300 mb-6 max-w-2xl mx-auto">
            Our documentation is constantly evolving. If you need help with something specific, 
            our support team is here to help you succeed.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              href="/support"
              className="inline-flex items-center justify-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 dark:bg-blue-500 dark:hover:bg-blue-600 transition-colors"
            >
              Contact Support
            </Link>
            <Link
              href="/support#community"
              className="inline-flex items-center justify-center px-6 py-3 border border-gray-300 dark:border-gray-600 text-base font-medium rounded-md text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
            >
              Join Community
            </Link>
          </div>
        </div>
      </div>
    </StaticPageTemplate>
  )
}