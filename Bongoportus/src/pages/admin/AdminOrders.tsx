import React, { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import {
    Package,
    CreditCard,
    Smartphone,
    Wallet,
    Search,
    ChevronDown,
    ChevronUp,
    Loader2,
    CheckCircle2,
    Clock,
    XCircle,
    Truck,
} from 'lucide-react';

interface Order {
    id: string;
    order_number: string;
    user_id: string;
    delivery_full_name: string;
    delivery_phone: string;
    delivery_city: string;
    delivery_state: string;
    total_amount: number;
    payment_method: string;
    payment_status: string;
    order_status: string;
    stripe_payment_intent_id: string | null;
    payment_details: string | null;
    created_at: string;
    profiles?: { email: string; full_name: string } | null;
}

interface PaymentDetails {
    method?: string;
    transactionId?: string;
    accountNumber?: string;
    cardType?: string;
    timestamp?: string;
}

export const AdminOrders: React.FC = () => {
    const [orders, setOrders] = useState<Order[]>([]);
    const [loading, setLoading] = useState(true);
    const [expandedOrder, setExpandedOrder] = useState<string | null>(null);
    const [searchQuery, setSearchQuery] = useState('');
    const [statusFilter, setStatusFilter] = useState<string>('all');

    useEffect(() => {
        loadOrders();
    }, []);

    const loadOrders = async () => {
        try {
            const { data, error } = await supabase
                .from('orders')
                .select('*, profiles(email, full_name)')
                .order('created_at', { ascending: false });

            if (error) throw error;
            setOrders(data || []);
        } catch (error) {
            console.error('Error loading orders:', error);
        } finally {
            setLoading(false);
        }
    };

    const updateOrderStatus = async (orderId: string, status: string) => {
        try {
            const { error } = await supabase
                .from('orders')
                .update({ order_status: status })
                .eq('id', orderId);

            if (error) throw error;
            loadOrders();
        } catch (error) {
            console.error('Error updating order status:', error);
        }
    };

    const parsePaymentDetails = (details: string | null): PaymentDetails | null => {
        if (!details) return null;
        try {
            return JSON.parse(details);
        } catch {
            return null;
        }
    };

    const getPaymentMethodDisplay = (order: Order) => {
        const details = parsePaymentDetails(order.payment_details);

        if (order.payment_method === 'cod') {
            return { icon: <Wallet className="w-4 h-4" />, label: 'Cash on Delivery', color: 'text-gray-600 bg-gray-100' };
        }

        if (details?.method === 'bkash') {
            return { icon: <Smartphone className="w-4 h-4" />, label: 'bKash', color: 'text-pink-600 bg-pink-100' };
        }
        if (details?.method === 'nagad') {
            return { icon: <Smartphone className="w-4 h-4" />, label: 'Nagad', color: 'text-orange-600 bg-orange-100' };
        }
        if (details?.method === 'upay') {
            return { icon: <Smartphone className="w-4 h-4" />, label: 'Upay', color: 'text-blue-600 bg-blue-100' };
        }
        if (details?.cardType === 'visa' || details?.method === 'visa') {
            return { icon: <CreditCard className="w-4 h-4" />, label: 'Visa Card', color: 'text-blue-700 bg-blue-100' };
        }
        if (details?.cardType === 'mastercard' || details?.method === 'mastercard') {
            return { icon: <CreditCard className="w-4 h-4" />, label: 'Mastercard', color: 'text-orange-700 bg-orange-100' };
        }
        if (order.payment_method === 'card') {
            return { icon: <CreditCard className="w-4 h-4" />, label: 'Card', color: 'text-slate-600 bg-slate-100' };
        }
        if (order.payment_method === 'mobile') {
            return { icon: <Smartphone className="w-4 h-4" />, label: 'Mobile Banking', color: 'text-purple-600 bg-purple-100' };
        }

        return { icon: <Wallet className="w-4 h-4" />, label: order.payment_method, color: 'text-gray-600 bg-gray-100' };
    };

    const getStatusBadge = (status: string) => {
        switch (status) {
            case 'pending':
                return { icon: <Clock className="w-3 h-3" />, color: 'bg-yellow-100 text-yellow-700', label: 'Pending' };
            case 'processing':
                return { icon: <Package className="w-3 h-3" />, color: 'bg-blue-100 text-blue-700', label: 'Processing' };
            case 'shipped':
                return { icon: <Truck className="w-3 h-3" />, color: 'bg-purple-100 text-purple-700', label: 'Shipped' };
            case 'delivered':
                return { icon: <CheckCircle2 className="w-3 h-3" />, color: 'bg-green-100 text-green-700', label: 'Delivered' };
            case 'cancelled':
                return { icon: <XCircle className="w-3 h-3" />, color: 'bg-red-100 text-red-700', label: 'Cancelled' };
            default:
                return { icon: <Clock className="w-3 h-3" />, color: 'bg-gray-100 text-gray-700', label: status };
        }
    };

    const filteredOrders = orders.filter((order) => {
        const matchesSearch =
            order.order_number.toLowerCase().includes(searchQuery.toLowerCase()) ||
            order.delivery_full_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
            order.delivery_phone.includes(searchQuery);
        const matchesStatus = statusFilter === 'all' || order.order_status === statusFilter;
        return matchesSearch && matchesStatus;
    });

    if (loading) {
        return (
            <div className="flex items-center justify-center min-h-screen">
                <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
            </div>
        );
    }

    return (
        <div className="max-w-7xl mx-auto px-4 py-8">
            <div className="mb-8">
                <h1 className="text-3xl font-bold mb-2">Order Management</h1>
                <p className="text-gray-600">View and manage all customer orders with payment details</p>
            </div>

            {/* Filters */}
            <div className="bg-white rounded-xl shadow-sm border p-4 mb-6 flex flex-col md:flex-row gap-4">
                <div className="flex-1 relative">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
                    <input
                        type="text"
                        placeholder="Search by order #, name, or phone..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    />
                </div>
                <select
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value)}
                    className="px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500"
                >
                    <option value="all">All Statuses</option>
                    <option value="pending">Pending</option>
                    <option value="processing">Processing</option>
                    <option value="shipped">Shipped</option>
                    <option value="delivered">Delivered</option>
                    <option value="cancelled">Cancelled</option>
                </select>
            </div>

            {/* Orders List */}
            <div className="space-y-4">
                {filteredOrders.length === 0 ? (
                    <div className="bg-white rounded-xl shadow-sm border p-12 text-center">
                        <Package className="w-12 h-12 text-gray-300 mx-auto mb-4" />
                        <p className="text-gray-500">No orders found</p>
                    </div>
                ) : (
                    filteredOrders.map((order) => {
                        const paymentMethod = getPaymentMethodDisplay(order);
                        const statusBadge = getStatusBadge(order.order_status);
                        const paymentDetails = parsePaymentDetails(order.payment_details);
                        const isExpanded = expandedOrder === order.id;

                        return (
                            <div key={order.id} className="bg-white rounded-xl shadow-sm border overflow-hidden">
                                {/* Order Header */}
                                <div
                                    onClick={() => setExpandedOrder(isExpanded ? null : order.id)}
                                    className="p-4 cursor-pointer hover:bg-gray-50 transition-colors"
                                >
                                    <div className="flex flex-wrap items-center justify-between gap-4">
                                        <div className="flex items-center gap-4">
                                            <div>
                                                <p className="font-bold text-lg">{order.order_number}</p>
                                                <p className="text-sm text-gray-500">
                                                    {new Date(order.created_at).toLocaleDateString('en-US', {
                                                        year: 'numeric',
                                                        month: 'short',
                                                        day: 'numeric',
                                                        hour: '2-digit',
                                                        minute: '2-digit',
                                                    })}
                                                </p>
                                            </div>
                                        </div>

                                        <div className="flex items-center gap-3">
                                            {/* Payment Method Badge */}
                                            <span className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium ${paymentMethod.color}`}>
                                                {paymentMethod.icon}
                                                {paymentMethod.label}
                                            </span>

                                            {/* Payment Status */}
                                            <span className={`px-3 py-1.5 rounded-lg text-sm font-medium ${order.payment_status === 'paid'
                                                    ? 'bg-green-100 text-green-700'
                                                    : 'bg-yellow-100 text-yellow-700'
                                                }`}>
                                                {order.payment_status === 'paid' ? '✓ Paid' : '⏳ Pending'}
                                            </span>

                                            {/* Order Status */}
                                            <span className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium ${statusBadge.color}`}>
                                                {statusBadge.icon}
                                                {statusBadge.label}
                                            </span>

                                            {/* Total */}
                                            <span className="font-bold text-lg text-blue-600">
                                                ৳{order.total_amount.toLocaleString()}
                                            </span>

                                            {isExpanded ? <ChevronUp className="w-5 h-5 text-gray-400" /> : <ChevronDown className="w-5 h-5 text-gray-400" />}
                                        </div>
                                    </div>
                                </div>

                                {/* Expanded Details */}
                                {isExpanded && (
                                    <div className="border-t p-4 bg-gray-50">
                                        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                                            {/* Customer Info */}
                                            <div>
                                                <h4 className="font-semibold text-gray-900 mb-2">Customer Details</h4>
                                                <div className="space-y-1 text-sm">
                                                    <p><span className="text-gray-500">Name:</span> {order.delivery_full_name}</p>
                                                    <p><span className="text-gray-500">Phone:</span> {order.delivery_phone}</p>
                                                    <p><span className="text-gray-500">Location:</span> {order.delivery_city}, {order.delivery_state}</p>
                                                    {order.profiles?.email && (
                                                        <p><span className="text-gray-500">Email:</span> {order.profiles.email}</p>
                                                    )}
                                                </div>
                                            </div>

                                            {/* Payment Details */}
                                            <div>
                                                <h4 className="font-semibold text-gray-900 mb-2">Payment Details</h4>
                                                <div className="space-y-1 text-sm">
                                                    <p><span className="text-gray-500">Method:</span> {paymentMethod.label}</p>
                                                    {paymentDetails?.transactionId && (
                                                        <p>
                                                            <span className="text-gray-500">Transaction ID:</span>{' '}
                                                            <span className="font-mono bg-white px-2 py-0.5 rounded border">{paymentDetails.transactionId}</span>
                                                        </p>
                                                    )}
                                                    {paymentDetails?.accountNumber && (
                                                        <p>
                                                            <span className="text-gray-500">Account/Mobile:</span>{' '}
                                                            <span className="font-mono">{paymentDetails.accountNumber}</span>
                                                        </p>
                                                    )}
                                                    {paymentDetails?.cardType && (
                                                        <p>
                                                            <span className="text-gray-500">Card Type:</span>{' '}
                                                            <span className="font-semibold capitalize">{paymentDetails.cardType}</span>
                                                        </p>
                                                    )}
                                                    {order.stripe_payment_intent_id && !paymentDetails?.transactionId && (
                                                        <p>
                                                            <span className="text-gray-500">Txn ID:</span>{' '}
                                                            <span className="font-mono text-xs">{order.stripe_payment_intent_id}</span>
                                                        </p>
                                                    )}
                                                    <p><span className="text-gray-500">Status:</span> {order.payment_status}</p>
                                                </div>
                                            </div>

                                            {/* Order Actions */}
                                            <div>
                                                <h4 className="font-semibold text-gray-900 mb-2">Update Status</h4>
                                                <select
                                                    value={order.order_status}
                                                    onChange={(e) => updateOrderStatus(order.id, e.target.value)}
                                                    className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500"
                                                >
                                                    <option value="pending">Pending</option>
                                                    <option value="processing">Processing</option>
                                                    <option value="shipped">Shipped</option>
                                                    <option value="delivered">Delivered</option>
                                                    <option value="cancelled">Cancelled</option>
                                                </select>
                                            </div>
                                        </div>
                                    </div>
                                )}
                            </div>
                        );
                    })
                )}
            </div>
        </div>
    );
};
