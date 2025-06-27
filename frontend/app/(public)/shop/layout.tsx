// (public)/shop/layout.tsx
import React from 'react';
import { EpicShopFooter } from '@/components/shop/common/EpicShopFooter';

export default function ShopLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      {/* No Header - each shop page has its own ShopNavHeader */}
      <main className="min-h-screen">{children}</main>
      {/* Epic Shop Footer */}
      <EpicShopFooter />
    </>
  );
}