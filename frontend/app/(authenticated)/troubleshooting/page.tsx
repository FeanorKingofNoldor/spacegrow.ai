import Link from 'next/link'
import StaticPageLayout from '@/components/layout/StaticPageLayout'

const troubleshootingCategories = [
  {
    id: 'connection',
    title: 'Connection Issues',
    icon: '📶',
    description: 'WiFi connectivity, device registration, and communication problems',
    issues: [
      {
        problem: 'Device won\'t connect to WiFi',
        symptoms: ['Red WiFi indicator light', 'Device not appearing in app', 'Timeout during setup'],
        solutions: [
          'Check WiFi password and network settings',
          'Ensure 2.4GHz network is available (devices don\'t support 5GHz)',
          'Move device closer to router during initial setup',
          'Restart router and try again',
          'Reset device to factory settings if persistent'
        ],
        urgency: 'medium'
      },
      {
        problem: 'Device loses connection frequently',
        symptoms: ['Intermittent data gaps', 'Connection status shows offline', 'Delayed notifications'],
        solutions: [
          'Check WiFi signal strength at device location',
          'Update device firmware to latest version',
          'Ensure power supply is stable and properly connected',
          'Check for network interference from other devices',
          'Consider WiFi extender if signal is weak'
        ],
        urgency: 'high'
      },
      {
        problem: 'Can\'t register device with activation token',
        symptoms: ['Invalid token error', 'Device already registered message', 'Token expired'],
        solutions: [
          'Verify token hasn\'t been used on another device',
          'Check token expiration date (tokens expire after 30 days)',
          'Ensure correct device type matches token',
          'Contact support if token appears valid but still fails',
          'Try registering from different network'
        ],
        urgency: 'high'
      }
    ]
  },
  {
    id: 'sensors',
    title: 'Sensor Problems',
    icon: '🔧',
    description: 'Sensor accuracy, calibration, and measurement issues',
    issues: [
      {
        problem: 'Sensor readings seem inaccurate',
        symptoms: ['Values outside expected range', 'Readings don\'t match reference instruments', 'Sudden value jumps'],
        solutions: [
          'Calibrate sensors using appropriate reference standards',
          'Clean sensor probes with recommended cleaning solutions',
          'Check sensor placement - avoid direct heat/light sources',
          'Verify environmental conditions are within sensor range',
          'Replace sensor if calibration doesn\'t resolve issue'
        ],
        urgency: 'medium'
      },
      {
        problem: 'pH sensor drift or instability',
        symptoms: ['pH readings constantly changing', 'Slow response to actual changes', 'Cannot maintain calibration'],
        solutions: [
          'Clean pH probe with pH electrode cleaning solution',
          'Store pH probe in proper storage solution when not in use',
          'Recalibrate using fresh pH 4.0, 7.0, and 10.0 buffer solutions',
          'Check probe age - pH electrodes typically last 12-18 months',
          'Ensure probe junction is not blocked or damaged'
        ],
        urgency: 'high'
      },
      {
        problem: 'Temperature readings inconsistent',
        symptoms: ['Large temperature swings', 'Delayed response to changes', 'Different from room thermometer'],
        solutions: [
          'Check sensor is not in direct sunlight or near heat sources',
          'Ensure adequate air circulation around sensor',
          'Clean sensor housing of dust or debris',
          'Verify calibration against certified thermometer',
          'Check for electrical interference from nearby equipment'
        ],
        urgency: 'medium'
      },
      {
        problem: 'EC/TDS sensor not responding',
        symptoms: ['Readings stuck at zero', 'No change when solution concentration varies', 'Error messages'],
        solutions: [
          'Clean electrode with electrode cleaning solution',
          'Check electrode for damage or corrosion',
          'Calibrate with fresh EC standard solutions (1.41 and 12.88 mS/cm)',
          'Ensure probe is fully submerged in solution',
          'Replace electrode if cleaning and calibration fail'
        ],
        urgency: 'high'
      }
    ]
  },
  {
    id: 'accuracy',
    title: 'Data Accuracy',
    icon: '📊',
    description: 'Data validation, logging issues, and measurement reliability',
    issues: [
      {
        problem: 'Missing data points or gaps in charts',
        symptoms: ['Blank periods in data history', 'Incomplete trend lines', 'Notification of data gaps'],
        solutions: [
          'Check device connection stability during missing periods',
          'Verify power supply wasn\'t interrupted',
          'Review sensor status for error conditions',
          'Check if device was in maintenance mode',
          'Ensure adequate storage space in cloud account'
        ],
        urgency: 'low'
      },
      {
        problem: 'Data doesn\'t match manual measurements',
        symptoms: ['Sensor vs manual readings differ significantly', 'Trends don\'t match observations'],
        solutions: [
          'Calibrate sensors against certified reference instruments',
          'Take manual measurements at same location as sensors',
          'Consider environmental factors affecting readings',
          'Check timing - some parameters change rapidly',
          'Document measurement methods for consistency'
        ],
        urgency: 'medium'
      },
      {
        problem: 'Alerts triggering incorrectly',
        symptoms: ['False alarms', 'Missed critical conditions', 'Alert fatigue from too many notifications'],
        solutions: [
          'Review and adjust alert thresholds based on actual needs',
          'Set different thresholds for different times/seasons',
          'Use alert delays to prevent false alarms from brief spikes',
          'Check sensor calibration and accuracy',
          'Consider multiple sensor confirmation for critical alerts'
        ],
        urgency: 'medium'
      }
    ]
  },
  {
    id: 'firmware',
    title: 'Firmware Updates',
    icon: '⚙️',
    description: 'Device software updates, version issues, and update failures',
    issues: [
      {
        problem: 'Firmware update failed',
        symptoms: ['Update process stopped', 'Device unresponsive after update', 'Error messages during update'],
        solutions: [
          'Ensure stable power supply during update process',
          'Check internet connection is stable and fast',
          'Don\'t interrupt update process once started',
          'Try update during off-peak hours for better connectivity',
          'Contact support if device becomes unresponsive'
        ],
        urgency: 'high'
      },
      {
        problem: 'Device won\'t check for updates',
        symptoms: ['Update check fails', 'Shows old firmware version', 'No update notifications'],
        solutions: [
          'Check device internet connectivity',
          'Verify device is registered and activated properly',
          'Force refresh in device settings',
          'Restart device and try again',
          'Check if manual update option is available'
        ],
        urgency: 'low'
      },
      {
        problem: 'New firmware causing issues',
        symptoms: ['Device behaving differently after update', 'New error messages', 'Reduced functionality'],
        solutions: [
          'Check release notes for known issues and workarounds',
          'Restart device to ensure update completed properly',
          'Reset device settings to defaults if problems persist',
          'Report issues to support team for investigation',
          'Check if rollback option is available'
        ],
        urgency: 'medium'
      }
    ]
  }
]

