import React from 'react';
import { 
  Shield, 
  Clock, 
  CheckCircle, 
  XCircle,
  AlertTriangle,
  ArrowLeft,
  FileText,
  Mail,
  Phone,
  Package,
  CreditCard,
  Calendar,
  Truck
} from 'lucide-react';

const RefundInfoPage = () => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-900 to-purple-900">
      <div className="container mx-auto px-4 py-8">
        {/* Header */}
        <div className="mb-8">
          <button className="flex items-center text-gray-300 hover:text-white mb-4 transition-colors">
            <ArrowLeft className="w-5 h-5 mr-2" />
            Back to Shop
          </button>
          <h1 className="text-4xl font-bold text-white mb-4">Refund & Return Policy</h1>
          <p className="text-xl text-gray-300 max-w-3xl">
            We want you to be completely satisfied with your XSpaceGrow purchase. 
            Here's everything you need to know about our refund and return process.
          </p>
        </div>

        {/* Quick Overview Cards */}
        <div className="grid md:grid-cols-3 gap-6 mb-12">
          <div className="bg-gray-800/80 backdrop-blur border border-gray-700 rounded-xl p-6 text-center">
            <Calendar className="w-12 h-12 text-blue-400 mx-auto mb-4" />
            <h3 className="text-xl font-semibold text-white mb-2">30-Day Returns</h3>
            <p className="text-gray-300">Full refund within 30 days of purchase</p>
          </div>
          <div className="bg-gray-800/80 backdrop-blur border border-gray-700 rounded-xl p-6 text-center">
            <Truck className="w-12 h-12 text-green-400 mx-auto mb-4" />
            <h3 className="text-xl font-semibold text-white mb-2">Free Returns</h3>
            <p className="text-gray-300">We cover return shipping costs</p>
          </div>
          <div className="bg-gray-800/80 backdrop-blur border border-gray-700 rounded-xl p-6 text-center">
            <Clock className="w-12 h-12 text-purple-400 mx-auto mb-4" />
            <h3 className="text-xl font-semibold text-white mb-2">Quick Processing</h3>
            <p className="text-gray-300">Refunds processed within 3-5 business days</p>
          </div>
        </div>

        <div className="max-w-4xl mx-auto space-y-8">
          {/* Return Policy Section */}
          <section className="bg-gray-800/80 backdrop-blur border border-gray-700 rounded-xl p-8">
            <h2 className="text-2xl font-bold text-white mb-6 flex items-center">
              <Shield className="w-8 h-8 mr-3 text-blue-400" />
              Our Return Promise
            </h2>
            
            <div className="prose prose-invert max-w-none">
              <p className="text-gray-300 text-lg mb-6">
                At XSpaceGrow, we stand behind our products. If you're not completely satisfied 
                with your purchase, we offer hassle-free returns within 30 days of delivery.
              </p>
              
              <div className="bg-blue-900/20 border border-blue-500/30 rounded-lg p-6">
                <h3 className="text-blue-300 font-semibold mb-3 flex items-center">
                  <CheckCircle className="w-5 h-5 mr-2" />
                  What's Covered
                </h3>
                <ul className="space-y-2 text-gray-300">
                  <li className="flex items-start">
                    <CheckCircle className="w-5 h-5 text-green-400 mr-2 mt-0.5 flex-shrink-0" />
                    <span>All XSpaceGrow monitoring devices and kits</span>
                  </li>
                  <li className="flex items-start">
                    <CheckCircle className="w-5 h-5 text-green-400 mr-2 mt-0.5 flex-shrink-0" />
                    <span>Accessories and calibration solutions</span>
                  </li>
                  <li className="flex items-start">
                    <CheckCircle className="w-5 h-5 text-green-400 mr-2 mt-0.5 flex-shrink-0" />
                    <span>Defective or damaged items</span>
                  </li>
                  <li className="flex items-start">
                    <CheckCircle className="w-5 h-5 text-green-400 mr-2 mt-0.5 flex-shrink-0" />
                    <span>Items that don't meet your expectations</span>
                  </li>
                </ul>
              </div>
            </div>
          </section>

          {/* Return Process */}
          <section className="bg-gray-800/80 backdrop-blur border border-gray-700 rounded-xl p-8">
            <h2 className="text-2xl font-bold text-white mb-6 flex items-center">
              <Package className="w-8 h-8 mr-3 text-green-400" />
              How to Return an Item
            </h2>
            
            <div className="grid md:grid-cols-4 gap-6">
              <div className="text-center">
                <div className="w-16 h-16 bg-blue-600 rounded-full flex items-center justify-center mx-auto mb-4">
                  <span className="text-white font-bold text-xl">1</span>
                </div>
                <h3 className="font-semibold text-white mb-2">Contact Us</h3>
                <p className="text-gray-300 text-sm">
                  Email us at support@xspacegrow.com with your order number
                </p>
              </div>
              
              <div className="text-center">
                <div className="w-16 h-16 bg-blue-600 rounded-full flex items-center justify-center mx-auto mb-4">
                  <span className="text-white font-bold text-xl">2</span>
                </div>
                <h3 className="font-semibold text-white mb-2">Get Label</h3>
                <p className="text-gray-300 text-sm">
                  We'll send you a prepaid return shipping label
                </p>
              </div>
              
              <div className="text-center">
                <div className="w-16 h-16 bg-blue-600 rounded-full flex items-center justify-center mx-auto mb-4">
                  <span className="text-white font-bold text-xl">3</span>
                </div>
                <h3 className="font-semibold text-white mb-2">Pack & Ship</h3>
                <p className="text-gray-300 text-sm">
                  Pack the item securely and drop it off
                </p>
              </div>
              
              <div className="text-center">
                <div className="w-16 h-16 bg-blue-600 rounded-full flex items-center justify-center mx-auto mb-4">
                  <span className="text-white font-bold text-xl">4</span>
                </div>
                <h3 className="font-semibold text-white mb-2">Get Refund</h3>
                <p className="text-gray-300 text-sm">
                  Receive your refund within 3-5 business days
                </p>
              </div>
            </div>
          </section>

          {/* Conditions */}
          <section className="bg-gray-800/80 backdrop-blur border border-gray-700 rounded-xl p-8">
            <h2 className="text-2xl font-bold text-white mb-6 flex items-center">
              <FileText className="w-8 h-8 mr-3 text-yellow-400" />
              Return Conditions
            </h2>
            
            <div className="grid md:grid-cols-2 gap-8">
              <div>
                <h3 className="text-lg font-semibold text-green-400 mb-4 flex items-center">
                  <CheckCircle className="w-6 h-6 mr-2" />
                  Eligible for Return
                </h3>
                <ul className="space-y-3 text-gray-300">
                  <li className="flex items-start">
                    <div className="w-2 h-2 bg-green-400 rounded-full mr-3 mt-2"></div>
                    <span>Items in original packaging</span>
                  </li>
                  <li className="flex items-start">
                    <div className="w-2 h-2 bg-green-400 rounded-full mr-3 mt-2"></div>
                    <span>Unused devices with all accessories</span>
                  </li>
                  <li className="flex items-start">
                    <div className="w-2 h-2 bg-green-400 rounded-full mr-3 mt-2"></div>
                    <span>Items returned within 30 days</span>
                  </li>
                  <li className="flex items-start">
                    <div className="w-2 h-2 bg-green-400 rounded-full mr-3 mt-2"></div>
                    <span>Defective items (any time)</span>
                  </li>
                </ul>
              </div>
              
              <div>
                <h3 className="text-lg font-semibold text-red-400 mb-4 flex items-center">
                  <XCircle className="w-6 h-6 mr-2" />
                  Not Eligible for Return
                </h3>
                <ul className="space-y-3 text-gray-300">
                  <li className="flex items-start">
                    <div className="w-2 h-2 bg-red-400 rounded-full mr-3 mt-2"></div>
                    <span>Digital downloads (after 48 hours)</span>
                  </li>
                  <li className="flex items-start">
                    <div className="w-2 h-2 bg-red-400 rounded-full mr-3 mt-2"></div>
                    <span>Custom or personalized items</span>
                  </li>
                  <li className="flex items-start">
                    <div className="w-2 h-2 bg-red-400 rounded-full mr-3 mt-2"></div>
                    <span>Items damaged by misuse</span>
                  </li>
                  <li className="flex items-start">
                    <div className="w-2 h-2 bg-red-400 rounded-full mr-3 mt-2"></div>
                    <span>Used calibration solutions</span>
                  </li>
                </ul>
              </div>
            </div>
          </section>

          {/* Refund Information */}
          <section className="bg-gray-800/80 backdrop-blur border border-gray-700 rounded-xl p-8">
            <h2 className="text-2xl font-bold text-white mb-6 flex items-center">
              <CreditCard className="w-8 h-8 mr-3 text-purple-400" />
              Refund Information
            </h2>
            
            <div className="space-y-6">
              <div className="bg-purple-900/20 border border-purple-500/30 rounded-lg p-6">
                <h3 className="text-purple-300 font-semibold mb-3">Processing Time</h3>
                <p className="text-gray-300 mb-4">
                  Once we receive your returned item, we'll process your refund within 3-5 business days. 
                  You'll receive an email confirmation when the refund has been processed.
                </p>
                <div className="text-sm text-gray-400">
                  <strong>Note:</strong> Depending on your bank or credit card company, it may take an 
                  additional 2-10 business days for the refund to appear in your account.
                </div>
              </div>
              
              <div className="grid md:grid-cols-2 gap-6">
                <div className="bg-gray-700/50 rounded-lg p-4">
                  <h4 className="font-semibold text-white mb-2">Credit Card Refunds</h4>
                  <p className="text-gray-300 text-sm">
                    Refunded to the original payment method used for the purchase.
                  </p>
                </div>
                <div className="bg-gray-700/50 rounded-lg p-4">
                  <h4 className="font-semibold text-white mb-2">PayPal Refunds</h4>
                  <p className="text-gray-300 text-sm">
                    Refunded directly to your PayPal account within 24-48 hours.
                  </p>
                </div>
              </div>
            </div>
          </section>

          {/* Exchange Policy */}
          <section className="bg-gray-800/80 backdrop-blur border border-gray-700 rounded-xl p-8">
            <h2 className="text-2xl font-bold text-white mb-6 flex items-center">
              <Package className="w-8 h-8 mr-3 text-blue-400" />
              Exchanges & Warranty
            </h2>
            
            <div className="space-y-6">
              <div>
                <h3 className="text-lg font-semibold text-white mb-3">Product Exchanges</h3>
                <p className="text-gray-300 mb-4">
                  If you need to exchange an item for a different model or size, please contact us. 
                  We'll help you process a return and place a new order for the correct item.
                </p>
              </div>
              
              <div>
                <h3 className="text-lg font-semibold text-white mb-3">Warranty Coverage</h3>
                <p className="text-gray-300 mb-4">
                  All XSpaceGrow devices come with a 1-year manufacturer warranty covering defects 
                  and malfunctions under normal use.
                </p>
                <div className="bg-blue-900/20 border border-blue-500/30 rounded-lg p-4">
                  <p className="text-blue-300 text-sm">
                    <strong>Warranty claims:</strong> Contact our support team with your order number 
                    and description of the issue. We'll arrange for repair or replacement at no cost to you.
                  </p>
                </div>
              </div>
            </div>
          </section>

          {/* Contact Information */}
          <section className="bg-gray-800/80 backdrop-blur border border-gray-700 rounded-xl p-8">
            <h2 className="text-2xl font-bold text-white mb-6 flex items-center">
              <Mail className="w-8 h-8 mr-3 text-green-400" />
              Need Help?
            </h2>
            
            <div className="grid md:grid-cols-2 gap-8">
              <div>
                <h3 className="font-semibold text-white mb-4">Contact Support</h3>
                <div className="space-y-3 text-gray-300">
                  <div className="flex items-center">
                    <Mail className="w-5 h-5 text-blue-400 mr-3" />
                    <span>support@xspacegrow.com</span>
                  </div>
                  <div className="flex items-center">
                    <Phone className="w-5 h-5 text-blue-400 mr-3" />
                    <span>1-800-XSPACE (1-800-977-2233)</span>
                  </div>
                  <div className="flex items-start">
                    <Clock className="w-5 h-5 text-blue-400 mr-3 mt-0.5" />
                    <div>
                      <div>Monday - Friday: 9 AM - 6 PM EST</div>
                      <div className="text-sm text-gray-400">Weekend support available for urgent issues</div>
                    </div>
                  </div>
                </div>
              </div>
              
              <div>
                <h3 className="font-semibold text-white mb-4">Return Address</h3>
                <div className="bg-gray-700/50 rounded-lg p-4 text-gray-300">
                  <div className="font-medium text-white mb-2">XSpaceGrow Returns</div>
                  <div>1234 Innovation Drive</div>
                  <div>Suite 567</div>
                  <div>TechCity, TC 12345</div>
                  <div className="mt-2 text-sm text-yellow-300">
                    ⚠️ Please contact us for a return authorization before shipping
                  </div>
                </div>
              </div>
            </div>
          </section>

          {/* Important Notice */}
          <section className="bg-yellow-900/20 border border-yellow-500/50 rounded-xl p-6">
            <div className="flex items-start">
              <AlertTriangle className="w-8 h-8 text-yellow-400 mr-4 mt-1 flex-shrink-0" />
              <div>
                <h3 className="text-yellow-300 font-semibold text-lg mb-2">Important Notice</h3>
                <p className="text-yellow-200 mb-4">
                  This return policy applies to purchases made directly from XSpaceGrow. 
                  For items purchased from authorized retailers, please check with the retailer 
                  for their specific return policy.
                </p>
                <p className="text-yellow-200 text-sm">
                  We reserve the right to refuse returns that don't meet our return conditions 
                  or show signs of misuse or damage not covered under warranty.
                </p>
              </div>
            </div>
          </section>
        </div>
      </div>
    </div>
  );
};

export default RefundInfoPage;