import Link from 'next/link'
import StaticPageLayout from '@/components/layout/StaticPageLayout'

const devices = [
  {
    id: 'environmental-monitor',
    name: 'Environmental Monitor V1',
    tagline: 'Complete environmental control for optimal growing conditions',
    price: '$299.99',
    image: '/api/placeholder/400/300',
    description: 'Advanced environmental monitoring device with integrated sensors and automated control systems.',
    sensors: [
      { name: 'Temperature', range: '0-40°C', accuracy: '±0.1°C', icon: '🌡️' },
      { name: 'Humidity', range: '0-100%', accuracy: '±2%', icon: '💧' },
      { name: 'Pressure', range: '0-11 bar', accuracy: '±0.01 bar', icon: '📊' }
    ],
    actuators: [
      { name: 'LED Lights', description: 'Programmable full-spectrum grow lights', icon: '💡' },
      { name: 'Misting System', description: 'Automated humidity control and nutrient delivery', icon: '🌊' }
    ],
    features: [
      'WiFi connectivity with real-time data sync',
      'Mobile app control and monitoring',
      'Automated scheduling and alerts',
      'Data logging and analytics',
      'Cloud backup and export',
      'Expandable sensor network'
    ],
    useCases: [
      'Indoor growing operations',
      'Greenhouse monitoring',
      'Hydroponic systems',
      'Research facilities'
    ]
  },
  {
    id: 'liquid-monitor',
    name: 'Liquid Monitor V1',
    tagline: 'Precision nutrient monitoring and automated dosing',
    price: '$199.99',
    image: '/api/placeholder/400/300',
    description: 'Professional-grade liquid monitoring system for precise nutrient management and water quality control.',
    sensors: [
      { name: 'pH Level', range: '0-14 pH', accuracy: '±0.1 pH', icon: '🧪' },
      { name: 'Electrical Conductivity', range: '0-10 mS/cm', accuracy: '±0.1 mS/cm', icon: '⚡' },
      { name: 'Temperature', range: '0-40°C', accuracy: '±0.1°C', icon: '🌡️' }
    ],
    actuators: [
      { name: 'Dosing Pumps (5x)', description: 'Precision nutrient and pH adjustment pumps', icon: '💉' },
      { name: 'Mixing System', description: 'Automated solution mixing and circulation', icon: '🔄' }
    ],
    features: [
      'Multi-channel dosing system',
      'Automated pH and EC correction',
      'Real-time nutrient tracking',
      'Custom dosing schedules',
      'Safety interlocks and alarms',
      'Integration with environmental systems'
    ],
    useCases: [
      'Hydroponic operations',
      'Aquaponics systems',
      'Commercial growing',
      'Research and development'
    ]
  }
]

const comparisonFeatures = [
  { feature: 'WiFi Connectivity', env: true, liquid: true },
  { feature: 'Mobile App', env: true, liquid: true },
  { feature: 'Cloud Sync', env: true, liquid: true },
  { feature: 'Temperature Sensor', env: true, liquid: true },
  { feature: 'Humidity Sensor', env: true, liquid: false },
  { feature: 'Pressure Sensor', env: true, liquid: false },
  { feature: 'pH Sensor', env: false, liquid: true },
  { feature: 'EC Sensor', env: false, liquid: true },
  { feature: 'LED Control', env: true, liquid: false },
  { feature: 'Misting System', env: true, liquid: false },
  { feature: 'Dosing Pumps', env: false, liquid: true },
  { feature: 'Automated Scheduling', env: true, liquid: true },
  { feature: 'Data Analytics', env: true, liquid: true },
  { feature: 'API Access', env: true, liquid: true }
]

