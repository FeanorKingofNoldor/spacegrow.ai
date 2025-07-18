# app/serializers/admin/analytics_serializer.rb
module Admin
  class AnalyticsSerializer
    include ActiveModel::Serialization

    def self.serialize_business_metrics(metrics)
      {
        revenue_metrics: {
          total_revenue: format_currency(metrics[:revenue_metrics][:total_revenue]),
          mrr: format_currency(metrics[:revenue_metrics][:mrr]),
          arr: format_currency(metrics[:revenue_metrics][:arr]),
          arpu: format_currency(metrics[:revenue_metrics][:arpu]),
          ltv: format_currency(metrics[:revenue_metrics][:ltv])
        },
        
        customer_metrics: {
          total_customers: metrics[:customer_metrics][:total_customers],
          new_customers: metrics[:customer_metrics][:new_customers],
          active_customers: metrics[:customer_metrics][:active_customers],
          churn_rate: format_percentage(metrics[:customer_metrics][:churn_rate]),
          retention_rate: format_percentage(metrics[:customer_metrics][:retention_rate])
        },
        
        product_metrics: {
          total_devices: metrics[:product_metrics][:total_devices],
          active_devices: metrics[:product_metrics][:active_devices],
          device_utilization: format_percentage(metrics[:product_metrics][:device_utilization]),
          feature_adoption: metrics[:product_metrics][:feature_adoption]
        },
        
        growth_metrics: {
          user_growth_rate: format_percentage(metrics[:growth_metrics][:user_growth_rate]),
          revenue_growth_rate: format_percentage(metrics[:growth_metrics][:revenue_growth_rate]),
          device_growth_rate: format_percentage(metrics[:growth_metrics][:device_growth_rate])
        }
      }
    end

    def self.serialize_operational_metrics(metrics)
      {
        system_performance: metrics[:system_performance],
        support_performance: metrics[:support_performance],
        reliability_metrics: metrics[:reliability_metrics],
        efficiency_metrics: metrics[:efficiency_metrics],
        quality_metrics: metrics[:quality_metrics]
      }
    end

    def self.serialize_export_data(export_info)
      {
        export_id: export_info[:export_id] || SecureRandom.uuid,
        file_path: export_info[:file_path],
        format: export_info[:format],
        sections: export_info[:sections],
        record_count: export_info[:record_count],
        file_size: calculate_file_size(export_info[:file_path]),
        generated_at: export_info[:generated_at].iso8601,
        expires_at: (export_info[:generated_at] + 24.hours).iso8601,
        download_url: build_download_url(export_info[:file_path])
      }
    end

    private

    def self.format_currency(amount)
      return "$0.00" if amount.nil?
      "$#{sprintf('%.2f', amount)}"
    end

    def self.format_percentage(percentage)
      return "0%" if percentage.nil?
      "#{sprintf('%.1f', percentage)}%"
    end

    def self.calculate_file_size(file_path)
      return "0 KB" unless file_path && File.exist?(file_path)
      
      size = File.size(file_path)
      units = ['B', 'KB', 'MB', 'GB']
      
      exp = (Math.log(size) / Math.log(1024)).floor
      exp = [exp, units.length - 1].min
      
      "#{sprintf('%.1f', size / (1024.0 ** exp))} #{units[exp]}"
    end

    def self.build_download_url(file_path)
      return nil unless file_path
      
      filename = File.basename(file_path)
      "/api/v1/admin/export/download/#{filename}"
    end
  end
end