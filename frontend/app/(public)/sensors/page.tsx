import Link from 'next/link'
import StaticPageLayout from '@/components/layout/StaticPageLayout'

const sensorTypes = [
  {
    id: 'temperature',
    name: 'Temperature Sensor',
    icon: '🌡️',
    unit: '°C',
    description: 'High-precision temperature monitoring for optimal growing conditions.',
    range: {
      min: 0,
      max: 40,
      optimal: '18-24'
    },
    accuracy: '±0.1°C',
    zones: {
      error_low: { min: 0, max: 11, color: 'red', description: 'Too cold - risk of plant damage' },
      warning_low: { min: 12, max: 15, color: 'orange', description: 'Below optimal - slow growth' },
      normal: { min: 16, max: 22, color: 'green', description: 'Optimal growing temperature' },
      warning_high: { min: 23, max: 30, color: 'orange', description: 'Above optimal - stress risk' },
      error_high: { min: 31, max: 40, color: 'red', description: 'Too hot - plant damage likely' }
    },
    applications: [
      'Greenhouse climate control',
      'Indoor growing operations',
      'Seedling nurseries',
      'Drying and curing rooms'
    ],
    tips: [
      'Place sensors away from direct heat sources',
      'Monitor daily temperature swings',
      'Consider different zones in larger spaces',
      'Calibrate monthly for best accuracy'
    ]
  },
  {
    id: 'humidity',
    name: 'Humidity Sensor',
    icon: '💧',
    unit: '%',
    description: 'Relative humidity monitoring to prevent mold and optimize transpiration.',
    range: {
      min: 0,
      max: 100,
      optimal: '60-70'
    },
    accuracy: '±2%',
    zones: {
      error_low: { min: 0, max: 39, color: 'red', description: 'Too dry - plant stress and slow growth' },
      warning_low: { min: 40, max: 59, color: 'orange', description: 'Low humidity - monitor closely' },
      normal: { min: 60, max: 70, color: 'green', description: 'Optimal humidity range' },
      warning_high: { min: 71, max: 80, color: 'orange', description: 'High humidity - mold risk' },
      error_high: { min: 81, max: 100, color: 'red', description: 'Too humid - high mold/pest risk' }
    },
    applications: [
      'Vegetative growth rooms',
      'Flowering chambers',
      'Drying and curing',
      'Propagation areas'
    ],
    tips: [
      'Adjust humidity based on growth stage',
      'Ensure good air circulation',
      'Monitor VPD (Vapor Pressure Deficit)',
      'Consider dehumidifiers for high humidity'
    ]
  },
  {
    id: 'pressure',
    name: 'Pressure Sensor',
    icon: '📊',
    unit: 'bar',
    description: 'Atmospheric pressure monitoring for environmental optimization.',
    range: {
      min: 0,
      max: 11,
      optimal: '6-8'
    },
    accuracy: '±0.01 bar',
    zones: {
      error_low: { min: 0, max: 3, color: 'red', description: 'Very low pressure - system issues' },
      warning_low: { min: 4, max: 5, color: 'orange', description: 'Below normal pressure' },
      normal: { min: 6, max: 8, color: 'green', description: 'Normal atmospheric pressure' },
      warning_high: { min: 8.1, max: 9, color: 'orange', description: 'Elevated pressure' },
      error_high: { min: 10, max: 11, color: 'red', description: 'High pressure - check systems' }
    },
    applications: [
      'Weather monitoring',
      'Altitude compensation',
      'HVAC system monitoring',
      'Environmental research'
    ],
    tips: [
      'Use for weather prediction',
      'Monitor pressure changes',
      'Correlate with other sensors',
      'Consider altitude effects'
    ]
  },
  {
    id: 'ph',
    name: 'pH Sensor',
    icon: '🧪',
    unit: 'pH',
    description: 'Precise pH monitoring for optimal nutrient uptake in hydroponic systems.',
    range: {
      min: 0,
      max: 14,
      optimal: '5.5-6.5'
    },
    accuracy: '±0.1 pH',
    zones: {
      error_low: { min: 0, max: 4.9, color: 'red', description: 'Too acidic - nutrient lockout' },
      warning_low: { min: 5.0, max: 5.4, color: 'orange', description: 'Slightly acidic - monitor' },
      normal: { min: 5.5, max: 6.5, color: 'green', description: 'Optimal pH for nutrient uptake' },
      warning_high: { min: 6.6, max: 7.0, color: 'orange', description: 'Slightly alkaline' },
      error_high: { min: 7.1, max: 14, color: 'red', description: 'Too alkaline - nutrient problems' }
    },
    applications: [
      'Hydroponic systems',
      'Nutrient reservoirs',
      'Water quality monitoring',
      'Aquaponics systems'
    ],
    tips: [
      'Calibrate with standard solutions',
      'Monitor pH drift over time',
      'Adjust gradually to avoid shock',
      'Clean probes regularly'
    ]
  },
  {
    id: 'ec',
    name: 'EC Sensor',
    icon: '⚡',
    unit: 'mS/cm',
    description: 'Electrical conductivity measurement for precise nutrient concentration monitoring.',
    range: {
      min: 0,
      max: 10,
      optimal: '1.2-2.0'
    },
    accuracy: '±0.1 mS/cm',
    zones: {
      error_low: { min: 0, max: 0.8, color: 'red', description: 'Too low - nutrient deficiency' },
      warning_low: { min: 0.9, max: 1.1, color: 'orange', description: 'Low nutrients - supplement' },
      normal: { min: 1.2, max: 2.0, color: 'green', description: 'Optimal nutrient concentration' },
      warning_high: { min: 2.1, max: 2.8, color: 'orange', description: 'High nutrients - dilute' },
      error_high: { min: 2.9, max: 10, color: 'red', description: 'Too high - nutrient burn risk' }
    },
    applications: [
      'Nutrient solution management',
      'Fertigation systems',
      'Water quality testing',
      'Hydroponic monitoring'
    ],
    tips: [
      'Adjust based on plant growth stage',
      'Consider water temperature effects',
      'Regular calibration essential',
      'Monitor TDS and PPM equivalents'
    ]
  }
]

