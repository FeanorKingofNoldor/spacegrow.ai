// (public)/shop/page.tsx
'use client';

// At the top of the file, add the helper function import
import { useState, useEffect } from 'react';
import { useShop } from '@/contexts/ShopContext';
import { ShopNavHeader } from '@/components/shop/common/ShopNavHeader';
import { ProductGrid } from '@/components/shop/product/ProductGrid';
import { CartSidebar } from '@/components/shop/cart/CartSidebar';
import { Product } from '@/types/shop';
import { 
  Star, 
  TrendingUp, 
  Zap, 
  Award,
  ArrowRight,
  Sparkles,
  Rocket,
  AlertCircle,
  Loader2,
  ShoppingBag
} from 'lucide-react';
import Link from 'next/link';
import { ClientOnlyDotSparkles, ClientOnlyIconSparkles } from '@/components/ui/ClientOnlySparkle';

// Helper function to get image URL
const getImageUrl = (image: string | { url: string; alt?: string; thumbnail?: string } | undefined): string | undefined => {
  if (!image) return undefined;
  if (typeof image === 'string') return image;
  return image.url;
};

const getImageAlt = (image: string | { url: string; alt?: string; thumbnail?: string } | undefined, fallback: string = ''): string => {
  if (!image || typeof image === 'string') return fallback;
  return image.alt || fallback;
};

const categories = [
  {
    name: 'Environmental',
    href: '/shop/environmental-monitor',
    icon: '🌡️',
    gradient: 'from-blue-500 to-purple-600',
    description: 'Climate monitoring systems',
    features: ['Temperature', 'Humidity', 'Pressure']
  },
  {
    name: 'Liquid',
    href: '/shop/liquid-monitor',
    icon: '💧',
    gradient: 'from-cyan-500 to-blue-600',
    description: 'Nutrient monitoring & dosing',
    features: ['pH Sensors', 'EC Monitoring', 'Auto Dosing']
  },
  {
    name: 'Bundles',
    href: '/shop/bundles',
    icon: '📦',
    gradient: 'from-green-500 to-blue-600',
    description: 'Complete system packages',
    features: ['Everything Included', 'Pre-configured', 'Best Value']
  },
  {
    name: 'Accessories',
    href: '/shop/accessories',
    icon: '🔧',
    gradient: 'from-orange-500 to-red-600',
    description: 'Parts, tools & maintenance',
    features: ['Calibration Kits', 'Replacement Parts', 'Tools']
  },
];

const features = [
  {
    icon: Star,
    title: 'Laboratory Grade',
    description: 'Professional-grade sensors with ±0.1% accuracy'
  },
  {
    icon: Zap,
    title: 'Real-time Data',
    description: 'Live monitoring with instant alerts and notifications'
  },
  {
    icon: Award,
    title: 'Expert Support',
    description: '24/7 technical support from IoT specialists'
  }
];

