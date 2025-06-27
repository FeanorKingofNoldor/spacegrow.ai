// (public)/shop/liquid-monitor/page.tsx
'use client';

import { useState } from 'react';
import { useShop } from '@/contexts/ShopContext';
import { ProductGrid } from '@/components/shop/product/ProductGrid';
import { CartSidebar } from '@/components/shop/cart/CartSidebar';
import { CartIcon } from '@/components/shop/cart/CartIcon';
import { Product } from '@/types/shop';
import { Droplets, Zap, Beaker } from 'lucide-react';
import Link from 'next/link';

// Mock liquid monitor products
const liquidProducts: Product[] = [
  {
    id: '2',
    name: 'Liquid Monitor V1',
    description: 'Professional liquid monitoring system with pH and EC sensors plus temperature monitoring for perfect nutrient solutions. Automated dosing control and real-time adjustments.',
    price: 199.99,
    category: 'Liquid Monitor V1',
    features: ['pH Sensor (±0.01)', 'EC Sensor (±2%)', 'Temperature Compensation', 'Automatic Dosing Control', 'Wi-Fi Connectivity', 'Mobile App'],
    in_stock: true,
    active: true,
    stock_quantity: 25,
    stock_status: 'in_stock',
    stock_description: 'Available for immediate shipping',
    low_stock_threshold: 5,
    featured: true,
  },
  {
    id: 'liquid-2',
    name: 'Liquid Monitor V1 Pro',
    description: 'Advanced liquid monitoring with 5-pump dosing system and dissolved oxygen sensing. Perfect for commercial hydroponic operations requiring precise nutrient management.',
    price: 349.99,
    category: 'Liquid Monitor V1',
    features: ['All V1 Features', 'Dissolved Oxygen Sensor', '5-Pump Dosing System', 'Advanced Algorithms', 'Professional Dashboard', 'API Integration'],
    in_stock: true,
    active: true,
    stock_quantity: 12,
    stock_status: 'in_stock',
    stock_description: 'Ships in 2-3 days',
    low_stock_threshold: 3,
    featured: false,
  },
  {
    id: 'liquid-3',
    name: 'Liquid Monitor V1 Basic',
    description: 'Essential liquid monitoring with pH and EC sensors. Perfect for small hydroponic systems and hobbyist growers starting with nutrient monitoring.',
    price: 149.99,
    category: 'Liquid Monitor V1',
    features: ['pH Sensor (±0.02)', 'EC Sensor (±3%)', 'Basic Temperature', 'Manual Dosing Alerts', 'Wi-Fi Connectivity', 'Simple Interface'],
    in_stock: true,
    active: true,
    stock_quantity: 30,
    stock_status: 'in_stock',
    stock_description: 'Ready to ship',
    low_stock_threshold: 5,
    featured: false,
  },
  {
    id: 'liquid-4',
    name: 'Liquid Monitor V1 - Commercial',
    description: 'Industrial-grade liquid monitoring for large-scale operations. Multiple sensor inputs, redundant systems, and enterprise-level reporting and control.',
    price: 599.99,
    category: 'Liquid Monitor V1',
    features: ['Multiple pH/EC Inputs', 'Redundant Sensors', 'Industrial Pumps', 'Enterprise Reporting', 'Remote Diagnostics', '24/7 Support'],
    in_stock: true,
    active: true,
    stock_quantity: 5,
    stock_status: 'in_stock',
    stock_description: 'Limited stock available',
    low_stock_threshold: 2,
    featured: false,
  },
  {
    id: 'liquid-5',
    name: 'Liquid Monitor V1 - Research',
    description: 'Precision monitoring system designed for research applications. Laboratory-grade sensors with data logging and export capabilities for scientific studies.',
    price: 799.99,
    category: 'Liquid Monitor V1',
    features: ['Lab-Grade Sensors', 'Data Export', 'Statistical Analysis', 'Research Protocols', 'Calibration Certificates', 'Academic Pricing Available'],
    in_stock: false,
    active: true,
    stock_quantity: 0,
    stock_status: 'out_of_stock',
    stock_description: 'Out of stock - contact for availability',
    low_stock_threshold: 1,
    featured: false,
  },
];

const sensorSpecs = [
  {
    icon: <Droplets className="w-6 h-6" />,
    name: 'pH Level',
    range: '0 to 14 pH',
    accuracy: '±0.01 pH',
    color: 'text-blue-400'
  },
  {
    icon: <Zap className="w-6 h-6" />,
    name: 'EC (Conductivity)',
    range: '0 to 20 mS/cm',
    accuracy: '±2%',
    color: 'text-yellow-400'
  },
  {
    icon: <Beaker className="w-6 h-6" />,
    name: 'Temperature',
    range: '0°C to 100°C',
    accuracy: '±0.1°C',
    color: 'text-red-400'
  }
];

