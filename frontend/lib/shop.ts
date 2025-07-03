// lib/api/shop.ts

import { 
  Product, 
  Cart, 
  Order, 
  CheckoutSession, 
  ApiResponse, 
  ProductFilters,
  ProductsResponse 
} from '@/types/shop';

class ShopAPI {
  private baseURL: string;
  private headers: HeadersInit;

  constructor() {
    this.baseURL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000';
    this.headers = {
      'Content-Type': 'application/json',
    };
  }

  private async request<T>(
    endpoint: string, 
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    const token = typeof window !== 'undefined' ? localStorage.getItem('token') : null;
    
    const url = `${this.baseURL}/api/v1/store${endpoint}`;
    const config: RequestInit = {
      credentials: 'include', // Include cookies for session
      headers: {
        ...this.headers,
        ...(token && { Authorization: `Bearer ${token}` }),
        ...options.headers,
      },
      ...options,
    };

    try {
      console.log(`🌐 API Request: ${options.method || 'GET'} ${url}`);
      const response = await fetch(url, config);
      
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.message || `HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      console.log(`✅ API Success:`, data);
      return data;
    } catch (error) {
      console.error('❌ API request failed:', error);
      throw error;
    }
  }

  // Product operations
  async getProducts(filters?: ProductFilters): Promise<ProductsResponse> {
    const params = new URLSearchParams();
    
    if (filters?.category && filters.category !== 'all') {
      params.append('category', filters.category);
    }
    if (filters?.search) params.append('search', filters.search);
    if (filters?.min_price) params.append('min_price', filters.min_price.toString());
    if (filters?.max_price) params.append('max_price', filters.max_price.toString());
    if (filters?.in_stock !== undefined) params.append('in_stock', filters.in_stock.toString());

    const queryString = params.toString();
    const endpoint = queryString ? `/products?${queryString}` : '/products';
    
    const response = await this.request<ProductsResponse>(endpoint);
    return response.data!;
  }

  async getProduct(id: string): Promise<Product> {
    const response = await this.request<{ product: Product }>(`/products/${id}`);
    return response.data!.product;
  }

  async getFeaturedProducts(): Promise<Product[]> {
    const response = await this.request<{ products: Product[] }>('/products/featured');
    return response.data!.products;
  }

  // Cart operations
  async getCart(): Promise<Cart> {
    try {
      const response = await this.request<Cart>('/cart');
      return response.data!;
    } catch (error) {
      // Return empty cart if no cart exists
      console.log('No existing cart, returning empty cart');
      return { items: [], total: 0, count: 0 };
    }
  }

  async addToCart(productId: string, quantity: number = 1): Promise<Cart> {
    const response = await this.request<Cart>('/cart/add', {
      method: 'POST',
      body: JSON.stringify({ product_id: productId, quantity }),
    });
    return response.data!;
  }

  async removeFromCart(productId: string): Promise<Cart> {
    const response = await this.request<Cart>('/cart/remove', {
      method: 'DELETE',
      body: JSON.stringify({ product_id: productId }),
    });
    return response.data!;
  }

  async updateCartQuantity(productId: string, quantity: number): Promise<Cart> {
    const response = await this.request<Cart>('/cart/update_quantity', {
      method: 'PATCH',
      body: JSON.stringify({ product_id: productId, quantity }),
    });
    return response.data!;
  }

  async clearCart(): Promise<void> {
    await this.request('/cart/clear', { method: 'DELETE' });
  }

  // Checkout operations
  async createCheckoutSession(): Promise<CheckoutSession> {
    const response = await this.request<CheckoutSession>('/checkout', {
      method: 'POST',
    });
    return response.data!;
  }

  // Order operations
  async getOrders(): Promise<Order[]> {
    const response = await this.request<{ orders: Order[] }>('/orders');
    return response.data!.orders;
  }

  async getOrder(id: string): Promise<Order> {
    const response = await this.request<{ order: Order }>(`/orders/${id}`);
    return response.data!.order;
  }
}

export const shopAPI = new ShopAPI();