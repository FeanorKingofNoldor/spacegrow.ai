// (public)/shop/environmental-monitor/page.tsx
'use client';

import { useState } from 'react';
import { useShop } from '@/contexts/ShopContext';
import { ProductGrid } from '@/components/shop/product/ProductGrid';
import { CartSidebar } from '@/components/shop/cart/CartSidebar';
import { CartIcon } from '@/components/shop/cart/CartIcon';
import { Product } from '@/types/shop';
import { Thermometer, Wind, Gauge } from 'lucide-react';
import Link from 'next/link';

// Mock environmental monitor products
const environmentalProducts: Product[] = [
  {
    id: '1',
    name: 'Environmental Monitor V1',
    description: 'Complete environmental monitoring solution with temperature, humidity, and pressure sensors for optimal growing conditions. Real-time data logging and wireless connectivity.',
    price: 299.99,
    category: 'Environmental Monitor V1',
    features: ['Temperature Sensor (±0.1°C)', 'Humidity Sensor (±2% RH)', 'Pressure Sensor (±0.1 hPa)', 'Wi-Fi Connectivity', 'Real-time Alerts', 'Mobile App'],
    in_stock: true,
    active: true,
  },
  {
    id: 'env-2',
    name: 'Environmental Monitor V1 Pro',
    description: 'Advanced environmental monitoring with additional CO2 sensing and extended range. Perfect for professional growing operations requiring comprehensive environmental control.',
    price: 399.99,
    category: 'Environmental Monitor V1',
    features: ['All V1 Features', 'CO2 Sensor (±30 ppm)', 'Extended Wi-Fi Range', 'Professional Dashboard', 'Advanced Analytics', 'API Access'],
    in_stock: true,
    active: true,
  },
  {
    id: 'env-3',
    name: 'Environmental Monitor V1 Basic',
    description: 'Essential environmental monitoring with temperature and humidity sensors. Perfect for hobbyists and small-scale growing operations.',
    price: 199.99,
    category: 'Environmental Monitor V1',
    features: ['Temperature Sensor (±0.2°C)', 'Humidity Sensor (±3% RH)', 'Basic Wi-Fi', 'Simple App Interface', 'Email Alerts', 'Easy Setup'],
    in_stock: true,
    active: true,
  },
  {
    id: 'env-4',
    name: 'Environmental Monitor V1 - Outdoor',
    description: 'Weather-resistant environmental monitor designed for outdoor growing. IP65 rated housing with solar panel option for remote installations.',
    price: 449.99,
    category: 'Environmental Monitor V1',
    features: ['Weatherproof IP65', 'Solar Panel Compatible', 'Extended Battery Life', 'UV Resistance', 'Temperature Range -40°C to 80°C', 'Satellite Connectivity Option'],
    in_stock: false,
    active: true,
  },
];

const sensorSpecs = [
  {
    icon: <Thermometer className="w-6 h-6" />,
    name: 'Temperature',
    range: '0°C to 100°C',
    accuracy: '±0.1°C',
    color: 'text-red-400'
  },
  {
    icon: <Wind className="w-6 h-6" />,
    name: 'Humidity',
    range: '0% to 100% RH',
    accuracy: '±2% RH',
    color: 'text-blue-400'
  },
  {
    icon: <Gauge className="w-6 h-6" />,
    name: 'Pressure',
    range: '300 to 1100 hPa',
    accuracy: '±0.1 hPa',
    color: 'text-green-400'
  }
];