export default function LiquidMonitorPage() {
  const { 
    cart, 
    addToCart, 
    removeFromCart, 
    updateQuantity,
    isCartOpen, 
    openCart, 
    closeCart 
  } = useShop();
  
  const [loading, setLoading] = useState(false);

  const handleAddToCart = async (product: Product) => {
    addToCart(product, 1);
  };

  const handleCheckout = () => {
    console.log('Proceeding to checkout with:', cart);
    alert(`Proceeding to checkout with ${cart.count} items totaling $${cart.total}`);
    closeCart();
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-900 to-purple-900">
      <div className="container mx-auto px-4 py-8">
        {/* Header */}
        <div className="flex justify-between items-start mb-8">
          <div className="flex-1">
            {/* Breadcrumb */}
            <div className="flex items-center gap-2 text-gray-400 mb-4">
              <Link href="/shop" className="hover:text-white transition-colors">
                Shop
              </Link>
              <span>/</span>
              <span className="text-white">Liquid Monitors</span>
            </div>

            {/* Title Section */}
            <div className="flex items-center gap-4 mb-4">
              <div className="w-16 h-16 bg-gradient-to-br from-cyan-500 to-blue-600 rounded-xl flex items-center justify-center">
                <Droplets className="w-8 h-8 text-white" />
              </div>
              <div>
                <h1 className="text-4xl font-bold text-white mb-2">Liquid Monitors</h1>
                <p className="text-xl text-gray-300">Precision nutrient monitoring and automated dosing systems</p>
              </div>
            </div>

            {/* Stats */}
            <div className="flex gap-6 text-sm text-gray-400">
              <span>{liquidProducts.length} models available</span>
              <span>•</span>
              <span>Starting at $149.99</span>
              <span>•</span>
              <span>Automated dosing included</span>
            </div>
          </div>
          
          {/* Cart Icon */}
          <CartIcon 
            itemCount={cart.count} 
            onClick={openCart}
            className="text-white hover:text-blue-400"
          />
        </div>

        {/* Sensor Specifications */}
        <div className="mb-8 bg-gray-800/50 backdrop-blur border border-gray-700 rounded-xl p-6">
          <h2 className="text-xl font-semibold text-white mb-6">Sensor Specifications</h2>
          <div className="grid md:grid-cols-3 gap-6">
            {sensorSpecs.map((sensor, index) => (
              <div key={index} className="bg-gray-700/30 rounded-lg p-4">
                <div className="flex items-center gap-3 mb-3">
                  <div className={`${sensor.color}`}>
                    {sensor.icon}
                  </div>
                  <h3 className="text-white font-semibold">{sensor.name}</h3>
                </div>
                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-gray-400">Range:</span>
                    <span className="text-gray-300">{sensor.range}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-400">Accuracy:</span>
                    <span className="text-gray-300">{sensor.accuracy}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Key Features */}
        <div className="mb-8 bg-gradient-to-r from-cyan-900/20 to-blue-900/20 backdrop-blur border border-cyan-500/30 rounded-xl p-6">
          <h2 className="text-xl font-semibold text-white mb-4">Why Liquid Monitoring Matters</h2>
          <div className="grid md:grid-cols-2 gap-6">
            <div>
              <h3 className="text-white font-medium mb-3">Nutrient Optimization</h3>
              <ul className="space-y-2 text-gray-300 text-sm">
                <li className="flex items-start gap-2">
                  <span className="text-cyan-400 mt-1">•</span>
                  <span>Maintain optimal pH levels for maximum nutrient uptake</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-cyan-400 mt-1">•</span>
                  <span>Monitor EC levels to prevent nutrient burn or deficiency</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-cyan-400 mt-1">•</span>
                  <span>Temperature compensation for accurate readings</span>
                </li>
              </ul>
            </div>
            <div>
              <h3 className="text-white font-medium mb-3">Automated Control</h3>
              <ul className="space-y-2 text-gray-300 text-sm">
                <li className="flex items-start gap-2">
                  <span className="text-blue-400 mt-1">•</span>
                  <span>Automatic pH adjustment with precision dosing pumps</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-blue-400 mt-1">•</span>
                  <span>Nutrient injection based on EC readings</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-blue-400 mt-1">•</span>
                  <span>Real-time alerts and remote monitoring</span>
                </li>
              </ul>
            </div>
          </div>
        </div>

        {/* Dosing System Highlight */}
        <div className="mb-8">
          <div className="flex items-center gap-2 mb-4">
            <span className="bg-cyan-600 text-white text-sm px-2 py-1 rounded">AUTOMATED DOSING</span>
            <h2 className="text-xl font-semibold text-white">Smart Nutrient Management</h2>
          </div>
          <div className="bg-gradient-to-r from-cyan-900/30 to-blue-900/30 border border-cyan-500/50 rounded-xl p-6">
            <div className="grid md:grid-cols-2 gap-6">
              <div>
                <h3 className="text-xl font-bold text-white mb-3">Precision Dosing System</h3>
                <p className="text-gray-300 mb-4">
                  Our liquid monitors don't just measure - they automatically maintain perfect nutrient 
                  levels. Smart algorithms learn your system and make micro-adjustments 24/7.
                </p>
                <div className="space-y-3">
                  <div className="flex items-center gap-3">
                    <div className="w-2 h-2 bg-cyan-400 rounded-full"></div>
                    <span className="text-gray-300 text-sm">pH Up/Down automatic dosing</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className="w-2 h-2 bg-blue-400 rounded-full"></div>
                    <span className="text-gray-300 text-sm">Nutrient A & B injection</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className="w-2 h-2 bg-purple-400 rounded-full"></div>
                    <span className="text-gray-300 text-sm">CalMag supplementation</span>
                  </div>
                </div>
              </div>
              <div className="bg-gray-800/50 rounded-lg p-4">
                <h4 className="text-white font-medium mb-3">Supported Nutrients</h4>
                <div className="grid grid-cols-2 gap-2 text-sm">
                  <div className="flex items-center gap-2">
                    <span className="w-3 h-3 bg-red-500 rounded"></span>
                    <span className="text-gray-300">pH Up</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="w-3 h-3 bg-blue-500 rounded"></span>
                    <span className="text-gray-300">pH Down</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="w-3 h-3 bg-green-500 rounded"></span>
                    <span className="text-gray-300">Nutrient A</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="w-3 h-3 bg-yellow-500 rounded"></span>
                    <span className="text-gray-300">Nutrient B</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="w-3 h-3 bg-purple-500 rounded"></span>
                    <span className="text-gray-300">CalMag</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="w-3 h-3 bg-orange-500 rounded"></span>
                    <span className="text-gray-300">Supplements</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Featured Product */}
        <div className="mb-8">
          <div className="flex items-center gap-2 mb-4">
            <span className="bg-cyan-600 text-white text-sm px-2 py-1 rounded">BESTSELLER</span>
            <h2 className="text-xl font-semibold text-white">Liquid Monitor V1</h2>
          </div>
          <div className="bg-gradient-to-r from-cyan-900/30 to-blue-900/30 border border-cyan-500/50 rounded-xl p-6">
            <div className="flex flex-col lg:flex-row gap-6 items-start">
              <div className="flex-1">
                <h3 className="text-2xl font-bold text-white mb-3">Professional Nutrient Monitoring</h3>
                <p className="text-gray-300 mb-4">
                  The perfect balance of features and affordability. Monitor pH, EC, and temperature while 
                  automatically maintaining optimal nutrient levels with precision dosing pumps.
                </p>
                <div className="grid md:grid-cols-2 gap-4 mb-4">
                  <div className="flex items-center gap-2">
                    <Droplets className="w-4 h-4 text-blue-400" />
                    <span className="text-gray-300 text-sm">±0.01 pH Accuracy</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Zap className="w-4 h-4 text-yellow-400" />
                    <span className="text-gray-300 text-sm">±2% EC Accuracy</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Beaker className="w-4 h-4 text-red-400" />
                    <span className="text-gray-300 text-sm">Temperature Compensation</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="text-cyan-400 text-sm">⚙️</span>
                    <span className="text-gray-300 text-sm">Automatic Dosing Control</span>
                  </div>
                </div>
                <div className="flex items-center gap-4">
                  <span className="text-3xl font-bold text-cyan-400">$199.99</span>
                  <span className="bg-green-600 text-white text-sm px-2 py-1 rounded">Free Calibration Kit</span>
                </div>
              </div>
              <button
                onClick={() => handleAddToCart(liquidProducts[0])}
                className="bg-gradient-to-r from-cyan-600 to-blue-600 hover:from-cyan-700 hover:to-blue-700 text-white font-semibold py-3 px-8 rounded-lg transition-all duration-300 transform hover:scale-105"
              >
                Add to Cart
              </button>
            </div>
          </div>
        </div>
        
        {/* All Liquid Monitors */}
        <div className="mb-4">
          <h2 className="text-2xl font-semibold text-white mb-6">All Liquid Monitors</h2>
        </div>
        <ProductGrid 
          products={liquidProducts}
          loading={loading}
          onAddToCart={handleAddToCart}
        />
      </div>
    </div>
  );
}