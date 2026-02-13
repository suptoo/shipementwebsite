import React from 'react';
import { Link } from 'react-router-dom';
import { Store, Mail, Phone, Heart } from 'lucide-react';

export const Footer: React.FC = () => {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="bg-slate-900 text-white">
      <div className="max-w-7xl mx-auto px-4 py-10">
        {/* Main Footer Content */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-8 mb-8">
          {/* Brand */}
          <div className="col-span-2 md:col-span-1">
            <Link to="/" className="flex items-center gap-2 mb-4">
              <div className="bg-gradient-to-br from-blue-500 to-indigo-600 p-2 rounded-lg">
                <Store className="w-5 h-5 text-white" />
              </div>
              <span className="text-lg font-bold">Bongoportus</span>
            </Link>
            <p className="text-slate-400 text-sm mb-4">
              Bangladesh's trusted online marketplace.
            </p>
            <div className="flex items-center gap-3 text-slate-400 text-sm">
              <Phone size={14} />
              <span>+880 1700-000000</span>
            </div>
            <div className="flex items-center gap-3 text-slate-400 text-sm mt-2">
              <Mail size={14} />
              <span>support@bongoportus.com</span>
            </div>
          </div>

          {/* Quick Links */}
          <div>
            <h4 className="font-semibold mb-4 text-white">Shop</h4>
            <ul className="space-y-2 text-sm">
              <li><Link to="/" className="text-slate-400 hover:text-white">Home</Link></li>
              <li><Link to="/products" className="text-slate-400 hover:text-white">Products</Link></li>
              <li><Link to="/cart" className="text-slate-400 hover:text-white">Cart</Link></li>
              <li><Link to="/checkout" className="text-slate-400 hover:text-white">Checkout</Link></li>
            </ul>
          </div>

          {/* Support */}
          <div>
            <h4 className="font-semibold mb-4 text-white">Support</h4>
            <ul className="space-y-2 text-sm">
              <li><Link to="/help" className="text-slate-400 hover:text-white">Help Center</Link></li>
              <li><Link to="/returns" className="text-slate-400 hover:text-white">Returns</Link></li>
              <li><Link to="/shipping" className="text-slate-400 hover:text-white">Shipping</Link></li>
              <li><Link to="/contact" className="text-slate-400 hover:text-white">Contact Us</Link></li>
            </ul>
          </div>

          {/* Company */}
          <div>
            <h4 className="font-semibold mb-4 text-white">Company</h4>
            <ul className="space-y-2 text-sm">
              <li><Link to="/about" className="text-slate-400 hover:text-white">About Us</Link></li>
              <li><Link to="/become-seller" className="text-slate-400 hover:text-white">Sell with Us</Link></li>
              <li><Link to="/terms" className="text-slate-400 hover:text-white">Terms</Link></li>
              <li><Link to="/privacy" className="text-slate-400 hover:text-white">Privacy</Link></li>
            </ul>
          </div>
        </div>

        {/* Payment Methods */}
        <div className="border-t border-slate-800 pt-6 mb-6">
          <div className="flex flex-wrap items-center justify-center gap-4">
            <span className="text-slate-500 text-sm">We Accept:</span>
            <div className="flex flex-wrap items-center justify-center gap-2">
              <div className="bg-white px-3 py-1 rounded text-xs font-bold text-blue-600">VISA</div>
              <div className="bg-white px-3 py-1 rounded text-xs font-bold text-orange-600">Mastercard</div>
              <div className="bg-pink-500 px-3 py-1 rounded text-xs font-bold text-white">bKash</div>
              <div className="bg-orange-500 px-3 py-1 rounded text-xs font-bold text-white">Nagad</div>
              <div className="bg-blue-500 px-3 py-1 rounded text-xs font-bold text-white">Upay</div>
              <div className="bg-slate-700 px-3 py-1 rounded text-xs font-medium text-white">COD</div>
            </div>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="border-t border-slate-800 pt-6 text-center text-slate-500 text-sm">
          <p className="flex items-center justify-center gap-1">
            © {currentYear} Bongoportus. Made with
            <Heart size={12} className="text-red-500 fill-red-500" />
            in Bangladesh
          </p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
