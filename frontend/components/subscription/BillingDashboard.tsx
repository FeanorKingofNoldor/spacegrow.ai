// components/subscription/BillingDashboard.tsx
'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/Button';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { DashboardLayoutWrapper } from '@/components/dashboard/DashboardLayoutWrapper';
import { 
  CreditCard, 
  Download, 
  Plus,
  Settings,
  MapPin,
  Calendar,
  DollarSign,
  FileText,
  CheckCircle,
  Clock,
  XCircle
} from 'lucide-react';
import { cn } from '@/lib/utils';

export function BillingDashboard() {
  const [loading, setLoading] = useState(false);

  // Mock data - replace with real billing context later
  const mockBillingData = {
    paymentMethods: [
      {
        id: 'pm_1',
        type: 'card',
        card: { brand: 'visa', last4: '4242', exp_month: 12, exp_year: 2025 },
        is_default: true
      },
      {
        id: 'pm_2', 
        type: 'card',
        card: { brand: 'mastercard', last4: '8888', exp_month: 6, exp_year: 2026 },
        is_default: false
      }
    ],
    billingAddress: {
      line1: '123 Main Street',
      city: 'San Francisco',
      state: 'CA',
      postal_code: '94105',
      country: 'US'
    },
    invoices: [
      {
        id: 'inv_1',
        amount: 29.00,
        currency: 'USD',
        status: 'paid',
        description: 'Professional Plan - January 2024',
        created_at: '2024-01-15T00:00:00Z',
        invoice_url: '#'
      },
      {
        id: 'inv_2',
        amount: 29.00,
        currency: 'USD', 
        status: 'paid',
        description: 'Professional Plan - December 2023',
        created_at: '2023-12-15T00:00:00Z',
        invoice_url: '#'
      },
      {
        id: 'inv_3',
        amount: 29.00,
        currency: 'USD',
        status: 'failed',
        description: 'Professional Plan - November 2023', 
        created_at: '2023-11-15T00:00:00Z',
        invoice_url: '#'
      }
    ]
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'paid': return 'text-green-400 bg-green-500/20';
      case 'pending': return 'text-yellow-400 bg-yellow-500/20';
      case 'failed': return 'text-red-400 bg-red-500/20';
      default: return 'text-cosmic-text-muted bg-space-secondary';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'paid': return CheckCircle;
      case 'pending': return Clock;
      case 'failed': return XCircle;
      default: return FileText;
    }
  };

  const formatCurrency = (amount: number, currency: string) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency
    }).format(amount);
  };

  return (
    <DashboardLayoutWrapper>
      <div className="max-w-6xl mx-auto space-y-8">
        {/* Header */}
        <div className="text-center">
          <h1 className="text-3xl font-bold text-cosmic-text mb-4">
            Billing & Payments
          </h1>
          <p className="text-cosmic-text-muted">
            Manage your payment methods, view invoices, and update billing information
          </p>
        </div>

        {/* Payment Methods */}
        <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-2xl p-8">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-xl font-bold text-cosmic-text">Payment Methods</h3>
            <Button variant="outline" size="sm">
              <Plus className="w-4 h-4 mr-2" />
              Add Payment Method
            </Button>
          </div>
          
          <div className="grid gap-4">
            {mockBillingData.paymentMethods.map((method) => (
              <div key={method.id} className="flex items-center justify-between bg-space-secondary rounded-xl p-4">
                <div className="flex items-center space-x-3">
                  <CreditCard className="w-10 h-10 text-cosmic-blue" />
                  <div>
                    <div className="flex items-center space-x-2">
                      <span className="font-medium text-cosmic-text capitalize">
                        {method.card.brand}
                      </span>
                      <span className="text-cosmic-text">•••• {method.card.last4}</span>
                      {method.is_default && (
                        <span className="px-2 py-1 bg-stellar-accent/20 text-stellar-accent text-xs rounded-full">
                          Default
                        </span>
                      )}
                    </div>
                    <div className="text-cosmic-text-muted text-sm">
                      Expires {method.card.exp_month.toString().padStart(2, '0')}/{method.card.exp_year}
                    </div>
                  </div>
                </div>
                
                <div className="flex items-center space-x-2">
                  {!method.is_default && (
                    <Button variant="ghost" size="sm">
                      Set Default
                    </Button>
                  )}
                  <Button variant="ghost" size="sm">
                    <Settings className="w-4 h-4" />
                  </Button>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Billing Address */}
        <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-2xl p-8">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-xl font-bold text-cosmic-text">Billing Address</h3>
            <Button variant="outline" size="sm">
              <Settings className="w-4 h-4 mr-2" />
              Update Address
            </Button>
          </div>
          
          <div className="flex items-start space-x-3">
            <MapPin className="w-5 h-5 text-cosmic-blue mt-1" />
            <div className="text-cosmic-text">
              <div>{mockBillingData.billingAddress.line1}</div>
              <div>
                {mockBillingData.billingAddress.city}, {mockBillingData.billingAddress.state} {mockBillingData.billingAddress.postal_code}
              </div>
              <div>{mockBillingData.billingAddress.country}</div>
            </div>
          </div>
        </div>

        {/* Billing History */}
        <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-2xl p-8">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-xl font-bold text-cosmic-text">Billing History</h3>
            <Button variant="outline" size="sm">
              <Download className="w-4 h-4 mr-2" />
              Export All
            </Button>
          </div>
          
          <div className="space-y-4">
            {mockBillingData.invoices.map((invoice) => {
              const StatusIcon = getStatusIcon(invoice.status);
              
              return (
                <div key={invoice.id} className="flex items-center justify-between bg-space-secondary rounded-xl p-4">
                  <div className="flex items-center space-x-4">
                    <StatusIcon className="w-5 h-5 text-cosmic-blue" />
                    <div>
                      <div className="font-medium text-cosmic-text">
                        {invoice.description}
                      </div>
                      <div className="text-cosmic-text-muted text-sm">
                        {new Date(invoice.created_at).toLocaleDateString()}
                      </div>
                    </div>
                  </div>
                  
                  <div className="flex items-center space-x-4">
                    <div className="text-right">
                      <div className="font-medium text-cosmic-text">
                        {formatCurrency(invoice.amount, invoice.currency)}
                      </div>
                      <span className={cn(
                        'px-2 py-1 text-xs font-medium rounded-full',
                        getStatusColor(invoice.status)
                      )}>
                        {invoice.status.toUpperCase()}
                      </span>
                    </div>
                    
                    {invoice.status === 'paid' && (
                      <Button variant="ghost" size="sm">
                        <Download className="w-4 h-4" />
                      </Button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Billing Summary */}
        <div className="grid md:grid-cols-2 gap-6">
          <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-2xl p-6">
            <div className="flex items-center space-x-3 mb-4">
              <DollarSign className="w-8 h-8 text-green-400" />
              <div>
                <h4 className="font-semibold text-cosmic-text">Total Paid</h4>
                <p className="text-cosmic-text-muted text-sm">This year</p>
              </div>
            </div>
            <div className="text-2xl font-bold text-green-400">$348.00</div>
          </div>

          <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-2xl p-6">
            <div className="flex items-center space-x-3 mb-4">
              <Calendar className="w-8 h-8 text-cosmic-blue" />
              <div>
                <h4 className="font-semibold text-cosmic-text">Next Payment</h4>
                <p className="text-cosmic-text-muted text-sm">Professional Plan</p>
              </div>
            </div>
            <div className="text-2xl font-bold text-cosmic-text">Feb 15, 2024</div>
          </div>
        </div>
      </div>
    </DashboardLayoutWrapper>
  );
}