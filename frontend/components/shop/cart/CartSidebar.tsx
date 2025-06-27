// components/shop/cart/CartSidebar.tsx
import { CartItem } from '@/types/shop';
import { X, Plus, Minus, ShoppingBag } from 'lucide-react';

interface CartSidebarProps {
  isOpen: boolean;
  onClose: () => void;
  items: CartItem[];
  onUpdateQuantity: (productId: string, quantity: number) => void;
  onRemoveItem: (productId: string) => void;
  onCheckout: () => void;
}

// Helper functions (add these at the top of your file)
const getImageUrl = (image: string | { url: string; alt?: string; thumbnail?: string } | undefined): string | undefined => {
  if (!image) return undefined;
  if (typeof image === 'string') return image;
  return image.url;
};

const getImageAlt = (image: string | { url: string; alt?: string; thumbnail?: string } | undefined, fallback: string = ''): string => {
  if (!image || typeof image === 'string') return fallback;
  return image.alt || fallback;
};

export function CartSidebar({ 
  isOpen, 
  onClose, 
  items, 
  onUpdateQuantity, 
  onRemoveItem, 
  onCheckout 
}: CartSidebarProps) {
  const total = items.reduce((sum, item) => sum + item.subtotal, 0);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 overflow-hidden">
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black bg-opacity-50" onClick={onClose} />
      
      {/* Sidebar */}
      <div className="absolute right-0 top-0 h-full w-full max-w-md bg-white shadow-xl">
        <div className="flex h-full flex-col">
          {/* Header */}
          <div className="flex items-center justify-between p-4 border-b">
            <h2 className="text-lg font-semibold flex items-center gap-2">
              <ShoppingBag className="w-5 h-5" />
              Shopping Cart ({items.length})
            </h2>
            <button
              onClick={onClose}
              className="p-2 hover:bg-gray-100 rounded-full"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Cart Items */}
          <div className="flex-1 overflow-y-auto p-4">
            {items.length === 0 ? (
              <div className="text-center py-8">
                <ShoppingBag className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                <p className="text-gray-500">Your cart is empty</p>
              </div>
            ) : (
              <div className="space-y-4">
                {items.map((item) => {
                  const imageSrc = getImageUrl(item.product.image);
                  const imageAlt = getImageAlt(item.product.image, item.product.name);

                  return (
                    <div key={item.id} className="flex gap-3 p-3 border rounded-lg">
                      {/* Product Image */}
                      <div className="w-16 h-16 bg-gray-200 rounded-lg flex items-center justify-center overflow-hidden">
                        {imageSrc ? (
                          <img 
                            src={imageSrc} 
                            alt={imageAlt}
                            className="w-full h-full object-cover"
                          />
                        ) : (
                          <div className="text-2xl">
                            {item.product.category === 'environmental' ? '🌡️' : 
                             item.product.category === 'liquid' ? '💧' : '📦'}
                          </div>
                        )}
                      </div>

                      {/* Product Details */}
                      <div className="flex-1">
                        <h3 className="font-medium text-sm">{item.product.name}</h3>
                        <p className="text-gray-600 text-xs">${item.product.price}</p>
                        
                        {/* Quantity Controls */}
                        <div className="flex items-center gap-2 mt-2">
                          <button
                            onClick={() => onUpdateQuantity(item.product.id, item.quantity - 1)}
                            disabled={item.quantity <= 1}
                            className="p-1 hover:bg-gray-100 rounded disabled:opacity-50"
                          >
                            <Minus className="w-3 h-3" />
                          </button>
                          <span className="text-sm font-medium w-8 text-center">{item.quantity}</span>
                          <button
                            onClick={() => onUpdateQuantity(item.product.id, item.quantity + 1)}
                            className="p-1 hover:bg-gray-100 rounded"
                          >
                            <Plus className="w-3 h-3" />
                          </button>
                          <button
                            onClick={() => onRemoveItem(item.product.id)}
                            className="ml-auto text-red-500 hover:text-red-700 text-xs"
                          >
                            Remove
                          </button>
                        </div>
                      </div>

                      {/* Item Total */}
                      <div className="text-right">
                        <p className="font-medium">${item.subtotal.toFixed(2)}</p>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          {/* Footer */}
          {items.length > 0 && (
            <div className="border-t p-4 space-y-4">
              <div className="flex justify-between text-lg font-semibold">
                <span>Total:</span>
                <span>${total.toFixed(2)}</span>
              </div>
              <button
                onClick={onCheckout}
                className="w-full bg-blue-600 hover:bg-blue-700 text-white py-3 px-4 rounded-lg font-medium transition-colors"
              >
                Proceed to Checkout
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}