Devise.setup do |config|
  config.mailer_sender = 'please-change-me-at-config-initializers-devise@example.com'
  
  require 'devise/orm/active_record'
  
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth, :params_auth]
  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.expire_all_remember_me_on_sign_out = true
  config.reset_password_within = 6.hours
  config.sign_out_via = :delete
  config.reconfirmable = true

  # For API-only, we want JSON responses
  config.navigational_formats = []
end
