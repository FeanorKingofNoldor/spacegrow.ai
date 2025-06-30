'use client'

import { useState } from 'react'
import Link from 'next/link'
import { 
  MapPinIcon, 
  ClockIcon, 
  CurrencyDollarIcon,
  BuildingOfficeIcon,
  HeartIcon,
  LightBulbIcon,
  RocketLaunchIcon,
  UsersIcon,
  AcademicCapIcon,
  ShieldCheckIcon
} from '@heroicons/react/24/outline'

const jobOpenings = [
  {
    id: 1,
    title: 'Senior IoT Hardware Engineer',
    department: 'Engineering',
    location: 'San Francisco, CA',
    type: 'Full-time',
    salary: '$120k - $160k',
    experience: '5+ years',
    description: 'Design and develop next-generation IoT devices for precision agriculture and growing systems.',
    requirements: [
      'Bachelor\'s degree in Electrical Engineering or related field',
      '5+ years experience in IoT hardware development',
      'Expertise in ESP32, Arduino, and sensor integration',
      'Experience with PCB design and prototyping',
      'Knowledge of wireless communication protocols (WiFi, Bluetooth, LoRa)',
      'Passion for sustainable agriculture and technology'
    ],
    responsibilities: [
      'Design and prototype new IoT device concepts',
      'Optimize sensor accuracy and power consumption',
      'Collaborate with firmware team on hardware-software integration',
      'Conduct testing and validation of device prototypes',
      'Work with manufacturing partners for production scaling'
    ],
    posted: '2024-01-15',
    remote: false,
    urgent: true
  },
  {
    id: 2,
    title: 'Full Stack Developer (React/Node.js)',
    department: 'Engineering',
    location: 'Remote',
    type: 'Full-time',
    salary: '$100k - $140k',
    experience: '3+ years',
    description: 'Build and enhance our web platform that helps thousands of growers monitor and optimize their operations.',
    requirements: [
      'Bachelor\'s degree in Computer Science or equivalent experience',
      '3+ years of React and Node.js development',
      'Experience with TypeScript, Next.js, and modern web frameworks',
      'Knowledge of database design (PostgreSQL preferred)',
      'Experience with real-time data visualization (charts, dashboards)',
      'Understanding of RESTful APIs and WebSocket connections'
    ],
    responsibilities: [
      'Develop new features for our web dashboard',
      'Create responsive, mobile-first user interfaces',
      'Build real-time data visualization components',
      'Optimize application performance and user experience',
      'Collaborate with design team on UI/UX improvements'
    ],
    posted: '2024-01-12',
    remote: true,
    urgent: false
  },
  {
    id: 3,
    title: 'Plant Science Researcher',
    department: 'Research',
    location: 'Davis, CA',
    type: 'Full-time',
    salary: '$80k - $110k',
    experience: '2+ years',
    description: 'Conduct research on optimal growing conditions and develop data-driven recommendations for our users.',
    requirements: [
      'PhD in Plant Sciences, Horticulture, or related field',
      '2+ years of research experience in controlled environment agriculture',
      'Knowledge of plant physiology and environmental factors',
      'Experience with statistical analysis and data interpretation',
      'Strong written and verbal communication skills',
      'Experience with hydroponic or indoor growing systems preferred'
    ],
    responsibilities: [
      'Design and conduct plant growth experiments',
      'Analyze sensor data to identify optimal growing conditions',
      'Develop evidence-based growing recommendations',
      'Collaborate with product team on new features',
      'Publish research findings and represent company at conferences'
    ],
    posted: '2024-01-10',
    remote: false,
    urgent: false
  },
  {
    id: 4,
    title: 'Customer Success Manager',
    department: 'Customer Success',
    location: 'Austin, TX',
    type: 'Full-time',
    salary: '$70k - $95k',
    experience: '2+ years',
    description: 'Help our customers succeed with their growing operations by providing expert guidance and support.',
    requirements: [
      'Bachelor\'s degree or equivalent experience',
      '2+ years in customer success, account management, or similar role',
      'Experience in agriculture, horticulture, or related industry preferred',
      'Excellent communication and problem-solving skills',
      'Technical aptitude for understanding IoT systems',
      'Passion for helping customers achieve their goals'
    ],
    responsibilities: [
      'Onboard new customers and ensure successful deployment',
      'Provide ongoing support and optimization recommendations',
      'Conduct training sessions and webinars',
      'Gather customer feedback for product development',
      'Maintain relationships with key accounts'
    ],
    posted: '2024-01-08',
    remote: true,
    urgent: false
  },
  {
    id: 5,
    title: 'DevOps Engineer',
    department: 'Engineering',
    location: 'Remote',
    type: 'Full-time',
    salary: '$110k - $150k',
    experience: '4+ years',
    description: 'Build and maintain the infrastructure that powers our IoT platform and handles millions of sensor readings.',
    requirements: [
      'Bachelor\'s degree in Computer Science or related field',
      '4+ years of DevOps or infrastructure engineering experience',
      'Expertise with AWS/GCP cloud platforms',
      'Experience with Docker, Kubernetes, and CI/CD pipelines',
      'Knowledge of monitoring and logging systems',
      'Experience with high-volume data processing'
    ],
    responsibilities: [
      'Design and maintain scalable cloud infrastructure',
      'Implement CI/CD pipelines for rapid deployment',
      'Monitor system performance and optimize for scale',
      'Ensure security and compliance best practices',
      'Automate infrastructure provisioning and management'
    ],
    posted: '2024-01-05',
    remote: true,
    urgent: true
  },
  {
    id: 6,
    title: 'Product Marketing Manager',
    department: 'Marketing',
    location: 'San Francisco, CA',
    type: 'Full-time',
    salary: '$90k - $120k',
    experience: '3+ years',
    description: 'Drive product positioning, messaging, and go-to-market strategy for our IoT growing solutions.',
    requirements: [
      'Bachelor\'s degree in Marketing, Business, or related field',
      '3+ years of product marketing experience',
      'Experience in B2B SaaS or hardware products',
      'Strong analytical and communication skills',
      'Understanding of IoT or agriculture markets preferred',
      'Experience with content creation and digital marketing'
    ],
    responsibilities: [
      'Develop product positioning and messaging',
      'Create marketing collateral and sales tools',
      'Conduct market research and competitive analysis',
      'Support product launches and campaigns',
      'Collaborate with sales team on customer engagement'
    ],
    posted: '2024-01-03',
    remote: false,
    urgent: false
  }
]

