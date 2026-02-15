import React, { useState, useEffect } from 'react';
import { useCartStore } from '../store/cartStore';
import { useAuth } from '../context/AuthContext';
import { orderService } from '../services/orderService';
import { Loader2, CreditCard, Smartphone, Wallet, ShoppingBag, CheckCircle2 } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { AddressManager, Address } from '../components/checkout/AddressManager';
import { PaymentModal, PaymentDetails } from '../components/checkout/PaymentModal';

export const CheckoutPage: React.FC = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const { items, getSubtotal, clearCart } = useCartStore();
  const [loading, setLoading] = useState(false);
  const [paymentMethod, setPaymentMethod] = useState<'cod' | 'card' | 'mobile'>('cod');
  const [couponCode, setCouponCode] = useState('');
  const [discountAmount, setDiscountAmount] = useState(0);
  const [shippingCharge] = useState(50);
  const [selectedAddress, setSelectedAddress] = useState<Address | null>(null);

  // Payment modal state
  const [showPaymentModal, setShowPaymentModal] = useState(false);
  const [pendingOrderId, setPendingOrderId] = useState<string | null>(null);
  const [paymentSuccess, setPaymentSuccess] = useState(false);
  const [paymentDetails, setPaymentDetails] = useState<PaymentDetails | null>(null);

  const subtotal = getSubtotal();
  const total = subtotal - discountAmount + shippingCharge;

  useEffect(() => {
    if (!user) {
      navigate('/login?redirect=/checkout');
    }
    if (items.length === 0 && !paymentSuccess) {
      navigate('/cart');
    }
  }, [user, items, navigate, paymentSuccess]);

  const handleApplyCoupon = async () => {
    if (!couponCode) return;

    try {
      const coupon = await orderService.applyCoupon(couponCode, subtotal);
      if (coupon) {
        const discount = orderService.calculateDiscount(coupon, subtotal);
        setDiscountAmount(discount);
        alert(`Coupon applied! You saved ৳${discount.toFixed(2)}`);
      } else {
        alert('Invalid or expired coupon code');
      }
    } catch (error) {
      console.error('Error applying coupon:', error);
      alert('Failed to apply coupon');
    }
  };

  const handlePlaceOrder = async () => {
    if (!user || !selectedAddress) {
      alert('Please select a delivery address');
      return;
    }

    // For card or mobile payments, show the payment modal first
    if (paymentMethod === 'card' || paymentMethod === 'mobile') {
      setShowPaymentModal(true);
      return;
    }

    // For Cash on Delivery, create order directly
    await createOrder();
  };

  const createOrder = async (paymentInfo?: PaymentDetails) => {
    if (!user || !selectedAddress) return;

    setLoading(true);

    try {
      // Prepare cart items for order - use default IDs if missing
      const cartItems = items.map((item) => ({
        productId: item.product_id,
        variantId: item.variant_id || undefined,
        quantity: item.quantity,
        price: item.product?.discount_price || item.product?.price || 0,
        productName: item.product?.name || 'Unknown Product',
        productImageUrl: item.product?.images?.[0]?.image_url,
        sellerId: item.product?.seller_id || 'default-seller',
        shopId: item.product?.shop_id || 'default-shop',
        commissionRate: 15,
      }));

      // Create order with properly typed address
      const orderAddress = {
        ...selectedAddress,
        address_line2: selectedAddress.address_line2 || null,
      };

      const order = await orderService.createOrder({
        userId: user.id,
        cartItems,
        address: orderAddress as any,
        paymentMethod,
        couponCode: couponCode || undefined,
        shippingCharge,
      });

      // If payment was made, update payment status with full details
      if (paymentInfo) {
        try {
          await orderService.updatePaymentStatus(order.id, 'paid', {
            transactionId: paymentInfo.transactionId,
            method: paymentInfo.method,
            accountNumber: paymentInfo.accountNumber,
            cardType: paymentInfo.method === 'visa' || paymentInfo.method === 'mastercard' ? paymentInfo.method : undefined,
          });
        } catch (e) {
          console.log('Payment status update skipped:', e);
        }
        setPaymentDetails(paymentInfo);
        setPaymentSuccess(true);
        setPendingOrderId(order.id);
      }

      clearCart();

      // Navigate after 1 MINUTE to give time for screenshots
      setTimeout(() => {
        navigate(`/orders/${order.id}`);
      }, paymentInfo ? 60000 : 500); // 60 seconds = 1 minute for screenshots

    } catch (error: any) {
      console.error('Error placing order:', error);
      // Show detailed error message
      const errorMsg = error?.message || error?.details || 'Unknown error occurred';
      alert(`Failed to place order: ${errorMsg}`);
    } finally {
      setLoading(false);
    }
  };

  const handlePaymentSuccess = async (details: PaymentDetails) => {
    setShowPaymentModal(false);
    await createOrder(details);
  };

  if (!user || (items.length === 0 && !paymentSuccess)) {
    return null;
  }

  // Show success screen after payment
  if (paymentSuccess && paymentDetails) {
    return (
      <div className="max-w-lg mx-auto px-4 py-8 sm:py-16 text-center">
        <div className="bg-white rounded-2xl shadow-xl p-6 sm:p-8">
          <div className="w-16 h-16 sm:w-20 sm:h-20 mx-auto mb-4 sm:mb-6 bg-green-100 rounded-full flex items-center justify-center">
            <CheckCircle2 className="w-10 h-10 sm:w-12 sm:h-12 text-green-500" />
          </div>
          <h1 className="text-xl sm:text-2xl font-bold text-green-600 mb-2">Payment Successful!</h1>
          <p className="text-slate-600 mb-4 sm:mb-6 text-sm sm:text-base">Your order has been placed successfully.</p>

          <div className="bg-slate-50 rounded-lg p-4 mb-6 text-left">
            <div className="grid grid-cols-2 gap-3 text-sm">
              <div className="text-slate-500">Payment Method</div>
              <div className="font-medium text-right capitalize">
                {paymentDetails.method === 'visa' && '💳 Visa'}
                {paymentDetails.method === 'mastercard' && '💳 Mastercard'}
                {paymentDetails.method === 'bkash' && '📱 bKash'}
                {paymentDetails.method === 'nagad' && '📱 Nagad'}
                {paymentDetails.method === 'upay' && '📱 Upay'}
              </div>
              <div className="text-slate-500">Transaction ID</div>
              <div className="font-mono text-xs text-right">{paymentDetails.transactionId}</div>
              <div className="text-slate-500">Amount Paid</div>
              <div className="font-bold text-green-600 text-right">৳{total.toFixed(2)}</div>
            </div>
          </div>

          <p className="text-sm text-slate-500 animate-pulse">
            Redirecting to order details...
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-gray-50 min-h-screen py-4 sm:py-8 pb-36 sm:pb-8">
      <div className="max-w-7xl mx-auto px-4">
        <h1 className="text-xl sm:text-2xl md:text-3xl font-bold text-gray-900 mb-4 sm:mb-8">Checkout</h1>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 sm:gap-8">
          {/* Left Column - Address & Payment */}
          <div className="lg:col-span-2 space-y-4 sm:space-y-6">
            {/* Delivery Address */}
            <div className="bg-white rounded-xl sm:rounded-2xl shadow-sm border border-gray-100 p-4 sm:p-6">
              <h2 className="text-lg sm:text-xl font-bold text-gray-900 mb-3 sm:mb-4">Delivery Address</h2>
              <AddressManager
                selectedAddress={selectedAddress}
                onAddressSelect={setSelectedAddress}
              />
            </div>

            {/* Payment Method */}
            <div className="bg-white rounded-xl sm:rounded-2xl shadow-sm border border-gray-100 p-4 sm:p-6">
              <h2 className="text-lg sm:text-xl font-bold text-gray-900 mb-3 sm:mb-4">Payment Method</h2>
              <div className="space-y-2 sm:space-y-3">
                <label className={`flex items-center gap-3 p-3 sm:p-4 border-2 rounded-xl cursor-pointer transition-all active:scale-[0.98] ${paymentMethod === 'cod' ? 'border-blue-500 bg-blue-50' : 'border-gray-200 hover:border-gray-300 hover:bg-gray-50'}`}>
                  <input
                    type="radio"
                    name="payment"
                    value="cod"
                    checked={paymentMethod === 'cod'}
                    onChange={(e) => setPaymentMethod(e.target.value as any)}
                    className="w-4 h-4 text-blue-600"
                  />
                  <Wallet className={`w-5 h-5 sm:w-6 sm:h-6 ${paymentMethod === 'cod' ? 'text-blue-600' : 'text-gray-500'}`} />
                  <span className="font-semibold text-gray-900 text-sm sm:text-base">Cash on Delivery</span>
                </label>

                <label className={`flex items-center gap-3 p-3 sm:p-4 border-2 rounded-xl cursor-pointer transition-all active:scale-[0.98] ${paymentMethod === 'card' ? 'border-blue-500 bg-blue-50' : 'border-gray-200 hover:border-gray-300 hover:bg-gray-50'}`}>
                  <input
                    type="radio"
                    name="payment"
                    value="card"
                    checked={paymentMethod === 'card'}
                    onChange={(e) => setPaymentMethod(e.target.value as any)}
                    className="w-4 h-4 text-blue-600"
                  />
                  <CreditCard className={`w-5 h-5 sm:w-6 sm:h-6 ${paymentMethod === 'card' ? 'text-blue-600' : 'text-gray-500'}`} />
                  <div className="flex flex-col">
                    <span className="font-semibold text-gray-900 text-sm sm:text-base">Credit/Debit Card</span>
                    <div className="flex gap-1.5 mt-1">
                      <span className="text-[10px] sm:text-xs bg-blue-100 text-blue-700 px-1.5 sm:px-2 py-0.5 rounded font-bold">VISA</span>
                      <span className="text-[10px] sm:text-xs bg-orange-100 text-orange-700 px-1.5 sm:px-2 py-0.5 rounded font-bold">Mastercard</span>
                    </div>
                  </div>
                </label>

                <label className={`flex items-center gap-3 p-3 sm:p-4 border-2 rounded-xl cursor-pointer transition-all active:scale-[0.98] ${paymentMethod === 'mobile' ? 'border-blue-500 bg-blue-50' : 'border-gray-200 hover:border-gray-300 hover:bg-gray-50'}`}>
                  <input
                    type="radio"
                    name="payment"
                    value="mobile"
                    checked={paymentMethod === 'mobile'}
                    onChange={(e) => setPaymentMethod(e.target.value as any)}
                    className="w-4 h-4 text-blue-600"
                  />
                  <Smartphone className={`w-5 h-5 sm:w-6 sm:h-6 ${paymentMethod === 'mobile' ? 'text-blue-600' : 'text-gray-500'}`} />
                  <div className="flex flex-col">
                    <span className="font-semibold text-gray-900 text-sm sm:text-base">Mobile Banking</span>
                    <div className="flex gap-1.5 mt-1">
                      <span className="text-[10px] sm:text-xs bg-pink-100 text-pink-700 px-1.5 sm:px-2 py-0.5 rounded font-bold">bKash</span>
                      <span className="text-[10px] sm:text-xs bg-orange-100 text-orange-700 px-1.5 sm:px-2 py-0.5 rounded font-bold">Nagad</span>
                      <span className="text-[10px] sm:text-xs bg-blue-100 text-blue-700 px-1.5 sm:px-2 py-0.5 rounded font-bold">Upay</span>
                    </div>
                  </div>
                </label>
              </div>
            </div>

            {/* Mobile Order Summary (collapsible) */}
            <div className="lg:hidden bg-white rounded-xl shadow-sm border border-gray-100 p-4">
              <h2 className="text-lg font-bold text-gray-900 mb-3">Order Summary</h2>
              <div className="space-y-2">
                {items.map((item) => (
                  <div key={item.id} className="flex gap-3">
                    <div className="w-12 h-12 rounded-lg overflow-hidden bg-gray-100 flex-shrink-0">
                      <img
                        src={item.product?.images?.[0]?.image_url || 'https://via.placeholder.com/60'}
                        alt={item.product?.name}
                        className="w-full h-full object-cover"
                      />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-xs font-medium text-gray-900 line-clamp-1">{item.product?.name}</p>
                      <p className="text-xs text-gray-500">৳{item.product?.discount_price || item.product?.price} × {item.quantity}</p>
                    </div>
                  </div>
                ))}
              </div>
              {/* Coupon - Mobile */}
              <div className="mt-3 pt-3 border-t border-gray-100">
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={couponCode}
                    onChange={(e) => setCouponCode(e.target.value.toUpperCase())}
                    placeholder="Coupon Code"
                    className="flex-1 px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-all text-sm"
                  />
                  <button
                    onClick={handleApplyCoupon}
                    className="px-3 py-2 bg-gray-100 hover:bg-gray-200 rounded-lg font-medium text-gray-700 transition-colors text-sm active:scale-95"
                  >
                    Apply
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Right Column - Order Summary - Desktop Only */}
          <div className="lg:col-span-1 hidden lg:block">
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 sticky top-20">
              <h2 className="text-xl font-bold text-gray-900 mb-4">Order Summary</h2>

              <div className="space-y-3 mb-6">
                {items.map((item) => (
                  <div key={item.id} className="flex gap-3">
                    <div className="w-16 h-16 rounded-lg overflow-hidden bg-gray-100 flex-shrink-0">
                      <img
                        src={item.product?.images?.[0]?.image_url || 'https://via.placeholder.com/60'}
                        alt={item.product?.name}
                        className="w-full h-full object-cover"
                      />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-gray-900 line-clamp-2">
                        {item.product?.name}
                      </p>
                      <p className="text-sm text-gray-500 mt-1">
                        ৳{item.product?.discount_price || item.product?.price} × {item.quantity}
                      </p>
                    </div>
                  </div>
                ))}
              </div>

              {/* Coupon */}
              <div className="mb-6">
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={couponCode}
                    onChange={(e) => setCouponCode(e.target.value.toUpperCase())}
                    placeholder="Coupon Code"
                    className="flex-1 px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-all"
                  />
                  <button
                    onClick={handleApplyCoupon}
                    className="px-4 py-2.5 bg-gray-100 hover:bg-gray-200 rounded-xl font-medium text-gray-700 transition-colors"
                  >
                    Apply
                  </button>
                </div>
              </div>

              <div className="space-y-3 pt-4 border-t border-gray-100">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">Subtotal</span>
                  <span className="font-medium text-gray-900">৳{subtotal.toLocaleString()}</span>
                </div>
                {discountAmount > 0 && (
                  <div className="flex justify-between text-sm text-green-600">
                    <span>Discount</span>
                    <span className="font-medium">-৳{discountAmount.toLocaleString()}</span>
                  </div>
                )}
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">Shipping</span>
                  <span className="font-medium text-gray-900">৳{shippingCharge}</span>
                </div>
                <div className="flex justify-between text-lg font-bold pt-4 border-t border-gray-100">
                  <span className="text-gray-900">Total</span>
                  <span className="text-blue-600">৳{total.toLocaleString()}</span>
                </div>
              </div>

              <button
                onClick={handlePlaceOrder}
                disabled={loading || !selectedAddress}
                className="w-full mt-6 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 disabled:from-gray-400 disabled:to-gray-400 text-white py-4 rounded-xl font-bold transition-all shadow-lg hover:shadow-xl flex items-center justify-center gap-2"
              >
                {loading ? (
                  <>
                    <Loader2 className="animate-spin" size={20} />
                    Processing...
                  </>
                ) : paymentMethod === 'cod' ? (
                  'Place Order'
                ) : paymentMethod === 'card' ? (
                  <>
                    <CreditCard size={18} />
                    Pay with Card
                  </>
                ) : (
                  <>
                    <Smartphone size={18} />
                    Pay with Mobile Banking
                  </>
                )}
              </button>

              <p className="text-xs text-gray-400 text-center mt-4">
                By placing this order, you agree to our Terms & Conditions
              </p>
            </div>
          </div>
        </div>

        {/* Mobile Sticky Bottom Bar */}
        <div className="lg:hidden fixed bottom-16 left-0 right-0 bg-white/95 backdrop-blur-lg border-t border-gray-200 px-4 py-3 z-40 shadow-[0_-4px_20px_rgba(0,0,0,0.08)]">
          <div className="flex items-center justify-between mb-2">
            <div className="flex flex-col">
              <span className="text-xs text-gray-500">Total</span>
              <span className="text-lg font-bold text-blue-600">৳{total.toLocaleString()}</span>
            </div>
            {discountAmount > 0 && (
              <span className="text-xs font-semibold text-green-600 bg-green-50 px-2 py-1 rounded-full">-৳{discountAmount}</span>
            )}
          </div>
          <button
            onClick={handlePlaceOrder}
            disabled={loading || !selectedAddress}
            className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 disabled:from-gray-400 disabled:to-gray-400 text-white py-3.5 rounded-xl font-bold transition-all shadow-lg flex items-center justify-center gap-2 active:scale-[0.98]"
          >
            {loading ? (
              <>
                <Loader2 className="animate-spin" size={18} />
                Processing...
              </>
            ) : paymentMethod === 'cod' ? (
              'Place Order'
            ) : paymentMethod === 'card' ? (
              <>
                <CreditCard size={18} />
                Pay ৳{total.toLocaleString()}
              </>
            ) : (
              <>
                <Smartphone size={18} />
                Pay ৳{total.toLocaleString()}
              </>
            )}
          </button>
        </div>

        {/* Payment Modal */}
        <PaymentModal
          isOpen={showPaymentModal}
          onClose={() => setShowPaymentModal(false)}
          onSuccess={handlePaymentSuccess}
          amount={total}
          paymentMethod={paymentMethod === 'card' ? 'card' : 'mobile'}
        />
      </div>
    </div>
  );
};

export const Checkout = CheckoutPage;
