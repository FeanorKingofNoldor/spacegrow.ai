// app/layout.tsx
import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { AuthProvider } from '@/contexts/AuthContext';
import { ThemeProvider } from '@/contexts/ThemeContext';
import { ShopProvider } from '@/contexts/ShopContext';

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
    <html lang="en" suppressHydrationWarning>
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        <ThemeProvider>
          <AuthProvider>
            <ShopProvider>
              {/* Cosmic Background Effects */}
              <div className="cosmic-starfield" />
              <div className="cosmic-sunflare" />
              
              {/* Main Content */}
              <div className="relative z-10">
                {children}
              </div>
            </ShopProvider>
          </AuthProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}