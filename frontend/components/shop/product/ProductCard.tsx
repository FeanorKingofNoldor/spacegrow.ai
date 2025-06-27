// components/shop/product/ProductCard.tsx
import { Product } from '@/types/shop';

interface ProductCardProps {
  product: Product;
  onAddToCart: (product: Product) => void;
  loading?: boolean;
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

export function ProductCard({ product, onAddToCart, loading }: ProductCardProps) {
  const imageSrc = getImageUrl(product.image);
  const imageAlt = getImageAlt(product.image, product.name);

  return (
    <div className="product-card bg-white rounded-lg shadow-md overflow-hidden">
      {/* Product Image */}
      <div className="w-full h-48 bg-gray-200 flex items-center justify-center">
        {imageSrc ? (
          <img 
            src={imageSrc} 
            alt={imageAlt}
            className="w-full h-full object-cover"
          />
        ) : (
          <div className="text-4xl">
            {product.category === 'environmental' ? '🌡️' : 
             product.category === 'liquid' ? '💧' : '📦'}
          </div>
        )}
      </div>

      {/* Product Info */}
      <div className="p-4">
        <h3 className="text-lg font-semibold text-gray-900 mb-2">{product.name}</h3>
        <p className="text-gray-600 text-sm mb-3 line-clamp-2">{product.description}</p>
        
        {/* Features */}
        {product.features && product.features.length > 0 && (
          <div className="mb-3">
            <div className="flex flex-wrap gap-1">
              {product.features.slice(0, 3).map((feature, index) => (
                <span 
                  key={index}
                  className="text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded"
                >
                  {feature}
                </span>
              ))}
            </div>
          </div>
        )}

        {/* Price and Stock */}
        <div className="flex items-center justify-between mb-3">
          <span className="text-xl font-bold text-gray-900">${product.price}</span>
          <span className={`text-sm ${product.in_stock ? 'text-green-600' : 'text-red-600'}`}>
            {product.in_stock ? 'In Stock' : 'Out of Stock'}
          </span>
        </div>

        {/* Add to Cart Button */}
        <button
          onClick={() => onAddToCart(product)}
          disabled={!product.in_stock || loading}
          className={`w-full py-2 px-4 rounded-lg font-medium transition-colors ${
            product.in_stock && !loading
              ? 'bg-blue-600 hover:bg-blue-700 text-white'
              : 'bg-gray-300 text-gray-500 cursor-not-allowed'
          }`}
        >
          {loading ? 'Adding...' : !product.in_stock ? 'Out of Stock' : 'Add to Cart'}
        </button>
      </div>
    </div>
  );
}