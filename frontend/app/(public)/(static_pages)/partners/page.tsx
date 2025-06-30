'use client'

import { useState } from 'react'
import Link from 'next/link'
import { 
  BuildingOfficeIcon,
  CogIcon,
  AcademicCapIcon,
  GlobeAltIcon,
  ChartBarIcon,
  BeakerIcon,
  ShoppingBagIcon,
  WrenchScrewdriverIcon,
  ArrowRightIcon,
  CheckCircleIcon,
  StarIcon
} from '@heroicons/react/24/outline'

const partnershipTypes = [
  {
    id: 'technology',
    icon: CogIcon,
    title: 'Technology Partners',
    description: 'Integrate your solutions with our IoT platform to create powerful growing ecosystems.',
    benefits: [
      'API access and technical documentation',
      'Joint solution development opportunities',
      'Co-marketing and sales support',
      'Technical integration assistance',
      'Access to beta features and roadmap'
    ],
    requirements: [
      'Established technology company',
      'Complementary product or service',
      'Technical integration capabilities',
      'Commitment to joint customer success'
    ],
    examples: [
      'Lighting system manufacturers',
      'HVAC control systems',
      'Nutrient dosing equipment',
      'Environmental control software',
      'Data analytics platforms'
    ]
  },
  {
    id: 'channel',
    icon: ShoppingBagIcon,
    title: 'Channel Partners',
    description: 'Expand your product portfolio with our award-winning IoT monitoring solutions.',
    benefits: [
      'Competitive wholesale pricing',
      'Sales training and certification',
      'Marketing materials and support',
      'Lead sharing and referrals',
      'Dedicated partner support'
    ],
    requirements: [
      'Established sales channels',
      'Experience in agriculture or IoT',
      'Customer support capabilities',
      'Marketing and sales commitment'
    ],
    examples: [
      'Agricultural equipment dealers',
      'Hydroponic supply stores',
      'Technology distributors',
      'Growing consultants',
      'Garden center chains'
    ]
  },
  {
    id: 'research',
    icon: AcademicCapIcon,
    title: 'Research Partners',
    description: 'Collaborate on cutting-edge research to advance the science of optimal growing.',
    benefits: [
      'Access to real-world growing data',
      'Research funding opportunities',
      'Publication and conference opportunities',
      'Product development collaboration',
      'Academic licensing programs'
    ],
    requirements: [
      'Accredited research institution',
      'Relevant research focus',
      'Publication track record',
      'Commitment to open science'
    ],
    examples: [
      'Universities and colleges',
      'Agricultural research centers',
      'Government laboratories',
      'Non-profit research organizations',
      'International research consortiums'
    ]
  },
  {
    id: 'integration',
    icon: WrenchScrewdriverIcon,
    title: 'System Integrators',
    description: 'Deliver complete growing solutions by integrating our monitoring technology.',
    benefits: [
      'Technical training and certification',
      'Project support and consultation',
      'Bulk pricing and terms',
      'Customer referrals',
      'Marketing co-op opportunities'
    ],
    requirements: [
      'Systems integration experience',
      'Technical installation capabilities',
      'Customer project management',
      'Local market presence'
    ],
    examples: [
      'Agricultural consultants',
      'Greenhouse contractors',
      'Automation specialists',
      'MEP engineering firms',
      'Smart building integrators'
    ]
  }
]

