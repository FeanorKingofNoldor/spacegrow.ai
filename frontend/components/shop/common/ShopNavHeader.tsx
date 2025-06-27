// components/shop/common/ShopNavHeader.tsx
'use client';

import { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { 
  Store, 
  Thermometer, 
  Droplets, 
  Package, 
  Wrench, 
  Search,
  Menu,
  X,
  Sparkles
} from 'lucide-react';
import { CartIcon } from '@/components/shop/cart/CartIcon';
import { useShop } from '@/contexts/ShopContext';
import { ClientOnlyDotSparkles, ClientOnlyIconSparkles } from '@/components/ui/client-only-sparkles';

interface NavItem {
  name: string;
  href: string;
  icon: React.ReactNode;
  description: string;
  color: string;
  gradient: string;
}

const navigation: NavItem[] = [
  {
    name: 'All Products',
    href: '/shop',
    icon: <Store className="w-5 h-5" />,
    description: 'Browse everything',
    color: 'text-purple-400',
    gradient: 'from-purple-600 to-pink-600'
  },
  {
    name: 'Environmental',
    href: '/shop/environmental-monitor',
    icon: <Thermometer className="w-5 h-5" />,
    description: 'Climate monitoring',
    color: 'text-blue-400',
    gradient: 'from-blue-600 to-purple-600'
  },
  {
    name: 'Liquid',
    href: '/shop/liquid-monitor',
    icon: <Droplets className="w-5 h-5" />,
    description: 'Nutrient monitoring',
    color: 'text-cyan-400',
    gradient: 'from-cyan-600 to-blue-600'
  },
  {
    name: 'Bundles',
    href: '/shop/bundles',
    icon: <Package className="w-5 h-5" />,
    description: 'Save on packages',
    color: 'text-green-400',
    gradient: 'from-green-600 to-blue-600'
  },
  {
    name: 'Accessories',
    href: '/shop/accessories',
    icon: <Wrench className="w-5 h-5" />,
    description: 'Parts & tools',
    color: 'text-orange-400',
    gradient: 'from-orange-600 to-red-600'
  }
];

export function ShopNavHeader() {
  const { cart, openCart } = useShop();
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const pathname = usePathname();

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    // TODO: Implement search functionality
    console.log('Searching for:', searchQuery);
  };

  return (
    <header className="relative">

		{/* Supernova particles background */}
		<ClientOnlyIconSparkles 
		count={50}
		className="absolute inset-0 overflow-hidden pointer-events-none"
		/>

      {/* Main header */}
      <div className="relative backdrop-blur-md bg-gray-900/80 border-b border-purple-500/30">
        <div className="container mx-auto px-4">
          <div className="flex items-center justify-between h-20">
            {/* Logo */}
            <Link href="/shop" className="flex items-center gap-3 group">
              <div className="relative">
                <div className="absolute inset-0 bg-gradient-to-r from-purple-600 to-pink-600 rounded-xl blur-lg opacity-50 group-hover:opacity-75 transition-opacity"></div>
                <div className="relative w-12 h-12 bg-gradient-to-r from-purple-600 to-pink-600 rounded-xl flex items-center justify-center">
                  <Store className="w-6 h-6 text-white" />
                </div>
              </div>
              <div>
                <h1 className="text-2xl font-bold bg-gradient-to-r from-purple-400 to-pink-400 bg-clip-text text-transparent">
                  SpaceGrow
                </h1>
                <p className="text-xs text-gray-400 -mt-1">Professional Shop</p>
              </div>
            </Link>

            {/* Desktop Navigation */}
            <nav className="hidden lg:flex items-center gap-1">
              {navigation.map((item) => {
                const isActive = pathname === item.href;
                return (
                  <Link
                    key={item.name}
                    href={item.href}
                    className={`relative px-4 py-2 rounded-lg transition-all duration-300 group ${
                      isActive 
                        ? 'text-white' 
                        : 'text-gray-300 hover:text-white'
                    }`}
                  >
                    {/* Active background */}
                    {isActive && (
                      <div className={`absolute inset-0 bg-gradient-to-r ${item.gradient} rounded-lg opacity-20`} />
                    )}
                    
                    {/* Hover effect */}
                    <div className={`absolute inset-0 bg-gradient-to-r ${item.gradient} rounded-lg opacity-0 group-hover:opacity-10 transition-opacity`} />
                    
                    <div className="relative flex items-center gap-2">
                      <span className={item.color}>{item.icon}</span>
                      <div>
                        <div className="font-medium">{item.name}</div>
                        <div className="text-xs text-gray-400 group-hover:text-gray-300">
                          {item.description}
                        </div>
                      </div>
                    </div>
                  </Link>
                );
              })}
            </nav>

            {/* Search Bar */}
            <div className="hidden md:block flex-1 max-w-md mx-8">
              <form onSubmit={handleSearch} className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                <input
                  type="text"
                  placeholder="Search products..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 bg-gray-800/50 border border-gray-600/50 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent backdrop-blur-sm"
                />
              </form>
            </div>

            {/* Cart and Mobile Menu */}
            <div className="flex items-center gap-4">
              {/* Cart Icon */}
              <CartIcon 
                itemCount={cart.count} 
                onClick={openCart}
                className="text-gray-300 hover:text-white"
              />

              {/* Mobile Menu Button */}
              <button
                onClick={() => setIsMenuOpen(!isMenuOpen)}
                className="lg:hidden p-2 text-gray-300 hover:text-white"
              >
                {isMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
              </button>
            </div>
          </div>

          {/* Mobile Search */}
          <div className="md:hidden pb-4">
            <form onSubmit={handleSearch} className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type="text"
                placeholder="Search products..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2 bg-gray-800/50 border border-gray-600/50 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent backdrop-blur-sm"
              />
            </form>
          </div>
        </div>
      </div>

      {/* Mobile Navigation */}
      {isMenuOpen && (
        <div className="lg:hidden absolute top-full left-0 right-0 z-50 backdrop-blur-md bg-gray-900/95 border-b border-purple-500/30">
          <nav className="container mx-auto px-4 py-4">
            <div className="space-y-2">
              {navigation.map((item) => {
                const isActive = pathname === item.href;
                return (
                  <Link
                    key={item.name}
                    href={item.href}
                    onClick={() => setIsMenuOpen(false)}
                    className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-all duration-300 ${
                      isActive 
                        ? 'bg-purple-600/20 text-white' 
                        : 'text-gray-300 hover:text-white hover:bg-gray-800/50'
                    }`}
                  >
                    <span className={item.color}>{item.icon}</span>
                    <div>
                      <div className="font-medium">{item.name}</div>
                      <div className="text-xs text-gray-400">{item.description}</div>
                    </div>
                  </Link>
                );
              })}
            </div>
          </nav>
        </div>
      )}
    </header>
  );
}