// types/shop.ts

export interface ProductImage {
  url: string;
  alt?: string;
  thumbnail?: string;
}

export interface Product {
  id: string;
  name: string;
  description: string;
  detailed_description?: string;
  price: number;
  active: boolean;
  image?: ProductImage | string; // Support both formats
  category: string;
  features: string[];
  device_type?: string;
  stripe_price_id?: string;
  created_at?: string;
  updated_at?: string;
  
  // Stock management (new)
  in_stock: boolean;
  stock_quantity: number;
  stock_status: 'in_stock' | 'low_stock' | 'out_of_stock';
  stock_description: string;
  low_stock_threshold: number;
  featured: boolean;
  
  // Related data (new)
  specifications?: any;
  related_products?: Product[];
}

export interface CartItem {
  id: string;
  product: Product;
  quantity: number;
  subtotal: number;
}

export interface Cart {
  items: CartItem[];
  total: number;
  count: number;
}

// Order related types
export interface LineItem {
  id: string;
  product_id: string;
  product_name: string;
  quantity: number;
  price: number;
  subtotal: number;
}

export interface Order {
  id: string;
  user_id: string;
  status: 'pending' | 'paid' | 'completed' | 'refunded';
  total: number;
  created_at: string;
  updated_at: string;
  line_items: LineItem[];
}

// Checkout types
export interface CheckoutSession {
  id: string;
  checkout_url: string;
  session_id: string;
  status: string;
}

// API Response types
export interface ApiResponse<T = any> {
  status: 'success' | 'error';
  data?: T;
  message?: string;
  errors?: string[];
  error?: string; // Additional error field for consistency
}

export interface ProductsResponse {
  products: Product[];
  total: number;
  page?: number;
  per_page?: number;
  categories: string[];
  filters: ShopFilters;
}

// Enhanced filter types with stock management
export interface ProductFilters {
  category?: string;
  min_price?: number;
  max_price?: number;
  search?: string;
  active?: boolean;
  device_type?: string;
  in_stock?: boolean;
  stock_status?: 'in_stock' | 'low_stock' | 'out_of_stock';
  sort?: 'price_asc' | 'price_desc' | 'name_asc' | 'name_desc' | 'newest' | 'stock_asc' | 'stock_desc';
}

// New shop filters for enhanced API response
export interface ShopFilters {
  categories: string[];
  price_range: {
    min: string | number;
    max: string | number;
  };
  stock_info: {
    total_products: number;
    in_stock: number;
    low_stock: number;
    out_of_stock: number;
  };
}

// New stock checking response
export interface StockCheckResponse {
  product_id: string;
  available: boolean;
  stock_quantity: number;
  requested_quantity: number;
  stock_status: string;
  stock_description: string;
}

// Enhanced context type
export interface ShopContextType {
  // Products
  products: Product[];
  featuredProducts: Product[];
  loading: boolean;
  error: string | null;
  
  // Cart state
  cart: Cart;
  isCartOpen: boolean;
  
  // Actions
  fetchProducts?: (filters?: ProductFilters) => Promise<Product[]>;
  fetchFeaturedProducts: () => Promise<void>;
  checkStock: (productId: string, quantity: number) => Promise<StockCheckResponse>;
  addToCart: (product: Product, quantity?: number) => Promise<void>;
  removeFromCart: (productId: string) => void;
  updateQuantity: (productId: string, quantity: number) => void;
  clearCart: () => void;
  openCart: () => void;
  closeCart: () => void;
}

// Component Props
export interface ProductGridProps {
  products: Product[];
  loading: boolean;
  onAddToCart: (product: Product) => Promise<void>; // Updated to async
  filters?: ProductFilters;
}

export interface CartSidebarProps {
  isOpen: boolean;
  onClose: () => void;
  items: CartItem[];
  onUpdateQuantity: (productId: string, quantity: number) => void;
  onRemoveItem: (productId: string) => void;
  onCheckout: () => void;
}

export interface ShopNavHeaderProps {
  cartCount?: number;
  onCartOpen?: () => void;
}

// Checkout related
export interface CheckoutProps {
  cart: Cart;
  onSuccess: (session: CheckoutSession) => void;
  onError: (error: string) => void;
}

// Enhanced product card props
export interface ProductCardProps {
  product: Product;
  onAddToCart: (product: Product) => Promise<void>; // Updated to async
  loading?: boolean;
  showFeatures?: boolean;
  compact?: boolean;
  showStock?: boolean; // New prop for stock display
  addingToCart?: boolean; // New prop for loading state
}

// New stock indicator props
export interface StockIndicatorProps {
  product: Product;
  size?: 'sm' | 'md' | 'lg';
  showQuantity?: boolean;
  className?: string;
}

// Admin/Management types
export interface InventoryItem {
  product_id: string;
  product_name: string;
  current_stock: number;
  low_stock_threshold: number;
  status: 'in_stock' | 'low_stock' | 'out_of_stock';
  last_updated: string;
}

export interface StockMovement {
  id: string;
  product_id: string;
  movement_type: 'sale' | 'restock' | 'adjustment' | 'return';
  quantity_change: number;
  previous_quantity: number;
  new_quantity: number;
  reason?: string;
  created_at: string;
}

// Featured products response
export interface FeaturedProductsResponse {
  products: Product[];
}

// Error handling
export interface ShopError {
  code: string;
  message: string;
  details?: any;
}