// components/landing/ProductShowcase.tsx
'use client';

import { ArrowRight, Thermometer, Droplets, Gauge } from 'lucide-react';

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
    <section className="bg-space-secondary py-24 sm:py-32">
      <div className="mx-auto max-w-7xl px-6 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-base/7 font-semibold text-stellar-accent">Our Products</h2>
          <p className="mt-2 text-pretty text-4xl font-semibold tracking-tight text-gradient-cosmic sm:text-5xl">
            Hardware designed for precision
          </p>
          <p className="mt-6 text-lg/8 text-cosmic-text-muted">
            Professional-grade sensors and controllers that integrate seamlessly with our platform.
          </p>
        </div>
        <div className="mx-auto mt-16 grid max-w-2xl auto-rows-fr grid-cols-1 gap-8 sm:mt-20 lg:mx-0 lg:max-w-none lg:grid-cols-3">
          {products.map((product, index) => (
            <article
              key={product.id}
              className="group relative isolate flex flex-col justify-end overflow-hidden rounded-2xl bg-space-card border border-space-border px-8 pb-8 pt-80 sm:pt-48 lg:pt-80 hover:scale-105 transition-all duration-300"
            >
              <img
                alt={product.name}
                src={product.image}
                className="absolute inset-0 -z-10 h-full w-full object-cover group-hover:scale-110 transition-transform duration-500"
              />
              <div className="absolute inset-0 -z-10 bg-gradient-to-t from-space-primary via-space-primary/40" />
              <div className="absolute inset-0 -z-10 rounded-2xl ring-1 ring-inset ring-space-border" />

              <div className="flex flex-wrap items-center gap-y-1 overflow-hidden text-sm/6 text-cosmic-text-muted">
                <product.icon className="h-4 w-4 text-stellar-accent" />
                <span className="ml-2">{product.features.join(' • ')}</span>
              </div>
              <h3 className="mt-3 text-lg/6 font-semibold text-cosmic-text group-hover:text-gradient-cosmic transition-all duration-300">
                <span className="absolute inset-0" />
                {product.name}
              </h3>
              <p className="mt-2 text-sm/6 text-cosmic-text-muted">{product.description}</p>
              <div className="mt-4 flex items-center justify-between">
                <span className="text-xl font-bold text-stellar-accent">{product.price}</span>
                <div className="flex items-center space-x-2 text-cosmic-text-muted group-hover:text-stellar-accent transition-colors">
                  <span className="text-xs font-medium">Learn More</span>
                  <ArrowRight className="h-4 w-4 group-hover:translate-x-1 transition-transform" />
                </div>
              </div>
            </article>
          ))}
        </div>
        <div className="mt-16 flex justify-center">
          <a
            href="/shop"
            className="rounded-lg bg-gradient-cosmic px-6 py-3 text-sm font-semibold text-white shadow-lg hover:scale-105 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-stellar-accent transition-all duration-200 animate-nebula-glow"
          >
            View All Products
          </a>
        </div>
      </div>
    </section>
  );
}