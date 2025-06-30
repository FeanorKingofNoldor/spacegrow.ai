// hooks/useChartData.ts
'use client';

import { useState, useEffect, useCallback } from 'react';
import { ChartMode, ChartDataPoint } from '@/types/chart';

interface UseChartDataProps {
  sensorId: number;
  mode: ChartMode;
  autoRefresh?: boolean;
  refreshInterval?: number; // milliseconds
}

interface UseChartDataReturn {
  data: ChartDataPoint[];
  loading: boolean;
  error: string | null;
  refetch: () => Promise<void>;
}

export function useChartData({
  sensorId,
  mode,
  autoRefresh = false,
  refreshInterval = 60000 // 1 minute default
}: UseChartDataProps): UseChartDataReturn {
  const [data, setData] = useState<ChartDataPoint[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

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
        return;
      }

      const rawData = await response.json();
      
      // Convert API response to ChartDataPoint format
      const chartData: ChartDataPoint[] = rawData.map((point: [string, number]) => ({
        timestamp: point[0],
        value: point[1]
      }));

      setData(chartData);
      console.log(`📊 Fetched ${chartData.length} data points for sensor ${sensorId} (${mode})`);
      
    } catch (err) {
      console.error('❌ Failed to fetch chart data:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch data');
    } finally {
      setLoading(false);
    }
  }, [sensorId, mode]);

  // Initial data fetch
  useEffect(() => {
    fetchData();
  }, [fetchData]);

  // Auto-refresh for historical data
  useEffect(() => {
    if (!autoRefresh || mode === 'live') return;

    const interval = setInterval(fetchData, refreshInterval);
    return () => clearInterval(interval);
  }, [autoRefresh, mode, refreshInterval, fetchData]);

  return {
    data,
    loading,
    error,
    refetch: fetchData
  };
}