const benefits = [
  {
    icon: HeartIcon,
    title: 'Health & Wellness',
    description: 'Comprehensive health, dental, and vision insurance with 100% premium coverage for employees.',
    details: ['Medical, dental, vision insurance', 'Mental health support', 'Wellness stipend', 'Gym membership reimbursement']
  },
  {
    icon: AcademicCapIcon,
    title: 'Learning & Development',
    description: 'Continuous learning opportunities with conference attendance, courses, and professional development.',
    details: ['$3,000 annual learning budget', 'Conference and workshop attendance', 'Internal tech talks', 'Mentorship programs']
  },
  {
    icon: ClockIcon,
    title: 'Work-Life Balance',
    description: 'Flexible working hours, unlimited PTO, and remote-first culture that values your personal time.',
    details: ['Unlimited PTO policy', 'Flexible working hours', 'Remote-first culture', '4-day work week during summer']
  },
  {
    icon: RocketLaunchIcon,
    title: 'Equity & Growth',
    description: 'Competitive equity package and clear career progression paths in a fast-growing company.',
    details: ['Equity participation for all employees', 'Clear promotion pathways', 'Stock option program', 'Performance bonuses']
  },
  {
    icon: UsersIcon,
    title: 'Team & Culture',
    description: 'Collaborative environment with brilliant colleagues who are passionate about sustainable technology.',
    details: ['Team building events', 'Quarterly offsites', 'Diverse and inclusive culture', 'Open communication']
  },
  {
    icon: LightBulbIcon,
    title: 'Innovation Time',
    description: '20% time for personal projects and innovation that could benefit our growing community.',
    details: ['20% innovation time', 'Hackathon participation', 'Patent bonus program', 'Side project support']
  }
]

