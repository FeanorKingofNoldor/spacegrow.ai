// hooks/useChartData.ts - ENHANCED with WebSocket real-time updates
'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { ChartMode, ChartDataPoint } from '@/types/chart';
import { useAuth } from '@/contexts/AuthContext';
import { actionCable } from '@/lib/actionCable';
import { WebSocketMessage, isChartDataUpdate } from '@/types/websocket';

interface UseChartDataProps {
  sensorId: number;
  mode: ChartMode;
  autoRefresh?: boolean;
  refreshInterval?: number; // milliseconds
  enableWebSocket?: boolean; // NEW: Enable real-time updates
}

interface UseChartDataReturn {
  data: ChartDataPoint[];
  loading: boolean;
  error: string | null;
  refetch: () => Promise<void>;
  lastUpdate: Date | null; // NEW: Track last update time
  isLive: boolean; // NEW: Track if receiving live data
}

export function useChartData({
  sensorId,
  mode,
  autoRefresh = false,
  refreshInterval = 60000, // 1 minute default
  enableWebSocket = true // NEW: Enable by default
}: UseChartDataProps): UseChartDataReturn {
  const [data, setData] = useState<ChartDataPoint[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdate, setLastUpdate] = useState<Date | null>(null);
  const [isLive, setIsLive] = useState(false);
  
  // ✅ NEW: WebSocket connection management
  const { user } = useAuth();
  const wsConnectedRef = useRef(false);
  const callbackRegisteredRef = useRef(false);

  // ✅ NEW: Setup WebSocket connection for real-time updates
  useEffect(() => {
    if (!enableWebSocket || !user || !sensorId) return;

    const setupWebSocket = async () => {
      try {
        // Connect to ActionCable if not already connected
        if (!actionCable.isConnected()) {
          const token = localStorage.getItem('auth_token');
          if (token) {
            await actionCable.connect(user.id, token);
            wsConnectedRef.current = true;
            console.log('📊 WebSocket connected for chart data');
          }
        }

        // Register callback for chart data updates - ✅ FIXED: Now handles all WebSocket message types
        if (!callbackRegisteredRef.current) {
          actionCable.on('chart_data_update', handleWebSocketUpdate);
          callbackRegisteredRef.current = true;
          setIsLive(true);
          console.log(`📊 Listening for chart updates on sensor ${sensorId}`);
        }

      } catch (error) {
        console.error('❌ Failed to setup WebSocket for charts:', error);
        setIsLive(false);
      }
    };

    setupWebSocket();

    // Cleanup function
    return () => {
      if (callbackRegisteredRef.current) {
        actionCable.off('chart_data_update');
        callbackRegisteredRef.current = false;
        setIsLive(false);
        console.log(`📊 Stopped listening for chart updates on sensor ${sensorId}`);
      }
    };
  }, [enableWebSocket, user, sensorId]);

  // ✅ FIXED: Handle incoming WebSocket messages with proper type guards
  const handleWebSocketUpdate = useCallback((message: WebSocketMessage) => {
    console.log('📊 WebSocket message received:', message);

    // ✅ FIXED: Use type guard for better type safety
    if (!isChartDataUpdate(message)) {
      console.log(`📊 Message type ${message.type} not relevant for charts, ignoring`);
      return;
    }

    // Now TypeScript knows message is ChartDataUpdate
    const chartUpdate = message;

    // Check if this update is for our sensor
    const chartId = `chart-${sensorId}`;
    if (chartUpdate.chart_id !== chartId) {
      console.log(`📊 Update not for our sensor (${chartId}), ignoring`);
      return;
    }

    // Only update if we're in live mode
    if (mode !== 'live') {
      console.log('📊 Not in live mode, ignoring real-time update');
      return;
    }

    try {
      // Convert WebSocket data to ChartDataPoint format
      const newData: ChartDataPoint[] = chartUpdate.data_points.map(([timestamp, value]) => ({
        timestamp,
        value
      }));

      console.log(`📊 Updating chart data for sensor ${sensorId}:`, newData);
      
      setData(newData);
      setLastUpdate(new Date());
      setError(null);
      
      // Show brief loading state for visual feedback
      setLoading(true);
      setTimeout(() => setLoading(false), 200);

    } catch (error) {
      console.error('❌ Error processing WebSocket chart update:', error);
      setError('Failed to process real-time update');
    }
  }, [sensorId, mode]);

  // ✅ ENHANCED: Fetch data via HTTP API (fallback + historical data)
  const fetchData = useCallback(async () => {
    if (!sensorId) return;

    setLoading(true);
    setError(null);

    try {
      const modeParam = mode === 'live' ? 'current' : mode;
      const response = await fetch(
        `/api/v1/chart_data/latest?sensor_id=${sensorId}&mode=${modeParam}`,
        {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('auth_token')}`,
            'Content-Type': 'application/json'
          }
        }
      );

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      // Handle empty response (204 No Content)
      if (response.status === 204) {
        setData([]);
        setLastUpdate(new Date());
        return;
      }

      const rawData = await response.json();
      
      // Convert API response to ChartDataPoint format
      const chartData: ChartDataPoint[] = rawData.map((point: [string, number]) => ({
        timestamp: point[0],
        value: point[1]
      }));

      setData(chartData);
      setLastUpdate(new Date());
      console.log(`📊 Fetched ${chartData.length} data points for sensor ${sensorId} (${mode})`);
      
    } catch (err) {
      console.error('❌ Failed to fetch chart data:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch data');
    } finally {
      setLoading(false);
    }
  }, [sensorId, mode]);

  // ✅ ENHANCED: Initial data fetch
  useEffect(() => {
    fetchData();
  }, [fetchData]);

  // ✅ ENHANCED: Auto-refresh for historical data (not needed for live mode with WebSocket)
  useEffect(() => {
    // Don't auto-refresh if:
    // - Auto-refresh is disabled
    // - We're in live mode and WebSocket is working
    // - We're in live mode (WebSocket handles updates)
    if (!autoRefresh || (mode === 'live' && isLive)) {
      return;
    }

    const interval = setInterval(fetchData, refreshInterval);
    return () => clearInterval(interval);
  }, [autoRefresh, mode, refreshInterval, fetchData, isLive]);

  // ✅ NEW: Re-fetch when switching from live to historical modes
  useEffect(() => {
    // When switching away from live mode, fetch historical data immediately
    if (mode !== 'live') {
      fetchData();
    }
  }, [mode, fetchData]);

  return {
    data,
    loading,
    error,
    refetch: fetchData,
    lastUpdate, // NEW: When data was last updated
    isLive: isLive && mode === 'live' // NEW: True if receiving real-time updates
  };
}