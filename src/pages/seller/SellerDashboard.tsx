import React, { useEffect, useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { supabase } from '../../lib/supabase';
import {
  DollarSign,
  Package,
  ShoppingCart,
  TrendingUp,
  Plus,
  Eye,
  Edit,
  Trash2,
} from 'lucide-react';
import { Link } from 'react-router-dom';

interface SellerStats {
  totalProducts: number;
  totalOrders: number;
  totalEarnings: number;
  pendingOrders: number;
}

export const SellerDashboard: React.FC = () => {
  const { user } = useAuth();
  const [stats, setStats] = useState<SellerStats>({
    totalProducts: 0,
    totalOrders: 0,
    totalEarnings: 0,
    pendingOrders: 0,
  });
  const [loading, setLoading] = useState(true);
  const [recentProducts, setRecentProducts] = useState<any[]>([]);
  const [sellerProfile, setSellerProfile] = useState<any>(null);

  useEffect(() => {
    if (user) {
      loadSellerData();
    }
  }, [user]);

  const loadSellerData = async () => {
    try {
      // Get seller profile
      const { data: seller, error: sellerError } = await supabase
        .from('seller_profiles')
        .select('*, shops(*)')
        .eq('user_id', user?.id)
        .single();

      if (sellerError) throw sellerError;
      setSellerProfile(seller);

      // Get product count
      const { count: productCount } = await supabase
        .from('products')
        .select('*', { count: 'exact', head: true })
        .eq('seller_id', seller.id);

      // Get order stats
      const { data: orderItems } = await supabase
        .from('order_items')
        .select('*')
        .eq('seller_id', seller.id);

      const totalOrders = orderItems?.length || 0;
      const pendingOrders =
        orderItems?.filter((item) => item.item_status === 'pending').length || 0;
      const totalEarnings =
        orderItems?.reduce((sum, item) => sum + item.seller_earnings, 0) || 0;

      // Get recent products
      const { data: products } = await supabase
        .from('products')
        .select('*, product_images(*)')
        .eq('seller_id', seller.id)
        .order('created_at', { ascending: false })
        .limit(5);

      setStats({
        totalProducts: productCount || 0,
        totalOrders,
        totalEarnings,
        pendingOrders,
      });
      setRecentProducts(products || []);
    } catch (error) {
      console.error('Error loading seller data:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!sellerProfile) {
    return (
      <div className="max-w-4xl mx-auto px-4 py-16 text-center">
        <Package className="mx-auto text-gray-400 mb-4" size={64} />
        <h2 className="text-2xl font-semibold mb-4">Become a Seller</h2>
        <p className="text-gray-600 mb-6">
          Start selling your products on Bongoportus Marketplace
        </p>
        <Link
          to="/seller/register"
          className="inline-block bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-md font-semibold"
        >
          Register as Seller
        </Link>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Seller Dashboard</h1>
        <p className="text-gray-600">
          Welcome back, {sellerProfile.business_name}!
        </p>
      </div>

      {/* Status Alert */}
      {sellerProfile.status !== 'approved' && (
        <div className="mb-6 bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <p className="text-yellow-800">
            <strong>Account Status: {sellerProfile.status}</strong>
            {sellerProfile.status === 'pending' &&
              ' - Your account is under review. You will be notified once approved.'}
          </p>
        </div>
      )}

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="p-3 bg-blue-100 rounded-lg">
              <Package className="text-blue-600" size={24} />
            </div>
          </div>
          <p className="text-2xl font-bold">{stats.totalProducts}</p>
          <p className="text-sm text-gray-600">Total Products</p>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="p-3 bg-green-100 rounded-lg">
              <ShoppingCart className="text-green-600" size={24} />
            </div>
          </div>
          <p className="text-2xl font-bold">{stats.totalOrders}</p>
          <p className="text-sm text-gray-600">Total Orders</p>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="p-3 bg-purple-100 rounded-lg">
              <DollarSign className="text-purple-600" size={24} />
            </div>
          </div>
          <p className="text-2xl font-bold">৳{stats.totalEarnings.toFixed(2)}</p>
          <p className="text-sm text-gray-600">Total Earnings</p>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="p-3 bg-orange-100 rounded-lg">
              <TrendingUp className="text-orange-600" size={24} />
            </div>
          </div>
          <p className="text-2xl font-bold">{stats.pendingOrders}</p>
          <p className="text-sm text-gray-600">Pending Orders</p>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="bg-white rounded-lg shadow-md p-6 mb-8">
        <h2 className="text-xl font-semibold mb-4">Quick Actions</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <Link
            to="/seller/products/new"
            className="flex items-center gap-2 p-4 border-2 border-dashed border-gray-300 rounded-lg hover:border-blue-500 hover:bg-blue-50 transition-colors"
          >
            <Plus size={20} />
            <span className="font-medium">Add Product</span>
          </Link>
          <Link
            to="/seller/orders"
            className="flex items-center gap-2 p-4 border-2 border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
          >
            <ShoppingCart size={20} />
            <span className="font-medium">View Orders</span>
          </Link>
          <Link
            to="/seller/products"
            className="flex items-center gap-2 p-4 border-2 border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
          >
            <Package size={20} />
            <span className="font-medium">Manage Products</span>
          </Link>
          <Link
            to="/seller/shop"
            className="flex items-center gap-2 p-4 border-2 border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
          >
            <Edit size={20} />
            <span className="font-medium">Edit Shop</span>
          </Link>
        </div>
      </div>

      {/* Recent Products */}
      <div className="bg-white rounded-lg shadow-md p-6">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold">Recent Products</h2>
          <Link to="/seller/products" className="text-blue-600 hover:underline">
            View All
          </Link>
        </div>
        {recentProducts.length > 0 ? (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-3 text-left text-sm font-semibold">Product</th>
                  <th className="px-4 py-3 text-left text-sm font-semibold">Price</th>
                  <th className="px-4 py-3 text-left text-sm font-semibold">Stock</th>
                  <th className="px-4 py-3 text-left text-sm font-semibold">Status</th>
                  <th className="px-4 py-3 text-left text-sm font-semibold">Actions</th>
                </tr>
              </thead>
              <tbody>
                {recentProducts.map((product) => (
                  <tr key={product.id} className="border-t">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <img
                          src={
                            product.product_images?.[0]?.image_url ||
                            'https://via.placeholder.com/50'
                          }
                          alt={product.name}
                          className="w-12 h-12 object-cover rounded"
                        />
                        <span className="font-medium">{product.name}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3">৳{product.price}</td>
                    <td className="px-4 py-3">{product.stock_quantity}</td>
                    <td className="px-4 py-3">
                      <span
                        className={`px-2 py-1 text-xs rounded-full ${
                          product.approval_status === 'approved'
                            ? 'bg-green-100 text-green-800'
                            : product.approval_status === 'pending'
                            ? 'bg-yellow-100 text-yellow-800'
                            : 'bg-red-100 text-red-800'
                        }`}
                      >
                        {product.approval_status}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <button className="p-1 hover:bg-gray-100 rounded">
                          <Eye size={18} />
                        </button>
                        <button className="p-1 hover:bg-gray-100 rounded">
                          <Edit size={18} />
                        </button>
                        <button className="p-1 hover:bg-gray-100 rounded text-red-600">
                          <Trash2 size={18} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <p className="text-gray-600 text-center py-8">
            No products yet. Start by adding your first product!
          </p>
        )}
      </div>
    </div>
  );
};
