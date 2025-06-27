// (public)/shop/bundles/page.tsx
'use client';

import { useState } from 'react';
import { useShop } from '@/contexts/ShopContext';
import { ProductGrid } from '@/components/shop/product/ProductGrid';
import { CartSidebar } from '@/components/shop/cart/CartSidebar';
import { CartIcon } from '@/components/shop/cart/CartIcon';
import { Product } from '@/types/shop';
import { Package, Star, TrendingUp } from 'lucide-react';
import Link from 'next/link';

// Mock bundle data
const bundleProducts: Product[] = [
  {
    id: 'bundle-1',
    name: 'Complete Grow System Bundle',
    description: 'Everything you need to start smart growing! Includes Environmental Monitor V1, Liquid Monitor V1, calibration solutions, and mounting hardware. Save $150 compared to buying individually.',
    price: 499.99,
    category: 'Bundles',
    features: ['Environmental Monitor V1', 'Liquid Monitor V1', 'Calibration Kit', 'Mounting Hardware', 'Setup Guide', 'Priority Support'],
    in_stock: true,
    active: true,
    stock_quantity: 20,
    stock_status: 'in_stock',
    stock_description: 'Available for immediate shipping',
    low_stock_threshold: 5,
    featured: true,
  },
  {
    id: 'bundle-2',
    name: 'Environmental Starter Kit',
    description: 'Perfect for beginners! Environmental Monitor V1 with essential accessories. Includes calibration solutions, mounting kit, and comprehensive setup guide.',
    price: 349.99,
    category: 'Bundles',
    features: ['Environmental Monitor V1', 'Calibration Solutions', 'Mounting Hardware', 'Power Supply', 'Quick Start Guide', '30-Day Support'],
    in_stock: true,
    active: true,
    stock_quantity: 15,
    stock_status: 'in_stock',
    stock_description: 'Ships within 2 business days',
    low_stock_threshold: 3,
    featured: false,
  },
  {
    id: 'bundle-3',
    name: 'Liquid Monitoring Pro Kit',
    description: 'Professional liquid monitoring solution with backup sensors. Includes Liquid Monitor V1, replacement probes, calibration solutions, and cleaning kit.',
    price: 399.99,
    category: 'Bundles',
    features: ['Liquid Monitor V1', 'pH Replacement Probe', 'EC Replacement Probe', 'Calibration Kit', 'Cleaning Kit', 'Professional Setup'],
    in_stock: true,
    active: true,
    stock_quantity: 10,
    stock_status: 'in_stock',
    stock_description: 'Limited stock available',
    low_stock_threshold: 2,
    featured: false,
  },
  {
    id: 'bundle-4',
    name: 'Maintenance & Calibration Bundle',
    description: 'Keep your systems running perfectly! Complete maintenance bundle with calibration solutions, cleaning kits, and replacement parts.',
    price: 149.99,
    category: 'Bundles',
    features: ['2x Calibration Kits', '2x Cleaning Kits', 'Replacement Parts', 'Maintenance Schedule', 'Video Tutorials', '6-Month Supply'],
    in_stock: true,
    active: true,
    stock_quantity: 30,
    stock_status: 'in_stock',
    stock_description: 'Always in stock',
    low_stock_threshold: 10,
    featured: false,
  },
  {
    id: 'bundle-5',
    name: 'Multi-Room Growing Bundle',
    description: 'Scale up your operation! 2x Environmental Monitors, 1x Liquid Monitor, and all necessary accessories for monitoring multiple grow spaces.',
    price: 799.99,
    category: 'Bundles',
    features: ['2x Environmental Monitor V1', '1x Liquid Monitor V1', 'Multi-Point Setup', 'Advanced Analytics', 'Bulk Accessories', 'Enterprise Support'],
    in_stock: false,
    active: true,
    stock_quantity: 0,
    stock_status: 'out_of_stock',
    stock_description: 'Currently out of stock',
    low_stock_threshold: 2,
    featured: false,
  },
  {
    id: 'bundle-6',
    name: 'Research & Education Kit',
    description: 'Perfect for schools and research facilities. Includes multiple sensors, extensive documentation, and educational materials.',
    price: 599.99,
    category: 'Bundles',
    features: ['Multiple Sensors', 'Educational Materials', 'Research Documentation', 'Lab Setup Guide', 'Academic Pricing', 'Extended Warranty'],
    in_stock: true,
    active: true,
    stock_quantity: 8,
    stock_status: 'in_stock',
    stock_description: 'Ships in 1 week',
    low_stock_threshold: 2,
    featured: false,
  },
];

