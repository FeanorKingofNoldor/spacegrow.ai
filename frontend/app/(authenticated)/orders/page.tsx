// app/(authenticated)/orders/page.tsx
'use client';

import { useState, useEffect } from 'react';
import { Order } from '@/types/shop';
import { Package, Calendar, CreditCard, Download, Eye } from 'lucide-react';

export default function OrdersPage() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchOrders();
  }, []);

  const fetchOrders = async () => {
    try {
      const response = await fetch('/api/v1/store/orders', {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('auth_token')}` // Adjust based on your auth
        }
      });

      if (!response.ok) {
        throw new Error('Failed to fetch orders');
      }

      const data = await response.json();
      if (data.status === 'success') {
        setOrders(data.data.orders || []);
      }
    } catch (err) {
      console.error('Error fetching orders:', err);
      setError('Failed to load orders');
    } finally {
      setLoading(false);
    }
  };

  const getStatusBadge = (status: string) => {
    const statusConfig = {
      pending: { bg: 'bg-yellow-100', text: 'text-yellow-800', label: 'Pending' },
      paid: { bg: 'bg-green-100', text: 'text-green-800', label: 'Paid' },
      completed: { bg: 'bg-blue-100', text: 'text-blue-800', label: 'Completed' },
      refunded: { bg: 'bg-red-100', text: 'text-red-800', label: 'Refunded' }
    };

    const config = statusConfig[status as keyof typeof statusConfig] || statusConfig.pending;

    return (
      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${config.bg} ${config.text}`}>
        {config.label}
      </span>
    );
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading your orders...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <Package className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <h1 className="text-2xl font-bold text-gray-900 mb-2">Unable to load orders</h1>
          <p className="text-gray-600 mb-6">{error}</p>
          <button
            onClick={fetchOrders}
            className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors"
          >
            Try Again
          </button>
        </div>
      </div>
    );
  }

  if (orders.length === 0) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <Package className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <h1 className="text-2xl font-bold text-gray-900 mb-2">No orders yet</h1>
          <p className="text-gray-600 mb-6">When you make a purchase, your orders will appear here.</p>
          <a
            href="/shop"
            className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors inline-block"
          >
            Start Shopping
          </a>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Order History</h1>
          <p className="text-gray-600 mt-2">View and manage your IoT device orders</p>
        </div>

        <div className="space-y-6">
          {orders.map((order) => (
            <div key={order.id} className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
              {/* Order Header */}
              <div className="px-6 py-4 border-b border-gray-200 bg-gray-50">
                <div className="flex flex-col md:flex-row md:items-center justify-between">
                  <div className="flex items-center gap-4">
                    <div>
                      <h3 className="text-lg font-semibold text-gray-900">
                        Order #{order.id}
                      </h3>
                      <div className="flex items-center gap-4 text-sm text-gray-600 mt-1">
                        <div className="flex items-center gap-1">
                          <Calendar className="w-4 h-4" />
                          {new Date(order.created_at).toLocaleDateString()}
                        </div>
                        <div className="flex items-center gap-1">
                          <CreditCard className="w-4 h-4" />
                          ${order.total}
                        </div>
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center gap-3 mt-3 md:mt-0">
                    {getStatusBadge(order.status)}
                    <button className="flex items-center gap-1 text-blue-600 hover:text-blue-700 text-sm font-medium">
                      <Eye className="w-4 h-4" />
                      View Details
                    </button>
                  </div>
                </div>
              </div>

              {/* Order Items */}
              <div className="px-6 py-4">
                <div className="space-y-3">
                  {order.line_items.map((item) => (
                    <div key={item.id} className="flex items-center gap-4">
                      <div className="w-12 h-12 bg-gray-200 rounded-lg flex items-center justify-center">
                        <Package className="w-6 h-6 text-gray-600" />
                      </div>
                      <div className="flex-1">
                        <h4 className="font-medium text-gray-900">{item.product_name}</h4>
                        <p className="text-sm text-gray-600">
                          Quantity: {item.quantity} × ${item.price} = ${item.subtotal}
                        </p>
                      </div>
                      {order.status === 'completed' && (
                        <button className="flex items-center gap-1 text-blue-600 hover:text-blue-700 text-sm">
                          <Download className="w-4 h-4" />
                          Download Tokens
                        </button>
                      )}
                    </div>
                  ))}
                </div>
              </div>

              {/* Order Actions */}
              {order.status === 'completed' && (
                <div className="px-6 py-4 bg-green-50 border-t border-green-200">
                  <div className="flex items-center justify-between">
                    <div className="text-sm text-green-700">
                      ✅ Order completed - Device activation tokens have been sent to your email
                    </div>
                    <button className="text-green-600 hover:text-green-700 text-sm font-medium">
                      Resend Tokens
                    </button>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}