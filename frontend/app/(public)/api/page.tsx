import Link from 'next/link'
import StaticPageLayout from '@/components/layout/StaticPageLayout'

const codeExamples = {
  curl: `curl -X POST https://api.spacegrow.ai/v1/devices/register \\
  -H "Authorization: Bearer YOUR_API_TOKEN" \\
  -H "Content-Type: application/json" \\
  -d '{
    "token": "device_activation_token",
    "device_type_id": 1
  }'`,
  
  javascript: `const response = await fetch('https://api.spacegrow.ai/v1/devices/register', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer YOUR_API_TOKEN',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    token: 'device_activation_token',
    device_type_id: 1
  })
});

const data = await response.json();`,

  python: `import requests

url = 'https://api.spacegrow.ai/v1/devices/register'
headers = {
    'Authorization': 'Bearer YOUR_API_TOKEN',
    'Content-Type': 'application/json'
}
data = {
    'token': 'device_activation_token',
    'device_type_id': 1
}

response = requests.post(url, headers=headers, json=data)`
}

const endpoints = [
  {
    method: 'POST',
    path: '/v1/auth/login',
    description: 'Authenticate user and get JWT token',
    category: 'Authentication'
  },
  {
    method: 'POST',
    path: '/v1/devices/register',
    description: 'Register a new device with activation token',
    category: 'Devices'
  },
  {
    method: 'GET',
    path: '/v1/devices',
    description: 'List all user devices',
    category: 'Devices'
  },
  {
    method: 'POST',
    path: '/v1/esp32/sensor_data',
    description: 'Submit sensor readings from ESP32 device',
    category: 'Sensor Data'
  },
  {
    method: 'GET',
    path: '/v1/chart_data/latest',
    description: 'Get latest sensor data for charts',
    category: 'Sensor Data'
  },
  {
    method: 'POST',
    path: '/v1/devices/{id}/commands',
    description: 'Send command to device (lights, pumps, etc.)',
    category: 'Device Control'
  }
]

