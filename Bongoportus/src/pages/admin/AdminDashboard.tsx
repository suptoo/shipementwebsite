import React, { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import {
  Users,
  ShoppingBag,
  DollarSign,
  Package,
  TrendingUp,
  UserCheck,
  AlertCircle,
} from 'lucide-react';

interface AdminStats {
  totalUsers: number;
  totalSellers: number;
  totalProducts: number;
  totalOrders: number;
  totalRevenue: number;
  pendingSellers: number;
  pendingProducts: number;
}

export const AdminDashboard: React.FC = () => {
  const [stats, setStats] = useState<AdminStats>({
    totalUsers: 0,
    totalSellers: 0,
    totalProducts: 0,
    totalOrders: 0,
    totalRevenue: 0,
    pendingSellers: 0,
    pendingProducts: 0,
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadAdminStats();
  }, []);

  const loadAdminStats = async () => {
    try {
      // Get user counts
      const { count: userCount } = await supabase
        .from('profiles')
        .select('*', { count: 'exact', head: true })
        .eq('role', 'user');

      const { count: sellerCount } = await supabase
        .from('seller_profiles')
        .select('*', { count: 'exact', head: true });

      const { count: pendingSellerCount } = await supabase
        .from('seller_profiles')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'pending');

      // Get product counts
      const { count: productCount } = await supabase
        .from('products')
        .select('*', { count: 'exact', head: true });

      const { count: pendingProductCount } = await supabase
        .from('products')
        .select('*', { count: 'exact', head: true })
        .eq('approval_status', 'pending');

      // Get order stats
      const { data: orders } = await supabase
        .from('orders')
        .select('total_amount');

      const totalOrders = orders?.length || 0;
      const totalRevenue =
        orders?.reduce((sum, order) => sum + order.total_amount, 0) || 0;

      setStats({
        totalUsers: userCount || 0,
        totalSellers: sellerCount || 0,
        totalProducts: productCount || 0,
        totalOrders,
        totalRevenue,
        pendingSellers: pendingSellerCount || 0,
        pendingProducts: pendingProductCount || 0,
      });
    } catch (error) {
      console.error('Error loading admin stats:', error);
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

  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">Admin Dashboard</h1>
        <p className="text-gray-600">Platform overview and management</p>
      </div>

      {/* Alerts */}
      {(stats.pendingSellers > 0 || stats.pendingProducts > 0) && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mb-6">
          <div className="flex items-start gap-3">
            <AlertCircle className="text-yellow-600 flex-shrink-0" size={20} />
            <div>
              <p className="font-semibold text-yellow-800">Action Required</p>
              {stats.pendingSellers > 0 && (
                <p className="text-yellow-700 text-sm">
                  {stats.pendingSellers} seller(s) waiting for approval
                </p>
              )}
              {stats.pendingProducts > 0 && (
                <p className="text-yellow-700 text-sm">
                  {stats.pendingProducts} product(s) pending review
                </p>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="p-3 bg-blue-100 rounded-lg">
              <Users className="text-blue-600" size={24} />
            </div>
            <TrendingUp className="text-green-500" size={20} />
          </div>
          <p className="text-2xl font-bold">{stats.totalUsers}</p>
          <p className="text-sm text-gray-600">Total Users</p>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="p-3 bg-purple-100 rounded-lg">
              <UserCheck className="text-purple-600" size={24} />
            </div>
            {stats.pendingSellers > 0 && (
              <span className="bg-yellow-500 text-white text-xs px-2 py-1 rounded-full">
                {stats.pendingSellers}
              </span>
            )}
          </div>
          <p className="text-2xl font-bold">{stats.totalSellers}</p>
          <p className="text-sm text-gray-600">Total Sellers</p>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="p-3 bg-green-100 rounded-lg">
              <Package className="text-green-600" size={24} />
            </div>
            {stats.pendingProducts > 0 && (
              <span className="bg-yellow-500 text-white text-xs px-2 py-1 rounded-full">
                {stats.pendingProducts}
              </span>
            )}
          </div>
          <p className="text-2xl font-bold">{stats.totalProducts}</p>
          <p className="text-sm text-gray-600">Total Products</p>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="p-3 bg-orange-100 rounded-lg">
              <ShoppingBag className="text-orange-600" size={24} />
            </div>
          </div>
          <p className="text-2xl font-bold">{stats.totalOrders}</p>
          <p className="text-sm text-gray-600">Total Orders</p>
        </div>
      </div>

      {/* Revenue Card */}
      <div className="bg-gradient-to-r from-blue-600 to-blue-800 text-white rounded-lg shadow-lg p-8 mb-8">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-blue-100 mb-2">Total Revenue</p>
            <p className="text-4xl font-bold">৳{stats.totalRevenue.toFixed(2)}</p>
          </div>
          <div className="p-4 bg-white/20 rounded-lg">
            <DollarSign size={48} />
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="font-semibold text-lg mb-4">Seller Management</h3>
          <div className="space-y-2">
            <a href="/admin/sellers" className="block text-blue-600 hover:underline">
              View All Sellers →
            </a>
            <a
              href="/admin/sellers?status=pending"
              className="block text-blue-600 hover:underline"
            >
              Pending Approvals ({stats.pendingSellers}) →
            </a>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="font-semibold text-lg mb-4">Product Management</h3>
          <div className="space-y-2">
            <a href="/admin/products" className="block text-blue-600 hover:underline">
              View All Products →
            </a>
            <a
              href="/admin/products?status=pending"
              className="block text-blue-600 hover:underline"
            >
              Pending Reviews ({stats.pendingProducts}) →
            </a>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-md p-6">
          <h3 className="font-semibold text-lg mb-4">Order Management</h3>
          <div className="space-y-2">
            <a href="/admin/orders" className="block text-blue-600 hover:underline">
              View All Orders →
            </a>
            <a href="/admin/reports" className="block text-blue-600 hover:underline">
              Sales Reports →
            </a>
          </div>
        </div>
      </div>
    </div>
  );
};
