// components/shop/common/StockIndicator.tsx
'use client';

import { AlertTriangle, CheckCircle, Clock, Package } from 'lucide-react';
import { Product } from '@/types/shop';

interface StockIndicatorProps {
  product: Product;
  size?: 'sm' | 'md' | 'lg';
  showQuantity?: boolean;
  className?: string;
}

export function StockIndicator({ 
  product, 
  size = 'md', 
  showQuantity = true,
  className = '' 
}: StockIndicatorProps) {
  const getSizeClasses = () => {
    switch (size) {
      case 'sm':
        return 'text-xs px-2 py-1';
      case 'lg':
        return 'text-sm px-4 py-2';
      default:
        return 'text-xs px-3 py-1.5';
    }
  };

  const getIconSize = () => {
    switch (size) {
      case 'sm':
        return 'w-3 h-3';
      case 'lg':
        return 'w-5 h-5';
      default:
        return 'w-4 h-4';
    }
  };

  if (!product.in_stock) {
    return (
      <div className={`inline-flex items-center gap-1.5 bg-red-500/10 border border-red-500/30 text-red-400 rounded-full font-medium ${getSizeClasses()} ${className}`}>
        <AlertTriangle className={getIconSize()} />
        <span>Out of Stock</span>
      </div>
    );
  }

  if (product.stock_status === 'low_stock') {
    return (
      <div className={`inline-flex items-center gap-1.5 bg-orange-500/10 border border-orange-500/30 text-orange-400 rounded-full font-medium ${getSizeClasses()} ${className}`}>
        <Clock className={getIconSize()} />
        <span>
          {showQuantity && product.stock_quantity <= 10 
            ? `Only ${product.stock_quantity} left!`
            : 'Low Stock'
          }
        </span>
      </div>
    );
  }

  return (
    <div className={`inline-flex items-center gap-1.5 bg-green-500/10 border border-green-500/30 text-green-400 rounded-full font-medium ${getSizeClasses()} ${className}`}>
      <CheckCircle className={getIconSize()} />
      <span>In Stock</span>
      {showQuantity && product.stock_quantity <= 20 && (
        <span className="text-green-300">({product.stock_quantity})</span>
      )}
    </div>
  );
}

// Stock status pill for admin/management views
export function StockStatusPill({ product }: { product: Product }) {
  const getStatusColor = () => {
    if (!product.in_stock) return 'bg-red-100 text-red-800 border-red-200';
    if (product.stock_status === 'low_stock') return 'bg-orange-100 text-orange-800 border-orange-200';
    return 'bg-green-100 text-green-800 border-green-200';
  };

  return (
    <span className={`inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium border ${getStatusColor()}`}>
      <Package className="w-3 h-3" />
      {product.stock_description}
    </span>
  );
}