export default function ApiPage() {
  return (
    <StaticPageLayout
      title="API Reference"
      description="Complete REST API documentation for integrating with SpaceGrow.ai platform."
      lastUpdated="January 2025"
    >
      {/* Quick Start */}
      <div className="not-prose mb-12">
        <div className="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-xl p-6">
          <div className="flex items-start space-x-3">
            <div className="text-green-600 dark:text-green-400 text-xl">✓</div>
            <div>
              <h3 className="font-semibold text-green-800 dark:text-green-200 mb-2">
                Ready to integrate?
              </h3>
              <p className="text-green-700 dark:text-green-300 mb-4">
                Our REST API uses standard HTTP methods and returns JSON responses. All endpoints require authentication via JWT tokens.
              </p>
              <div className="flex flex-wrap gap-3">
                <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-green-100 dark:bg-green-800 text-green-800 dark:text-green-200">
                  Base URL: https://api.spacegrow.ai
                </span>
                <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-green-100 dark:bg-green-800 text-green-800 dark:text-green-200">
                  Version: v1
                </span>
                <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-green-100 dark:bg-green-800 text-green-800 dark:text-green-200">
                  Format: JSON
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Authentication Section */}
      <section id="authentication" className="mb-12">
        <h2>Authentication</h2>
        <p>All API requests require a valid JWT token obtained through the authentication endpoint.</p>
        
        <h3>Getting an API Token</h3>
        <div className="not-prose bg-gray-50 dark:bg-gray-800 rounded-lg p-4 my-6">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium text-gray-700 dark:text-gray-300">Example Request</span>
          </div>
          <pre className="text-sm text-gray-800 dark:text-gray-200 overflow-x-auto">
            <code>{codeExamples.curl}</code>
          </pre>
        </div>

        <h3>Using the Token</h3>
        <p>Include the JWT token in the Authorization header of all subsequent requests:</p>
        <div className="not-prose bg-gray-50 dark:bg-gray-800 rounded-lg p-4 my-6">
          <pre className="text-sm text-gray-800 dark:text-gray-200">
            <code>Authorization: Bearer YOUR_JWT_TOKEN</code>
          </pre>
        </div>
      </section>

      {/* Rate Limits Section */}
      <section id="rate-limits" className="mb-12">
        <h2>Rate Limits</h2>
        <p>API requests are rate limited to ensure service quality for all users:</p>
        
        <div className="not-prose my-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="border dark:border-gray-700 rounded-lg p-4">
              <div className="text-2xl font-bold text-blue-600 dark:text-blue-400">1,000</div>
              <div className="text-sm text-gray-600 dark:text-gray-400">requests per hour</div>
              <div className="text-xs text-gray-500 dark:text-gray-500 mt-1">General API</div>
            </div>
            <div className="border dark:border-gray-700 rounded-lg p-4">
              <div className="text-2xl font-bold text-green-600 dark:text-green-400">100</div>
              <div className="text-sm text-gray-600 dark:text-gray-400">requests per minute</div>
              <div className="text-xs text-gray-500 dark:text-gray-500 mt-1">Device Data</div>
            </div>
            <div className="border dark:border-gray-700 rounded-lg p-4">
              <div className="text-2xl font-bold text-purple-600 dark:text-purple-400">10</div>
              <div className="text-sm text-gray-600 dark:text-gray-400">requests per minute</div>
              <div className="text-xs text-gray-500 dark:text-gray-500 mt-1">Device Commands</div>
            </div>
          </div>
        </div>
      </section>

      {/* Endpoints Section */}
      <section id="endpoints" className="mb-12">
        <h2>API Endpoints</h2>
        <p>Complete list of available endpoints organized by category:</p>

        <div className="not-prose my-8">
          {['Authentication', 'Devices', 'Sensor Data', 'Device Control'].map((category) => (
            <div key={category} className="mb-8">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4 border-b dark:border-gray-700 pb-2">
                {category}
              </h3>
              <div className="space-y-3">
                {endpoints.filter(endpoint => endpoint.category === category).map((endpoint, index) => (
                  <div key={index} className="border dark:border-gray-700 rounded-lg p-4 hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center space-x-3 mb-2">
                          <span className={`inline-flex items-center px-2 py-1 rounded text-xs font-medium ${
                            endpoint.method === 'GET' 
                              ? 'bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200'
                              : 'bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200'
                          }`}>
                            {endpoint.method}
                          </span>
                          <code className="text-sm font-mono text-gray-900 dark:text-gray-100">
                            {endpoint.path}
                          </code>
                        </div>
                        <p className="text-sm text-gray-600 dark:text-gray-400">
                          {endpoint.description}
                        </p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* SDKs Section */}
      <section id="sdks" className="mb-12">
        <h2>SDKs & Libraries</h2>
        <p>Official and community SDKs to help you integrate faster:</p>

        <div className="not-prose my-8 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div className="border dark:border-gray-700 rounded-xl p-6">
            <div className="flex items-center space-x-3 mb-4">
              <div className="w-10 h-10 bg-yellow-100 dark:bg-yellow-900 rounded-lg flex items-center justify-center">
                <span className="text-yellow-600 dark:text-yellow-400 font-bold">JS</span>
              </div>
              <div>
                <h3 className="font-semibold text-gray-900 dark:text-white">JavaScript SDK</h3>
                <p className="text-sm text-gray-600 dark:text-gray-400">Official</p>
              </div>
            </div>
            <p className="text-sm text-gray-600 dark:text-gray-300 mb-4">
              Full-featured SDK for Node.js and browser applications.
            </p>
            <Link 
              href="#" 
              className="text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 text-sm font-medium"
            >
              View on GitHub →
            </Link>
          </div>

          <div className="border dark:border-gray-700 rounded-xl p-6">
            <div className="flex items-center space-x-3 mb-4">
              <div className="w-10 h-10 bg-blue-100 dark:bg-blue-900 rounded-lg flex items-center justify-center">
                <span className="text-blue-600 dark:text-blue-400 font-bold">PY</span>
              </div>
              <div>
                <h3 className="font-semibold text-gray-900 dark:text-white">Python SDK</h3>
                <p className="text-sm text-gray-600 dark:text-gray-400">Official</p>
              </div>
            </div>
            <p className="text-sm text-gray-600 dark:text-gray-300 mb-4">
              Perfect for data analysis and automation scripts.
            </p>
            <Link 
              href="#" 
              className="text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 text-sm font-medium"
            >
              View on GitHub →
            </Link>
          </div>

          <div className="border dark:border-gray-700 rounded-xl p-6">
            <div className="flex items-center space-x-3 mb-4">
              <div className="w-10 h-10 bg-red-100 dark:bg-red-900 rounded-lg flex items-center justify-center">
                <span className="text-red-600 dark:text-red-400 font-bold">🔧</span>
              </div>
              <div>
                <h3 className="font-semibold text-gray-900 dark:text-white">Arduino Library</h3>
                <p className="text-sm text-gray-600 dark:text-gray-400">Official</p>
              </div>
            </div>
            <p className="text-sm text-gray-600 dark:text-gray-300 mb-4">
              Easy integration for ESP32 and Arduino projects.
            </p>
            <Link 
              href="#" 
              className="text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 text-sm font-medium"
            >
              View on GitHub →
            </Link>
          </div>
        </div>
      </section>

      {/* Status Codes */}
      <section className="mb-12">
        <h2>HTTP Status Codes</h2>
        <p>Our API uses standard HTTP status codes to indicate success or failure:</p>

        <div className="not-prose my-6">
          <div className="border dark:border-gray-700 rounded-lg overflow-hidden">
            <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
              <thead className="bg-gray-50 dark:bg-gray-800">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Code
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Meaning
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white dark:bg-gray-900 divide-y divide-gray-200 dark:divide-gray-700">
                {[
                  { code: '200', meaning: 'OK - Request successful' },
                  { code: '201', meaning: 'Created - Resource created successfully' },
                  { code: '400', meaning: 'Bad Request - Invalid request parameters' },
                  { code: '401', meaning: 'Unauthorized - Invalid or missing authentication' },
                  { code: '403', meaning: 'Forbidden - Insufficient permissions' },
                  { code: '404', meaning: 'Not Found - Resource not found' },
                  { code: '429', meaning: 'Too Many Requests - Rate limit exceeded' },
                  { code: '500', meaning: 'Internal Server Error - Server error' }
                ].map((status) => (
                  <tr key={status.code}>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-mono text-gray-900 dark:text-gray-100">
                      {status.code}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600 dark:text-gray-300">
                      {status.meaning}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>

      {/* Footer CTA */}
      <div className="not-prose mt-16">
        <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-xl p-8 text-center">
          <h3 className="text-xl font-semibold text-blue-900 dark:text-blue-100 mb-4">
            Need help getting started?
          </h3>
          <p className="text-blue-700 dark:text-blue-300 mb-6 max-w-2xl mx-auto">
            Our developer support team is here to help you integrate successfully. 
            Join our community or reach out directly.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              href="/support"
              className="inline-flex items-center justify-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 transition-colors"
            >
              Contact Support
            </Link>
            <Link
              href="/support#community"
              className="inline-flex items-center justify-center px-6 py-3 border border-blue-300 dark:border-blue-600 text-base font-medium rounded-md text-blue-700 dark:text-blue-300 bg-white dark:bg-blue-900/20 hover:bg-blue-50 dark:hover:bg-blue-900/40 transition-colors"
            >
              Join Discord
            </Link>
          </div>
        </div>
      </div>
    </StaticPageLayout>
  )
}