const companyValues = [
  {
    icon: '🌱',
    title: 'Sustainability First',
    description: 'Everything we do is aimed at creating a more sustainable future for agriculture and food production.'
  },
  {
    icon: '🚀',
    title: 'Innovation Drive',
    description: 'We push the boundaries of what\'s possible with IoT technology to solve real-world growing challenges.'
  },
  {
    icon: '🤝',
    title: 'Customer Obsession',
    description: 'Our customers\' success is our success. We build products that truly help growers thrive.'
  },
  {
    icon: '📊',
    title: 'Data-Driven',
    description: 'We make decisions based on data and scientific evidence, not assumptions or guesswork.'
  },
  {
    icon: '⚡',
    title: 'Move Fast',
    description: 'We iterate quickly, learn from failures, and deliver solutions that make an immediate impact.'
  },
  {
    icon: '🌍',
    title: 'Global Impact',
    description: 'Our work contributes to solving global food security and environmental sustainability challenges.'
  }
]

const departments = [
  { name: 'All Departments', value: 'all', count: jobOpenings.length },
  { name: 'Engineering', value: 'Engineering', count: jobOpenings.filter(job => job.department === 'Engineering').length },
  { name: 'Research', value: 'Research', count: jobOpenings.filter(job => job.department === 'Research').length },
  { name: 'Customer Success', value: 'Customer Success', count: jobOpenings.filter(job => job.department === 'Customer Success').length },
  { name: 'Marketing', value: 'Marketing', count: jobOpenings.filter(job => job.department === 'Marketing').length }
]

const locations = [
  { name: 'All Locations', value: 'all' },
  { name: 'Remote', value: 'Remote' },
  { name: 'San Francisco, CA', value: 'San Francisco, CA' },
  { name: 'Austin, TX', value: 'Austin, TX' },
  { name: 'Davis, CA', value: 'Davis, CA' }
]

