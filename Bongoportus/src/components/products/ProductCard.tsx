import React, { useState } from 'react';
import { Product } from '../../types';
import { ShoppingCart, Heart, Star, TrendingUp, MessageCircle } from 'lucide-react';
import { useCartStore } from '../../store/cartStore';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { ProductDetailsModal } from './ProductDetailsModal';

interface ProductCardProps {
  product: Product;
}

export const ProductCard: React.FC<ProductCardProps> = ({ product }) => {
  const addItem = useCartStore((state) => state.addItem);
  const { user } = useAuth();
  const navigate = useNavigate();
  const [isInWishlist, setIsInWishlist] = useState(false);
  const [imageLoaded, setImageLoaded] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const [modalTab, setModalTab] = useState<'details' | 'chat'>('details');
  const [imageError, setImageError] = useState(false);

  const displayPrice = product.discount_price || product.price;
  const hasDiscount = product.discount_price && product.discount_price < product.price;
  const primaryImage =
    product.images?.find((img) => img.is_primary)?.image_url ||
    product.images?.[0]?.image_url ||
    `https://picsum.photos/seed/${product.slug}/400/400`;
  
  const fallbackImage = `https://picsum.photos/seed/${product.slug || 'product'}/400/400`;

  const handleAddToCart = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    addItem(product);
  };

  const handleChat = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    
    if (!user) {
      navigate('/login');
      return;
    }
    
    setModalTab('chat');
    setShowModal(true);
  };

  const handleProductClick = () => {
    setModalTab('details');
    setShowModal(true);
  };

  const handleToggleWishlist = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsInWishlist(!isInWishlist);
  };

  const handleImageError = () => {
    setImageError(true);
    setImageLoaded(true);
  };

  return (
    <>
      <div
        onClick={handleProductClick}
        className="group bg-white rounded-2xl shadow-sm hover:shadow-2xl transition-all duration-300 overflow-hidden border border-gray-100 hover:border-blue-200 hover:-translate-y-2 cursor-pointer"
      >
      <div className="relative aspect-square overflow-hidden bg-gradient-to-br from-gray-100 to-gray-50">
        {!imageLoaded && (
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="animate-spin rounded-full h-10 w-10 border-4 border-blue-200 border-t-blue-600"></div>
          </div>
        )}
        <img
          src={imageError ? fallbackImage : primaryImage}
          alt={product.name}
          onLoad={() => setImageLoaded(true)}
          onError={handleImageError}
          className={`w-full h-full object-cover group-hover:scale-110 transition-transform duration-500 ${imageLoaded ? 'opacity-100' : 'opacity-0'}`}
        />
        
        {/* Badges */}
        <div className="absolute top-3 left-3 flex flex-col gap-2">
          {hasDiscount && (
            <div className="bg-gradient-to-r from-red-500 to-pink-600 text-white px-3 py-1.5 rounded-lg text-xs font-bold shadow-lg flex items-center gap-1">
              <TrendingUp size={12} />
              {product.discount_percentage?.toFixed(0)}% OFF
            </div>
          )}
          {product.is_featured && (
            <div className="bg-gradient-to-r from-yellow-400 to-orange-500 text-white px-3 py-1.5 rounded-lg text-xs font-bold shadow-lg">
              ⭐ Featured
            </div>
          )}
          {product.stock_quantity < 10 && product.stock_quantity > 0 && (
            <div className="bg-orange-500 text-white px-3 py-1.5 rounded-lg text-xs font-bold shadow-lg">
              Only {product.stock_quantity} left
            </div>
          )}
        </div>

        {/* Action Buttons */}
        <div className="absolute top-3 right-3 flex flex-col gap-2 opacity-0 group-hover:opacity-100 transition-all duration-300">
          <button
            onClick={handleToggleWishlist}
            className="p-2.5 bg-white/95 backdrop-blur-sm rounded-xl shadow-lg hover:bg-white hover:scale-110 transition-all duration-200"
            title="Add to Wishlist"
          >
            <Heart
              size={18}
              className={isInWishlist ? 'fill-red-500 text-red-500' : 'text-gray-700'}
            />
          </button>
        </div>

        {/* Quick View Overlay */}
        <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/60 to-transparent p-4 opacity-0 group-hover:opacity-100 transition-all duration-300 translate-y-2 group-hover:translate-y-0">
          <button
            onClick={handleAddToCart}
            disabled={product.stock_quantity === 0}
            className="w-full flex items-center justify-center gap-2 bg-white text-blue-600 hover:bg-blue-50 py-2.5 px-4 rounded-xl transition-all duration-200 font-bold text-sm shadow-lg disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <ShoppingCart size={18} />
            Quick Add
          </button>
        </div>
      </div>

      <div className="p-5">
        {product.category && (
          <div className="text-xs text-blue-600 font-semibold mb-1 uppercase tracking-wider">
            {product.category.name}
          </div>
        )}
        <h3 className="text-sm font-semibold text-gray-900 line-clamp-2 mb-3 min-h-[40px] group-hover:text-blue-600 transition-colors">
          {product.name}
        </h3>

        <div className="flex items-center gap-2 mb-3">
          <div className="flex items-center gap-0.5">
            {[1, 2, 3, 4, 5].map((star) => (
              <Star
                key={star}
                size={14}
                className={
                  star <= product.rating
                    ? 'fill-yellow-400 text-yellow-400'
                    : 'fill-gray-200 text-gray-200'
                }
              />
            ))}
          </div>
          <span className="text-xs text-gray-500 font-medium">
            {product.rating.toFixed(1)} ({product.total_reviews})
          </span>
        </div>

        <div className="flex items-center justify-between mb-4">
          <div className="flex items-baseline gap-2">
            <span className="text-xl font-bold text-blue-600">
              ৳{displayPrice.toLocaleString()}
            </span>
            {hasDiscount && (
              <span className="text-sm text-gray-400 line-through">
                ৳{product.price.toLocaleString()}
              </span>
            )}
          </div>
          {product.stock_quantity > 0 && product.stock_quantity < 20 && (
            <span className="text-xs text-orange-600 font-semibold bg-orange-50 px-2 py-1 rounded">
              Low Stock
            </span>
          )}
        </div>

        {product.stock_quantity > 0 ? (
          <div className="flex gap-2">
            <button
              onClick={handleAddToCart}
              className="flex-1 flex items-center justify-center gap-2 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white py-3 px-4 rounded-xl transition-all duration-200 text-sm font-bold shadow-md hover:shadow-lg transform hover:scale-[1.02]"
            >
              <ShoppingCart size={16} />
              Add to Cart
            </button>
            <button
              onClick={handleChat}
              className="flex items-center justify-center gap-2 bg-white border-2 border-blue-100 hover:border-blue-300 text-blue-600 py-3 px-3 rounded-xl transition-all duration-200 shadow-sm hover:shadow-md"
              title="Chat with Admin"
            >
              <MessageCircle size={20} />
            </button>
          </div>
        ) : (
          <button
            disabled
            className="w-full bg-gray-100 text-gray-400 py-3 px-4 rounded-xl text-sm font-bold cursor-not-allowed"
          >
            Out of Stock
          </button>
        )}
      </div>
    </div>

    {showModal && (
      <ProductDetailsModal
        product={product}
        initialTab={modalTab}
        onClose={() => setShowModal(false)}
      />
    )}
  </>
  );
};
