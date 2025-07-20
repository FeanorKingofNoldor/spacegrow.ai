# config/initializers/minio.rb

# Only configure MinIO if endpoint is present and AWS SDK is available
if ENV['MINIO_ENDPOINT'].present?
  begin
    # Require AWS SDK
    require 'aws-sdk-s3'
    
    # Get MinIO credentials from Rails encrypted credentials
    minio_config = Rails.application.credentials.dig(Rails.env.to_sym, :minio) || {}
    
    if minio_config[:access_key_id].present? && minio_config[:secret_access_key].present?
      # Configure AWS SDK to use MinIO
      Aws.config.update({
        endpoint: ENV['MINIO_ENDPOINT'],
        access_key_id: minio_config[:access_key_id],
        secret_access_key: minio_config[:secret_access_key],
        force_path_style: true,
        region: ENV['MINIO_REGION'] || 'us-east-1'
      })

      # Configure Active Storage to use MinIO
      Rails.application.configure do
        config.active_storage.service = :minio
      end

      Rails.logger.info "✅ MinIO configured: #{ENV['MINIO_ENDPOINT']}/#{ENV['MINIO_BUCKET']}"
    else
      Rails.logger.warn "⚠️  MinIO credentials not found in Rails credentials"
    end
  rescue LoadError => e
    Rails.logger.warn "⚠️  AWS SDK not available - MinIO integration disabled: #{e.message}"
  rescue => e
    Rails.logger.error "❌ MinIO configuration failed: #{e.message}"
  end
else
  Rails.logger.info "ℹ️  MINIO_ENDPOINT not configured - using local storage"
end