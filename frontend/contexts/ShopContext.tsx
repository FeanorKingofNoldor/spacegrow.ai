// contexts/ShopContext.tsx
'use client';

import { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { Product, Cart, CartItem, ApiResponse, ProductsResponse, StockCheckResponse } from '@/types/shop';

interface ShopContextType {
  // Products
  products: Product[];
  featuredProducts: Product[];
  loading: boolean;
  error: string | null;
  
  // Cart
  cart: Cart;
  isCartOpen: boolean;
  
  // Actions
  fetchProducts: () => Promise<void>;
  fetchFeaturedProducts: () => Promise<void>;
  checkStock: (productId: string, quantity: number) => Promise<StockCheckResponse>;
  addToCart: (product: Product, quantity?: number) => Promise<void>;
  removeFromCart: (productId: string) => void;
  updateQuantity: (productId: string, quantity: number) => void;
  clearCart: () => void;
  openCart: () => void;
  closeCart: () => void;
}

const ShopContext = createContext<ShopContextType | undefined>(undefined);

export function ShopProvider({ children }: { children: React.ReactNode }) {
  // State
  const [products, setProducts] = useState<Product[]>([]);
  const [featuredProducts, setFeaturedProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [cart, setCart] = useState<Cart>({ items: [], total: 0, count: 0 });
  const [isCartOpen, setIsCartOpen] = useState(false);

  // Load cart from localStorage on mount
  useEffect(() => {
    const savedCart = localStorage.getItem('xspacegrow_cart');
    if (savedCart) {
      try {
        const parsedCart = JSON.parse(savedCart);
        setCart(parsedCart);
      } catch (error) {
        console.error('Failed to load cart from localStorage:', error);
        localStorage.removeItem('xspacegrow_cart');
      }
    }
  }, []);

  // Save cart to localStorage whenever cart changes
  useEffect(() => {
    localStorage.setItem('xspacegrow_cart', JSON.stringify(cart));
  }, [cart]);

  // Recalculate cart totals
  const recalculateCart = useCallback((items: CartItem[]): Cart => {
    const total = items.reduce((sum, item) => sum + item.subtotal, 0);
    const count = items.reduce((sum, item) => sum + item.quantity, 0);
    return { items, total, count };
  }, []);

  // Fetch products from API
  const fetchProducts = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      console.log('🔄 Fetching products from API...');
      
      // Use relative URL - Next.js proxy will handle the routing
      const response = await fetch('/api/v1/store/products');
      
      console.log('🌐 Fetching from: /api/v1/store/products');
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      console.log('📦 Raw API Response:', data);
      
      // Parse response according to your Rails API structure
      if (data.status === 'success' && data.data && data.data.products) {
        console.log('✅ Found products:', data.data.products.length);
        setProducts(data.data.products);
      } else {
        console.warn('⚠️ Unexpected API response structure:', data);
        throw new Error(data.message || 'No products found in response');
      }
    } catch (error) {
      console.error('❌ Failed to fetch products:', error);
      setError(error instanceof Error ? error.message : 'Failed to fetch products');
      setProducts([]);
    } finally {
      setLoading(false);
    }
  }, []);

  // Fetch featured products
  const fetchFeaturedProducts = useCallback(async () => {
    try {
      console.log('🔄 Fetching featured products...');
      
      // Use the dedicated featured endpoint with relative URL
      const response = await fetch('/api/v1/store/products/featured');
      
      if (!response.ok) {
        console.warn('Featured endpoint not available, falling back to regular products');
        // Fallback to regular products endpoint
        const fallbackResponse = await fetch('/api/v1/store/products');
        if (!fallbackResponse.ok) {
          throw new Error(`HTTP error! status: ${fallbackResponse.status}`);
        }
        const data = await fallbackResponse.json();
        if (data.status === 'success' && data.data && data.data.products) {
          const featured = data.data.products.slice(0, 3);
          console.log('✅ Found featured products (fallback):', featured.length);
          setFeaturedProducts(featured);
        }
        return;
      }
      
      const data = await response.json();
      
      if (data.status === 'success' && data.data && data.data.products) {
        console.log('✅ Found featured products:', data.data.products.length);
        setFeaturedProducts(data.data.products);
      }
    } catch (error) {
      console.error('❌ Failed to fetch featured products:', error);
    }
  }, []);

  // Check stock availability - MOCK for now since endpoint doesn't exist
  const checkStock = useCallback(async (productId: string, quantity: number): Promise<StockCheckResponse> => {
    // Mock implementation - replace with real API call when available
    console.log(`🔍 Checking stock for product ${productId}, quantity: ${quantity}`);
    
    return {
      available: true,
      stock_quantity: 999,
      product_id: productId,
      requested_quantity: quantity,
      stock_status: 'in_stock',
      stock_description: 'In stock'
    };
  }, []);

