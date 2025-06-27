'use client'

import { useState } from 'react'
import { CheckCircleIcon, ExclamationTriangleIcon, PaperAirplaneIcon } from '@heroicons/react/24/outline'

interface FormData {
  name: string
  email: string
  company: string
  phone: string
  subject: string
  priority: 'low' | 'medium' | 'high' | 'urgent'
  category: string
  message: string
  deviceType: string
  acceptTerms: boolean
  newsletter: boolean
}

interface FormErrors {
  [key: string]: string
}

const categories = [
  { value: '', label: 'Select a category...' },
  { value: 'technical-support', label: '🔧 Technical Support' },
  { value: 'sales-inquiry', label: '💰 Sales Inquiry' },
  { value: 'partnership', label: '🤝 Partnership Opportunity' },
  { value: 'billing', label: '💳 Billing & Account' },
  { value: 'feature-request', label: '✨ Feature Request' },
  { value: 'bug-report', label: '🐛 Bug Report' },
  { value: 'general', label: '💬 General Question' }
]

const deviceTypes = [
  { value: '', label: 'No device (general inquiry)' },
  { value: 'environmental-monitor', label: 'Environmental Monitor V1' },
  { value: 'liquid-monitor', label: 'Liquid Monitor V1' },
  { value: 'multiple-devices', label: 'Multiple devices' },
  { value: 'planning-purchase', label: 'Planning to purchase' }
]

const priorityLevels = [
  { value: 'low', label: 'Low - General question', color: 'text-green-600', bg: 'bg-green-50 border-green-200' },
  { value: 'medium', label: 'Medium - Technical issue', color: 'text-yellow-600', bg: 'bg-yellow-50 border-yellow-200' },
  { value: 'high', label: 'High - System down', color: 'text-orange-600', bg: 'bg-orange-50 border-orange-200' },
  { value: 'urgent', label: 'Urgent - Production emergency', color: 'text-red-600', bg: 'bg-red-50 border-red-200' }
]

