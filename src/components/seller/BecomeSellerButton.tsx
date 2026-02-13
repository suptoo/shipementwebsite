import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Store, TrendingUp, DollarSign, Users } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

export const BecomeSellerButton: React.FC = () => {
  const navigate = useNavigate();
  const { profile } = useAuth();

  // Don't show if already a seller or admin
  if (!profile || profile.role === 'seller' || profile.role === 'admin') {
    return null;
  }

  return (
    <div className="fixed bottom-6 right-6 z-40 animate-bounce">
      <button
        onClick={() => navigate('/become-seller')}
        className="group bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white px-6 py-4 rounded-2xl shadow-2xl hover:shadow-3xl transition-all duration-300 flex items-center gap-3 font-bold text-lg"
      >
        <div className="p-2 bg-white/20 rounded-xl">
          <Store className="w-6 h-6" />
        </div>
        <span className="hidden sm:inline">Start Selling</span>
        <span className="sm:hidden">Sell</span>
      </button>
    </div>
  );
};

export const BecomeSellerBanner: React.FC = () => {
  const navigate = useNavigate();
  const { profile } = useAuth();

  // Don't show if already a seller or admin
  if (!profile || profile.role === 'seller' || profile.role === 'admin') {
    return null;
  }

  return (
    <div className="bg-gradient-to-r from-orange-500 via-red-500 to-pink-600 text-white py-12 md:py-16">
      <div className="max-w-7xl mx-auto px-4">
        <div className="flex flex-col md:flex-row items-center justify-between gap-8">
          <div className="text-center md:text-left flex-1">
            <div className="inline-flex items-center gap-2 bg-white/20 backdrop-blur-sm px-4 py-2 rounded-full mb-4">
              <Store size={18} />
              <span className="text-sm font-bold">SELLER PROGRAM</span>
            </div>
            <h2 className="text-3xl md:text-5xl font-extrabold mb-4">
              Start Your Business Today
            </h2>
            <p className="text-lg md:text-xl text-white/90 mb-6 max-w-2xl">
              Join thousands of successful sellers. Reach millions of customers nationwide and grow your business with Bongoportus
            </p>
            
            <div className="grid grid-cols-3 gap-4 md:gap-8 max-w-xl mb-8">
              <div className="text-center">
                <div className="flex items-center justify-center mb-2">
                  <Users className="w-8 h-8 md:w-10 md:h-10" />
                </div>
                <p className="text-2xl md:text-3xl font-bold">10M+</p>
                <p className="text-xs md:text-sm text-white/80">Customers</p>
              </div>
              <div className="text-center">
                <div className="flex items-center justify-center mb-2">
                  <TrendingUp className="w-8 h-8 md:w-10 md:h-10" />
                </div>
                <p className="text-2xl md:text-3xl font-bold">50K+</p>
                <p className="text-xs md:text-sm text-white/80">Sellers</p>
              </div>
              <div className="text-center">
                <div className="flex items-center justify-center mb-2">
                  <DollarSign className="w-8 h-8 md:w-10 md:h-10" />
                </div>
                <p className="text-2xl md:text-3xl font-bold">৳5Cr+</p>
                <p className="text-xs md:text-sm text-white/80">Daily Sales</p>
              </div>
            </div>

            <button
              onClick={() => navigate('/become-seller')}
              className="bg-white text-orange-600 hover:bg-orange-50 px-8 md:px-12 py-4 rounded-xl font-bold text-base md:text-lg transition-all duration-200 shadow-2xl hover:shadow-3xl transform hover:scale-105 inline-flex items-center gap-3"
            >
              <Store size={24} />
              Register as Seller
            </button>
          </div>

          <div className="hidden lg:block">
            <div className="relative">
              <div className="w-64 h-64 bg-white/10 backdrop-blur-sm rounded-3xl p-8 transform rotate-3 hover:rotate-0 transition-transform duration-300">
                <div className="space-y-4">
                  <div className="flex items-center gap-3 bg-white/20 p-3 rounded-xl">
                    <div className="w-10 h-10 bg-white/30 rounded-lg"></div>
                    <div className="flex-1">
                      <div className="h-3 bg-white/40 rounded mb-2"></div>
                      <div className="h-2 bg-white/30 rounded w-2/3"></div>
                    </div>
                  </div>
                  <div className="flex items-center gap-3 bg-white/20 p-3 rounded-xl">
                    <div className="w-10 h-10 bg-white/30 rounded-lg"></div>
                    <div className="flex-1">
                      <div className="h-3 bg-white/40 rounded mb-2"></div>
                      <div className="h-2 bg-white/30 rounded w-2/3"></div>
                    </div>
                  </div>
                  <div className="flex items-center gap-3 bg-white/20 p-3 rounded-xl">
                    <div className="w-10 h-10 bg-white/30 rounded-lg"></div>
                    <div className="flex-1">
                      <div className="h-3 bg-white/40 rounded mb-2"></div>
                      <div className="h-2 bg-white/30 rounded w-2/3"></div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
