'use client';

import React from 'react';
import { useShop } from '@/contexts/ShopContext';
import { CartSidebar } from '@/components/shop/cart/CartSidebar';
import { EpicShopFooter } from '@/components/shop/common/EpicShopFooter';
import { useRouter } from 'next/navigation';

export default function ShopLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { 
    cart, 
    isCartOpen, 
    closeCart, 
    updateQuantity, 
    removeFromCart 
  } = useShop();
  
  const router = useRouter();

  const handleCheckout = () => {
    closeCart();
    router.push('/shop/checkout');
  };

  return (
    <>
      {/* No Header - each shop page has its own ShopNavHeader */}
      <main className="min-h-screen">{children}</main>
      
      {/* Epic Shop Footer */}
      <EpicShopFooter />
      
      {/* Single CartSidebar for the entire shop */}
      <CartSidebar
        isOpen={isCartOpen}
        onClose={closeCart}
        items={cart.items}
        onUpdateQuantity={updateQuantity}
        onRemoveItem={removeFromCart}
        onCheckout={handleCheckout}
      />
    </>
  );
}