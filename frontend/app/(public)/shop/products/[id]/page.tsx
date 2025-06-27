// app/(public)/shop/products/[id]/page.tsx
'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useShop } from '@/contexts/ShopContext';
import { Product } from '@/types/shop';
import { 
  ArrowLeft, 
  Star, 
  Shield, 
  Truck, 
  RefreshCw, 
  Check,
  Plus,
  Minus,
  ShoppingCart,
  Loader2
} from 'lucide-react';
import { getImageUrl, getImageAlt } from '@/app/utils/imageHelpers';

export default function ProductDetailPage() {
  const params = useParams();
  const router = useRouter();
  const { addToCart, openCart } = useShop();
  
  const [product, setProduct] = useState<Product | null>(null);
  const [loading, setLoading] = useState(true);
  const [quantity, setQuantity] = useState(1);
  const [addingToCart, setAddingToCart] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (params.id) {
      fetchProduct(params.id as string);
    }
  }, [params.id]);

  const fetchProduct = async (id: string) => {
    try {
      setLoading(true);
      const response = await fetch(`/api/v1/store/products/${id}`);
      
      if (!response.ok) {
        throw new Error('Product not found');
      }
      
      const data = await response.json();
      
      if (data.status === 'success' && data.data) {
        setProduct(data.data.product || data.data);
      } else {
        throw new Error('Product not found');
      }
    } catch (err) {
      console.error('Error fetching product:', err);
      setError('Product not found');
    } finally {
      setLoading(false);
    }
  };

  const handleAddToCart = async () => {
    if (!product) return;
    
    try {
      setAddingToCart(true);
      await addToCart(product, quantity);
      
      // Show success feedback
      const button = document.getElementById('add-to-cart-btn');
      if (button) {
        const originalText = button.textContent;
        button.textContent = 'Added to Cart!';
        setTimeout(() => {
          button.textContent = originalText;
        }, 2000);
      }
      
      // Optionally open cart
      // openCart();
      
    } catch (error) {
      console.error('Failed to add to cart:', error);
    } finally {
      setAddingToCart(false);
    }
  };

  const updateQuantity = (change: number) => {
    const newQuantity = quantity + change;
    if (newQuantity >= 1 && newQuantity <= 10) {
      setQuantity(newQuantity);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  if (error || !product) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-gray-900 mb-4">Product Not Found</h1>
          <button
            onClick={() => router.push('/shop')}
            className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors"
          >
            Back to Shop
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 py-8">
        {/* Breadcrumb */}
        <div className="flex items-center gap-2 text-sm text-gray-600 mb-8">
          <button
            onClick={() => router.push('/shop')}
            className="flex items-center gap-1 hover:text-gray-900 transition-colors"
          >
            <ArrowLeft className="w-4 h-4" />
            Back to Shop
          </button>
          <span>/</span>
          <span className="text-gray-900">{product.name}</span>
        </div>

        <div className="grid lg:grid-cols-2 gap-12">
          {/* Product Images */}
          <div className="space-y-4">
            <div className="aspect-square bg-white rounded-lg shadow-sm overflow-hidden">
              {getImageUrl(product.image) ? (
                <img
                  src={getImageUrl(product.image)!}
                  alt={getImageAlt(product.image, product.name)}
                  className="w-full h-full object-cover"
                />
              ) : (
                <div className="w-full h-full flex items-center justify-center bg-gray-100">
                  <div className="text-center">
                    <div className="text-8xl mb-4">
                      {product.category === 'environmental' ? '🌡️' : 
                       product.category === 'liquid' ? '💧' : '📦'}
                    </div>
                    <p className="text-gray-500">Product Image</p>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Product Info */}
          <div className="space-y-6">
            {/* Category */}
            <div>
              <span className="inline-block bg-blue-100 text-blue-800 text-sm font-medium px-3 py-1 rounded-full">
                {product.category}
              </span>
            </div>

            {/* Title and Price */}
            <div>
              <h1 className="text-3xl font-bold text-gray-900 mb-2">{product.name}</h1>
              <div className="flex items-center gap-4">
                <span className="text-3xl font-bold text-blue-600">${product.price}</span>
                <span className={`text-sm font-medium ${product.in_stock ? 'text-green-600' : 'text-red-600'}`}>
                  {product.in_stock ? 'In Stock' : 'Out of Stock'}
                </span>
              </div>
            </div>

            {/* Rating (placeholder) */}
            <div className="flex items-center gap-2">
              <div className="flex">
                {[1, 2, 3, 4, 5].map((star) => (
                  <Star key={star} className="w-5 h-5 text-yellow-400 fill-current" />
                ))}
              </div>
              <span className="text-sm text-gray-600">(4.8 out of 5 from 127 reviews)</span>
            </div>

            {/* Description */}
            <div>
              <p className="text-gray-700 leading-relaxed">{product.description}</p>
            </div>

            {/* Features */}
            {product.features && product.features.length > 0 && (
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-3">Key Features</h3>
                <ul className="space-y-2">
                  {product.features.map((feature, index) => (
                    <li key={index} className="flex items-center gap-2">
                      <Check className="w-5 h-5 text-green-600" />
                      <span className="text-gray-700">{feature}</span>
                    </li>
                  ))}
                </ul>
              </div>
            )}

            {/* Quantity and Add to Cart */}
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Quantity
                </label>
                <div className="flex items-center gap-3">
                  <button
                    onClick={() => updateQuantity(-1)}
                    disabled={quantity <= 1}
                    className="w-10 h-10 rounded-full border border-gray-300 flex items-center justify-center hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <Minus className="w-4 h-4" />
                  </button>
                  <span className="text-lg font-medium w-8 text-center">{quantity}</span>
                  <button
                    onClick={() => updateQuantity(1)}
                    disabled={quantity >= 10}
                    className="w-10 h-10 rounded-full border border-gray-300 flex items-center justify-center hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <Plus className="w-4 h-4" />
                  </button>
                </div>
              </div>

              <button
                id="add-to-cart-btn"
                onClick={handleAddToCart}
                disabled={!product.in_stock || addingToCart}
                className={`w-full py-4 px-6 rounded-lg font-semibold transition-colors flex items-center justify-center gap-2 ${
                  product.in_stock && !addingToCart
                    ? 'bg-blue-600 hover:bg-blue-700 text-white'
                    : 'bg-gray-300 text-gray-500 cursor-not-allowed'
                }`}
              >
                {addingToCart ? (
                  <>
                    <Loader2 className="w-5 h-5 animate-spin" />
                    Adding to Cart...
                  </>
                ) : !product.in_stock ? (
                  'Out of Stock'
                ) : (
                  <>
                    <ShoppingCart className="w-5 h-5" />
                    Add to Cart - ${(product.price * quantity).toFixed(2)}
                  </>
                )}
              </button>
            </div>

            {/* Guarantees */}
            <div className="border-t pt-6 space-y-4">
              <div className="flex items-center gap-3">
                <Truck className="w-5 h-5 text-gray-600" />
                <span className="text-sm text-gray-700">Free shipping on orders over $200</span>
              </div>
              <div className="flex items-center gap-3">
                <Shield className="w-5 h-5 text-gray-600" />
                <span className="text-sm text-gray-700">1-year warranty included</span>
              </div>
              <div className="flex items-center gap-3">
                <RefreshCw className="w-5 h-5 text-gray-600" />
                <span className="text-sm text-gray-700">30-day return policy</span>
              </div>
            </div>
          </div>
        </div>

        {/* Technical Specifications */}
        <div className="mt-16 bg-white rounded-lg shadow-sm p-8">
          <h2 className="text-2xl font-bold text-gray-900 mb-6">Technical Specifications</h2>
          <div className="grid md:grid-cols-2 gap-8">
            <div>
              <h3 className="text-lg font-semibold text-gray-900 mb-4">Sensors Included</h3>
              <ul className="space-y-2">
                {product.features?.map((feature, index) => (
                  <li key={index} className="flex items-center gap-2">
                    <div className="w-2 h-2 bg-blue-600 rounded-full"></div>
                    <span className="text-gray-700">{feature}</span>
                  </li>
                ))}
              </ul>
            </div>
            <div>
              <h3 className="text-lg font-semibold text-gray-900 mb-4">What's in the Box</h3>
              <ul className="space-y-2 text-gray-700">
                <li>• Main monitoring device</li>
                <li>• All sensors and probes</li>
                <li>• Power adapter</li>
                <li>• Quick start guide</li>
                <li>• Calibration solutions</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}