const quickDiagnostics = [
  {
    step: 'Check Power',
    description: 'Verify device has power and LED indicators are functioning',
    icon: '🔌'
  },
  {
    step: 'Test Connectivity',
    description: 'Confirm WiFi connection and internet access',
    icon: '📡'
  },
  {
    step: 'Review Logs',
    description: 'Check device logs and error messages in the app',
    icon: '📋'
  },
  {
    step: 'Verify Calibration',
    description: 'Ensure sensors are properly calibrated and within range',
    icon: '⚖️'
  }
]

export default function TroubleshootingPage() {
  return (
    <StaticPageLayout
      title="Troubleshooting Guide"
      description="Quick solutions to common issues with SpaceGrow.ai devices and sensors."
      lastUpdated="January 2025"
    >
      {/* Quick Diagnostics */}
      <div className="not-prose mb-12">
        <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-xl p-6">
          <h3 className="font-semibold text-blue-800 dark:text-blue-200 mb-4">
            Quick Diagnostic Steps
          </h3>
          <p className="text-blue-700 dark:text-blue-300 mb-6">
            Before diving into specific issues, try these quick diagnostic steps to identify the problem:
          </p>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            {quickDiagnostics.map((step, index) => (
              <div key={step.step} className="flex items-center space-x-3 p-3 bg-white dark:bg-blue-900/40 rounded-lg">
                <div className="text-2xl">{step.icon}</div>
                <div>
                  <div className="font-medium text-blue-900 dark:text-blue-100 text-sm">
                    {index + 1}. {step.step}
                  </div>
                  <div className="text-xs text-blue-700 dark:text-blue-300">
                    {step.description}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Emergency Contact */}
      <div className="not-prose mb-12">
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-xl p-6">
          <div className="flex items-start space-x-3">
            <span className="text-red-600 dark:text-red-400 text-2xl">🚨</span>
            <div>
              <h3 className="font-semibold text-red-800 dark:text-red-200 mb-2">
                Critical Issues? Get Immediate Help
              </h3>
              <p className="text-red-700 dark:text-red-300 mb-4">
                For urgent issues affecting your growing operation, contact our emergency support line:
              </p>
              <div className="flex flex-col sm:flex-row gap-3">
                <a 
                  href="tel:+1-555-GROW-911"
                  className="inline-flex items-center px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-medium"
                >
                  📞 Emergency: +1 (555) GROW-911
                </a>
                <Link
                  href="/support"
                  className="inline-flex items-center px-4 py-2 border border-red-300 dark:border-red-600 text-red-700 dark:text-red-300 rounded-lg hover:bg-red-50 dark:hover:bg-red-900/40 transition-colors font-medium"
                >
                  💬 Live Chat Support
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Troubleshooting Categories */}
      <div className="space-y-16">
        {troubleshootingCategories.map((category) => (
          <section key={category.id} id={category.id} className="scroll-mt-8">
            <div className="flex items-center space-x-4 mb-8">
              <div className="text-4xl">{category.icon}</div>
              <div>
                <h2 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
                  {category.title}
                </h2>
                <p className="text-lg text-gray-600 dark:text-gray-300">
                  {category.description}
                </p>
              </div>
            </div>

            <div className="not-prose space-y-8">
              {category.issues.map((issue, index) => (
                <div key={index} className="border dark:border-gray-700 rounded-xl p-6">
                  <div className="flex items-start justify-between mb-4">
                    <h3 className="text-xl font-semibold text-gray-900 dark:text-white">
                      {issue.problem}
                    </h3>
                    <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                      issue.urgency === 'high' 
                        ? 'bg-red-100 dark:bg-red-900 text-red-800 dark:text-red-200'
                        : issue.urgency === 'medium'
                        ? 'bg-yellow-100 dark:bg-yellow-900 text-yellow-800 dark:text-yellow-200'
                        : 'bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200'
                    }`}>
                      {issue.urgency} priority
                    </span>
                  </div>

                  <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    {/* Symptoms */}
                    <div>
                      <h4 className="font-medium text-gray-900 dark:text-white mb-3">
                        Common Symptoms
                      </h4>
                      <ul className="space-y-2">
                        {issue.symptoms.map((symptom, symIndex) => (
                          <li key={symIndex} className="flex items-start space-x-2">
                            <span className="text-orange-500 mt-1 text-sm">⚠️</span>
                            <span className="text-sm text-gray-600 dark:text-gray-400">
                              {symptom}
                            </span>
                          </li>
                        ))}
                      </ul>
                    </div>

                    {/* Solutions */}
                    <div>
                      <h4 className="font-medium text-gray-900 dark:text-white mb-3">
                        Solution Steps
                      </h4>
                      <ol className="space-y-2">
                        {issue.solutions.map((solution, solIndex) => (
                          <li key={solIndex} className="flex items-start space-x-3">
                            <span className="flex-shrink-0 w-5 h-5 bg-blue-100 dark:bg-blue-900 text-blue-600 dark:text-blue-400 rounded-full flex items-center justify-center text-xs font-medium mt-0.5">
                              {solIndex + 1}
                            </span>
                            <span className="text-sm text-gray-600 dark:text-gray-400">
                              {solution}
                            </span>
                          </li>
                        ))}
                      </ol>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </section>
        ))}
      </div>

      {/* Maintenance Schedule */}
      <section className="mt-16 mb-12">
        <h2>Preventive Maintenance Schedule</h2>
        <p>Regular maintenance prevents most issues and ensures optimal device performance:</p>

        <div className="not-prose my-8">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div className="border dark:border-gray-700 rounded-xl p-6">
              <h3 className="font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
                <span className="text-green-600 dark:text-green-400 mr-2">📅</span>
                Weekly Tasks
              </h3>
              <ul className="space-y-2 text-sm text-gray-600 dark:text-gray-400">
                <li>• Check device status lights and indicators</li>
                <li>• Review data trends and anomalies</li>
                <li>• Clean sensor housings if needed</li>
                <li>• Test alert notifications</li>
              </ul>
            </div>

            <div className="border dark:border-gray-700 rounded-xl p-6">
              <h3 className="font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
                <span className="text-blue-600 dark:text-blue-400 mr-2">📆</span>
                Monthly Tasks
              </h3>
              <ul className="space-y-2 text-sm text-gray-600 dark:text-gray-400">
                <li>• Calibrate temperature and humidity sensors</li>
                <li>• Check WiFi signal strength</li>
                <li>• Update firmware if available</li>
                <li>• Review and adjust alert thresholds</li>
              </ul>
            </div>

            <div className="border dark:border-gray-700 rounded-xl p-6">
              <h3 className="font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
                <span className="text-purple-600 dark:text-purple-400 mr-2">🗓️</span>
                Quarterly Tasks
              </h3>
              <ul className="space-y-2 text-sm text-gray-600 dark:text-gray-400">
                <li>• Deep clean all sensor probes</li>
                <li>• Calibrate pH and EC sensors</li>
                <li>• Check physical connections</li>
                <li>• Review data export and backup</li>
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* Still Need Help */}
      <div className="not-prose mt-16">
        <div className="bg-gray-50 dark:bg-gray-800 rounded-2xl p-8 text-center">
          <h3 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
            Still experiencing issues?
          </h3>
          <p className="text-gray-600 dark:text-gray-300 mb-8 max-w-2xl mx-auto">
            Our technical support team is ready to help you resolve any remaining issues. 
            We offer multiple ways to get the support you need.
          </p>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <Link
              href="/support#contact"
              className="inline-flex flex-col items-center justify-center p-4 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-white dark:hover:bg-gray-700 transition-colors"
            >
              <span className="text-2xl mb-2">💬</span>
              <span className="font-medium text-gray-900 dark:text-white">Live Chat</span>
              <span className="text-sm text-gray-600 dark:text-gray-400">Available 24/7</span>
            </Link>
            <Link
              href="/support#contact"
              className="inline-flex flex-col items-center justify-center p-4 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-white dark:hover:bg-gray-700 transition-colors"
            >
              <span className="text-2xl mb-2">📧</span>
              <span className="font-medium text-gray-900 dark:text-white">Email Support</span>
              <span className="text-sm text-gray-600 dark:text-gray-400">Response in 4 hours</span>
            </Link>
            <Link
              href="/support#community"
              className="inline-flex flex-col items-center justify-center p-4 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-white dark:hover:bg-gray-700 transition-colors"
            >
              <span className="text-2xl mb-2">👥</span>
              <span className="font-medium text-gray-900 dark:text-white">Community</span>
              <span className="text-sm text-gray-600 dark:text-gray-400">User forums</span>
            </Link>
            <Link
              href="/support#videos"
              className="inline-flex flex-col items-center justify-center p-4 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-white dark:hover:bg-gray-700 transition-colors"
            >
              <span className="text-2xl mb-2">🎥</span>
              <span className="font-medium text-gray-900 dark:text-white">Video Guides</span>
              <span className="text-sm text-gray-600 dark:text-gray-400">Step-by-step tutorials</span>
            </Link>
          </div>
        </div>
      </div>
    </StaticPageLayout>
  )
}