export default function DevicesPage() {
  return (
    <StaticPageLayout
      title="IoT Devices"
      description="Professional-grade IoT devices designed for precision growing, monitoring, and automation."
    >
      {/* Device Overview */}
      <div className="not-prose mb-16">
        <div className="text-center mb-12">
          <h2 className="text-3xl font-bold text-gray-900 dark:text-white mb-4">
            Choose Your Growing Solution
          </h2>
          <p className="text-lg text-gray-600 dark:text-gray-300 max-w-3xl mx-auto">
            Our IoT devices are designed by growers, for growers. Each device combines precision sensors, 
            automated controls, and intelligent software to optimize your growing environment.
          </p>
        </div>

        {/* Device Cards */}
        <div className="space-y-16">
          {devices.map((device, index) => (
            <div key={device.id} id={device.id} className={`flex flex-col ${index % 2 === 1 ? 'lg:flex-row-reverse' : 'lg:flex-row'} gap-12 items-center`}>
              {/* Device Image */}
              <div className="flex-1">
                <div className="aspect-[4/3] bg-gray-100 dark:bg-gray-800 rounded-2xl overflow-hidden">
                  <img 
                    src={device.image} 
                    alt={device.name}
                    className="w-full h-full object-cover"
                  />
                </div>
              </div>

              {/* Device Info */}
              <div className="flex-1 space-y-6">
                <div>
                  <div className="flex items-center space-x-4 mb-2">
                    <h3 className="text-2xl font-bold text-gray-900 dark:text-white">
                      {device.name}
                    </h3>
                    <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200">
                      {device.price}
                    </span>
                  </div>
                  <p className="text-lg text-gray-600 dark:text-gray-300 mb-4">
                    {device.tagline}
                  </p>
                  <p className="text-gray-600 dark:text-gray-400">
                    {device.description}
                  </p>
                </div>

                {/* Sensors */}
                <div>
                  <h4 className="font-semibold text-gray-900 dark:text-white mb-3">Sensors</h4>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    {device.sensors.map((sensor) => (
                      <div key={sensor.name} className="flex items-center space-x-3 p-3 bg-gray-50 dark:bg-gray-800 rounded-lg">
                        <span className="text-xl">{sensor.icon}</span>
                        <div>
                          <div className="font-medium text-gray-900 dark:text-white text-sm">
                            {sensor.name}
                          </div>
                          <div className="text-xs text-gray-600 dark:text-gray-400">
                            {sensor.range} • {sensor.accuracy}
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Actuators */}
                <div>
                  <h4 className="font-semibold text-gray-900 dark:text-white mb-3">Controls</h4>
                  <div className="space-y-2">
                    {device.actuators.map((actuator) => (
                      <div key={actuator.name} className="flex items-start space-x-3 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
                        <span className="text-lg mt-0.5">{actuator.icon}</span>
                        <div>
                          <div className="font-medium text-blue-900 dark:text-blue-100 text-sm">
                            {actuator.name}
                          </div>
                          <div className="text-xs text-blue-700 dark:text-blue-300">
                            {actuator.description}
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* CTA */}
                <div className="pt-4">
                  <Link
                    href="/shop"
                    className="inline-flex items-center justify-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 transition-colors"
                  >
                    View in Shop →
                  </Link>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Feature Comparison */}
      <section id="comparison" className="mb-16">
        <h2>Device Comparison</h2>
        <p>Compare features across our device lineup to find the perfect fit for your needs:</p>

        <div className="not-prose my-8 overflow-x-auto">
          <table className="min-w-full border dark:border-gray-700 rounded-lg overflow-hidden">
            <thead className="bg-gray-50 dark:bg-gray-800">
              <tr>
                <th className="px-6 py-4 text-left text-sm font-medium text-gray-900 dark:text-white">
                  Feature
                </th>
                <th className="px-6 py-4 text-center text-sm font-medium text-gray-900 dark:text-white">
                  Environmental Monitor V1
                </th>
                <th className="px-6 py-4 text-center text-sm font-medium text-gray-900 dark:text-white">
                  Liquid Monitor V1
                </th>
              </tr>
            </thead>
            <tbody className="bg-white dark:bg-gray-900 divide-y divide-gray-200 dark:divide-gray-700">
              {comparisonFeatures.map((row) => (
                <tr key={row.feature}>
                  <td className="px-6 py-4 text-sm text-gray-900 dark:text-white font-medium">
                    {row.feature}
                  </td>
                  <td className="px-6 py-4 text-center">
                    {row.env ? (
                      <span className="text-green-600 dark:text-green-400 text-xl">✓</span>
                    ) : (
                      <span className="text-gray-300 dark:text-gray-600 text-xl">✗</span>
                    )}
                  </td>
                  <td className="px-6 py-4 text-center">
                    {row.liquid ? (
                      <span className="text-green-600 dark:text-green-400 text-xl">✓</span>
                    ) : (
                      <span className="text-gray-300 dark:text-gray-600 text-xl">✗</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      {/* Technical Specifications */}
      <section id="specs" className="mb-16">
        <h2>Technical Specifications</h2>
        
        <div className="not-prose grid grid-cols-1 lg:grid-cols-2 gap-8 my-8">
          {devices.map((device) => (
            <div key={device.id} className="border dark:border-gray-700 rounded-xl p-6">
              <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-6">
                {device.name}
              </h3>
              
              <div className="space-y-6">
                <div>
                  <h4 className="font-medium text-gray-900 dark:text-white mb-3">Power & Connectivity</h4>
                  <div className="space-y-2 text-sm">
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">Power Supply</span>
                      <span className="text-gray-900 dark:text-white">12V DC, 2A</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">WiFi</span>
                      <span className="text-gray-900 dark:text-white">802.11 b/g/n</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">Bluetooth</span>
                      <span className="text-gray-900 dark:text-white">5.0 BLE</span>
                    </div>
                  </div>
                </div>

                <div>
                  <h4 className="font-medium text-gray-900 dark:text-white mb-3">Physical</h4>
                  <div className="space-y-2 text-sm">
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">Dimensions</span>
                      <span className="text-gray-900 dark:text-white">150×100×50mm</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">Weight</span>
                      <span className="text-gray-900 dark:text-white">450g</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">IP Rating</span>
                      <span className="text-gray-900 dark:text-white">IP65</span>
                    </div>
                  </div>
                </div>

                <div>
                  <h4 className="font-medium text-gray-900 dark:text-white mb-3">Use Cases</h4>
                  <div className="flex flex-wrap gap-2">
                    {device.useCases.map((useCase) => (
                      <span 
                        key={useCase}
                        className="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-gray-100 dark:bg-gray-800 text-gray-800 dark:text-gray-200"
                      >
                        {useCase}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Integration & Setup */}
      <section className="mb-16">
        <h2>Easy Integration</h2>
        <p>Get your devices connected and monitoring in minutes with our streamlined setup process:</p>

        <div className="not-prose my-8 grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="text-center p-6">
            <div className="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-lg flex items-center justify-center mx-auto mb-4">
              <span className="text-blue-600 dark:text-blue-400 font-bold text-xl">1</span>
            </div>
            <h3 className="font-semibold text-gray-900 dark:text-white mb-2">Unbox & Connect</h3>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Connect your device to power and WiFi using our mobile app's guided setup.
            </p>
          </div>
          
          <div className="text-center p-6">
            <div className="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-lg flex items-center justify-center mx-auto mb-4">
              <span className="text-blue-600 dark:text-blue-400 font-bold text-xl">2</span>
            </div>
            <h3 className="font-semibold text-gray-900 dark:text-white mb-2">Configure & Calibrate</h3>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Set your growing parameters and calibrate sensors for optimal accuracy.
            </p>
          </div>
          
          <div className="text-center p-6">
            <div className="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-lg flex items-center justify-center mx-auto mb-4">
              <span className="text-blue-600 dark:text-blue-400 font-bold text-xl">3</span>
            </div>
            <h3 className="font-semibold text-gray-900 dark:text-white mb-2">Monitor & Optimize</h3>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Start monitoring in real-time and let automation optimize your growing environment.
            </p>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <div className="not-prose mt-16">
        <div className="bg-gradient-to-r from-green-50 to-blue-50 dark:from-green-900/20 dark:to-blue-900/20 rounded-2xl p-8 text-center">
          <h3 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
            Ready to transform your growing operation?
          </h3>
          <p className="text-gray-600 dark:text-gray-300 mb-8 max-w-2xl mx-auto">
            Join thousands of growers who've improved their yields and reduced manual monitoring 
            with our IoT devices. Free shipping on all orders.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              href="/shop"
              className="inline-flex items-center justify-center px-8 py-4 border border-transparent text-lg font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 transition-colors"
            >
              Shop Devices
            </Link>
            <Link
              href="/docs"
              className="inline-flex items-center justify-center px-8 py-4 border border-gray-300 dark:border-gray-600 text-lg font-medium rounded-md text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
            >
              View Documentation
            </Link>
          </div>
        </div>
      </div>
    </StaticPageLayout>
  )
}