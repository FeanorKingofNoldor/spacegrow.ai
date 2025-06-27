// components/shop/product/ProductGrid.tsx
'use client';

import { Product } from '@/types/shop';
import { 
  ShoppingCart, 
  Star, 
  Package, 
  AlertTriangle,
  CheckCircle,
  Clock,
  Loader2
} from 'lucide-react';
import { useState } from 'react';

interface ProductGridProps {
  products: Product[];
  loading: boolean;
  onAddToCart: (product: Product) => Promise<void>;
}

export function ProductGrid({ products, loading, onAddToCart }: ProductGridProps) {
  const [addingToCart, setAddingToCart] = useState<string | null>(null);

  const handleAddToCart = async (product: Product) => {
    if (!product.in_stock) return;
    
    try {
      setAddingToCart(product.id);
      await onAddToCart(product);
    } catch (error) {
      console.error('Failed to add to cart:', error);
    } finally {
      setAddingToCart(null);
    }
  };

  const getStockBadge = (product: Product) => {
    if (!product.in_stock) {
      return (
        <div className="flex items-center gap-1 text-red-400 text-xs font-medium">
          <AlertTriangle className="w-3 h-3" />
          Out of Stock
        </div>
      );
    }
    
    if (product.stock_status === 'low_stock') {
      return (
        <div className="flex items-center gap-1 text-orange-400 text-xs font-medium">
          <Clock className="w-3 h-3" />
          {product.stock_description}
        </div>
      );
    }
    
    return (
      <div className="flex items-center gap-1 text-green-400 text-xs font-medium">
        <CheckCircle className="w-3 h-3" />
        In Stock
      </div>
    );
  };

  const getStockIndicatorColor = (product: Product) => {
    if (!product.in_stock) return 'border-red-500/50 bg-red-500/10';
    if (product.stock_status === 'low_stock') return 'border-orange-500/50 bg-orange-500/10';
    return 'border-green-500/50 bg-green-500/10';
  };

  if (loading) {
    return (
      <div className="grid md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        {Array.from({ length: 8 }).map((_, i) => (
          <div key={i} className="animate-pulse">
            <div className="bg-white/10 rounded-2xl h-96"></div>
          </div>
        ))}
      </div>
    );
  }

  if (products.length === 0) {
    return (
      <div className="text-center py-16">
        <Package className="w-16 h-16 text-gray-400 mx-auto mb-4" />
        <h3 className="text-2xl font-bold text-white mb-2">No Products Found</h3>
        <p className="text-gray-300">Try adjusting your filters or search terms.</p>
      </div>
    );
  }

  return (
    <div className="grid md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
      {products.map((product, index) => (
        <div
          key={product.id}
          className="group relative"
          style={{ animationDelay: `${index * 0.1}s` }}
        >
          {/* Stock status indicator */}
          <div className={`absolute top-4 left-4 z-10 px-2 py-1 rounded-full border ${getStockIndicatorColor(product)} backdrop-blur-sm`}>
            {getStockBadge(product)}
          </div>

          {/* Featured badge */}
          {product.featured && (
            <div className="absolute top-4 right-4 z-10">
              <div className="bg-gradient-to-r from-yellow-500 to-orange-500 text-black text-xs font-bold px-2 py-1 rounded-full flex items-center gap-1">
                <Star className="w-3 h-3 fill-current" />
                FEATURED
              </div>
            </div>
          )}

          <div className="relative backdrop-blur-md bg-white/10 border border-white/20 rounded-2xl p-6 transform group-hover:scale-105 transition-all duration-300 hover:border-white/40">
            {/* Product image */}
            <div className="w-full h-48 bg-gradient-to-br from-gray-700 to-gray-800 rounded-lg mb-4 flex items-center justify-center overflow-hidden">
              {product.image ? (
                <img 
                  src={typeof product.image === 'string' ? product.image : product.image.url} 
                  alt={product.name}
                  className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500"
                />
              ) : (
                <div className="text-6xl">
                  {product.category.includes('Environmental') ? '🌡️' : 
                   product.category.includes('Liquid') ? '💧' : '🔧'}
                </div>
              )}
            </div>
            
            {/* Category */}
            <div className="mb-2">
              <span className="text-sm text-blue-400 font-medium">
                {product.category}
              </span>
            </div>

            {/* Product name */}
            <h3 className="text-xl font-bold text-white mb-3 line-clamp-2 group-hover:text-yellow-400 transition-colors">
              {product.name}
            </h3>

            {/* Description */}
            <p className="text-gray-300 text-sm mb-4 line-clamp-2">
              {product.description}
            </p>

            {/* Features */}
            {product.features && product.features.length > 0 && (
              <div className="mb-4">
                <div className="flex flex-wrap gap-1">
                  {product.features.slice(0, 2).map((feature, idx) => (
                    <span 
                      key={idx}
                      className="text-xs bg-blue-500/20 text-blue-300 px-2 py-1 rounded-full"
                    >
                      {feature}
                    </span>
                  ))}
                  {product.features.length > 2 && (
                    <span className="text-xs text-gray-400">
                      +{product.features.length - 2} more
                    </span>
                  )}
                </div>
              </div>
            )}

            {/* Price and stock info */}
            <div className="flex items-center justify-between mb-4">
              <span className="text-3xl font-bold text-yellow-400">
                ${product.price}
              </span>
              {product.stock_status === 'low_stock' && product.stock_quantity <= 10 && (
                <span className="text-orange-400 text-sm font-medium">
                  {product.stock_quantity} left
                </span>
              )}
            </div>

            {/* Add to cart button */}
            <button
              onClick={() => handleAddToCart(product)}
              disabled={!product.in_stock || addingToCart === product.id}
              className={`w-full py-3 px-6 rounded-lg font-semibold transition-all duration-300 transform hover:scale-105 min-h-[48px] flex items-center justify-center gap-2 ${
                !product.in_stock
                  ? 'bg-gray-600 text-gray-400 cursor-not-allowed'
                  : addingToCart === product.id
                  ? 'bg-green-600 text-white'
                  : 'bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white'
              }`}
            >
              {addingToCart === product.id ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Adding...
                </>
              ) : !product.in_stock ? (
                'Out of Stock'
              ) : (
                <>
                  <ShoppingCart className="w-4 h-4" />
                  Add to Cart
                </>
              )}
            </button>
          </div>
        </div>
      ))}
    </div>
  );
}