export default function ContactForm() {
  const [formData, setFormData] = useState<FormData>({
    name: '',
    email: '',
    company: '',
    phone: '',
    subject: '',
    priority: 'medium',
    category: '',
    message: '',
    deviceType: '',
    acceptTerms: false,
    newsletter: true
  })

  const [errors, setErrors] = useState<FormErrors>({})
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [submitStatus, setSubmitStatus] = useState<'idle' | 'success' | 'error'>('idle')
  const [submitMessage, setSubmitMessage] = useState('')

  const validateForm = (): boolean => {
    const newErrors: FormErrors = {}

    // Required fields
    if (!formData.name.trim()) newErrors.name = 'Name is required'
    if (!formData.email.trim()) newErrors.email = 'Email is required'
    if (!formData.subject.trim()) newErrors.subject = 'Subject is required'
    if (!formData.category) newErrors.category = 'Please select a category'
    if (!formData.message.trim()) newErrors.message = 'Message is required'
    if (!formData.acceptTerms) newErrors.acceptTerms = 'You must accept the terms and conditions'

    // Email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (formData.email && !emailRegex.test(formData.email)) {
      newErrors.email = 'Please enter a valid email address'
    }

    // Phone validation (if provided)
    if (formData.phone && !/^[\+]?[\d\s\-\(\)]+$/.test(formData.phone)) {
      newErrors.phone = 'Please enter a valid phone number'
    }

    // Message length
    if (formData.message && formData.message.length < 10) {
      newErrors.message = 'Message must be at least 10 characters long'
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!validateForm()) {
      setSubmitStatus('error')
      setSubmitMessage('Please fix the errors above and try again.')
      return
    }

    setIsSubmitting(true)
    setSubmitStatus('idle')

    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 2000))
      
      // Here you would typically send to your backend:
      // const response = await fetch('/api/contact', {
      //   method: 'POST',
      //   headers: { 'Content-Type': 'application/json' },
      //   body: JSON.stringify(formData)
      // })

      console.log('Form submitted:', formData)
      
      setSubmitStatus('success')
      setSubmitMessage('Thank you! Your message has been sent successfully. We\'ll get back to you within 24 hours.')
      
      // Reset form
      setFormData({
        name: '',
        email: '',
        company: '',
        phone: '',
        subject: '',
        priority: 'medium',
        category: '',
        message: '',
        deviceType: '',
        acceptTerms: false,
        newsletter: true
      })
    } catch (error) {
      setSubmitStatus('error')
      setSubmitMessage('Sorry, there was an error sending your message. Please try again or contact us directly.')
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleInputChange = (field: keyof FormData, value: string | boolean) => {
    setFormData(prev => ({ ...prev, [field]: value }))
    
    // Clear error when user starts typing
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: '' }))
    }
  }

  const getFieldError = (field: string) => errors[field]
  const hasError = (field: string) => !!errors[field]

  return (
    <div className="bg-white dark:bg-gray-900 py-24 sm:py-32">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <div className="mx-auto max-w-2xl text-center mb-16">
          <h2 className="text-3xl font-bold tracking-tight text-gray-900 dark:text-white sm:text-4xl">
            Get in Touch
          </h2>
          <p className="mt-2 text-lg leading-8 text-gray-600 dark:text-gray-300">
            Have questions about our IoT devices or need support? We're here to help you grow successfully.
          </p>
        </div>

        <div className="mx-auto max-w-4xl">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-12">
            {/* Contact Info */}
            <div className="lg:col-span-1">
              <div className="bg-gray-50 dark:bg-gray-800 rounded-2xl p-8 h-fit">
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-6">
                  Contact Information
                </h3>
                
                <div className="space-y-6">
                  <div className="flex items-start space-x-3">
                    <div className="flex-shrink-0 w-6 h-6 bg-blue-600 rounded-full flex items-center justify-center mt-1">
                      <svg className="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
                        <path d="M2.003 5.884L10 9.882l7.997-3.998A2 2 0 0016 4H4a2 2 0 00-1.997 1.884z" />
                        <path d="M18 8.118l-8 4-8-4V14a2 2 0 002 2h12a2 2 0 002-2V8.118z" />
                      </svg>
                    </div>
                    <div>
                      <p className="font-medium text-gray-900 dark:text-white">Email</p>
                      <p className="text-gray-600 dark:text-gray-400">support@spacegrow.ai</p>
                    </div>
                  </div>

                  <div className="flex items-start space-x-3">
                    <div className="flex-shrink-0 w-6 h-6 bg-blue-600 rounded-full flex items-center justify-center mt-1">
                      <svg className="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
                        <path d="M2 3a1 1 0 011-1h2.153a1 1 0 01.986.836l.74 4.435a1 1 0 01-.54 1.06l-1.548.773a11.037 11.037 0 006.105 6.105l.774-1.548a1 1 0 011.059-.54l4.435.74a1 1 0 01.836.986V17a1 1 0 01-1 1h-2C7.82 18 2 12.18 2 5V3z" />
                      </svg>
                    </div>
                    <div>
                      <p className="font-medium text-gray-900 dark:text-white">Phone</p>
                      <p className="text-gray-600 dark:text-gray-400">+1 (555) SPACEGROW</p>
                      <p className="text-sm text-gray-500 dark:text-gray-400">Mon-Fri 9AM-6PM PST</p>
                    </div>
                  </div>

                  <div className="flex items-start space-x-3">
                    <div className="flex-shrink-0 w-6 h-6 bg-red-600 rounded-full flex items-center justify-center mt-1">
                      <svg className="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
                      </svg>
                    </div>
                    <div>
                      <p className="font-medium text-gray-900 dark:text-white">Emergency</p>
                      <p className="text-gray-600 dark:text-gray-400">+1 (555) GROW-911</p>
                      <p className="text-sm text-gray-500 dark:text-gray-400">24/7 for critical issues</p>
                    </div>
                  </div>
                </div>

                <div className="mt-8 pt-8 border-t border-gray-200 dark:border-gray-700">
                  <h4 className="font-medium text-gray-900 dark:text-white mb-4">Response Times</h4>
                  <div className="space-y-2 text-sm">
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">General Inquiries</span>
                      <span className="text-gray-900 dark:text-white">&lt; 24 hours</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">Technical Support</span>
                      <span className="text-gray-900 dark:text-white">&lt; 4 hours</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">Emergency</span>
                      <span className="text-gray-900 dark:text-white">&lt; 15 minutes</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Contact Form */}
            <div className="lg:col-span-2">
              <form onSubmit={handleSubmit} className="space-y-6">
                {/* Status Message */}
                {submitStatus !== 'idle' && (
                  <div className={`rounded-lg p-4 ${
                    submitStatus === 'success' 
                      ? 'bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800' 
                      : 'bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800'
                  }`}>
                    <div className="flex">
                      {submitStatus === 'success' ? (
                        <CheckCircleIcon className="h-5 w-5 text-green-400 mt-0.5" />
                      ) : (
                        <ExclamationTriangleIcon className="h-5 w-5 text-red-400 mt-0.5" />
                      )}
                      <div className="ml-3">
                        <p className={`text-sm ${
                          submitStatus === 'success' 
                            ? 'text-green-800 dark:text-green-200' 
                            : 'text-red-800 dark:text-red-200'
                        }`}>
                          {submitMessage}
                        </p>
                      </div>
                    </div>
                  </div>
                )}

                {/* Basic Info */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label htmlFor="name" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                      Full Name *
                    </label>
                    <input
                      type="text"
                      id="name"
                      value={formData.name}
                      onChange={(e) => handleInputChange('name', e.target.value)}
                      className={`w-full px-3 py-2 border rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-colors ${
                        hasError('name') ? 'border-red-500' : 'border-gray-300 dark:border-gray-600'
                      }`}
                      placeholder="Enter your full name"
                    />
                    {getFieldError('name') && (
                      <p className="mt-1 text-sm text-red-600 dark:text-red-400">{getFieldError('name')}</p>
                    )}
                  </div>

                  <div>
                    <label htmlFor="email" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                      Email Address *
                    </label>
                    <input
                      type="email"
                      id="email"
                      value={formData.email}
                      onChange={(e) => handleInputChange('email', e.target.value)}
                      className={`w-full px-3 py-2 border rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-colors ${
                        hasError('email') ? 'border-red-500' : 'border-gray-300 dark:border-gray-600'
                      }`}
                      placeholder="your.email@example.com"
                    />
                    {getFieldError('email') && (
                      <p className="mt-1 text-sm text-red-600 dark:text-red-400">{getFieldError('email')}</p>
                    )}
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label htmlFor="company" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                      Company (Optional)
                    </label>
                    <input
                      type="text"
                      id="company"
                      value={formData.company}
                      onChange={(e) => handleInputChange('company', e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-colors"
                      placeholder="Your company name"
                    />
                  </div>

                  <div>
                    <label htmlFor="phone" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                      Phone Number (Optional)
                    </label>
                    <input
                      type="tel"
                      id="phone"
                      value={formData.phone}
                      onChange={(e) => handleInputChange('phone', e.target.value)}
                      className={`w-full px-3 py-2 border rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-colors ${
                        hasError('phone') ? 'border-red-500' : 'border-gray-300 dark:border-gray-600'
                      }`}
                      placeholder="+1 (555) 123-4567"
                    />
                    {getFieldError('phone') && (
                      <p className="mt-1 text-sm text-red-600 dark:text-red-400">{getFieldError('phone')}</p>
                    )}
                  </div>
                </div>

                {/* Subject */}
                <div>
                  <label htmlFor="subject" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Subject *
                  </label>
                  <input
                    type="text"
                    id="subject"
                    value={formData.subject}
                    onChange={(e) => handleInputChange('subject', e.target.value)}
                    className={`w-full px-3 py-2 border rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-colors ${
                      hasError('subject') ? 'border-red-500' : 'border-gray-300 dark:border-gray-600'
                    }`}
                    placeholder="Brief description of your inquiry"
                  />
                  {getFieldError('subject') && (
                    <p className="mt-1 text-sm text-red-600 dark:text-red-400">{getFieldError('subject')}</p>
                  )}
                </div>

                {/* Category and Priority */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label htmlFor="category" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                      Category *
                    </label>
                    <select
                      id="category"
                      value={formData.category}
                      onChange={(e) => handleInputChange('category', e.target.value)}
                      className={`w-full px-3 py-2 border rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500 transition-colors ${
                        hasError('category') ? 'border-red-500' : 'border-gray-300 dark:border-gray-600'
                      }`}
                    >
                      {categories.map(cat => (
                        <option key={cat.value} value={cat.value}>{cat.label}</option>
                      ))}
                    </select>
                    {getFieldError('category') && (
                      <p className="mt-1 text-sm text-red-600 dark:text-red-400">{getFieldError('category')}</p>
                    )}
                  </div>

                  <div>
                    <label htmlFor="priority" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                      Priority Level
                    </label>
                    <select
                      id="priority"
                      value={formData.priority}
                      onChange={(e) => handleInputChange('priority', e.target.value as FormData['priority'])}
                      className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500 transition-colors"
                    >
                      {priorityLevels.map(level => (
                        <option key={level.value} value={level.value}>{level.label}</option>
                      ))}
                    </select>
                  </div>
                </div>

                {/* Device Type */}
                <div>
                  <label htmlFor="deviceType" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Related Device (Optional)
                  </label>
                  <select
                    id="deviceType"
                    value={formData.deviceType}
                    onChange={(e) => handleInputChange('deviceType', e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500 transition-colors"
                  >
                    {deviceTypes.map(device => (
                      <option key={device.value} value={device.value}>{device.label}</option>
                    ))}
                  </select>
                </div>

                {/* Message */}
                <div>
                  <label htmlFor="message" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Message *
                  </label>
                  <textarea
                    id="message"
                    rows={6}
                    value={formData.message}
                    onChange={(e) => handleInputChange('message', e.target.value)}
                    className={`w-full px-3 py-2 border rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-colors resize-none ${
                      hasError('message') ? 'border-red-500' : 'border-gray-300 dark:border-gray-600'
                    }`}
                    placeholder="Please provide as much detail as possible about your inquiry, including any error messages, steps you've tried, or specific questions you have..."
                  />
                  <div className="flex justify-between items-center mt-1">
                    {getFieldError('message') ? (
                      <p className="text-sm text-red-600 dark:text-red-400">{getFieldError('message')}</p>
                    ) : (
                      <div></div>
                    )}
                    <p className="text-xs text-gray-500 dark:text-gray-400">
                      {formData.message.length}/1000 characters
                    </p>
                  </div>
                </div>

                {/* Checkboxes */}
                <div className="space-y-4">
                  <div className="flex items-start">
                    <input
                      id="acceptTerms"
                      type="checkbox"
                      checked={formData.acceptTerms}
                      onChange={(e) => handleInputChange('acceptTerms', e.target.checked)}
                      className="mt-1 h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                    />
                    <label htmlFor="acceptTerms" className="ml-3 text-sm text-gray-700 dark:text-gray-300">
                      I agree to the{' '}
                      <a href="/terms" className="text-blue-600 dark:text-blue-400 hover:underline">
                        Terms of Service
                      </a>{' '}
                      and{' '}
                      <a href="/privacy" className="text-blue-600 dark:text-blue-400 hover:underline">
                        Privacy Policy
                      </a>{' '}
                      *
                    </label>
                  </div>
                  {getFieldError('acceptTerms') && (
                    <p className="text-sm text-red-600 dark:text-red-400 ml-7">{getFieldError('acceptTerms')}</p>
                  )}

                  <div className="flex items-start">
                    <input
                      id="newsletter"
                      type="checkbox"
                      checked={formData.newsletter}
                      onChange={(e) => handleInputChange('newsletter', e.target.checked)}
                      className="mt-1 h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                    />
                    <label htmlFor="newsletter" className="ml-3 text-sm text-gray-700 dark:text-gray-300">
                      I'd like to receive updates about new features, growing tips, and product announcements
                    </label>
                  </div>
                </div>

                {/* Submit Button */}
                <div className="pt-6">
                  <button
                    type="submit"
                    disabled={isSubmitting}
                    className={`w-full flex items-center justify-center px-8 py-4 border border-transparent text-base font-medium rounded-lg text-white transition-all duration-200 ${
                      isSubmitting
                        ? 'bg-gray-400 cursor-not-allowed'
                        : 'bg-blue-600 hover:bg-blue-700 focus:ring-4 focus:ring-blue-500/50 hover:scale-105 active:scale-95'
                    }`}
                  >
                    {isSubmitting ? (
                      <>
                        <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                        Sending...
                      </>
                    ) : (
                      <>
                        <PaperAirplaneIcon className="h-5 w-5 mr-2" />
                        Send Message
                      </>
                    )}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}