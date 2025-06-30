// utils/chartColors.ts
export const getZoneColor = (zone: string): string => {
  switch (zone) {
    case 'error_low':
    case 'error_high':
      return '#ef4444'; // red-500
    case 'warning_low':
    case 'warning_high':
      return '#f59e0b'; // amber-500
    case 'normal':
      return '#10b981'; // emerald-500
    default:
      return '#6b7280'; // gray-500
  }
};

export const getStatusColor = (status: string): string => {
  switch (status) {
    case 'ok':
      return '#10b981'; // emerald-500
    case 'warning':
      return '#f59e0b'; // amber-500
    case 'error':
      return '#ef4444'; // red-500
    case 'no_data':
      return '#6b7280'; // gray-500
    default:
      return '#6b7280'; // gray-500
  }
};