export function SystemStatusSection() {
  return (
    <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
      <h2 className="text-xl font-semibold text-cosmic-text mb-4">System Status</h2>
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <span className="text-cosmic-text">System Uptime</span>
          <span className="text-green-400 font-semibold">99.8%</span>
        </div>
        <div className="flex items-center justify-between">
          <span className="text-cosmic-text">API Connectivity</span>
          <div className="flex items-center space-x-2">
            <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
            <span className="text-green-400 text-sm">Online</span>
          </div>
        </div>
        <div className="flex items-center justify-between">
          <span className="text-cosmic-text">Last Backup</span>
          <span className="text-cosmic-text-muted text-sm">2 hours ago</span>
        </div>
      </div>
    </div>
  );
}