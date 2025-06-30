// app/(dashboard)/user/page.tsx - Main user landing page (redirects to system dashboard)
'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';

export default function UserPage() {
  const router = useRouter();

  useEffect(() => {
    // Redirect to system dashboard as the default user landing
    router.push('/user/dashboard/system_dashboard');
  }, [router]);

  return (
    <div className="min-h-screen bg-space-primary flex items-center justify-center">
      <div className="cosmic-starfield" />
      <div className="cosmic-sunflare" />
      <div className="relative z-10">
        <LoadingSpinner />
      </div>
    </div>
  );
}