const currentPartners = [
  {
    name: 'AgriTech Solutions',
    logo: 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=120&h=60&fit=crop&q=80',
    type: 'Technology Partner',
    description: 'Leading provider of automated irrigation systems integrated with our IoT monitoring.',
    website: '#',
    featured: true
  },
  {
    name: 'GreenThumb Distribution',
    logo: 'https://images.unsplash.com/photo-1560472355-536de3962603?w=120&h=60&fit=crop&q=80',
    type: 'Channel Partner',
    description: 'National distributor serving over 500 hydroponic stores across North America.',
    website: '#',
    featured: true
  },
  {
    name: 'University of California Davis',
    logo: 'https://images.unsplash.com/photo-1562774053-701939374585?w=120&h=60&fit=crop&q=80',
    type: 'Research Partner',
    description: 'Collaborative research on precision agriculture and sustainable growing practices.',
    website: '#',
    featured: true
  },
  {
    name: 'Spectrum LED Systems',
    logo: 'https://images.unsplash.com/photo-1560472354-b13be1c2b00a?w=120&h=60&fit=crop&q=80',
    type: 'Technology Partner',
    description: 'Full-spectrum LED grow lights with integrated environmental monitoring.',
    website: '#',
    featured: false
  },
  {
    name: 'Hydro Experts Inc.',
    logo: 'https://images.unsplash.com/photo-1560472355-a9a6b32b8834?w=120&h=60&fit=crop&q=80',
    type: 'System Integrator',
    description: 'Commercial hydroponic system design and installation specialists.',
    website: '#',
    featured: false
  },
  {
    name: 'Climate Control Pro',
    logo: 'https://images.unsplash.com/photo-1560472354-a5b8b0f1c9b2?w=120&h=60&fit=crop&q=80',
    type: 'Technology Partner',
    description: 'HVAC systems optimized for controlled environment agriculture.',
    website: '#',
    featured: false
  },
  {
    name: 'Cornell AgTech',
    logo: 'https://images.unsplash.com/photo-1562774053-a64a9e2f3e38?w=120&h=60&fit=crop&q=80',
    type: 'Research Partner',
    description: 'Leading research in plant sciences and agricultural innovation.',
    website: '#',
    featured: false
  },
  {
    name: 'Growing Solutions Network',
    logo: 'https://images.unsplash.com/photo-1560472355-b39d2e4f6b65?w=120&h=60&fit=crop&q=80',
    type: 'Channel Partner',
    description: 'Regional distributor specializing in commercial growing operations.',
    website: '#',
    featured: false
  }
]

const partnerPrograms = [
  {
    name: 'Certified Partner',
    level: 'Entry Level',
    color: 'bg-gray-100 text-gray-800 border-gray-300',
    requirements: ['Basic product training', 'Initial order commitment', 'Customer references'],
    benefits: ['Standard pricing', 'Marketing materials', 'Email support'],
    commitment: '1 year minimum'
  },
  {
    name: 'Preferred Partner',
    level: 'Advanced',
    color: 'bg-blue-100 text-blue-800 border-blue-300',
    requirements: ['Advanced certification', 'Sales targets', 'Customer success metrics'],
    benefits: ['Volume pricing', 'Lead sharing', 'Priority support', 'Co-marketing'],
    commitment: '2 year minimum'
  },
  {
    name: 'Elite Partner',
    level: 'Expert',
    color: 'bg-gold-100 text-gold-800 border-gold-300',
    requirements: ['Expert certification', 'Strategic alignment', 'Joint business plan'],
    benefits: ['Best pricing', 'Exclusive territories', 'Product roadmap input', 'Joint development'],
    commitment: '3 year minimum'
  }
]

const successStories = [
  {
    partner: 'AgriTech Solutions',
    title: 'Integrated Automation Success',
    metric: '300% increase in customer satisfaction',
    description: 'By integrating our IoT monitoring with their irrigation systems, AgriTech delivered complete automation solutions that increased customer yields by an average of 25%.',
    image: 'https://images.unsplash.com/photo-1574943320219-553eb213f72d?w=400&h=250&fit=crop&q=80',
    results: [
      '25% average yield increase for customers',
      '300% increase in customer satisfaction',
      '150% growth in partnership revenue',
      '50+ successful installations'
    ]
  },
  {
    partner: 'University of California Davis',
    title: 'Breakthrough Research Collaboration',
    metric: '5 peer-reviewed publications',
    description: 'Our partnership led to groundbreaking research on VPD optimization, resulting in new industry best practices and significant media attention.',
    image: 'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=400&h=250&fit=crop&q=80',
    results: [
      '5 peer-reviewed publications',
      '12 conference presentations',
      '2 industry awards',
      'New VPD optimization algorithms'
    ]
  }
]

const partnerResources = [
  {
    title: 'Partner Portal',
    description: 'Access training materials, marketing assets, and sales tools.',
    icon: GlobeAltIcon,
    link: '/partners/portal'
  },
  {
    title: 'Technical Documentation',
    description: 'Complete API docs, integration guides, and SDK downloads.',
    icon: CogIcon,
    link: '/docs'
  },
  {
    title: 'Certification Program',
    description: 'Get certified on our products and earn partnership benefits.',
    icon: AcademicCapIcon,
    link: '/partners/certification'
  },
  {
    title: 'Marketing Center',
    description: 'Download logos, product images, and marketing materials.',
    icon: ChartBarIcon,
    link: '/partners/marketing'
  }
]