export default function EpicShopPage() {
  const { 
    products,
    loading,
    cart, 
    addToCart, 
    removeFromCart, 
    updateQuantity,
    isCartOpen, 
    openCart, 
    closeCart
  } = useShop();
  
  const [featuredProducts, setFeaturedProducts] = useState<Product[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [addingToCart, setAddingToCart] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const loadData = async () => {
      try {
        setIsLoading(true);
        setError(null);
        
        // Use first 3 products as featured (you can modify this logic)
        if (products.length > 0) {
          // Simple featured logic - take first 3 products or filter by some criteria
          const featured = products.slice(0, 3);
          setFeaturedProducts(featured);
        }
      } catch (err) {
        console.error('Failed to load featured products:', err);
        setError('Failed to load products');
        // Fallback to empty array
        setFeaturedProducts([]);
      } finally {
        setIsLoading(false);
      }
    };

    if (products.length > 0) {
      loadData();
    } else if (!loading) {
      setIsLoading(false);
    }
  }, [products, loading]);

  const handleAddToCart = async (product: Product) => {
    try {
      setAddingToCart(product.id);
      await addToCart(product, 1);
      
      // Optional: Show success feedback
      const button = document.querySelector(`[data-product-id="${product.id}"]`);
      if (button) {
        button.textContent = 'Added!';
        setTimeout(() => {
          button.textContent = 'Add to Cart';
        }, 1500);
      }
    } catch (error) {
      console.error('Failed to add to cart:', error);
      // Could show an error toast here
    } finally {
      setAddingToCart(null);
    }
  };

  const handleCheckout = () => {
    console.log('Proceeding to checkout with:', cart);
    // Navigate to checkout page instead of alert
    closeCart();
    window.location.href = '/shop/checkout';
  };

  // Error state
  if (error) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-900 to-purple-900">
        <ShopNavHeader />
        <div className="container mx-auto px-4 py-16">
          <div className="text-center">
            <AlertCircle className="w-16 h-16 text-red-400 mx-auto mb-4" />
            <h1 className="text-3xl font-bold text-white mb-4">Oops! Something went wrong</h1>
            <p className="text-gray-300 mb-8">{error}</p>
            <button
              onClick={() => window.location.reload()}
              className="bg-gradient-to-r from-blue-600 to-purple-600 text-white px-6 py-3 rounded-lg hover:from-blue-700 hover:to-purple-700 transition-all"
            >
              Try Again
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen relative overflow-hidden">
      {/* SUPERNOVA BACKGROUND */}
      <div className="fixed inset-0 bg-gradient-to-br from-purple-900 via-blue-900 to-pink-900">
        {/* Animated supernova core */}
        <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2">
          <div className="w-96 h-96 bg-gradient-radial from-yellow-400/30 via-orange-500/20 to-transparent rounded-full animate-pulse"></div>
          <div className="absolute inset-0 w-96 h-96 bg-gradient-radial from-pink-500/20 via-purple-600/15 to-transparent rounded-full animate-ping"></div>
        </div>

		{/* Stellar particles */}
		<ClientOnlyDotSparkles />

        {/* Nebula clouds */}
        <div className="absolute inset-0">
          <div className="absolute top-20 left-10 w-64 h-64 bg-gradient-radial from-blue-500/10 to-transparent rounded-full blur-3xl animate-slow-float"></div>
          <div className="absolute bottom-20 right-10 w-80 h-80 bg-gradient-radial from-purple-500/10 to-transparent rounded-full blur-3xl animate-slow-float-reverse"></div>
          <div className="absolute top-1/3 right-1/4 w-48 h-48 bg-gradient-radial from-pink-500/10 to-transparent rounded-full blur-2xl animate-slow-float"></div>
        </div>
      </div>

      {/* CONTENT */}
      <div className="relative z-10">
        {/* Shop Navigation Header */}
        <ShopNavHeader />

        <div className="container mx-auto px-4 py-8">
          {/* Hero Section */}
          <section className="text-center mb-16 relative">
            <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/5 to-transparent blur-xl"></div>
            <div className="relative">
              <div className="flex items-center justify-center gap-2 mb-4">
                <Rocket className="w-8 h-8 text-yellow-400 animate-bounce" />
                <span className="text-yellow-400 font-semibold tracking-wider">PROFESSIONAL IOT SOLUTIONS</span>
                <Rocket className="w-8 h-8 text-yellow-400 animate-bounce" style={{ animationDelay: '0.2s' }} />
              </div>
              <h1 className="text-6xl md:text-8xl font-bold mb-6">
                <span className="bg-gradient-to-r from-yellow-400 via-pink-500 to-purple-600 bg-clip-text text-transparent animate-pulse">
                  SpaceGrow
                </span>
              </h1>
              <p className="text-2xl md:text-3xl text-white mb-8 max-w-4xl mx-auto leading-relaxed">
                Professional IoT monitoring systems for 
                <span className="text-transparent bg-gradient-to-r from-green-400 to-blue-500 bg-clip-text font-semibold"> smart growing operations</span>
              </p>
              
              {/* Feature highlights */}
              <div className="flex flex-wrap justify-center gap-6 text-lg text-gray-300 mb-8">
                {features.map((feature, index) => (
                  <div key={feature.title} className="flex items-center gap-2 bg-white/10 backdrop-blur-sm rounded-full px-4 py-2">
                    <feature.icon className="w-5 h-5 text-yellow-400" />
                    <span className="font-medium">{feature.title}</span>
                  </div>
                ))}
              </div>

              {/* CTA Button */}
              <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
                <button
                  onClick={() => document.getElementById('products')?.scrollIntoView({ behavior: 'smooth' })}
                  className="bg-gradient-to-r from-yellow-500 to-orange-500 hover:from-yellow-600 hover:to-orange-600 text-black font-bold py-4 px-8 rounded-lg transition-all duration-300 transform hover:scale-105 shadow-2xl"
                >
                  <div className="flex items-center gap-2">
                    <ShoppingBag className="w-5 h-5" />
                    <span>Shop Now</span>
                  </div>
                </button>
                <div className="text-gray-400 text-sm">
                  Free shipping on orders over $200
                </div>
              </div>
            </div>
          </section>

          {/* Category Quick Access */}
          <section className="mb-16">
            <div className="text-center mb-12">
              <h2 className="text-4xl font-bold text-white mb-4">Shop by Category</h2>
              <p className="text-xl text-gray-300">Find the perfect monitoring solution for your needs</p>
            </div>
            <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
              {categories.map((category, index) => (
                <Link
                  key={category.name}
                  href={category.href}
                  className="group relative p-6 rounded-2xl backdrop-blur-md bg-white/10 border border-white/20 hover:border-white/40 transition-all duration-300 transform hover:scale-105 hover:-translate-y-2"
                  style={{ animationDelay: `${index * 0.1}s` }}
                >
                  <div className={`absolute inset-0 bg-gradient-to-br ${category.gradient} opacity-0 group-hover:opacity-20 rounded-2xl transition-opacity`}></div>
                  <div className="relative">
                    <div className="text-4xl mb-4">{category.icon}</div>
                    <h3 className="text-xl font-bold text-white mb-2">{category.name}</h3>
                    <p className="text-gray-300 text-sm mb-4">{category.description}</p>
                    
                    {/* Feature list */}
                    <ul className="text-xs text-gray-400 mb-4 space-y-1">
                      {category.features.map((feature) => (
                        <li key={feature} className="flex items-center gap-1">
                          <div className="w-1 h-1 bg-yellow-400 rounded-full"></div>
                          {feature}
                        </li>
                      ))}
                    </ul>
                    
                    <div className="flex items-center gap-2 text-white font-medium">
                      <span>Explore</span>
                      <ArrowRight className="w-4 h-4 transform group-hover:translate-x-1 transition-transform" />
                    </div>
                  </div>
                </Link>
              ))}
            </div>
          </section>

          {/* Featured Products */}
          {featuredProducts.length > 0 && (
            <section className="mb-16">
              <div className="flex items-center justify-center gap-3 mb-12">
                <TrendingUp className="w-6 h-6 text-yellow-400" />
                <h2 className="text-4xl font-bold text-white">Featured Products</h2>
                <Sparkles className="w-6 h-6 text-yellow-400" />
              </div>
              <div className="grid md:grid-cols-3 gap-8">
                {featuredProducts.map((product, index) => (
                  <div
                    key={product.id}
                    className="relative group"
                    style={{ animationDelay: `${index * 0.2}s` }}
                  >
                    <div className="absolute inset-0 bg-gradient-to-r from-yellow-600/20 to-pink-600/20 rounded-2xl blur-xl group-hover:blur-2xl transition-all"></div>
                    <div className="relative backdrop-blur-md bg-white/10 border border-yellow-500/30 rounded-2xl p-6 transform group-hover:scale-105 transition-all duration-300">
                      <div className="absolute top-4 right-4">
                        <span className="bg-gradient-to-r from-yellow-500 to-orange-500 text-black text-xs font-bold px-2 py-1 rounded-full">
                          FEATURED
                        </span>
                      </div>
                      
                      {/* Product image */}
                      <div className="w-full h-48 bg-gradient-to-br from-gray-700 to-gray-800 rounded-lg mb-4 flex items-center justify-center overflow-hidden">
                        {getImageUrl(product.image) ? (
                          <img 
                            src={getImageUrl(product.image)!} 
                            alt={getImageAlt(product.image, product.name)}
                            className="w-full h-full object-cover"
                          />
                        ) : (
                          <div className="text-6xl">
                            {product.name.includes('Environmental') ? '🌡️' : 
                             product.name.includes('Liquid') ? '💧' : '📦'}
                          </div>
                        )}
                      </div>
                      
                      <div className="mb-2">
                        <span className="text-sm text-yellow-400 font-medium">
                          {product.name.includes('Environmental') ? 'Environmental Monitor' : 
                           product.name.includes('Liquid') ? 'Liquid Monitor' : 'IoT Device'}
                        </span>
                      </div>
                      <h3 className="text-xl font-bold text-white mb-3">{product.name}</h3>
                      <p className="text-gray-300 text-sm mb-6 line-clamp-2">{product.description}</p>
                      <div className="flex items-center justify-between">
                        <span className="text-3xl font-bold text-yellow-400">${product.price}</span>
                        <button
                          onClick={() => handleAddToCart(product)}
                          disabled={addingToCart === product.id}
                          data-product-id={product.id}
                          className="bg-gradient-to-r from-yellow-500 to-orange-500 hover:from-yellow-600 hover:to-orange-600 disabled:opacity-50 text-black font-semibold py-3 px-6 rounded-lg transition-all duration-300 transform hover:scale-105 min-w-[120px]"
                        >
                          {addingToCart === product.id ? (
                            <Loader2 className="w-4 h-4 animate-spin mx-auto" />
                          ) : (
                            'Add to Cart'
                          )}
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </section>
          )}

          {/* All Products */}
          <section id="products">
            <div className="text-center mb-12">
              <h2 className="text-4xl font-bold text-white mb-4">All Products</h2>
              <p className="text-xl text-gray-300">
                Professional IoT monitoring solutions for every application
                {products.length > 0 && (
                  <span className="text-blue-400 font-semibold"> ({products.length} products available)</span>
                )}
              </p>
            </div>
            
            {isLoading ? (
              <div className="flex justify-center items-center py-16">
                <Loader2 className="w-8 h-8 animate-spin text-yellow-400" />
                <span className="ml-2 text-white">Loading products...</span>
              </div>
            ) : (
              <ProductGrid 
                products={products}
                loading={loading}
                onAddToCart={handleAddToCart}
              />
            )}
          </section>
        </div>


      {/* Custom animations */}
      <style jsx>{`
        @keyframes slow-float {
          0%, 100% { transform: translateY(0px) rotate(0deg); }
          50% { transform: translateY(-20px) rotate(5deg); }
        }
        @keyframes slow-float-reverse {
          0%, 100% { transform: translateY(0px) rotate(0deg); }
          50% { transform: translateY(20px) rotate(-5deg); }
        }
        .animate-slow-float {
          animation: slow-float 8s ease-in-out infinite;
        }
        .animate-slow-float-reverse {
          animation: slow-float-reverse 10s ease-in-out infinite;
        }
        .bg-gradient-radial {
          background: radial-gradient(circle, var(--tw-gradient-stops));
        }
        .line-clamp-2 {
          display: -webkit-box;
          -webkit-line-clamp: 2;
          -webkit-box-orient: vertical;
          overflow: hidden;
        }
      `}</style>
    </div>
    {/* Close main container div */}
  </div>
  );
}