# db/migrate/xxx_create_email_unsubscribes.rb
class CreateEmailUnsubscribes < ActiveRecord::Migration[7.1]
  def change
    create_table :email_unsubscribes do |t|
      t.references :user, null: false, foreign_key: true
      
      # Type of unsubscribe (marketing_all, nurture_sequence, etc.)
      t.string :unsubscribe_type, null: false
      
      # Reason for unsubscribing (optional)
      t.string :reason
      
      # When the unsubscribe happened
      t.datetime :unsubscribed_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      
      # Tracking information
      t.string :user_agent
      t.string :ip_address
      
      # Optional feedback from user
      t.text :feedback
      
      # Source of unsubscribe (email_link, settings_page, admin_action)
      t.string :source, default: 'email_link'
      
      t.timestamps
    end
    
    # ===== INDEXES =====
    # Ensure one unsubscribe record per user per type
    add_index :email_unsubscribes, [:user_id, :unsubscribe_type], unique: true, 
              name: 'idx_email_unsubscribes_user_type'
    
    # Query by type for analytics
    add_index :email_unsubscribes, :unsubscribe_type
    
    # Query by reason for analytics
    add_index :email_unsubscribes, :reason
    
    # Query by date for reporting
    add_index :email_unsubscribes, :unsubscribed_at
    add_index :email_unsubscribes, :created_at
    
    # Query by source for tracking
    add_index :email_unsubscribes, :source
    
    # Composite index for analytics queries
    add_index :email_unsubscribes, [:unsubscribe_type, :reason, :created_at], 
              name: 'idx_email_unsubscribes_analytics'
    
    # ===== CHECK CONSTRAINTS =====
    # Ensure unsubscribe_type has valid values
    add_check_constraint :email_unsubscribes, 
                        "unsubscribe_type IN ('marketing_all', 'nurture_sequence', 'promotional', 'educational', 'device_recommendations', 'case_studies', 'seasonal_campaigns', 'win_back_campaigns')", 
                        name: 'valid_unsubscribe_type'
    
    # Ensure reason has valid values (if provided)
    add_check_constraint :email_unsubscribes, 
                        "reason IS NULL OR reason IN ('too_frequent', 'not_relevant', 'never_signed_up', 'privacy_concerns', 'found_alternative', 'no_longer_needed', 'poor_content', 'other')", 
                        name: 'valid_unsubscribe_reason'
    
    # Ensure source has valid values
    add_check_constraint :email_unsubscribes, 
                        "source IN ('email_link', 'settings_page', 'admin_action', 'api_request')", 
                        name: 'valid_unsubscribe_source'
  end
  
  def down
    drop_table :email_unsubscribes
  end
end