export default function BundlesPage() {
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
              <span className="text-white">Bundles</span>
            </div>

            {/* Title Section */}
            <div className="flex items-center gap-4 mb-4">
              <div className="w-16 h-16 bg-gradient-to-br from-green-500 to-blue-600 rounded-xl flex items-center justify-center">
                <Package className="w-8 h-8 text-white" />
              </div>
              <div>
                <h1 className="text-4xl font-bold text-white mb-2">Bundle Deals</h1>
                <p className="text-xl text-gray-300">Complete systems and package deals - save more when you buy together</p>
              </div>
            </div>

            {/* Stats */}
            <div className="flex gap-6 text-sm text-gray-400">
              <span>{bundleProducts.length} bundles available</span>
              <span>•</span>
              <span>Save up to $150</span>
              <span>•</span>
              <span>Free setup support included</span>
            </div>
          </div>
          
          {/* Cart Icon */}
          <CartIcon 
            itemCount={cart.count} 
            onClick={openCart}
            className="text-white hover:text-blue-400"
          />
        </div>

        {/* Bundle Benefits */}
        <div className="mb-8 bg-gradient-to-r from-green-900/20 to-blue-900/20 backdrop-blur border border-green-500/30 rounded-xl p-6">
          <div className="flex items-center gap-3 mb-4">
            <Star className="w-6 h-6 text-yellow-400" />
            <h2 className="text-xl font-semibold text-white">Why Choose Bundles?</h2>
          </div>
          <div className="grid md:grid-cols-3 gap-4">
            <div className="flex items-start gap-3">
              <div className="w-8 h-8 bg-green-600/20 rounded-lg flex items-center justify-center flex-shrink-0">
                <span className="text-green-400 text-lg">💰</span>
              </div>
              <div>
                <h3 className="text-white font-medium">Significant Savings</h3>
                <p className="text-gray-400 text-sm">Save 15-30% compared to individual purchases</p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <div className="w-8 h-8 bg-blue-600/20 rounded-lg flex items-center justify-center flex-shrink-0">
                <span className="text-blue-400 text-lg">📦</span>
              </div>
              <div>
                <h3 className="text-white font-medium">Everything Included</h3>
                <p className="text-gray-400 text-sm">Complete systems with all necessary components</p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <div className="w-8 h-8 bg-purple-600/20 rounded-lg flex items-center justify-center flex-shrink-0">
                <span className="text-purple-400 text-lg">🎯</span>
              </div>
              <div>
                <h3 className="text-white font-medium">Expert Curation</h3>
                <p className="text-gray-400 text-sm">Professionally selected combinations that work perfectly together</p>
              </div>
            </div>
          </div>
        </div>

        {/* Popular Bundle Highlight */}
        <div className="mb-8">
          <div className="flex items-center gap-2 mb-4">
            <TrendingUp className="w-5 h-5 text-yellow-400" />
            <h2 className="text-xl font-semibold text-white">Most Popular Bundle</h2>
          </div>
          <div className="bg-gradient-to-r from-yellow-900/20 to-orange-900/20 border border-yellow-500/30 rounded-xl p-6">
            <div className="flex flex-col md:flex-row gap-6 items-start">
              <div className="flex-1">
                <h3 className="text-2xl font-bold text-white mb-2">Complete Grow System Bundle</h3>
                <p className="text-gray-300 mb-4">
                  Our best-selling bundle includes everything you need to monitor both environmental 
                  conditions and liquid nutrients. Perfect for serious growers who want comprehensive monitoring.
                </p>
                <div className="flex items-center gap-4">
                  <span className="text-3xl font-bold text-green-400">$499.99</span>
                  <span className="text-gray-400 line-through">$649.99</span>
                  <span className="bg-green-600 text-white text-sm px-2 py-1 rounded">Save $150</span>
                </div>
              </div>
              <button
                onClick={() => handleAddToCart(bundleProducts[0])}
                className="bg-gradient-to-r from-green-600 to-blue-600 hover:from-green-700 hover:to-blue-700 text-white font-semibold py-3 px-8 rounded-lg transition-all duration-300 transform hover:scale-105"
              >
                Add to Cart
              </button>
            </div>
          </div>
        </div>
        
        {/* All Bundles */}
        <ProductGrid 
          products={bundleProducts}
          loading={loading}
          onAddToCart={handleAddToCart}
        />
      </div>
    </div>
  );
}