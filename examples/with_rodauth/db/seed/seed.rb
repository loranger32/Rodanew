require_relative "../db"

require "bcrypt"

tables = [:account_recovery_codes,
  :account_otp_keys,
  :account_session_keys,
  :account_active_session_keys,
  :account_email_auth_keys,
  :account_lockouts,
  :account_login_failures,
  :account_login_change_keys,
  :account_verification_keys,
  :account_password_reset_keys,
  :account_authentication_audit_logs,
  :accounts]

tables.each { DB.reset_primary_key_sequence(_1) }

accounts = [
  {email: "alice@example.com",
   user_name: "Alice",
   password_hash: BCrypt::Password.create("supersecret", cost: 2),
   status_id: 2},
  {email: ENV["MY_EMAIL"],
   user_name: ENV["MY_NAME"],
   password_hash: BCrypt::Password.create("foobar", cost: 2),
   status_id: 2},
]

accounts.each { |account| Account.new(account).save }

