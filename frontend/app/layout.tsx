// app/layout.tsx - MERGED with SubscriptionProvider
import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { AuthProvider } from '@/contexts/AuthContext';
import { ShopProvider } from '@/contexts/ShopContext';
import { PresetProvider } from '@/contexts/PresetContext';
import { SubscriptionProvider } from '@/contexts/SubscriptionContext'; // ✅ NEW: Import SubscriptionProvider
import { SubscriptionGuard } from '@/components/guards/SubscriptionGuard'; // ✅ NEW: Import SubscriptionGuard
import { ClientOnlyDotSparkles, ClientOnlyIconSparkles } from '@/components/ui/ClientOnlySparkle';

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "SpaceGrow.ai",
  description: "IoT Device Management Platform for Smart Growing",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased bg-transparent overflow-x-hidden`}
      >
        <AuthProvider>
          <SubscriptionProvider> {/* ✅ NEW: Wrap with SubscriptionProvider */}
            <PresetProvider>
              <ShopProvider>
                <SubscriptionGuard> {/* ✅ NEW: Add subscription route protection */}
                  {/* EPIC COSMIC BACKGROUND - Fixed position, never moves */}
                  <div className="fixed inset-0 z-0 bg-gradient-to-br from-purple-900 via-blue-900 to-pink-900">
                    {/* Animated supernova core */}
                    <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2">
                      <div className="w-96 h-96 bg-gradient-radial from-yellow-400/30 via-orange-500/20 to-transparent rounded-full animate-pulse"></div>
                      <div className="absolute inset-0 w-96 h-96 bg-gradient-radial from-pink-500/20 via-purple-600/15 to-transparent rounded-full animate-ping"></div>
                    </div>

                    {/* Stellar particles */}
                    <div className="cosmic-starfield" />
                    <div className="cosmic-sunflare" />

                    {/* EPIC SPARKLES - Multiple layers */}
                    <ClientOnlyDotSparkles 
                      count={60} 
                      className="absolute inset-0"
                    />
                    <ClientOnlyIconSparkles 
                      count={30} 
                      className="absolute inset-0"
                      iconClassName="w-2 h-2 text-yellow-400/30"
                    />
                    <ClientOnlyIconSparkles 
                      count={20} 
                      className="absolute inset-0"
                      iconClassName="w-3 h-3 text-pink-400/20"
                    />

                    {/* Nebula clouds */}
                    <div className="absolute inset-0">
                      <div className="absolute top-20 left-10 w-64 h-64 bg-gradient-radial from-blue-500/10 to-transparent rounded-full blur-3xl animate-slow-float"></div>
                      <div className="absolute bottom-20 right-10 w-80 h-80 bg-gradient-radial from-purple-500/10 to-transparent rounded-full blur-3xl animate-slow-float-reverse"></div>
                      <div className="absolute top-1/3 right-1/4 w-48 h-48 bg-gradient-radial from-pink-500/10 to-transparent rounded-full blur-2xl animate-slow-float"></div>
                    </div>
                  </div>
                  
                  {/* Main Content - Floats above background */}
                  <div className="relative z-20">
                    {children}
                  </div>
                </SubscriptionGuard>
              </ShopProvider>
            </PresetProvider>
          </SubscriptionProvider> {/* ✅ NEW: Close SubscriptionProvider */}
        </AuthProvider>
      </body>
    </html>
  );
}