const calibrationSchedule = [
  { sensor: 'Temperature', frequency: 'Monthly', method: 'Reference thermometer', difficulty: 'Easy' },
  { sensor: 'Humidity', frequency: 'Bi-monthly', method: 'Salt solutions', difficulty: 'Medium' },
  { sensor: 'Pressure', frequency: 'Quarterly', method: 'Barometric reference', difficulty: 'Easy' },
  { sensor: 'pH', frequency: 'Weekly', method: 'Buffer solutions (4.0, 7.0, 10.0)', difficulty: 'Medium' },
  { sensor: 'EC', frequency: 'Bi-weekly', method: 'Standard solutions (1.41, 12.88 mS/cm)', difficulty: 'Medium' }
]

export default function SensorsPage() {
  return (
    <StaticPageLayout
      title="Sensor Technology"
      description="Comprehensive guide to our precision sensors, optimal ranges, and monitoring best practices."
    >
      {/* Sensor Overview */}
      <div className="not-prose mb-16">
        <div className="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-xl p-6 mb-12">
          <div className="flex items-start space-x-4">
            <div className="text-green-600 dark:text-green-400 text-2xl">🎯</div>
            <div>
              <h3 className="font-semibold text-green-800 dark:text-green-200 mb-2">
                Precision Monitoring for Optimal Growth
              </h3>
              <p className="text-green-700 dark:text-green-300 mb-4">
                Our industrial-grade sensors provide the accuracy and reliability needed for professional growing operations. 
                Each sensor is calibrated and tested to ensure consistent, accurate readings.
              </p>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                <div className="text-center">
                  <div className="font-semibold text-green-800 dark:text-green-200">Industrial Grade</div>
                  <div className="text-green-600 dark:text-green-400">Professional accuracy</div>
                </div>
                <div className="text-center">
                  <div className="font-semibold text-green-800 dark:text-green-200">Real-time Data</div>
                  <div className="text-green-600 dark:text-green-400">Continuous monitoring</div>
                </div>
                <div className="text-center">
                  <div className="font-semibold text-green-800 dark:text-green-200">Smart Alerts</div>
                  <div className="text-green-600 dark:text-green-400">Proactive notifications</div>
                </div>
                <div className="text-center">
                  <div className="font-semibold text-green-800 dark:text-green-200">Long Lifespan</div>
                  <div className="text-green-600 dark:text-green-400">Years of reliable service</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Sensor Types Section */}
      <section id="types" className="mb-16">
        <h2>Sensor Types</h2>
        <p>Each sensor type serves a specific purpose in monitoring and optimizing your growing environment:</p>

        <div className="not-prose space-y-12 mt-8">
          {sensorTypes.map((sensor) => (
            <div key={sensor.id} id={sensor.id} className="border dark:border-gray-700 rounded-2xl p-8">
              {/* Sensor Header */}
              <div className="flex items-center space-x-4 mb-6">
                <div className="text-4xl">{sensor.icon}</div>
                <div>
                  <h3 className="text-2xl font-bold text-gray-900 dark:text-white">
                    {sensor.name}
                  </h3>
                  <p className="text-gray-600 dark:text-gray-300">
                    {sensor.description}
                  </p>
                </div>
                <div className="ml-auto text-right">
                  <div className="text-sm text-gray-500 dark:text-gray-400">Accuracy</div>
                  <div className="font-bold text-blue-600 dark:text-blue-400">{sensor.accuracy}</div>
                </div>
              </div>

              {/* Sensor Specs */}
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Range & Zones */}
                <div className="lg:col-span-2">
                  <h4 className="font-semibold text-gray-900 dark:text-white mb-4">Measurement Zones</h4>
                  <div className="space-y-3">
                    {Object.entries(sensor.zones).map(([zone, config]) => (
                      <div key={zone} className="flex items-center space-x-3">
                        <div className={`w-4 h-4 rounded-full ${
                          config.color === 'red' ? 'bg-red-500' :
                          config.color === 'orange' ? 'bg-orange-500' :
                          'bg-green-500'
                        }`}></div>
                        <div className="flex-1">
                          <div className="flex items-center justify-between">
                            <span className="font-medium text-gray-900 dark:text-white text-sm">
                              {config.min} - {config.max} {sensor.unit}
                            </span>
                            <span className="text-xs text-gray-500 dark:text-gray-400 capitalize">
                              {zone.replace('_', ' ')}
                            </span>
                          </div>
                          <div className="text-xs text-gray-600 dark:text-gray-400">
                            {config.description}
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                  
                  <div className="mt-4 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
                    <div className="text-sm font-medium text-blue-900 dark:text-blue-100">
                      Optimal Range: {sensor.range.optimal} {sensor.unit}
                    </div>
                  </div>
                </div>

                {/* Applications & Tips */}
                <div className="space-y-6">
                  <div>
                    <h4 className="font-semibold text-gray-900 dark:text-white mb-3">Applications</h4>
                    <ul className="space-y-2">
                      {sensor.applications.map((app) => (
                        <li key={app} className="text-sm text-gray-600 dark:text-gray-400 flex items-start space-x-2">
                          <span className="text-green-500 mt-1">•</span>
                          <span>{app}</span>
                        </li>
                      ))}
                    </ul>
                  </div>

                  <div>
                    <h4 className="font-semibold text-gray-900 dark:text-white mb-3">Pro Tips</h4>
                    <ul className="space-y-2">
                      {sensor.tips.map((tip) => (
                        <li key={tip} className="text-sm text-gray-600 dark:text-gray-400 flex items-start space-x-2">
                          <span className="text-blue-500 mt-1">💡</span>
                          <span>{tip}</span>
                        </li>
                      ))}
                ```
                                    </ul>
                                  </div>
                                </div>
                              </div>
                            </div>
                          ))}
                        </div>
                      </section>
                
                      {/* Calibration Schedule Section */}
                      <section id="calibration" className="mb-16">
                        <h2>Calibration Schedule</h2>
                        <p>Regular calibration ensures your sensors remain accurate and reliable. Follow these recommended schedules:</p>
                        <div className="overflow-x-auto mt-6">
                          <table className="min-w-full text-sm border rounded-lg overflow-hidden">
                            <thead>
                              <tr className="bg-gray-100 dark:bg-gray-800">
                                <th className="px-4 py-2 text-left font-semibold">Sensor</th>
                                <th className="px-4 py-2 text-left font-semibold">Frequency</th>
                                <th className="px-4 py-2 text-left font-semibold">Calibration Method</th>
                                <th className="px-4 py-2 text-left font-semibold">Difficulty</th>
                              </tr>
                            </thead>
                            <tbody>
                              {calibrationSchedule.map((item) => (
                                <tr key={item.sensor} className="border-t dark:border-gray-700">
                                  <td className="px-4 py-2">{item.sensor}</td>
                                  <td className="px-4 py-2">{item.frequency}</td>
                                  <td className="px-4 py-2">{item.method}</td>
                                  <td className="px-4 py-2">{item.difficulty}</td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>
                      </section>
                
                      {/* More Info */}
                      <div className="not-prose mt-12 text-center">
                        <Link href="/contact" className="inline-block bg-green-600 text-white px-6 py-3 rounded-lg font-semibold hover:bg-green-700 transition">
                          Contact us for custom sensor solutions
                        </Link>
                      </div>
                    </StaticPageLayout>
                  )
                }