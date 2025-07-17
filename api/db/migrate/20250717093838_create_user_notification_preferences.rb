# db/migrate/20250717093838_create_user_notification_preferences.rb
class CreateUserNotificationPreferences < ActiveRecord::Migration[7.1]
  def change
    # Only create table if it doesn't exist
    unless table_exists?(:user_notification_preferences)
      create_table :user_notification_preferences do |t|
        t.references :user, null: false, foreign_key: true, index: false
        
        # ===== EMAIL PREFERENCES FOR EACH CATEGORY =====
        # Security & Authentication (mandatory - always true)
        t.boolean :security_auth_email, default: true, null: false
        
        # Financial & Billing (mandatory - always true)
        t.boolean :financial_billing_email, default: true, null: false
        
        # Critical Device Alerts (user controllable - default true)
        t.boolean :critical_device_alerts_email, default: true, null: false
        
        # Device Management (user controllable - default false)
        t.boolean :device_management_email, default: false, null: false
        
        # Account Updates (user controllable - default false)
        t.boolean :account_updates_email, default: false, null: false
        
        # System Notifications (user controllable - default false)
        t.boolean :system_notifications_email, default: false, null: false
        
        # Reports & Analytics (user controllable - default false)
        t.boolean :reports_analytics_email, default: false, null: false
        
        # Marketing & Tips (user controllable - default false)
        t.boolean :marketing_tips_email, default: false, null: false
        
        # ===== IN-APP NOTIFICATION PREFERENCES =====
        # Security & Authentication (always true)
        t.boolean :security_auth_inapp, default: true, null: false
        
        # Financial & Billing (always true)
        t.boolean :financial_billing_inapp, default: true, null: false
        
        # Critical Device Alerts (user controllable - default true)
        t.boolean :critical_device_alerts_inapp, default: true, null: false
        
        # Device Management (user controllable - default true)
        t.boolean :device_management_inapp, default: true, null: false
        
        # Account Updates (user controllable - default true)
        t.boolean :account_updates_inapp, default: true, null: false
        
        # System Notifications (user controllable - default true)
        t.boolean :system_notifications_inapp, default: true, null: false
        
        # Reports & Analytics (user controllable - default false)
        t.boolean :reports_analytics_inapp, default: false, null: false
        
        # Marketing & Tips (user controllable - default false)
        t.boolean :marketing_tips_inapp, default: false, null: false
        
        # ===== MARKETING OPT-IN TRACKING =====
        # Separate from categories - tracks explicit marketing consent
        t.boolean :marketing_emails_opted_in, default: false, null: false
        t.datetime :marketing_opted_in_at
        t.datetime :marketing_opted_out_at
        t.string :marketing_opt_source # 'registration', 'settings', 'campaign', etc.
        
        # ===== DIGEST & FREQUENCY PREFERENCES =====
        # How often users want to receive non-critical notifications
        t.string :digest_frequency, default: 'immediate', null: false # 'immediate', 'daily', 'weekly', 'disabled'
        t.time :digest_time, default: '09:00:00' # What time to send daily/weekly digests
        t.integer :digest_day_of_week, default: 1 # For weekly digests (1=Monday)
        
        # ===== ESCALATION PREFERENCES =====
        # Controls progressive escalation from in-app to email
        t.boolean :enable_escalation, default: true, null: false
        t.integer :escalation_delay_minutes, default: 120, null: false # 2 hours default
        
        # Note: timezone comes from user.timezone, no need to duplicate
        
        # ===== TRACKING & ANALYTICS =====
        t.datetime :last_email_sent_at
        t.datetime :last_inapp_notification_at
        t.integer :total_emails_sent, default: 0, null: false
        t.integer :total_inapp_notifications, default: 0, null: false
        
        # ===== TEMPORARY SUPPRESSION =====
        # For "snooze" functionality or temporary opt-outs
        t.datetime :suppress_all_until
        t.text :suppression_reason
        
        t.timestamps
      end
    end
    
    # ===== INDEXES (with conditional creation) =====
    add_index_if_not_exists :user_notification_preferences, :user_id, unique: true
    add_index_if_not_exists :user_notification_preferences, :marketing_emails_opted_in
    add_index_if_not_exists :user_notification_preferences, :digest_frequency
    add_index_if_not_exists :user_notification_preferences, :marketing_opted_in_at
    add_index_if_not_exists :user_notification_preferences, :marketing_opted_out_at
    add_index_if_not_exists :user_notification_preferences, :suppress_all_until
    add_index_if_not_exists :user_notification_preferences, [:user_id, :marketing_emails_opted_in], 
              name: 'idx_user_notification_preferences_marketing'
    
    # ===== CHECK CONSTRAINTS (with conditional creation) =====
    add_check_constraint_if_not_exists :user_notification_preferences, 
                        "digest_frequency IN ('immediate', 'daily', 'weekly', 'disabled')", 
                        name: 'valid_digest_frequency'
    
    add_check_constraint_if_not_exists :user_notification_preferences, 
                        "digest_day_of_week >= 1 AND digest_day_of_week <= 7", 
                        name: 'valid_digest_day_of_week'
    
    add_check_constraint_if_not_exists :user_notification_preferences, 
                        "escalation_delay_minutes >= 15 AND escalation_delay_minutes <= 1440", 
                        name: 'valid_escalation_delay'
  end
  
  def down
    drop_table :user_notification_preferences if table_exists?(:user_notification_preferences)
  end

  private

  def add_index_if_not_exists(table_name, column_name, **options)
    index_name = options[:name] || index_name(table_name, column_name)
    return if index_exists?(table_name, column_name, **options)
    
    add_index(table_name, column_name, **options)
  end

  def add_check_constraint_if_not_exists(table_name, expression, name:)
    return if check_constraint_exists?(table_name, name: name)
    
    add_check_constraint(table_name, expression, name: name)
  end

  def check_constraint_exists?(table_name, name:)
    # Check if constraint exists in PostgreSQL
    result = connection.execute(<<~SQL)
      SELECT 1 FROM pg_constraint 
      WHERE conname = '#{name}' 
      AND conrelid = '#{table_name}'::regclass::oid
    SQL
    result.any?
  end
end