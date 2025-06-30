// components/landing/ProductShowcase.tsx
'use client';

import Link from 'next/link';
import { ArrowRight, Thermometer, Droplets, Gauge } from 'lucide-react';
import { CosmicButton } from '@/components/ui/ButtonVariants';

const products = [
  {
    id: 1,
    name: 'Environmental Monitor V1',
    description: 'Complete environmental monitoring with temperature, humidity, and pressure sensors.',
    image: 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?w=400&h=400&fit=crop',
    features: ['Temperature Sensor', 'Humidity Sensor', 'Pressure Sensor'],
    icon: Thermometer,
    price: '$299',
  },
  {
    id: 2,
    name: 'Liquid Monitor V1',
    description: 'Professional liquid monitoring with pH, EC sensors and temperature control.',
    image: 'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=400&h=400&fit=crop',
    features: ['pH Sensor', 'EC Sensor', 'Temperature Control'],
    icon: Droplets,
    price: '$199',
  },
  {
    id: 3,
    name: 'Pressure Monitor Pro',
    description: 'Industrial-grade pressure monitoring for advanced growing systems.',
    image: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=400&h=400&fit=crop',
    features: ['High Precision', 'Industrial Grade', 'Real-time Alerts'],
    icon: Gauge,
    price: '$149',
  },
];

export function ProductShowcase() {
  return (
    <section className="py-16 px-4">
      <div className="max-w-6xl mx-auto">
        <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-8 md:p-12 shadow-2xl">
          <div className="text-center mb-12">
            <h2 className="text-base font-semibold text-yellow-400 mb-4">Our Products</h2>
            <p className="text-4xl md:text-5xl font-semibold tracking-tight text-white mb-6">
              Hardware designed for{' '}
              <span className="bg-gradient-to-r from-yellow-400 via-pink-500 to-purple-600 bg-clip-text text-transparent">
                precision
              </span>
            </p>
            <p className="text-lg text-gray-300 max-w-2xl mx-auto">
              Professional-grade sensors and controllers that integrate seamlessly with our platform.
            </p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-12">
            {products.map((product, index) => (
              <article
                key={product.id}
                className="group relative overflow-hidden rounded-xl bg-white/10 backdrop-blur-sm border border-white/20 hover:border-white/30 transition-all duration-300 hover:scale-105"
              >
                <div className="aspect-w-16 aspect-h-10 relative">
                  <img
                    alt={product.name}
                    src={product.image}
                    className="w-full h-48 object-cover group-hover:scale-110 transition-transform duration-500"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent"></div>
                </div>

                <div className="p-6">
                  <div className="flex flex-wrap items-center gap-2 text-sm text-gray-400 mb-3">
                    <product.icon className="h-4 w-4 text-yellow-400" />
                    <span>{product.features.join(' • ')}</span>
                  </div>
                  <h3 className="text-xl font-semibold text-white mb-2 group-hover:text-yellow-400 transition-colors">
                    {product.name}
                  </h3>
                  <p className="text-sm text-gray-300 mb-4">{product.description}</p>
                  <div className="flex items-center justify-between">
                    <span className="text-2xl font-bold text-yellow-400">{product.price}</span>
                    <div className="flex items-center space-x-2 text-gray-400 group-hover:text-yellow-400 transition-colors">
                      <span className="text-xs font-medium">Learn More</span>
                      <ArrowRight className="h-4 w-4 group-hover:translate-x-1 transition-transform" />
                    </div>
                  </div>
                </div>
              </article>
            ))}
          </div>
          
          <div className="text-center">
            <Link href="/shop">
              <CosmicButton size="lg">
                View All Products
              </CosmicButton>
            </Link>
          </div>
        </div>
      </div>
    </section>
  );
}