const addToCart = useCallback(async (product: Product, quantity: number = 1) => {
  try {
    console.log('🛒 Adding to cart:', product.name, 'x', quantity);
    console.log('🛒 Current cart before:', cart);
    
    // Check if product is active (since we don't have stock_quantity in the current API)
    if (!product.active) {
      throw new Error('Product is not available');
    }

    // Check current cart quantity for this product
    const existingItem = cart.items.find(item => item.product.id === product.id);
    const currentCartQuantity = existingItem ? existingItem.quantity : 0;
    const totalRequestedQuantity = currentCartQuantity + quantity;

    // Check stock availability for total quantity
    const stockCheck = await checkStock(product.id, totalRequestedQuantity);
    
    if (!stockCheck.available) {
      throw new Error(`Only ${stockCheck.stock_quantity} items available. You have ${currentCartQuantity} in cart.`);
    }

    // Add to cart
    setCart(prevCart => {
      console.log('🛒 Previous cart state:', prevCart);
      
      const existingItemIndex = prevCart.items.findIndex(item => item.product.id === product.id);
      let newItems: CartItem[];

      if (existingItemIndex >= 0) {
        // Update existing item
        newItems = [...prevCart.items];
        newItems[existingItemIndex] = {
          ...newItems[existingItemIndex],
          quantity: newItems[existingItemIndex].quantity + quantity,
          subtotal: (newItems[existingItemIndex].quantity + quantity) * product.price
        };
        console.log('🛒 Updated existing item:', newItems[existingItemIndex]);
      } else {
        // Add new item
        const newItem: CartItem = {
          id: product.id,
          product,
          quantity,
          subtotal: quantity * product.price
        };
        newItems = [...prevCart.items, newItem];
        console.log('🛒 Added new item:', newItem);
      }

      const updatedCart = recalculateCart(newItems);
      console.log('🛒 New cart state:', updatedCart);
      return updatedCart;
    });

    console.log('🛒 About to open cart...');
    // Auto-open cart for user feedback
    setIsCartOpen(true);
    console.log('✅ Cart opened successfully');
    console.log('✅ Added to cart successfully');
    
  } catch (error) {
    console.error('❌ Failed to add to cart:', error);
    throw error; // Re-throw so component can handle the error
  }
}, [cart.items, checkStock, recalculateCart]);

  // Remove from cart
  const removeFromCart = useCallback((productId: string) => {
    console.log('🗑️ Removing from cart:', productId);
    setCart(prevCart => {
      const newItems = prevCart.items.filter(item => item.product.id !== productId);
      return recalculateCart(newItems);
    });
  }, [recalculateCart]);

  // Update quantity
  const updateQuantity = useCallback(async (productId: string, quantity: number) => {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    try {
      console.log('📝 Updating quantity:', productId, 'to', quantity);
      
      // Find the product
      const cartItem = cart.items.find(item => item.product.id === productId);
      if (!cartItem) return;

      // Check stock availability
      const stockCheck = await checkStock(productId, quantity);
      
      if (!stockCheck.available) {
        throw new Error(`Only ${stockCheck.stock_quantity} items available`);
      }

      // Update quantity
      setCart(prevCart => {
        const newItems = prevCart.items.map(item => 
          item.product.id === productId
            ? { ...item, quantity, subtotal: quantity * item.product.price }
            : item
        );
        return recalculateCart(newItems);
      });
      
    } catch (error) {
      console.error('❌ Failed to update quantity:', error);
      throw error;
    }
  }, [cart.items, checkStock, recalculateCart, removeFromCart]);

  // Clear cart
  const clearCart = useCallback(() => {
    console.log('🧹 Clearing cart');
    setCart({ items: [], total: 0, count: 0 });
  }, []);

  // Cart visibility
  const openCart = useCallback(() => {
    console.log('👀 Opening cart');
    setIsCartOpen(true);
  }, []);
  
  const closeCart = useCallback(() => {
    console.log('👋 Closing cart');
    setIsCartOpen(false);
  }, []);

  // Load products on mount
  useEffect(() => {
    fetchProducts();
    fetchFeaturedProducts();
  }, [fetchProducts, fetchFeaturedProducts]);

  const value: ShopContextType = {
    // Products
    products,
    featuredProducts,
    loading,
    error,
    
    // Cart
    cart,
    isCartOpen,
    
    // Actions
    fetchProducts,
    fetchFeaturedProducts,
    checkStock,
    addToCart,
    removeFromCart,
    updateQuantity,
    clearCart,
    openCart,
    closeCart,
  };

  return (
    <ShopContext.Provider value={value}>
      {children}
    </ShopContext.Provider>
  );
}

export function useShop() {
  const context = useContext(ShopContext);
  if (context === undefined) {
    throw new Error('useShop must be used within a ShopProvider');
  }
  return context;
}