// app/(dashboard)/user/dashboard/system_dashboard/page.tsx - System overview dashboard
'use client';

import { DashboardLayoutWrapper } from '@/components/dashboard/DashboardLayoutWrapper';
import { WelcomeSection } from '@/components/dashboard/auth_main_page/WelcomeSection';
import { BlogPostsSection } from '@/components/dashboard/auth_main_page/BlogPostsSection';
import { ForumHighlightsSection } from '@/components/dashboard/auth_main_page/ForumHighlightsSection';
import { SystemStatusSection } from '@/components/dashboard/auth_main_page/SystemStatusSection';
import { QuickActionsSection } from '@/components/dashboard/auth_main_page/QuickActionsSection';
import { FirmwareUpdatesSection } from '@/components/dashboard/auth_main_page/FirmwareUpdatesSection';
import { SystemOverviewSection } from '@/components/dashboard/SystemOverviewSection';
import { SubscriptionBanner } from '@/components/subscription/SubscriptionBanner';

export default function SystemDashboardPage() {
  return (
    <DashboardLayoutWrapper>
      <div className="space-y-6">
        {/* Welcome Section */}
        <WelcomeSection />

        {/* ✅ NEW: Subscription Alerts */}
        <SubscriptionBanner />

        {/* System Overview - Power, Stats, etc. */}
        <SystemOverviewSection />

        {/* Content Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <BlogPostsSection />
          <ForumHighlightsSection />
          <SystemStatusSection />
          <QuickActionsSection />
        </div>

        {/* Firmware Updates */}
        <FirmwareUpdatesSection />
      </div>
    </DashboardLayoutWrapper>
  );
}