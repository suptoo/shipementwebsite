import React from 'react';
import { useCartStore } from '../store/cartStore';
import { Link, useNavigate } from 'react-router-dom';
import { Trash2, Plus, Minus, ShoppingBag, ArrowLeft, ShieldCheck, Truck, CreditCard } from 'lucide-react';

export const CartPage: React.FC = () => {
  const { items, updateQuantity, removeItem, getTotalItems, getSubtotal } = useCartStore();
  const navigate = useNavigate();

  const subtotal = getSubtotal();
  const shippingCharge = subtotal >= 1000 ? 0 : 50;
  const total = subtotal + shippingCharge;

  if (items.length === 0) {
    return (
      <div className="min-h-[60vh] flex items-center justify-center bg-gray-50 px-4">
        <div className="text-center p-6 sm:p-8">
          <div className="w-20 h-20 sm:w-24 sm:h-24 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4 sm:mb-6">
            <ShoppingBag className="text-gray-400" size={32} />
          </div>
          <h2 className="text-xl sm:text-2xl font-bold text-gray-800 mb-2">Your cart is empty</h2>
          <p className="text-gray-500 mb-6 sm:mb-8 max-w-sm text-sm sm:text-base">
            Explore our products and find something you love!
          </p>
          <Link
            to="/"
            className="inline-flex items-center gap-2 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white px-6 sm:px-8 py-2.5 sm:py-3 rounded-xl font-semibold shadow-lg hover:shadow-xl transition-all text-sm sm:text-base"
          >
            <ArrowLeft size={18} />
            Start Shopping
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-gray-50 min-h-screen py-4 sm:py-8 pb-36 sm:pb-8">
      <div className="max-w-7xl mx-auto px-4">
        {/* Header */}
        <div className="flex items-center justify-between mb-4 sm:mb-8">
          <div>
            <h1 className="text-xl sm:text-2xl md:text-3xl font-bold text-gray-900">Shopping Cart</h1>
            <p className="text-gray-500 mt-0.5 sm:mt-1 text-sm">{getTotalItems()} item{getTotalItems() > 1 ? 's' : ''}</p>
          </div>
          <Link
            to="/"
            className="flex items-center gap-1 sm:gap-2 text-blue-600 hover:text-blue-700 font-medium text-xs sm:text-sm"
          >
            <ArrowLeft size={16} />
            <span className="hidden sm:inline">Continue Shopping</span>
            <span className="sm:hidden">Shop</span>
          </Link>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Cart Items */}
          <div className="lg:col-span-2 space-y-3 sm:space-y-4">
            {items.map((item) => {
              const product = item.product;
              if (!product) return null;

              const price = product.discount_price || product.price;
              const imageUrl =
                product.images?.[0]?.image_url || 'https://via.placeholder.com/150';

              return (
                <div
                  key={item.id}
                  className="bg-white rounded-xl sm:rounded-2xl shadow-sm border border-gray-100 p-3 sm:p-4 md:p-6 flex gap-3 sm:gap-4 md:gap-6 active:scale-[0.99] transition-all"
                >
                  <div className="w-20 h-20 sm:w-24 sm:h-24 md:w-32 md:h-32 rounded-lg sm:rounded-xl overflow-hidden bg-gray-100 flex-shrink-0">
                    <img
                      src={imageUrl}
                      alt={product.name}
                      className="w-full h-full object-cover"
                    />
                  </div>

                  <div className="flex-1 flex flex-col min-w-0">
                    <div className="flex-1">
                      <Link
                        to={`/products/${product.slug}`}
                        className="text-sm sm:text-lg font-semibold text-gray-900 hover:text-blue-600 line-clamp-2 transition-colors"
                      >
                        {product.name}
                      </Link>

                      {item.variant && (
                        <p className="text-xs sm:text-sm text-gray-500 mt-0.5 sm:mt-1">
                          {item.variant.variant_type}: <span className="font-medium text-gray-700">{item.variant.variant_value}</span>
                        </p>
                      )}

                      <p className="text-xs sm:text-sm text-green-600 font-medium mt-1 sm:mt-2 items-center gap-1 hidden sm:flex">
                        <Truck size={14} />
                        In Stock • Ships in 1-2 days
                      </p>
                    </div>

                    <div className="flex items-center justify-between mt-2 sm:mt-4 gap-2">
                      <div className="flex items-center gap-0.5 bg-gray-100 rounded-lg p-0.5">
                        <button
                          onClick={() => updateQuantity(item.id, item.quantity - 1)}
                          className="w-8 h-8 flex items-center justify-center rounded-md hover:bg-white hover:shadow transition-all text-gray-600 active:scale-90"
                        >
                          <Minus size={14} />
                        </button>
                        <span className="font-semibold w-8 text-center text-gray-900 text-sm">{item.quantity}</span>
                        <button
                          onClick={() => updateQuantity(item.id, item.quantity + 1)}
                          className="w-8 h-8 flex items-center justify-center rounded-md hover:bg-white hover:shadow transition-all text-gray-600 active:scale-90"
                        >
                          <Plus size={14} />
                        </button>
                      </div>

                      <div className="flex items-center gap-2 sm:gap-4">
                        <span className="text-base sm:text-xl font-bold text-gray-900">
                          ৳{(price * item.quantity).toLocaleString()}
                        </span>
                        <button
                          onClick={() => removeItem(item.id)}
                          className="w-8 h-8 sm:w-10 sm:h-10 flex items-center justify-center rounded-lg text-gray-400 hover:text-red-500 hover:bg-red-50 transition-all active:scale-90"
                        >
                          <Trash2 size={16} />
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Order Summary - Desktop Only */}
          <div className="lg:col-span-1 hidden lg:block">
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 sticky top-20">
              <h2 className="text-xl font-bold text-gray-900 mb-6">Order Summary</h2>

              <div className="space-y-4 mb-6">
                <div className="flex justify-between text-gray-600">
                  <span>Subtotal</span>
                  <span className="font-medium text-gray-900">৳{subtotal.toLocaleString()}</span>
                </div>
                <div className="flex justify-between text-gray-600">
                  <span>Shipping</span>
                  {shippingCharge === 0 ? (
                    <span className="font-medium text-green-600">FREE</span>
                  ) : (
                    <span className="font-medium text-gray-900">৳{shippingCharge}</span>
                  )}
                </div>
                {subtotal < 1000 && (
                  <p className="text-sm text-blue-600 bg-blue-50 p-3 rounded-lg">
                    Add ৳{(1000 - subtotal).toLocaleString()} more for <strong>FREE shipping!</strong>
                  </p>
                )}
                <div className="border-t border-gray-200 pt-4 flex justify-between">
                  <span className="text-lg font-bold text-gray-900">Total</span>
                  <span className="text-xl font-bold text-blue-600">৳{total.toLocaleString()}</span>
                </div>
              </div>

              <button
                onClick={() => navigate('/checkout')}
                className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white py-4 rounded-xl font-bold transition-all shadow-lg hover:shadow-xl flex items-center justify-center gap-2"
              >
                <CreditCard size={20} />
                Proceed to Checkout
              </button>

              {/* Trust Badges */}
              <div className="mt-6 pt-6 border-t border-gray-100">
                <div className="flex items-center gap-3 text-gray-500 text-sm mb-3">
                  <ShieldCheck size={18} className="text-green-500" />
                  <span>Secure checkout with SSL encryption</span>
                </div>
                <div className="flex flex-wrap gap-2 justify-center">
                  <div className="bg-gray-100 px-3 py-1.5 rounded text-xs font-bold text-blue-600">VISA</div>
                  <div className="bg-gray-100 px-3 py-1.5 rounded text-xs font-bold text-orange-600">Mastercard</div>
                  <div className="bg-pink-100 px-3 py-1.5 rounded text-xs font-bold text-pink-600">bKash</div>
                  <div className="bg-orange-100 px-3 py-1.5 rounded text-xs font-bold text-orange-600">Nagad</div>
                  <div className="bg-blue-100 px-3 py-1.5 rounded text-xs font-bold text-blue-600">Upay</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Mobile Sticky Bottom Bar - App Style */}
      <div className="lg:hidden fixed bottom-16 left-0 right-0 bg-white/95 backdrop-blur-lg border-t border-gray-200 px-4 py-3 z-40 shadow-[0_-4px_20px_rgba(0,0,0,0.08)]">
        <div className="flex items-center justify-between mb-2">
          <div className="flex flex-col">
            <span className="text-xs text-gray-500">Total ({getTotalItems()} items)</span>
            <span className="text-lg font-bold text-blue-600">৳{total.toLocaleString()}</span>
          </div>
          {shippingCharge === 0 && (
            <span className="text-xs font-semibold text-green-600 bg-green-50 px-2 py-1 rounded-full">FREE Shipping</span>
          )}
        </div>
        <button
          onClick={() => navigate('/checkout')}
          className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 text-white py-3.5 rounded-xl font-bold transition-all shadow-lg flex items-center justify-center gap-2 active:scale-[0.98]"
        >
          <CreditCard size={18} />
          Checkout Now
        </button>
      </div>
    </div>
  );
};

export const Cart = CartPage;
