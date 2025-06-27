// components/shop/cart/CartIcon.tsx
'use client';

import { ShoppingCart } from 'lucide-react';

interface CartIconProps {
  itemCount: number;
  onClick: () => void;
  className?: string;
}

export function CartIcon({ itemCount, onClick, className = '' }: CartIconProps) {
  return (
    <button
      onClick={onClick}
      className={`relative p-2 text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white transition-colors ${className}`}
    >
      <ShoppingCart className="w-6 h-6" />
      
      {itemCount > 0 && (
        <>
          {/* Badge */}
          <span className="absolute -top-1 -right-1 bg-blue-600 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center font-medium">
            {itemCount > 99 ? '99+' : itemCount}
          </span>
          
          {/* Pulse animation when items are added */}
          <span className="absolute -top-1 -right-1 bg-blue-600 rounded-full w-5 h-5 animate-ping opacity-75" />
        </>
      )}
    </button>
  );
}