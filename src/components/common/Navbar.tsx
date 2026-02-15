import React, { useState, useEffect, useRef } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { Menu, X, LogOut, ShieldCheck, Home, User, MessageSquare, ShoppingCart, Store, Package, LayoutDashboard, ChevronDown } from 'lucide-react';
import { useCartStore } from '../../store/cartStore';

const Navbar: React.FC = () => {
  const { user, profile, signOut } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [adminDropdownOpen, setAdminDropdownOpen] = useState(false);
  const [hideTopNav, setHideTopNav] = useState(false);
  const adminDropdownRef = useRef<HTMLDivElement>(null);
  const lastScrollY = useRef(0);
  const cartItems = useCartStore((state) => state.items);
  const cartCount = cartItems.reduce((sum, item) => sum + item.quantity, 0);

  // Close mobile menu on route change
  useEffect(() => {
    setMobileMenuOpen(false);
    setAdminDropdownOpen(false);
  }, [location.pathname]);

  // Close admin dropdown on outside click
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (adminDropdownRef.current && !adminDropdownRef.current.contains(e.target as Node)) {
        setAdminDropdownOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Auto-hide top nav on scroll down (mobile only, app-like behavior)
  useEffect(() => {
    const handleScroll = () => {
      const currentScrollY = window.scrollY;
      if (window.innerWidth < 768) {
        if (currentScrollY > lastScrollY.current && currentScrollY > 80) {
          setHideTopNav(true);
        } else {
          setHideTopNav(false);
        }
      } else {
        setHideTopNav(false);
      }
      lastScrollY.current = currentScrollY;
    };
    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const handleLogout = async () => {
    await signOut();
    navigate('/login');
  };

  const isAdmin = profile?.role === 'admin';
  const isActive = (path: string) => location.pathname === path;
  const isAdminPage = location.pathname.startsWith('/admin');

  return (
    <>
      <nav className={`bg-white shadow-lg sticky top-0 z-50 border-b border-gray-100 safe-top transition-transform duration-300 ${hideTopNav ? '-translate-y-full md:translate-y-0' : 'translate-y-0'}`}>
        <div className="max-w-7xl mx-auto px-3 sm:px-4">
          <div className="flex justify-between items-center h-14 sm:h-16">
            {/* Logo */}
            <Link to="/" className="flex items-center gap-3 group">
              <div className="bg-gradient-to-br from-blue-600 to-indigo-600 p-2.5 rounded-xl shadow-lg group-hover:shadow-xl transition-all duration-300 group-hover:scale-110">
                <Store className="w-6 h-6 text-white" />
              </div>
              <span className="hidden sm:inline text-xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 text-transparent bg-clip-text">
                Bongoportus
              </span>
            </Link>

            {/* Desktop Menu */}
            <div className="hidden md:flex items-center gap-1">
              <Link
                to="/"
                className={`flex items-center gap-2 px-4 py-2 rounded-xl transition-all font-medium ${isActive('/')
                  ? 'bg-blue-50 text-blue-600'
                  : 'text-gray-700 hover:bg-gray-50'
                  }`}
              >
                <Home className="w-4 h-4" />
                Home
              </Link>

              <Link
                to="/cart"
                className={`relative flex items-center gap-2 px-4 py-2 rounded-xl transition-all font-medium ${isActive('/cart')
                  ? 'bg-blue-50 text-blue-600'
                  : 'text-gray-700 hover:bg-gray-50'
                  }`}
              >
                <ShoppingCart className="w-4 h-4" />
                Cart
                {cartCount > 0 && (
                  <span className="absolute -top-1 -right-1 bg-gradient-to-r from-orange-500 to-red-500 text-white text-xs font-bold rounded-full w-5 h-5 flex items-center justify-center shadow-lg">
                    {cartCount > 9 ? '9+' : cartCount}
                  </span>
                )}
              </Link>

              {user && (
                <>
                  <Link
                    to="/messages"
                    className={`flex items-center gap-2 px-4 py-2 rounded-xl transition-all font-medium ${isActive('/messages')
                      ? 'bg-blue-50 text-blue-600'
                      : 'text-gray-700 hover:bg-gray-50'
                      }`}
                  >
                    <MessageSquare className="w-4 h-4" />
                    Messages
                  </Link>
                </>
              )}

              {user && isAdmin && (
                <div className="relative" ref={adminDropdownRef}>
                  <button
                    onClick={() => setAdminDropdownOpen(!adminDropdownOpen)}
                    className={`flex items-center gap-2 px-4 py-2 rounded-xl transition-all font-medium ${isAdminPage
                      ? 'bg-blue-50 text-blue-600'
                      : 'text-gray-700 hover:bg-gray-50'
                      }`}
                  >
                    <ShieldCheck className="w-4 h-4" />
                    Admin
                    <ChevronDown className={`w-3.5 h-3.5 transition-transform ${adminDropdownOpen ? 'rotate-180' : ''}`} />
                  </button>
                  {adminDropdownOpen && (
                    <div className="absolute top-full right-0 mt-2 w-52 bg-white rounded-xl shadow-xl border border-gray-100 py-2 z-50 animate-in">
                      <Link
                        to="/admin"
                        className="flex items-center gap-3 px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-blue-50 hover:text-blue-600 transition-colors"
                      >
                        <LayoutDashboard className="w-4 h-4" />
                        Dashboard
                      </Link>
                      <Link
                        to="/admin/orders"
                        className="flex items-center gap-3 px-4 py-2.5 text-sm font-medium text-gray-700 hover:bg-blue-50 hover:text-blue-600 transition-colors"
                      >
                        <Package className="w-4 h-4" />
                        Order Management
                      </Link>
                    </div>
                  )}
                </div>
              )}

              {user ? (
                <div className="flex items-center gap-3 ml-4 pl-4 border-l border-gray-200">
                  <div className="flex items-center gap-2 bg-gradient-to-r from-blue-50 to-indigo-50 px-3 py-2 rounded-xl">
                    <User className="w-4 h-4 text-blue-600" />
                    <span className="text-sm font-semibold text-gray-900">
                      {profile?.full_name || profile?.email?.split('@')[0]}
                    </span>
                    {isAdmin && (
                      <span className="bg-gradient-to-r from-yellow-400 to-orange-400 text-white text-xs px-2.5 py-0.5 rounded-full font-bold shadow">
                        Admin
                      </span>
                    )}
                  </div>
                  <button
                    onClick={handleLogout}
                    className="flex items-center gap-2 bg-gradient-to-r from-red-500 to-pink-600 hover:from-red-600 hover:to-pink-700 text-white px-4 py-2 rounded-xl transition-all shadow-lg hover:shadow-xl font-medium"
                  >
                    <LogOut className="w-4 h-4" />
                    Logout
                  </button>
                </div>
              ) : (
                <Link
                  to="/login"
                  className="ml-4 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white px-6 py-2 rounded-xl font-bold transition-all shadow-lg hover:shadow-xl"
                >
                  Sign In
                </Link>
              )}
            </div>

            {/* Mobile Menu Button */}
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="md:hidden p-2 hover:bg-gray-50 rounded-xl transition-colors text-gray-700"
            >
              {mobileMenuOpen ? (
                <X className="w-6 h-6" />
              ) : (
                <Menu className="w-6 h-6" />
              )}
            </button>
          </div>

          {/* Mobile Menu - Animated Slide Down */}
          <div
            className={`md:hidden overflow-hidden transition-all duration-300 ease-in-out ${mobileMenuOpen ? 'max-h-[600px] opacity-100' : 'max-h-0 opacity-0'
              }`}
          >
            <div className="py-3 border-t border-gray-100 bg-white">
              <div className="flex flex-col gap-0.5">
                <Link
                  to="/"
                  onClick={() => setMobileMenuOpen(false)}
                  className={`flex items-center gap-3 px-4 py-3.5 rounded-xl transition-all font-medium ${isActive('/')
                    ? 'bg-blue-50 text-blue-600'
                    : 'text-gray-700 hover:bg-gray-50 active:bg-gray-100'
                    }`}
                >
                  <Home className="w-5 h-5" />
                  Home
                </Link>

                <Link
                  to="/cart"
                  onClick={() => setMobileMenuOpen(false)}
                  className={`relative flex items-center gap-3 px-4 py-3.5 rounded-xl transition-all font-medium ${isActive('/cart')
                    ? 'bg-blue-50 text-blue-600'
                    : 'text-gray-700 hover:bg-gray-50 active:bg-gray-100'
                    }`}
                >
                  <ShoppingCart className="w-5 h-5" />
                  Cart
                  {cartCount > 0 && (
                    <span className="bg-gradient-to-r from-orange-500 to-red-500 text-white text-xs font-bold rounded-full px-2 py-0.5 ml-auto shadow">
                      {cartCount}
                    </span>
                  )}
                </Link>

                {user && (
                  <Link
                    to="/messages"
                    onClick={() => setMobileMenuOpen(false)}
                    className={`flex items-center gap-3 px-4 py-3.5 rounded-xl transition-all font-medium ${isActive('/messages')
                      ? 'bg-blue-50 text-blue-600'
                      : 'text-gray-700 hover:bg-gray-50 active:bg-gray-100'
                      }`}
                  >
                    <MessageSquare className="w-5 h-5" />
                    Messages
                  </Link>
                )}

                {isAdmin && (
                  <div className="mt-1 mb-1">
                    <div className="px-4 py-2 text-xs font-bold text-gray-400 uppercase tracking-wider">Admin</div>
                    <Link
                      to="/admin"
                      onClick={() => setMobileMenuOpen(false)}
                      className={`flex items-center gap-3 px-4 py-3.5 rounded-xl transition-all font-medium ${isActive('/admin')
                        ? 'bg-blue-50 text-blue-600'
                        : 'text-gray-700 hover:bg-gray-50 active:bg-gray-100'
                        }`}
                    >
                      <LayoutDashboard className="w-5 h-5" />
                      Dashboard
                    </Link>
                    <Link
                      to="/admin/orders"
                      onClick={() => setMobileMenuOpen(false)}
                      className={`flex items-center gap-3 px-4 py-3.5 rounded-xl transition-all font-medium ${isActive('/admin/orders')
                        ? 'bg-blue-50 text-blue-600'
                        : 'text-gray-700 hover:bg-gray-50 active:bg-gray-100'
                        }`}
                    >
                      <Package className="w-5 h-5" />
                      Order Management
                    </Link>
                  </div>
                )}

                {user ? (
                  <div className="pt-3 mt-2 border-t border-gray-200 space-y-2">
                    <div className="flex items-center gap-2 bg-gradient-to-r from-blue-50 to-indigo-50 px-4 py-3 rounded-xl">
                      <User className="w-5 h-5 text-blue-600" />
                      <span className="text-sm font-semibold text-gray-900 truncate">
                        {profile?.full_name || profile?.email?.split('@')[0]}
                      </span>
                      {isAdmin && (
                        <span className="bg-gradient-to-r from-yellow-400 to-orange-400 text-white text-xs px-2 py-0.5 rounded-full font-bold ml-auto shadow flex-shrink-0">
                          Admin
                        </span>
                      )}
                    </div>
                    <button
                      onClick={handleLogout}
                      className="flex items-center justify-center gap-2 bg-gradient-to-r from-red-500 to-pink-600 hover:from-red-600 hover:to-pink-700 text-white px-4 py-3.5 rounded-xl transition-all w-full font-medium shadow-lg active:scale-95"
                    >
                      <LogOut className="w-5 h-5" />
                      Logout
                    </button>
                  </div>
                ) : (
                  <Link
                    to="/login"
                    onClick={() => setMobileMenuOpen(false)}
                    className="mt-3 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white px-6 py-3.5 rounded-xl font-bold transition-all text-center block shadow-lg active:scale-95"
                  >
                    Sign In
                  </Link>
                )}
              </div>
            </div>
          </div>
        </div>
      </nav>

      {/* Mobile Bottom Navigation Bar - App Style */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 bg-white/95 backdrop-blur-lg border-t border-gray-200 z-50 safe-area-bottom shadow-[0_-4px_20px_rgba(0,0,0,0.08)]">
        <div className="flex items-center justify-around h-16 px-2 max-w-lg mx-auto">
          <Link
            to="/"
            className={`flex flex-col items-center justify-center gap-0.5 flex-1 py-2 min-w-0 rounded-xl transition-all duration-200 ${isActive('/') ? 'text-blue-600' : 'text-gray-400'
              }`}
          >
            <Home className={`w-5 h-5 ${isActive('/') ? 'stroke-[2.5]' : ''}`} />
            <span className={`text-[10px] ${isActive('/') ? 'font-bold' : 'font-medium'}`}>Home</span>
            {isActive('/') && <div className="w-1 h-1 rounded-full bg-blue-600 mt-0.5"></div>}
          </Link>

          <Link
            to="/cart"
            className={`relative flex flex-col items-center justify-center gap-0.5 flex-1 py-2 min-w-0 rounded-xl transition-all duration-200 ${isActive('/cart') ? 'text-blue-600' : 'text-gray-400'
              }`}
          >
            <div className="relative">
              <ShoppingCart className={`w-5 h-5 ${isActive('/cart') ? 'stroke-[2.5]' : ''}`} />
              {cartCount > 0 && (
                <span className="absolute -top-1.5 -right-2.5 bg-red-500 text-white text-[9px] font-bold rounded-full w-4 h-4 flex items-center justify-center animate-bounce">
                  {cartCount > 9 ? '9+' : cartCount}
                </span>
              )}
            </div>
            <span className={`text-[10px] ${isActive('/cart') ? 'font-bold' : 'font-medium'}`}>Cart</span>
            {isActive('/cart') && <div className="w-1 h-1 rounded-full bg-blue-600 mt-0.5"></div>}
          </Link>

          {user && (
            <Link
              to="/messages"
              className={`flex flex-col items-center justify-center gap-0.5 flex-1 py-2 min-w-0 rounded-xl transition-all duration-200 ${isActive('/messages') ? 'text-blue-600' : 'text-gray-400'
                }`}
            >
              <MessageSquare className={`w-5 h-5 ${isActive('/messages') ? 'stroke-[2.5]' : ''}`} />
              <span className={`text-[10px] ${isActive('/messages') ? 'font-bold' : 'font-medium'}`}>Messages</span>
              {isActive('/messages') && <div className="w-1 h-1 rounded-full bg-blue-600 mt-0.5"></div>}
            </Link>
          )}

          {isAdmin && (
            <Link
              to="/admin"
              className={`flex flex-col items-center justify-center gap-0.5 flex-1 py-2 min-w-0 rounded-xl transition-all duration-200 ${isAdminPage ? 'text-blue-600' : 'text-gray-400'
                }`}
            >
              <ShieldCheck className={`w-5 h-5 ${isAdminPage ? 'stroke-[2.5]' : ''}`} />
              <span className={`text-[10px] ${isAdminPage ? 'font-bold' : 'font-medium'}`}>Admin</span>
              {isAdminPage && <div className="w-1 h-1 rounded-full bg-blue-600 mt-0.5"></div>}
            </Link>
          )}

          {user ? (
            <button
              onClick={handleLogout}
              className="flex flex-col items-center justify-center gap-0.5 flex-1 py-2 min-w-0 rounded-xl text-gray-400 transition-all duration-200 active:scale-90"
            >
              <LogOut className="w-5 h-5" />
              <span className="text-[10px] font-medium">Logout</span>
            </button>
          ) : (
            <Link
              to="/login"
              className={`flex flex-col items-center justify-center gap-0.5 flex-1 py-2 min-w-0 rounded-xl transition-all duration-200 ${isActive('/login') ? 'text-blue-600' : 'text-gray-400'
                }`}
            >
              <User className={`w-5 h-5 ${isActive('/login') ? 'stroke-[2.5]' : ''}`} />
              <span className={`text-[10px] ${isActive('/login') ? 'font-bold' : 'font-medium'}`}>Sign In</span>
              {isActive('/login') && <div className="w-1 h-1 rounded-full bg-blue-600 mt-0.5"></div>}
            </Link>
          )}
        </div>
      </nav>
    </>
  );
};

export default Navbar;