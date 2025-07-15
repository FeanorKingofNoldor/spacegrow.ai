// lib/config.ts - SINGLE SOURCE OF TRUTH for all configuration
// ✅ This file centralizes all environment-dependent URLs and settings

export const config = {
  // ✅ API Configuration
  api: {
    baseUrl: process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000',
    wsUrl: process.env.NEXT_PUBLIC_WS_URL || 'ws://localhost:3000/cable',
    timeout: 10000, // Request timeout in ms
  },

  // ✅ WebSocket Configuration
  websocket: {
    url: process.env.NEXT_PUBLIC_WS_URL || 'ws://localhost:3000/cable',
    maxReconnectAttempts: 5,
    reconnectBackoffMs: 1000,
    healthCheckIntervalMs: 30000,
    connectionTimeoutMs: 10000,
  },

  // ✅ Chart Configuration
  charts: {
    defaultRefreshInterval: 60000, // 1 minute
    enableWebSocketByDefault: true,
    historicalDataPoints: {
      '24h': 144,   // Every 10 minutes
      '7d': 168,    // Every hour
      '3m': 90,     // Every day
    },
  },

  // ✅ Environment Detection
  env: {
    isDevelopment: process.env.NEXT_PUBLIC_ENVIRONMENT === 'development' || process.env.NODE_ENV === 'development',
    isProduction: process.env.NEXT_PUBLIC_ENVIRONMENT === 'production' || process.env.NODE_ENV === 'production',
    isTest: process.env.NODE_ENV === 'test',
  },

  // ✅ Feature Flags
  features: {
    enableSubscriptions: process.env.NEXT_PUBLIC_ENABLE_SUBSCRIPTIONS === 'true',
    enableBilling: process.env.NEXT_PUBLIC_ENABLE_BILLING === 'true',
    enableWebSocketCharts: true, // Always enabled now
    enableDebugLogs: process.env.NEXT_PUBLIC_ENVIRONMENT === 'development',
  },

  // ✅ Subscription Configuration
  subscription: {
    trialPeriodDays: parseInt(process.env.NEXT_PUBLIC_TRIAL_PERIOD_DAYS || '7'),
    gracePeriodDays: parseInt(process.env.NEXT_PUBLIC_GRACE_PERIOD_DAYS || '3'),
    maxDevicesBasic: 2,
    maxDevicesPro: 10,
  },

  // ✅ External Services
  stripe: {
    publishableKey: process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY || '',
  },

  cdn: {
    baseUrl: process.env.NEXT_PUBLIC_CDN_URL || '',
  },

  // ✅ App Metadata
  app: {
    name: 'XSpaceGrow',
    version: process.env.NEXT_PUBLIC_APP_VERSION || '1.0.0',
    supportEmail: 'support@xspacegrow.com',
  },
} as const;

// ✅ Utility functions for configuration
export const configUtils = {
  /**
   * Get the appropriate WebSocket URL based on API base URL if WS_URL not set
   */
  getWebSocketUrl(): string {
    if (config.websocket.url !== 'ws://localhost:3000/cable') {
      return config.websocket.url;
    }

    // Fallback: derive from API base URL
    const apiUrl = config.api.baseUrl;
    const wsProtocol = apiUrl.startsWith('https') ? 'wss:' : 'ws:';
    const urlWithoutProtocol = apiUrl.replace(/^https?:\/\//, '');
    
    return `${wsProtocol}//${urlWithoutProtocol}/cable`;
  },

  /**
   * Get API URL with optional path
   */
  getApiUrl(path: string = ''): string {
    const baseUrl = config.api.baseUrl.replace(/\/$/, ''); // Remove trailing slash
    const cleanPath = path.startsWith('/') ? path : `/${path}`;
    return `${baseUrl}${cleanPath}`;
  },

  /**
   * Check if a feature is enabled
   */
  isFeatureEnabled(feature: keyof typeof config.features): boolean {
    return config.features[feature];
  },

  /**
   * Get debug logging status
   */
  shouldLog(): boolean {
    return config.features.enableDebugLogs;
  },

  /**
   * Validate configuration on app startup
   */
  validateConfig(): { isValid: boolean; errors: string[] } {
    const errors: string[] = [];

    // Check required environment variables
    if (!config.api.baseUrl) {
      errors.push('NEXT_PUBLIC_API_BASE_URL is required');
    }

    if (config.features.enableBilling && !config.stripe.publishableKey) {
      errors.push('NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY is required when billing is enabled');
    }

    // Validate URLs
    try {
      new URL(config.api.baseUrl);
    } catch {
      errors.push('NEXT_PUBLIC_API_BASE_URL must be a valid URL');
    }

    try {
      new URL(configUtils.getWebSocketUrl());
    } catch {
      errors.push('WebSocket URL must be valid');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  },
};

// ✅ Export specific configurations for easy imports
export const apiConfig = config.api;
export const wsConfig = config.websocket;
export const chartConfig = config.charts;
export const featureFlags = config.features;

// ✅ Development helper
if (config.env.isDevelopment) {
  console.log('🔧 App Configuration:', {
    apiUrl: config.api.baseUrl,
    wsUrl: configUtils.getWebSocketUrl(),
    features: config.features,
    env: config.env,
  });

  // Validate config on startup in development
  const validation = configUtils.validateConfig();
  if (!validation.isValid) {
    console.error('❌ Configuration errors:', validation.errors);
  }
}