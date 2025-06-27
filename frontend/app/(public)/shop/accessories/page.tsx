// (public)/shop/accessories/page.tsx
'use client';

import { useState } from 'react';
import { useShop } from '@/contexts/ShopContext';
import { ProductGrid } from '@/components/shop/product/ProductGrid';
import { CartSidebar } from '@/components/shop/cart/CartSidebar';
import { CartIcon } from '@/components/shop/cart/CartIcon';
import { Product } from '@/types/shop';
import { ArrowLeft, Wrench } from 'lucide-react';
import Link from 'next/link';

// Mock accessories data
const accessoriesProducts: Product[] = [
  {
    id: '3',
    name: 'Calibration Solution Kit',
    description: 'Essential pH and EC calibration solutions to keep your sensors accurate and reliable. Includes pH 4.0, 7.0, and 10.0 solutions plus EC 1413 μS/cm solution.',
    price: 49.99,
    category: 'Accessories',
    features: ['pH 4.0, 7.0, 10.0 Solutions', 'EC 1413 μS/cm Solution', 'Long Lasting Formula', 'Professional Grade', '6 Month Shelf Life'],
    in_stock: true,
    active: true,
  },
  {
    id: '4',
    name: 'Sensor Cleaning Kit',
    description: 'Professional cleaning solutions and tools to maintain your sensors in perfect condition. Extends sensor life and maintains accuracy.',
    price: 29.99,
    category: 'Accessories',
    features: ['Cleaning Solutions', 'Soft Brush Set', 'Microfiber Cloths', 'Storage Case', 'Maintenance Guide'],
    in_stock: false,
    active: true,
  },
  {
    id: '5',
    name: 'pH Probe Replacement',
    description: 'High-quality replacement pH probe compatible with all XSpaceGrow liquid monitoring systems. Factory calibrated and ready to use.',
    price: 89.99,
    category: 'Accessories',
    features: ['Factory Calibrated', 'BNC Connector', '6 Month Warranty', 'Temperature Compensation', 'Quick Response'],
    in_stock: true,
    active: true,
  },
  {
    id: '6',
    name: 'EC Probe Replacement',
    description: 'Precision EC probe replacement for accurate conductivity measurements. Compatible with all XSpaceGrow monitoring systems.',
    price: 79.99,
    category: 'Accessories',
    features: ['High Precision', 'Temperature Compensation', 'Long Life Design', 'Easy Installation', '6 Month Warranty'],
    in_stock: true,
    active: true,
  },
  {
    id: '7',
    name: 'Mounting Hardware Kit',
    description: 'Complete mounting solution for XSpaceGrow devices. Includes wall mounts, brackets, and all necessary hardware.',
    price: 24.99,
    category: 'Accessories',
    features: ['Universal Mounting', 'Stainless Steel Hardware', 'Adjustable Brackets', 'Indoor/Outdoor Use', 'Easy Installation'],
    in_stock: true,
    active: true,
  },
  {
    id: '8',
    name: 'Power Supply - 12V 2A',
    description: 'Reliable power supply for XSpaceGrow devices. Includes multiple plug adapters for worldwide compatibility.',
    price: 34.99,
    category: 'Accessories',
    features: ['12V 2A Output', 'Multiple Plugs', 'Overcurrent Protection', 'CE/FCC Certified', '3 Year Warranty'],
    in_stock: true,
    active: true,
  },
];

export default function AccessoriesPage() {
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
              <span className="text-white">Accessories</span>
            </div>

            {/* Title Section */}
            <div className="flex items-center gap-4 mb-4">
              <div className="w-16 h-16 bg-gradient-to-br from-orange-500 to-red-600 rounded-xl flex items-center justify-center">
                <Wrench className="w-8 h-8 text-white" />
              </div>
              <div>
                <h1 className="text-4xl font-bold text-white mb-2">Accessories</h1>
                <p className="text-xl text-gray-300">Essential tools and parts to keep your systems running perfectly</p>
              </div>
            </div>

            {/* Stats */}
            <div className="flex gap-6 text-sm text-gray-400">
              <span>{accessoriesProducts.length} products</span>
              <span>•</span>
              <span>{accessoriesProducts.filter(p => p.in_stock).length} in stock</span>
              <span>•</span>
              <span>Starting at $24.99</span>
            </div>
          </div>
          
          {/* Cart Icon */}
          <CartIcon 
            itemCount={cart.count} 
            onClick={openCart}
            className="text-white hover:text-blue-400"
          />
        </div>

        {/* Category Benefits */}
        <div className="mb-8 bg-gray-800/50 backdrop-blur border border-gray-700 rounded-xl p-6">
          <h2 className="text-xl font-semibold text-white mb-4">Why Choose XSpaceGrow Accessories?</h2>
          <div className="grid md:grid-cols-3 gap-4">
            <div className="flex items-start gap-3">
              <div className="w-8 h-8 bg-green-600/20 rounded-lg flex items-center justify-center flex-shrink-0">
                <span className="text-green-400 text-lg">✓</span>
              </div>
              <div>
                <h3 className="text-white font-medium">Perfect Compatibility</h3>
                <p className="text-gray-400 text-sm">Designed specifically for XSpaceGrow systems</p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <div className="w-8 h-8 bg-blue-600/20 rounded-lg flex items-center justify-center flex-shrink-0">
                <span className="text-blue-400 text-lg">⚡</span>
              </div>
              <div>
                <h3 className="text-white font-medium">Professional Quality</h3>
                <p className="text-gray-400 text-sm">Laboratory-grade materials and precision</p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <div className="w-8 h-8 bg-purple-600/20 rounded-lg flex items-center justify-center flex-shrink-0">
                <span className="text-purple-400 text-lg">🛡️</span>
              </div>
              <div>
                <h3 className="text-white font-medium">Extended Warranty</h3>
                <p className="text-gray-400 text-sm">6-month to 3-year warranty coverage</p>
              </div>
            </div>
          </div>
        </div>
        
        {/* Products */}
        <ProductGrid 
          products={accessoriesProducts}
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