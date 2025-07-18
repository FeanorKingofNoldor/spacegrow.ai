# app/controllers/concerns/admin_exportable.rb
module AdminExportable
  extend ActiveSupport::Concern

  def export_data(scope, format: 'csv', columns: nil)
    begin
      # Validate format
      allowed_formats = %w[csv excel json]
      format = 'csv' unless allowed_formats.include?(format)
      
      # Generate export
      case format
      when 'csv'
        export_csv(scope, columns)
      when 'excel'
        export_excel(scope, columns)
      when 'json'
        export_json(scope, columns)
      end
    rescue => e
      Rails.logger.error "Export error: #{e.message}"
      { success: false, error: "Export failed: #{e.message}" }
    end
  end

  private

  def export_csv(scope, columns)
    require 'csv'
    
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    filename = "#{controller_name}_export_#{timestamp}.csv"
    file_path = Rails.root.join('tmp', filename)
    
    headers = determine_export_columns(scope.first, columns)
    
    CSV.open(file_path, 'w', write_headers: true, headers: headers) do |csv|
      scope.find_each do |record|
        row_data = headers.map { |header| extract_field_value(record, header) }
        csv << row_data
      end
    end
    
    {
      success: true,
      file_path: file_path.to_s,
      filename: filename,
      format: 'csv',
      record_count: scope.count
    }
  end

  def export_excel(scope, columns)
    # This would require the 'spreadsheet' or 'axlsx' gem
    # For now, fall back to CSV
    Rails.logger.info "Excel export requested, falling back to CSV"
    export_csv(scope, columns)
  end

  def export_json(scope, columns)
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    filename = "#{controller_name}_export_#{timestamp}.json"
    file_path = Rails.root.join('tmp', filename)
    
    headers = determine_export_columns(scope.first, columns)
    
    data = scope.map do |record|
      headers.map { |header| [header, extract_field_value(record, header)] }.to_h
    end
    
    File.write(file_path, JSON.pretty_generate(data))
    
    {
      success: true,
      file_path: file_path.to_s,
      filename: filename,
      format: 'json',
      record_count: scope.count
    }
  end

  def determine_export_columns(sample_record, requested_columns)
    return requested_columns if requested_columns.present?
    
    # Default columns based on model type
    return [] unless sample_record
    
    case sample_record.class.name
    when 'User'
      %w[id email display_name role status created_at last_sign_in_at]
    when 'Device'
      %w[id name status device_type user_email created_at last_connection]
    when 'Order'
      %w[id status total user_email created_at updated_at]
    when 'Subscription'
      %w[id plan_name status user_email created_at monthly_cost]
    else
      sample_record.attributes.keys
    end
  end

  def extract_field_value(record, field)
    case field
    when 'user_email'
      record.respond_to?(:user) ? record.user&.email : nil
    when 'device_type'
      record.respond_to?(:device_type) ? record.device_type&.name : nil
    when 'plan_name'
      record.respond_to?(:plan) ? record.plan&.name : nil
    else
      value = record.send(field) if record.respond_to?(field)
      format_export_value(value)
    end
  rescue
    nil
  end

  def format_export_value(value)
    case value
    when Time, DateTime
      value.iso8601
    when Date
      value.to_s
    when BigDecimal, Float
      value.to_f
    else
      value.to_s
    end
  end
end