export default function PartnersPage() {
  const [selectedPartnershipType, setSelectedPartnershipType] = useState('technology')
  const [showAllPartners, setShowAllPartners] = useState(false)

  const selectedType = partnershipTypes.find(type => type.id === selectedPartnershipType)
  const displayedPartners = showAllPartners ? currentPartners : currentPartners.filter(p => p.featured)

  return (
    <div className="bg-white dark:bg-gray-900 min-h-screen">
      {/* Hero Section */}
      <div className="relative bg-gradient-to-br from-blue-50 to-green-50 dark:from-gray-800 dark:to-gray-900 py-24 sm:py-32">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl text-center">
            <h1 className="text-4xl font-bold tracking-tight text-gray-900 dark:text-white sm:text-6xl">
              Partner With Us
            </h1>
            <p className="mt-6 text-lg leading-8 text-gray-600 dark:text-gray-300">
              Join our ecosystem of technology partners, distributors, and innovators working together 
              to revolutionize agriculture through smart IoT solutions.
            </p>
            <div className="mt-10 flex items-center justify-center gap-x-6">
              <Link
                href="#partnership-types"
                className="rounded-md bg-blue-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600 transition-colors"
              >
                Explore Partnerships
              </Link>
              <a href="#current-partners" className="text-sm font-semibold leading-6 text-gray-900 dark:text-white">
                View Our Partners <span aria-hidden="true">→</span>
              </a>
            </div>
          </div>
        </div>

        {/* Floating partnership icons */}
        <div className="absolute top-1/4 left-10 w-16 h-16 bg-blue-200 dark:bg-blue-800 rounded-full opacity-50 flex items-center justify-center animate-pulse">
        {/* Removed HandshakeIcon as it does not exist in @heroicons/react/24/outline */}
          <CogIcon className="w-7 h-7 text-green-600 dark:text-green-400" />
        </div>
        <div className="absolute bottom-1/4 left-1/4 w-12 h-12 bg-purple-200 dark:bg-purple-800 rounded-full opacity-50 flex items-center justify-center animate-pulse delay-2000">
          <BuildingOfficeIcon className="w-6 h-6 text-purple-600 dark:text-purple-400" />
        </div>
      </div>

      {/* Partnership Types */}
      <section id="partnership-types" className="py-24 sm:py-32">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl text-center mb-16">
            <h2 className="text-3xl font-bold tracking-tight text-gray-900 dark:text-white sm:text-4xl">
              Partnership Opportunities
            </h2>
            <p className="mt-6 text-lg leading-8 text-gray-600 dark:text-gray-300">
              Choose the partnership type that aligns with your business goals and expertise.
            </p>
          </div>

          {/* Partnership Type Selector */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-12">
            {partnershipTypes.map((type) => (
              <button
                key={type.id}
                onClick={() => setSelectedPartnershipType(type.id)}
                className={`p-6 rounded-xl border-2 transition-all text-left ${
                  selectedPartnershipType === type.id
                    ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                    : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
                }`}
              >
                <type.icon className={`h-8 w-8 mb-3 ${
                  selectedPartnershipType === type.id 
                    ? 'text-blue-600 dark:text-blue-400' 
                    : 'text-gray-600 dark:text-gray-400'
                }`} />
                <h3 className="font-semibold text-gray-900 dark:text-white mb-2">
                  {type.title}
                </h3>
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  {type.description}
                </p>
              </button>
            ))}
          </div>

          {/* Selected Partnership Details */}
          {selectedType && (
            <div className="bg-white dark:bg-gray-800 rounded-2xl p-8 shadow-lg border border-gray-200 dark:border-gray-700">
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                <div>
                  <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                    Benefits
                  </h3>
                  <ul className="space-y-3">
                    {selectedType.benefits.map((benefit, index) => (
                      <li key={index} className="flex items-start">
                        <CheckCircleIcon className="h-5 w-5 text-green-500 mr-3 mt-0.5 flex-shrink-0" />
                        <span className="text-gray-600 dark:text-gray-400 text-sm">{benefit}</span>
                      </li>
                    ))}
                  </ul>
                </div>

                <div>
                  <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                    Requirements
                  </h3>
                  <ul className="space-y-3">
                    {selectedType.requirements.map((requirement, index) => (
                      <li key={index} className="flex items-start">
                        <div className="w-2 h-2 bg-blue-500 rounded-full mr-3 mt-2 flex-shrink-0"></div>
                        <span className="text-gray-600 dark:text-gray-400 text-sm">{requirement}</span>
                      </li>
                    ))}
                  </ul>
                </div>

                <div>
                  <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                    Examples
                  </h3>
                  <ul className="space-y-3">
                    {selectedType.examples.map((example, index) => (
                      <li key={index} className="flex items-start">
                        <ArrowRightIcon className="h-4 w-4 text-gray-400 mr-3 mt-1 flex-shrink-0" />
                        <span className="text-gray-600 dark:text-gray-400 text-sm">{example}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              </div>

              <div className="mt-8 pt-8 border-t border-gray-200 dark:border-gray-700 text-center">
                <Link
                  href="/contact"
                  className="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 transition-colors"
                >
                  Apply for {selectedType.title}
                  <ArrowRightIcon className="ml-2 h-5 w-5" />
                </Link>
              </div>
            </div>
          )}
        </div>
      </section>

      {/* Current Partners */}
      <section id="current-partners" className="bg-gray-50 dark:bg-gray-800 py-24 sm:py-32">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl text-center mb-16">
            <h2 className="text-3xl font-bold tracking-tight text-gray-900 dark:text-white sm:text-4xl">
              Our Partners
            </h2>
            <p className="mt-6 text-lg leading-8 text-gray-600 dark:text-gray-300">
              We're proud to work with industry leaders and innovative companies across the growing ecosystem.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            {displayedPartners.map((partner, index) => (
              <div key={index} className="bg-white dark:bg-gray-900 rounded-xl p-6 shadow-sm hover:shadow-lg transition-shadow">
                <div className="aspect-[2/1] bg-gray-100 dark:bg-gray-800 rounded-lg mb-4 overflow-hidden">
                  <img
                    src={partner.logo}
                    alt={partner.name}
                    className="w-full h-full object-cover"
                  />
                </div>
                <div className="flex items-center justify-between mb-2">
                  <h3 className="font-semibold text-gray-900 dark:text-white">
                    {partner.name}
                  </h3>
                  {partner.featured && (
                    <StarIcon className="h-5 w-5 text-yellow-500" />
                  )}
                </div>
                <div className="mb-3">
                  <span className="inline-flex items-center rounded-full bg-blue-100 dark:bg-blue-900 px-2.5 py-0.5 text-xs font-medium text-blue-800 dark:text-blue-200">
                    {partner.type}
                  </span>
                </div>
                <p className="text-gray-600 dark:text-gray-400 text-sm mb-4">
                  {partner.description}
                </p>
                <a
                  href={partner.website}
                  className="text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 text-sm font-medium"
                >
                  Learn More →
                </a>
              </div>
            ))}
          </div>

          <div className="text-center">
            <button
              onClick={() => setShowAllPartners(!showAllPartners)}
              className="inline-flex items-center px-6 py-3 border border-gray-300 dark:border-gray-600 text-base font-medium rounded-md text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
            >
              {showAllPartners ? 'Show Featured Partners' : 'View All Partners'}
            </button>
          </div>
        </div>
      </section>

      {/* Partner Programs */}
      <section className="py-24 sm:py-32">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl text-center mb-16">
            <h2 className="text-3xl font-bold tracking-tight text-gray-900 dark:text-white sm:text-4xl">
              Partner Programs
            </h2>
            <p className="mt-6 text-lg leading-8 text-gray-600 dark:text-gray-300">
              Choose the program level that matches your commitment and unlock corresponding benefits.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {partnerPrograms.map((program, index) => (
              <div key={index} className={`rounded-2xl p-8 border-2 ${program.color.includes('gold') ? 'border-yellow-300 bg-yellow-50 dark:bg-yellow-900/20' : program.color.includes('blue') ? 'border-blue-300 bg-blue-50 dark:bg-blue-900/20' : 'border-gray-300 bg-gray-50 dark:bg-gray-800'} relative`}>
                {program.level === 'Advanced' && (
                  <div className="absolute -top-3 left-1/2 transform -translate-x-1/2">
                    <span className="bg-blue-600 text-white text-xs font-medium px-3 py-1 rounded-full">
                      Most Popular
                    </span>
                  </div>
                )}
                
                <div className="text-center mb-6">
                  <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
                    {program.name}
                  </h3>
                  <p className="text-sm text-gray-600 dark:text-gray-400">
                    {program.level}
                  </p>
                </div>

                <div className="mb-6">
                  <h4 className="font-medium text-gray-900 dark:text-white mb-3">Requirements</h4>
                  <ul className="space-y-2">
                    {program.requirements.map((req, reqIndex) => (
                      <li key={reqIndex} className="flex items-start text-sm text-gray-600 dark:text-gray-400">
                        <div className="w-1.5 h-1.5 bg-gray-400 rounded-full mr-3 mt-2 flex-shrink-0"></div>
                        {req}
                      </li>
                    ))}
                  </ul>
                </div>

                <div className="mb-6">
                  <h4 className="font-medium text-gray-900 dark:text-white mb-3">Benefits</h4>
                  <ul className="space-y-2">
                    {program.benefits.map((benefit, benefitIndex) => (
                      <li key={benefitIndex} className="flex items-start text-sm text-gray-600 dark:text-gray-400">
                        <CheckCircleIcon className="h-4 w-4 text-green-500 mr-2 mt-0.5 flex-shrink-0" />
                        {benefit}
                      </li>
                    ))}
                  </ul>
                </div>

                <div className="border-t border-gray-200 dark:border-gray-700 pt-6">
                  <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
                    <strong>Commitment:</strong> {program.commitment}
                  </p>
                  <Link
                    href="/contact"
                    className={`w-full inline-flex items-center justify-center px-4 py-2 border border-transparent text-sm font-medium rounded-md transition-colors ${
                      program.level === 'Advanced'
                        ? 'text-white bg-blue-600 hover:bg-blue-700'
                        : 'text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 border-gray-300 dark:border-gray-600'
                    }`}
                  >
                    Apply Now
                  </Link>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Success Stories */}
      <section className="bg-gray-50 dark:bg-gray-800 py-24 sm:py-32">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl text-center mb-16">
            <h2 className="text-3xl font-bold tracking-tight text-gray-900 dark:text-white sm:text-4xl">
              Partnership Success Stories
            </h2>
            <p className="mt-6 text-lg leading-8 text-gray-600 dark:text-gray-300">
              Real results from our collaborative partnerships across the industry.
            </p>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
            {successStories.map((story, index) => (
              <div key={index} className="bg-white dark:bg-gray-900 rounded-2xl overflow-hidden shadow-lg">
                <div className="aspect-[16/10] bg-gray-100 dark:bg-gray-800">
                  <img
                    src={story.image}
                    alt={story.title}
                    className="w-full h-full object-cover"
                  />
                </div>
                <div className="p-8">
                  <div className="flex items-center justify-between mb-4">
                    <h3 className="text-xl font-semibold text-gray-900 dark:text-white">
                      {story.title}
                    </h3>
                    <span className="text-2xl font-bold text-blue-600 dark:text-blue-400">
                      {story.metric.split(' ')[0]}
                    </span>
                  </div>
                  <p className="text-gray-600 dark:text-gray-400 mb-6">
                    {story.description}
                  </p>
                  <div className="grid grid-cols-2 gap-4">
                    {story.results.map((result, resultIndex) => (
                      <div key={resultIndex} className="flex items-start">
                        <CheckCircleIcon className="h-5 w-5 text-green-500 mr-2 mt-0.5 flex-shrink-0" />
                        <span className="text-sm text-gray-600 dark:text-gray-400">{result}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Partner Resources */}
      <section className="py-24 sm:py-32">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl text-center mb-16">
            <h2 className="text-3xl font-bold tracking-tight text-gray-900 dark:text-white sm:text-4xl">
              Partner Resources
            </h2>
            <p className="mt-6 text-lg leading-8 text-gray-600 dark:text-gray-300">
              Everything you need to succeed as a SpaceGrow.ai partner.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {partnerResources.map((resource, index) => (
              <Link
                key={index}
                href={resource.link}
                className="block p-6 bg-white dark:bg-gray-800 rounded-xl shadow-sm hover:shadow-lg transition-shadow border border-gray-200 dark:border-gray-700 group"
              >
                <resource.icon className="h-8 w-8 text-blue-600 dark:text-blue-400 mb-4 group-hover:scale-110 transition-transform" />
                <h3 className="font-semibold text-gray-900 dark:text-white mb-2">
                  {resource.title}
                </h3>
                <p className="text-gray-600 dark:text-gray-400 text-sm">
                  {resource.description}
                </p>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="bg-blue-600 dark:bg-blue-700 py-16">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl text-center">
            <h2 className="text-3xl font-bold tracking-tight text-white sm:text-4xl">
              Ready to Partner With Us?
            </h2>
            <p className="mt-6 text-lg leading-8 text-blue-100">
              Let's discuss how we can work together to drive innovation in agriculture 
              and create value for growers worldwide.
            </p>
            <div className="mt-10 flex items-center justify-center gap-x-6">
              <Link
                href="/contact"
                className="rounded-md bg-white px-3.5 py-2.5 text-sm font-semibold text-blue-600 shadow-sm hover:bg-blue-50 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white transition-colors"
              >
                Start Partnership Discussion
              </Link>
              <Link
                href="/docs"
                className="text-sm font-semibold leading-6 text-white"
              >
                View Documentation <span aria-hidden="true">→</span>
              </Link>
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}