export default function CareersPage() {
  const [selectedDepartment, setSelectedDepartment] = useState('all')
  const [selectedLocation, setSelectedLocation] = useState('all')
  const [expandedJob, setExpandedJob] = useState<number | null>(null)

  const filteredJobs = jobOpenings.filter(job => {
    const matchesDepartment = selectedDepartment === 'all' || job.department === selectedDepartment
    const matchesLocation = selectedLocation === 'all' || job.location === selectedLocation
    return matchesDepartment && matchesLocation
  })

  return (
    <div className="bg-white dark:bg-gray-900 min-h-screen">
      {/* Hero Section */}
      <div className="relative bg-gradient-to-br from-green-50 to-blue-50 dark:from-gray-800 dark:to-gray-900 py-24 sm:py-32">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl text-center">
            <h1 className="text-4xl font-bold tracking-tight text-gray-900 dark:text-white sm:text-6xl">
              Grow Your Career With Us
            </h1>
            <p className="mt-6 text-lg leading-8 text-gray-600 dark:text-gray-300">
              Join our mission to revolutionize agriculture through innovative IoT technology. 
              We're building the future of sustainable growing, one device at a time.
            </p>
            <div className="mt-10 flex items-center justify-center gap-x-6">
              <a
                href="#open-positions"
                className="rounded-md bg-blue-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600 transition-colors"
              >
                View Open Positions
              </a>
              <a href="#company-culture" className="text-sm font-semibold leading-6 text-gray-900 dark:text-white">
                Learn About Our Culture <span aria-hidden="true">→</span>
              </a>
            </div>
          </div>
        </div>
        
        {/* Floating elements */}
        <div className="absolute top-1/4 left-10 w-20 h-20 bg-green-200 dark:bg-green-800 rounded-full opacity-50 animate-pulse"></div>
        <div className="absolute top-1/3 right-20 w-16 h-16 bg-blue-200 dark:bg-blue-800 rounded-full opacity-50 animate-pulse delay-1000"></div>
        <div className="absolute bottom-1/4 left-1/4 w-12 h-12 bg-purple-200 dark:bg-purple-800 rounded-full opacity-50 animate-pulse delay-2000"></div>
      </div>

      {/* Company Values */}
      <section id="company-culture" className="py-24 sm:py-32">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl text-center">
            <h2 className="text-3xl font-bold tracking-tight text-gray-900 dark:text-white sm:text-4xl">
              Our Values
            </h2>
            <p className="mt-6 text-lg leading-8 text-gray-600 dark:text-gray-300">
              We're united by shared values that guide everything we do, from product development to customer relationships.
            </p>
          </div>
          <div className="mx-auto mt-16 grid max-w-2xl grid-cols-1 gap-8 lg:mx-0 lg:max-w-none lg:grid-cols-3">
            {companyValues.map((value, index) => (
              <div key={index} className="flex flex-col items-start p-6 bg-gray-50 dark:bg-gray-800 rounded-2xl hover:shadow-lg transition-shadow">
                <div className="text-4xl mb-4">{value.icon}</div>
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
                  {value.title}
                </h3>
                <p className="text-gray-600 dark:text-gray-400">
                  {value.description}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Benefits */}
      <section className="bg-gray-50 dark:bg-gray-800 py-24 sm:py-32">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl text-center">
            <h2 className="text-3xl font-bold tracking-tight text-gray-900 dark:text-white sm:text-4xl">
              Why Work With Us
            </h2>
            <p className="mt-6 text-lg leading-8 text-gray-600 dark:text-gray-300">
              We believe in taking care of our team so they can do their best work and live their best lives.
            </p>
          </div>
          <div className="mx-auto mt-16 grid max-w-2xl grid-cols-1 gap-8 lg:mx-0 lg:max-w-none lg:grid-cols-2">
            {benefits.map((benefit, index) => (
              <div key={index} className="bg-white dark:bg-gray-900 rounded-2xl p-8 shadow-sm hover:shadow-lg transition-shadow">
                <div className="flex items-center mb-4">
                  <benefit.icon className="h-8 w-8 text-blue-600 dark:text-blue-400 mr-3" />
                  <h3 className="text-xl font-semibold text-gray-900 dark:text-white">
                    {benefit.title}
                  </h3>
                </div>
                <p className="text-gray-600 dark:text-gray-400 mb-4">
                  {benefit.description}
                </p>
                <ul className="space-y-2">
                  {benefit.details.map((detail, detailIndex) => (
                    <li key={detailIndex} className="flex items-center text-sm text-gray-600 dark:text-gray-400">
                      <div className="w-1.5 h-1.5 bg-green-500 rounded-full mr-3"></div>
                      {detail}
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Open Positions */}
      <section id="open-positions" className="py-24 sm:py-32">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl text-center mb-16">
            <h2 className="text-3xl font-bold tracking-tight text-gray-900 dark:text-white sm:text-4xl">
              Open Positions
            </h2>
            <p className="mt-6 text-lg leading-8 text-gray-600 dark:text-gray-300">
              Join our growing team and help build the future of smart agriculture.
            </p>
          </div>

          {/* Filters */}
          <div className="flex flex-col sm:flex-row gap-4 mb-12">
            <div className="flex-1">
              <label htmlFor="department" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Department
              </label>
              <select
                id="department"
                value={selectedDepartment}
                onChange={(e) => setSelectedDepartment(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                {departments.map(dept => (
                  <option key={dept.value} value={dept.value}>
                    {dept.name} ({dept.count})
                  </option>
                ))}
              </select>
            </div>
            <div className="flex-1">
              <label htmlFor="location" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Location
              </label>
              <select
                id="location"
                value={selectedLocation}
                onChange={(e) => setSelectedLocation(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                {locations.map(location => (
                  <option key={location.value} value={location.value}>
                    {location.name}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Job Listings */}
          <div className="space-y-6">
            {filteredJobs.map((job) => (
              <div key={job.id} className="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-2xl p-6 hover:shadow-lg transition-shadow">
                <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-4 mb-2">
                      <h3 className="text-xl font-semibold text-gray-900 dark:text-white">
                        {job.title}
                      </h3>
                      {job.urgent && (
                        <span className="inline-flex items-center rounded-full bg-red-100 dark:bg-red-900 px-2.5 py-0.5 text-xs font-medium text-red-800 dark:text-red-200">
                          Urgent
                        </span>
                      )}
                    </div>
                    <p className="text-gray-600 dark:text-gray-400 mb-4">
                      {job.description}
                    </p>
                    <div className="flex flex-wrap gap-4 text-sm text-gray-600 dark:text-gray-400">
                      <div className="flex items-center">
                        <BuildingOfficeIcon className="h-4 w-4 mr-1" />
                        {job.department}
                      </div>
                      <div className="flex items-center">
                        <MapPinIcon className="h-4 w-4 mr-1" />
                        {job.location}
                      </div>
                      <div className="flex items-center">
                        <ClockIcon className="h-4 w-4 mr-1" />
                        {job.type}
                      </div>
                      <div className="flex items-center">
                        <CurrencyDollarIcon className="h-4 w-4 mr-1" />
                        {job.salary}
                      </div>
                    </div>
                  </div>
                  <div className="mt-4 lg:mt-0 lg:ml-6 flex flex-col sm:flex-row gap-3">
                    <button
                      onClick={() => setExpandedJob(expandedJob === job.id ? null : job.id)}
                      className="px-4 py-2 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
                    >
                      {expandedJob === job.id ? 'Hide Details' : 'View Details'}
                    </button>
                    <Link
                      href={`/careers/apply?job=${job.id}`}
                      className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-center"
                    >
                      Apply Now
                    </Link>
                  </div>
                </div>

                {expandedJob === job.id && (
                  <div className="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                      <div>
                        <h4 className="font-semibold text-gray-900 dark:text-white mb-3">Requirements</h4>
                        <ul className="space-y-2">
                          {job.requirements.map((req, index) => (
                            <li key={index} className="flex items-start text-sm text-gray-600 dark:text-gray-400">
                              <div className="w-1.5 h-1.5 bg-blue-500 rounded-full mr-3 mt-2"></div>
                              {req}
                            </li>
                          ))}
                        </ul>
                      </div>
                      <div>
                        <h4 className="font-semibold text-gray-900 dark:text-white mb-3">Responsibilities</h4>
                        <ul className="space-y-2">
                          {job.responsibilities.map((resp, index) => (
                            <li key={index} className="flex items-start text-sm text-gray-600 dark:text-gray-400">
                              <div className="w-1.5 h-1.5 bg-green-500 rounded-full mr-3 mt-2"></div>
                              {resp}
                            </li>
                          ))}
                        </ul>
                      </div>
                    </div>
                    <div className="mt-6 flex items-center justify-between">
                      <div className="text-sm text-gray-500 dark:text-gray-400">
                        Posted on {new Date(job.posted).toLocaleDateString('en-US', { 
                          year: 'numeric', 
                          month: 'long', 
                          day: 'numeric' 
                        })}
                      </div>
                      <Link
                        href={`/careers/apply?job=${job.id}`}
                        className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                      >
                        Apply for This Position
                      </Link>
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>

          {filteredJobs.length === 0 && (
            <div className="text-center py-12">
              <div className="text-gray-400 dark:text-gray-500 mb-4">
                <UsersIcon className="mx-auto h-12 w-12" />
              </div>
              <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">No positions found</h3>
              <p className="text-gray-500 dark:text-gray-400 mb-6">
                No positions match your current filters. Try adjusting your search criteria.
              </p>
              <button
                onClick={() => {
                  setSelectedDepartment('all')
                  setSelectedLocation('all')
                }}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              >
                Clear Filters
              </button>
            </div>
          )}
        </div>
      </section>

      {/* Call to Action */}
      <section className="bg-blue-600 dark:bg-blue-700 py-16">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl text-center">
            <h2 className="text-3xl font-bold tracking-tight text-white sm:text-4xl">
              Don't See Your Perfect Role?
            </h2>
            <p className="mt-6 text-lg leading-8 text-blue-100">
              We're always looking for talented individuals who share our passion for sustainable technology. 
              Send us your resume and let's start a conversation.
            </p>
            <div className="mt-10 flex items-center justify-center gap-x-6">
              <Link
                href="/contact"
                className="rounded-md bg-white px-3.5 py-2.5 text-sm font-semibold text-blue-600 shadow-sm hover:bg-blue-50 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white transition-colors"
              >
                Get in Touch
              </Link>
              <Link
                href="/about"
                className="text-sm font-semibold leading-6 text-white"
              >
                Learn More About Us <span aria-hidden="true">→</span>
              </Link>
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}