export default function EnvironmentalMonitorPage() {
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
              <span className="text-white">Environmental Monitors</span>
            </div>

            {/* Title Section */}
            <div className="flex items-center gap-4 mb-4">
              <div className="w-16 h-16 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl flex items-center justify-center">
                <Thermometer className="w-8 h-8 text-white" />
              </div>
              <div>
                <h1 className="text-4xl font-bold text-white mb-2">Environmental Monitors</h1>
                <p className="text-xl text-gray-300">Precise climate monitoring for optimal growing conditions</p>
              </div>
            </div>

            {/* Stats */}
            <div className="flex gap-6 text-sm text-gray-400">
              <span>{environmentalProducts.length} models available</span>
              <span>•</span>
              <span>Starting at $199.99</span>
              <span>•</span>
              <span>Professional accuracy sensors</span>
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
        <div className="mb-8 bg-gradient-to-r from-blue-900/20 to-purple-900/20 backdrop-blur border border-blue-500/30 rounded-xl p-6">
          <h2 className="text-xl font-semibold text-white mb-4">Why Choose Environmental Monitoring?</h2>
          <div className="grid md:grid-cols-2 gap-6">
            <div>
              <h3 className="text-white font-medium mb-3">Critical for Plant Health</h3>
              <ul className="space-y-2 text-gray-300 text-sm">
                <li className="flex items-start gap-2">
                  <span className="text-green-400 mt-1">•</span>
                  <span>Optimal temperature ranges prevent stress and disease</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-green-400 mt-1">•</span>
                  <span>Proper humidity levels reduce mold and pest risks</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-green-400 mt-1">•</span>
                  <span>Pressure monitoring helps predict weather changes</span>
                </li>
              </ul>
            </div>
            <div>
              <h3 className="text-white font-medium mb-3">Smart Features</h3>
              <ul className="space-y-2 text-gray-300 text-sm">
                <li className="flex items-start gap-2">
                  <span className="text-blue-400 mt-1">•</span>
                  <span>Real-time alerts via mobile app and email</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-blue-400 mt-1">•</span>
                  <span>Historical data logging and trend analysis</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-blue-400 mt-1">•</span>
                  <span>Wi-Fi connectivity for remote monitoring</span>
                </li>
              </ul>
            </div>
          </div>
        </div>

        {/* Featured Product */}
        <div className="mb-8">
          <div className="flex items-center gap-2 mb-4">
            <span className="bg-blue-600 text-white text-sm px-2 py-1 rounded">MOST POPULAR</span>
            <h2 className="text-xl font-semibold text-white">Environmental Monitor V1</h2>
          </div>
          <div className="bg-gradient-to-r from-blue-900/30 to-purple-900/30 border border-blue-500/50 rounded-xl p-6">
            <div className="flex flex-col lg:flex-row gap-6 items-start">
              <div className="flex-1">
                <h3 className="text-2xl font-bold text-white mb-3">Professional Environmental Monitoring</h3>
                <p className="text-gray-300 mb-4">
                  Our flagship environmental monitor provides laboratory-grade accuracy for temperature, 
                  humidity, and pressure. Perfect balance of features and affordability for serious growers.
                </p>
                <div className="grid md:grid-cols-2 gap-4 mb-4">
                  <div className="flex items-center gap-2">
                    <Thermometer className="w-4 h-4 text-red-400" />
                    <span className="text-gray-300 text-sm">±0.1°C Temperature Accuracy</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Wind className="w-4 h-4 text-blue-400" />
                    <span className="text-gray-300 text-sm">±2% RH Humidity Accuracy</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Gauge className="w-4 h-4 text-green-400" />
                    <span className="text-gray-300 text-sm">±0.1 hPa Pressure Accuracy</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="text-purple-400 text-sm">📱</span>
                    <span className="text-gray-300 text-sm">Mobile App & Wi-Fi</span>
                  </div>
                </div>
                <div className="flex items-center gap-4">
                  <span className="text-3xl font-bold text-blue-400">$299.99</span>
                  <span className="bg-green-600 text-white text-sm px-2 py-1 rounded">Free Shipping</span>
                </div>
              </div>
              <button
                onClick={() => handleAddToCart(environmentalProducts[0])}
                className="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white font-semibold py-3 px-8 rounded-lg transition-all duration-300 transform hover:scale-105"
              >
                Add to Cart
              </button>
            </div>
          </div>
        </div>
        
        {/* All Environmental Monitors */}
        <div className="mb-4">
          <h2 className="text-2xl font-semibold text-white mb-6">All Environmental Monitors</h2>
        </div>
        <ProductGrid 
          products={environmentalProducts}
          loading={loading}
          onAddToCart={handleAddToCart}
        />

        {/* Cart Sidebar */}
        <CartSidebar
          isOpen={isCartOpen}
          onClose={closeCart}
          items={cart.items}
          onUpdateQuantity={updateQuantity}
          onRemoveItem={removeFromCart}
          onCheckout={handleCheckout}
        />
      </div>
    </div>
  );
}