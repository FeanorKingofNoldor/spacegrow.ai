import React, { useState, useEffect } from 'react';
import { Activity, AlertTriangle, Wifi, WifiOff, Droplets } from 'lucide-react';
import { DeviceSensor } from '@/types/device';

interface HumidityGaugeChartProps {
  sensor: DeviceSensor;
  value: number | null | undefined;
  className?: string;
}

// Humidity Gauge Component
const HumidityGaugeChart: React.FC<HumidityGaugeChartProps> = ({ sensor, value, className = '' }) => {
  const [animatedValue, setAnimatedValue] = useState(0);
  const { sensor_type } = sensor;
  
  // Animation effect when value changes
  useEffect(() => {
    const timer = setTimeout(() => {
      setAnimatedValue(value || 0);
    }, 300);
    return () => clearTimeout(timer);
  }, [value]);

  // Check if we have valid data
  const hasValidData = value !== null && value !== undefined && !isNaN(value);
  
  // Gauge configuration
  const size = 300;
  const center = size / 2;
  const radius = 110;
  const strokeWidth = 25;
  
  // Angle configuration (240 degrees total, starting from bottom-left)
  const startAngle = 150; // Start angle in degrees
  const endAngle = 390;   // End angle in degrees (240 degrees total)
  const totalAngle = endAngle - startAngle;
  
  // Helper function to convert degrees to radians
  const toRadians = (degrees: number): number => (degrees * Math.PI) / 180;
  
  // Helper function to get point on circle
  const getPoint = (angle: number, r: number = radius): { x: number; y: number } => {
    const radian = toRadians(angle);
    return {
      x: center + r * Math.cos(radian),
      y: center + r * Math.sin(radian)
    };
  };
  
  // Create arc path for SVG
  const createArc = (startAngle: number, endAngle: number, innerRadius: number, outerRadius: number): string => {
    const start = getPoint(startAngle, outerRadius);
    const end = getPoint(endAngle, outerRadius);
    const startInner = getPoint(startAngle, innerRadius);
    const endInner = getPoint(endAngle, innerRadius);
    
    const largeArcFlag = endAngle - startAngle <= 180 ? "0" : "1";
    
    return [
      "M", start.x, start.y,
      "A", outerRadius, outerRadius, 0, largeArcFlag, 1, end.x, end.y,
      "L", endInner.x, endInner.y,
      "A", innerRadius, innerRadius, 0, largeArcFlag, 0, startInner.x, startInner.y,
      "Z"
    ].join(" ");
  };
  
  // Define humidity zones with moisture-specific color scheme
  const zones = [
    {
      min: sensor_type.error_low_min,
      max: sensor_type.error_low_max,
      color: '#ff0040',
      label: 'Very Dry'
    },
    {
      min: sensor_type.warning_low_min,
      max: sensor_type.warning_low_max,
      color: '#ffaa00',
      label: 'Dry'
    },
    {
      min: sensor_type.normal_min,
      max: sensor_type.normal_max,
      color: '#00ff80',
      label: 'Optimal'
    },
    {
      min: sensor_type.warning_high_min,
      max: sensor_type.warning_high_max,
      color: '#00aaff',
      label: 'Humid'
    },
    {
      min: sensor_type.error_high_min,
      max: sensor_type.error_high_max,
      color: '#aa00ff',
      label: 'Very Humid'
    }
  ];
  
  // Calculate needle angle
  const valueRange = sensor_type.max_value - sensor_type.min_value;
  const valueRatio = Math.max(0, Math.min(1, (animatedValue - sensor_type.min_value) / valueRange));
  const needleAngle = startAngle + (valueRatio * totalAngle);
  
  // Get current zone color
  const getCurrentZoneColor = (val: number): string => {
    for (const zone of zones) {
      if (val >= zone.min && val <= zone.max) {
        return zone.color;
      }
    }
    return '#6b7280';
  };
  
  // Get current zone status
  const getCurrentZoneStatus = (val: number): string => {
    if (val >= sensor_type.normal_min && val <= sensor_type.normal_max) return 'OPTIMAL';
    if ((val >= sensor_type.warning_low_min && val <= sensor_type.warning_low_max) || 
        (val >= sensor_type.warning_high_min && val <= sensor_type.warning_high_max)) return 'WARNING';
    return 'CRITICAL';
  };

  // Get current zone info for display
  const getCurrentZoneInfo = (val: number): { status: string; color: string } => {
    for (const zone of zones) {
      if (val >= zone.min && val <= zone.max) {
        return {
          status: zone.label,
          color: zone.color
        };
      }
    }
    return { status: 'Unknown', color: '#6b7280' };
  };
  
  // Generate tick marks for humidity scale (0-100%)
  const generateHumidityTicks = (): React.ReactElement[] => {
    const ticks: React.ReactElement[] = [];
    
    // Major ticks every 20% (0, 20, 40, 60, 80, 100)
    const majorTicks = [0, 20, 40, 60, 80, 100];
    
    majorTicks.forEach((tickValue: number, i: number) => {
      const tickAngle = startAngle + (tickValue / sensor_type.max_value) * totalAngle;
      const tickStart = getPoint(tickAngle, radius - strokeWidth / 2 - 15);
      const tickEnd = getPoint(tickAngle, radius - strokeWidth / 2 - 5);
      const labelPos = getPoint(tickAngle, radius - strokeWidth / 2 - 25);
      
      ticks.push(
        <g key={`humidity-major-tick-${i}`}>
          <line
            x1={tickStart.x}
            y1={tickStart.y}
            x2={tickEnd.x}
            y2={tickEnd.y}
            stroke="#00ff41"
            strokeWidth="2"
            opacity="0.9"
            style={{ filter: 'drop-shadow(0 0 3px #00ff41)' }}
          />
          <text
            x={labelPos.x}
            y={labelPos.y}
            textAnchor="middle"
            dominantBaseline="middle"
            fill="#00ff41"
            fontSize="11"
            fontWeight="600"
            style={{ filter: 'drop-shadow(0 0 3px #00ff41)' }}
          >
            {tickValue}
          </text>
        </g>
      );
    });
    
    return ticks;
  };
  
  // Generate minor tick marks for humidity scale (10, 30, 50, 70, 90)
  const generateMinorHumidityTicks = (): React.ReactElement[] => {
    const ticks: React.ReactElement[] = [];
    const minorTicks = [10, 30, 50, 70, 90];
    
    minorTicks.forEach((tickValue: number, i: number) => {
      const tickAngle = startAngle + (tickValue / sensor_type.max_value) * totalAngle;
      const tickStart = getPoint(tickAngle, radius - strokeWidth / 2 - 45);
      const tickEnd = getPoint(tickAngle, radius - strokeWidth / 2 - 35);
      const labelPos = getPoint(tickAngle, radius - strokeWidth / 2 - 55);
      
      ticks.push(
        <g key={`humidity-minor-tick-${i}`}>
          <line
            x1={tickStart.x}
            y1={tickStart.y}
            x2={tickEnd.x}
            y2={tickEnd.y}
            stroke="#00ffff"
            strokeWidth="1"
            opacity="0.8"
            style={{ filter: 'drop-shadow(0 0 2px #00ffff)' }}
          />
          <text
            x={labelPos.x}
            y={labelPos.y}
            textAnchor="middle"
            dominantBaseline="middle"
            fill="#00ffff"
            fontSize="9"
            fontWeight="500"
            style={{ filter: 'drop-shadow(0 0 2px #00ffff)' }}
          >
            {tickValue}
          </text>
        </g>
      );
    });
    
    return ticks;
  };

  // If no valid data, show empty state
  if (!hasValidData) {
    return (
      <div className={`bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-4 ${className}`}>
        {/* Sensor Name */}
        <div className="text-center mb-2">
          <h3 className="text-sm font-semibold text-cosmic-text flex items-center justify-center space-x-2">
            <Droplets size={16} />
            <span>{sensor.type}</span>
          </h3>
          <p className="text-xs text-cosmic-text-muted">Relative Humidity (%)</p>
        </div>

        {/* Empty State */}
        <div className="h-64 w-full flex flex-col items-center justify-center text-center border-2 border-dashed border-space-border rounded-lg">
          <Activity size={32} className="text-cosmic-text-muted mb-2 opacity-50" />
          <h4 className="text-sm font-medium text-cosmic-text mb-1">Waiting for Humidity Data</h4>
          <p className="text-xs text-cosmic-text-muted mb-3 max-w-32">
            Humidity readings will appear here once sensor data is received
          </p>
          
          <div className="flex items-center space-x-1 text-xs text-cosmic-text-muted">
            <WifiOff size={12} />
            <span>No Recent Data</span>
          </div>
        </div>

        {/* Troubleshooting Info */}
        <div className="mt-3 p-2 bg-space-secondary rounded-lg">
          <div className="flex items-start space-x-2">
            <AlertTriangle size={12} className="text-yellow-400 mt-0.5 flex-shrink-0" />
            <div className="text-xs text-cosmic-text-muted">
              <p className="font-medium text-cosmic-text mb-1">Check:</p>
              <ul className="space-y-0.5 list-disc list-inside ml-1">
                <li>Humidity sensor calibration</li>
                <li>Sensor placement and airflow</li>
                <li>Temperature compensation</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    );
  }

  const zoneInfo = getCurrentZoneInfo(animatedValue);

  return (
    <div className={`bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-4 ${className}`}>
      {/* Sensor Name */}
      <div className="text-center mb-2">
        <h3 className="text-sm font-semibold text-cosmic-text flex items-center justify-center space-x-2">
          <Droplets size={16} />
          <span>{sensor.type}</span>
        </h3>
        <div className="flex items-center justify-center space-x-2">
          <p className="text-xs text-cosmic-text-muted">Humidity %</p>
          <Wifi size={12} className="text-green-400" />
        </div>
      </div>

      {/* Humidity Gauge SVG */}
      <div className="flex justify-center">
        <svg width={size} height={size * 0.85} viewBox={`0 0 ${size} ${size * 0.9}`} className="overflow-visible">
          {/* Outer chrome border - neon green */}
          <circle
            cx={center}
            cy={center}
            r={radius + strokeWidth + 8}
            fill="url(#cosmicOuterGradient)"
            stroke="#00ff41"
            strokeWidth="3"
            style={{ filter: 'drop-shadow(0 0 6px #00ff41)' }}
          />
          
          {/* Inner border - neon green */}
          <circle
            cx={center}
            cy={center}
            r={radius + strokeWidth + 2}
            fill="url(#cosmicInnerGradient)"
            stroke="#00ff41"
            strokeWidth="2"
            opacity="0.8"
          />
          
          {/* Background circle */}
          <circle
            cx={center}
            cy={center}
            r={radius + strokeWidth / 2}
            fill="#2a2a2a"
            stroke="#333333"
            strokeWidth="2"
            opacity="0.95"
          />
          
          {/* Gradients */}
          <defs>
            <radialGradient id="chromeGradient" cx="0.3" cy="0.3">
              <stop offset="0%" stopColor="#ffffff" />
              <stop offset="50%" stopColor="#e5e5e7" />
              <stop offset="100%" stopColor="#d1d1d6" />
            </radialGradient>
            <radialGradient id="innerBorderGradient" cx="0.3" cy="0.3">
              <stop offset="0%" stopColor="#f2f2f7" />
              <stop offset="100%" stopColor="#e5e5ea" />
            </radialGradient>
            <radialGradient id="cosmicHubGradient" cx="0.3" cy="0.3">
              <stop offset="0%" stopColor="#333333" />
              <stop offset="50%" stopColor="#1a1a1a" />
              <stop offset="100%" stopColor="#000000" />
            </radialGradient>
            <filter id="needleGlow">
              <feGaussianBlur stdDeviation="3" result="coloredBlur"/>
              <feMerge> 
                <feMergeNode in="coloredBlur"/>
                <feMergeNode in="SourceGraphic"/>
              </feMerge>
            </filter>
          </defs>
          
          {/* Humidity zone backgrounds - seamless and enhanced */}
          {zones.map((zone, index) => {
            const zoneStart = startAngle + ((zone.min - sensor_type.min_value) / valueRange) * totalAngle;
            const zoneEnd = startAngle + ((zone.max - sensor_type.min_value) / valueRange) * totalAngle;
            
            return (
              <path
                key={`zone-${index}`}
                d={createArc(zoneStart, zoneEnd, radius - strokeWidth / 2, radius + strokeWidth / 2)}
                fill={zone.color}
                opacity="0.8"
                stroke="none"
                style={{ 
                  filter: `drop-shadow(0 0 8px ${zone.color}40)`,
                }}
              />
            );
          })}
          
          {/* Major humidity tick marks and labels (outer scale - green) */}
          {generateHumidityTicks()}
          
          {/* Minor humidity tick marks and labels (inner scale - cyan) */}
          {generateMinorHumidityTicks()}
          
          {/* Scale unit labels - cosmic neon */}
          <text
            x={center}
            y={center + 55}
            textAnchor="middle"
            fill="#00ffff"
            fontSize="11"
            fontWeight="600"
            style={{ filter: 'drop-shadow(0 0 3px #00ffff)' }}
          >
            RH%
          </text>
          
          {/* Humidity condition labels */}
          <text
            x={center - 50}
            y={center + 70}
            textAnchor="middle"
            fill="#ff0040"
            fontSize="9"
            fontWeight="600"
            style={{ filter: 'drop-shadow(0 0 3px #ff0040)' }}
          >
            DRY
          </text>
          <text
            x={center + 50}
            y={center + 70}
            textAnchor="middle"
            fill="#aa00ff"
            fontSize="9"
            fontWeight="600"
            style={{ filter: 'drop-shadow(0 0 3px #aa00ff)' }}
          >
            HUMID
          </text>
          
          {/* Needle shadow */}
          <g transform={`rotate(${needleAngle} ${center} ${center})`}>
            <line
              x1={center}
              y1={center}
              x2={center + radius - 25}
              y2={center}
              stroke="rgba(0,0,0,0.3)"
              strokeWidth="4"
              strokeLinecap="round"
              transform="translate(2,2)"
            />
          </g>
          
          {/* Main needle - cosmic neon */}
          <g transform={`rotate(${needleAngle} ${center} ${center})`}>
            <line
              x1={center}
              y1={center}
              x2={center + radius - 25}
              y2={center}
              stroke="#ffff00"
              strokeWidth="4"
              strokeLinecap="round"
              style={{
                filter: 'drop-shadow(0 0 8px #ffff00) drop-shadow(0 0 16px #ffff0080)'
              }}
            />
          </g>
          
          {/* Center hub - cosmic styling */}
          <circle
            cx={center}
            cy={center}
            r="12"
            fill="url(#cosmicHubGradient)"
            stroke="#ffff00"
            strokeWidth="2"
            style={{ filter: 'drop-shadow(0 0 6px #ffff00)' }}
          />
          
          {/* Center dot */}
          <circle
            cx={center}
            cy={center}
            r="4"
            fill="#ffff00"
            style={{ filter: 'drop-shadow(0 0 4px #ffff00)' }}
          />
        </svg>
      </div>

      {/* Digital Value Display (like speedometer) */}
      <div className="flex justify-center mt-2">
        <div className="bg-gray-900 text-green-400 px-4 py-2 rounded border-2 border-gray-700 font-mono text-lg font-bold min-w-[80px] text-center"
             style={{
               background: 'linear-gradient(145deg, #1a1a1a, #2d2d2d)',
               boxShadow: 'inset 2px 2px 5px rgba(0,0,0,0.5), inset -2px -2px 5px rgba(255,255,255,0.1)'
             }}>
          {animatedValue.toFixed(1)}%
        </div>
      </div>

      {/* Humidity Classification */}
      <div className="text-center mt-2">
        <div className="text-xs text-cosmic-text-muted">
          {animatedValue.toFixed(1)}% RH - {zoneInfo.status}
        </div>
      </div>

      {/* Status Indicator */}
      <div className="flex items-center justify-center mt-3 space-x-2">
        <div 
          className="w-3 h-3 rounded-full"
          style={{ backgroundColor: getCurrentZoneColor(animatedValue) }}
        />
        <span className="text-xs font-semibold text-cosmic-text">
          {getCurrentZoneStatus(animatedValue)}
        </span>
        <span className="text-xs text-cosmic-text-muted">
          ({sensor.status.replace('_', ' ').toUpperCase()})
        </span>
      </div>
    </div>
  );
};

export { HumidityGaugeChart };