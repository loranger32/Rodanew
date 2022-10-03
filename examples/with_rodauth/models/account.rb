class Account < Sequel::Model
  plugin :validation_helpers

  def self.verified
    where(status_id: 2).all
  end

  def self.unverified
    where(status_id: 1).all
  end

  def self.closed
    where(status_id: 3).all
  end

  def self.otp_on
    otp_on_account_ids = DB[:account_otp_keys].select_map(:id)
    where(id: otp_on_account_ids).all
  end

  def self.otp_off
    otp_on_account_ids = DB[:account_otp_keys].select_map(:id)
    exclude(id: otp_on_account_ids).all
  end

  def validate
    super
    validates_presence [:user_name, :email, :password_hash]
    validates_unique :email
    validates_format(/^[^,;@ \r\n]+@[^,@; \r\n]+\.[^,@; \r\n]+$/, :email, message: "is not a valid email")
    validates_min_length 3, :user_name, message: "must have at least 3 characters"
    validates_max_length 100, :user_name
  end

  def otp_on?
    !DB[:account_otp_keys].where(id: id).first.nil?
  end

  def is_verified?
    status_id == 2
  end

  def is_closed?
    status_id == 3
  end

  def is_open?
    is_unverified? || is_verified?
  end

  def is_unverified?
    status_id == 1
  end

  def account_status
    case status_id
    when 2 then "verified"
    when 3 then "closed"
    when 1 then "unverified"
    else
      "unknown status"
    end
  end

  def before_destroy
    # Delete all rows associated with the account in RODAUTH tables
    rodauth_tables_with_account_id = [:account_active_session_keys, :account_authentication_audit_logs]
    rodauth_tables_with_id = [:account_email_auth_keys, :account_lockouts, :account_login_change_keys,
      :account_login_failures, :account_otp_keys, :account_password_reset_keys,
      :account_recovery_codes, :account_session_keys,
      :account_verification_keys, :account_verification_keys]
    rodauth_tables_with_account_id.each do |table|
      DB[table].where(account_id: id).delete
    end

    rodauth_tables_with_id.each do |table|
      DB[table].where(id: id).delete
    end

    super
  end
end
