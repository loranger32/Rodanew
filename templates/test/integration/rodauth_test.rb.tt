require_relative "../test_helpers"

module GenericAccountActions
  def test_user_can_login
    login!

    assert_current_path "/"
    assert_css ".alert-success"
    assert_content "You have been logged in"

    visit "/account"
    assert_current_path "/account"
  end

  def test_user_can_logout
    login!

    logout!

    assert_current_path "/"
    assert_css ".alert-success"
    assert_content "You have been logged out"
    visit "/account"
    assert_current_path "/login"
    assert_css ".alert-danger"
    assert_content "Please login to continue"
  end

  def test_can_setup_authenticate_and_manage_two_factor_authentication
    login!

    # Setup 2FA
    visit "/otp-setup"
    assert_current_path "/otp-setup"
    assert_content "Two Factors Authentication Setup"
    secret = page.find("#otp-secret-key").text
    totp = ROTP::TOTP.new(secret)
    fill_in "Password", with: "foobar"
    fill_in "Authentication Code", with: totp.now
    click_on "Setup TOTP Authentication"
    assert_current_path "/"
    assert_css ".alert-success"
    assert_content "TOTP authentication is now setup"

    assert_equal 16, DB[:account_recovery_codes].where(id: @alice_account.id).count
    logout!

    # Authenticate with TOTP
    login!
    assert_current_path "/"
    assert_css ".alert-success"
    assert_content "You have been logged in"

    visit "/account"

    assert_current_path "/multifactor-auth"

    assert_link "Authenticate Using TOTP", href: "/otp-auth"
    assert_link "Authenticate Using Recovery Code", href: "/recovery-auth"

    click_on "Authenticate Using TOTP"

    assert_current_path "/otp-auth"
    assert_content "Authentication Code"

    # Hack the "Preventing reuse of Time based OTP's" mechanism
    last_use_time_stamp = DB[:account_otp_keys].where(id: @alice_account.id).first[:last_use]
    DB[:account_otp_keys].where(id: @alice_account.id).update(last_use: last_use_time_stamp - 60)

    fill_in "Authentication Code", with: totp.now
    click_on "Authenticate Using TOTP"

    assert_current_path "/"
    assert_css ".alert-success"
    assert_content "You have been multifactor authenticated"
    visit "/account"
    assert_current_path "/account"
    assert_content "Alice"

    logout!

    # Authenticate with recovery code
    assert_current_path "/"
    assert_css ".alert-success"
    assert_content "You have been logged out"

    login!
    assert_current_path "/"
    assert_css ".alert-success"
    assert_content "You have been logged in"

    visit "/account"

    assert_current_path "/multifactor-auth"

    assert_link "Authenticate Using TOTP", href: "/otp-auth"
    assert_link "Authenticate Using Recovery Code", href: "/recovery-auth"

    click_on "Authenticate Using Recovery Code"
    assert_current_path "/recovery-auth"
    assert_content "Recovery Code"

    recovery_code = DB[:account_recovery_codes].where(id: @alice_account.id).first[:code]

    fill_in "Recovery Code", with: recovery_code
    click_on "Authenticate via Recovery Code"

    assert_current_path "/"
    assert_css ".alert-success"
    assert_content "You have been multifactor authenticated"

    visit "/account"
    assert_current_path "/account"
    assert_content "Alice"

    assert_equal 15, DB[:account_recovery_codes].where(id: @alice_account.id).count

    # View recovery codes when one code is missing - ability to add more

    visit "/recovery-codes"
    assert_current_path "/recovery-codes"
    fill_in "Password", with: "foobar"
    click_on "View Authentication Recovery Codes"

    assert_current_path "/recovery-codes"
    assert_link "Back to Account", href: "/account"
    assert_content "Print"
    assert_content "Copy"

    assert_equal 15, DB[:account_recovery_codes].where(id: @alice_account.id).count

    recovery_codes = DB[:account_recovery_codes].where(id: @alice_account.id).map(:code)
    recovery_codes.each do |code|
      assert_content code
    end

    assert_css "#recovery-codes-form"
    fill_in "Password", with: "foobar"
    click_on "Add Authentication Recovery Codes"
    assert_current_path "/recovery-codes"
    assert_css ".alert-success"
    assert_content "Additional authentication recovery codes have been added"

    # No codes are missing anymore, new code are added ans no ability to add more
    assert_equal 16, DB[:account_recovery_codes].where(id: @alice_account.id).count

    recovery_codes = DB[:account_recovery_codes].where(id: @alice_account.id).map(:code)
    recovery_codes.each do |code|
      assert_content code
    end

    refute_css "#recovery-codes-form"

    # Disable 2FA
    visit "/multifactor-disable"
    assert_current_path "/multifactor-disable"

    assert_link "Back to Account", href: "/account"

    fill_in "Password", with: "foobar"
    click_on "Remove 2FA"

    assert_css ".alert-success"
    assert_content "All multifactor authentication methods have been disabled"
    assert_current_path "/"

    assert_equal 0, DB[:account_recovery_codes].where(id: @alice_account.id).all.size
    assert_equal 0, DB[:account_otp_keys].where(id: @alice_account.id).all.size

    logout!
    login!
    assert_css ".alert-success"
    assert_content "You have been logged in"

    visit "/account"

    assert_current_path "/account"
    assert_content "Alice"
  end

  def test_security_log
    login!
    logout!

    login!
    logout!

    # Wrong password
    visit "/login"
    within("form#login-form") do
      fill_in "login", with: "alice@example.com"
      fill_in "password", with: "wrongpassword"
      click_on "Login"
    end
    login!

    visit "/security-log"

    assert_current_path "/security-log"
    assert_content "Review the access to your account"
    within("table") do
      assert_content "create_account", count: 1
      assert_content(/\slogin\s/, count: 3)
      assert_content "logout", count: 2
      assert_content "login_failure", count: 1
    end
  end

  def test_security_logs_are_capped_to_100_rows
    current_number_of_rows = DB[:account_authentication_audit_logs].where(account_id: 1).count
    DB.transaction do
      110.times { DB[:account_authentication_audit_logs].insert(account_id: 1, message: "test login #{_1}}") }
    end
    assert_equal current_number_of_rows + 110, DB[:account_authentication_audit_logs].where(account_id: 1).count

    login!
    assert_equal 100, DB[:account_authentication_audit_logs].where(account_id: 1).count
  end

  def test_can_close_account
    login!
    visit "/close-account"

    assert_current_path "/close-account"
    assert_css "#close-account-form"

    fill_in "Password", with: "foobar"
    click_on "Close Account"

    assert_current_path "/"
    assert_css ".alert-success"
    assert_content "Your account has been closed"

    visit "/account"

    assert_current_path "/login"
    login!

    assert_current_path "/login"
    assert_css ".alert-danger"
    assert_content "There was an error logging in"
    assert_content "no matching login"

    @alice_account.reload

    refute_nil @alice_account
    assert @alice_account.is_closed?
  end

  def test_account_can_be_locked_out_and_unlocked_with_link
    visit "/login"

    11.times do
      within("form#login-form") do
        fill_in "Email", with: "alice@example.com"
        fill_in "Password", with: "wrong_password"
        click_on "Login"
      end
    end

    assert_current_path "/login"
    assert_css ".alert-danger"
    assert_content "This account is currently locked out and cannot be logged in to"
    assert_content :all, "Request Account Unlock"

    visit "/login"
    within("form#login-form") do
      fill_in "Email", with: "alice@example.com"
      fill_in "Password", with: "foobar"
      click_on "Login"
    end

    assert_current_path "/login"
    assert_content "This account is currently locked out and cannot be logged in to"
    assert_css ".alert-danger"
    assert_content :all, "Request Account Unlock"

    click_on "Request Account Unlock"
    assert_equal 1, mails_count

    assert_match(/<a href='http:\/\/www\.example\.com\/unlock-account\?key=/, mail_body(0))
    assert_equal @alice_account.id, DB[:account_lockouts].first[:id]

    unlock_account_key = /<a href='http:\/\/www\.example\.com\/unlock-account\?key=([\w|-]+)'>/i.match(mail_body(0))[1]

    visit "/unlock-account?key=#{unlock_account_key}"
    assert_current_path "/unlock-account"
    click_on "Unlock Account"
    assert_current_path "/"
    assert_css ".alert-success"
    assert_content "Your account has been unlocked"

    visit "/account"
    assert_current_path "/account"
    assert_content "Alice"
  end

  def test_can_change_user_name
    new_user_name = "Alice In Wonderland"
    login!
    visit "/change-user-name"
    assert_current_path "/change-user-name"
    fill_in "user_name", with: new_user_name
    fill_in "password", with: "foobar"
    click_on "Change User Name"

    assert_current_path "/"
    assert_css ".alert-success"
    assert_content "User Name successfully changed"

    @alice_account.reload

    assert_equal new_user_name, @alice_account.user_name

    visit "/account"
    assert_current_path "/account"
    assert_content new_user_name
  end

  def test_can_change_password
    new_password = "barfoo"
    login!
    visit "/change-password"

    assert_current_path "/change-password"
    fill_in "Password", with: "foobar"
    fill_in "New Password", with: new_password
    fill_in "Confirm Password", with: new_password
    click_on "Change Password"

    assert_current_path "/"
    assert_css ".alert-success"
    assert_content "Your password has been changed"

    # Check user is notified
    assert_equal 1, mails_count
    assert_match(/Your Password has been changed/, mail_body(0))

    logout!

    login!(password: new_password)

    assert_current_path "/"
    assert_css ".alert-success"
    assert_content "You have been logged in"
  end
end

class UnverifiedAccountTest < CapybaraTestCase
  include GenericAccountActions

  def before_all
    super
    clean_test_db!
    @alice_account = create_account!
    @test_account_status = 1
  end

  def after_all
    clean_test_db!
    super
  end

  def around
    DB.transaction(rollback: :always, savepoint: true, auto_savepoint: true) do
      clean_mailbox
      super
    end
  end

  def test_user_can_create_an_unverified_account
    assert_equal 0, mails_count
    assert_equal 1, Account.count # Alice account
    visit "/create-account"
    fill_in "user_name", with: "Bob"
    fill_in "login", with: "bob@example.com"
    fill_in "password", with: "foobar"
    fill_in "password-confirm", with: "foobar"
    click_on "Create Account"
    assert_current_path "/"
    assert_css ".alert-success"
    assert_equal 2, mails_count
    assert_includes last_mail_body, "A new user signed up"
    visit "/account"
    assert_current_path "/account"
    assert_content "Bob"
    assert_equal 2, Account.count
    bob_account = Account.where(user_name: "Bob").first
    refute_nil bob_account
    assert bob_account.is_unverified?
  end

  def test_unverified_account_cannot_change_login
    login!
    visit "/change-login"

    assert_current_path "/"
    assert_css ".alert-danger"
    assert_content "Please verify this account before changing the login"
  end

  def test_unverified_account_cannot_reset_password
    visit "/login"
    click_on "Forgot Password?"

    assert_current_path "/reset-password-request"
    fill_in "Email", with: "alice@example.com"
    click_on "Password Reset"

    assert_current_path "/"
    assert_css ".alert-success"
    assert_content "An Email has been sent to reset your password"
    assert_equal 1, mails_count
    assert_match(/<a href='http:\/\/www\.example\.com\/reset-password\?key=/, mail_body(0))
    assert_equal @alice_account.id, DB[:account_password_reset_keys].first[:id]

    reset_password_key = /<a href='http:\/\/www\.example\.com\/reset-password\?key=([\w|-]+)'>/i.match(mail_body(0))[1]

    visit "/reset-password?key=#{reset_password_key}"

    assert_current_path "/login"

    assert_css ".alert-danger"
    assert_content "There was an error resetting your password: invalid or expired password reset key"
  end
end

class VerifiedAccountTest < CapybaraTestCase
  include GenericAccountActions

  def before_all
    super
    clean_test_db!
    @alice_account = create_and_verify_account!
    @test_account_status = 1
  end

  def after_all
    clean_test_db!
    clean_mailbox
    super
  end

  def around
    DB.transaction(rollback: :always, savepoint: true, auto_savepoint: true) do
      clean_mailbox
      super
    end
  end

  def test_user_can_create_and_verify_account
    assert_equal 0, mails_count
    assert_equal 1, Account.count # Alice account
    visit "/create-account"
    fill_in "user_name", with: "Bob"
    fill_in "login", with: "bob@example.com"
    fill_in "password", with: "foobar"
    fill_in "password-confirm", with: "foobar"
    click_on "Create Account"
    assert_current_path "/"
    assert_css ".alert-success"
    assert_equal 2, mails_count # One for the verify account and one for the admin notification of account creation
    assert_includes last_mail_body, "A new user signed up"
    visit "/account"
    assert_current_path "/account"
    assert_content "Bob"
    assert_equal 2, Account.count
    bob_account = Account.where(user_name: "Bob").first
    refute_nil bob_account
    assert bob_account.is_unverified?

    # TO FIX - Should be HTTPS - works fine in other apps
    assert_match(/<a href='http:\/\/www\.example\.com\/verify-account\?key=/, verify_account_mail_body)
    assert_equal bob_account.id, DB[:account_verification_keys].first[:id]

    # TO FIX - Should be HTTPS - works fine in other apps
    verify_account_key = /<a href='http:\/\/www\.example\.com\/verify-account\?key=([\w|-]+)'>/i.match(verify_account_mail_body)[1]

    visit "/verify-account?key=#{verify_account_key}"
    assert_current_path "/verify-account"
    click_on "Verify Account"
    assert_current_path "/"
    assert_css ".alert-success"
    assert_content "Your account has been verified"
    visit "/account"
    assert_current_path "/account"
    assert_content "Bob"
  end

  def test_send_a_new_verify_account_email_if_first_has_expired
    bob_account = create_account!(user_name: "Bob", email: "bob@example.com", password: "foobar")
    assert_equal 2, mails_count # One for the verify account and one for the admin notification of account creation

    assert_equal 1, DB[:account_verification_keys].all.count
    assert_equal bob_account.id, DB[:account_verification_keys].first[:id]
    # Hack to simulate an account not verified during grace period
    DB[:account_verification_keys].update(requested_at: Time.now - (60 * 60 * 24 * 4))
    DB[:account_verification_keys].update(email_last_sent: Time.now - (60 * 60 * 24 * 3))
    hacked_email_last_sent = DB[:account_verification_keys].first[:email_last_sent]

    visit "/account"
    assert_current_path "/login"

    login!(email: "bob@example.com")

    assert_css ".alert-danger"
    assert_content "The account you tried to login with is currently awaiting verification"
    click_on "Send Verification Email Again"

    assert_equal 3, mails_count

    assert_current_path "/"
    assert_css ".alert-success"

    refute_equal hacked_email_last_sent, DB[:account_verification_keys].first[:email_last_sent]

    assert_match(/<a href='http:\/\/www\.example\.com\/verify-account\?key=/, last_mail_body)
    assert_equal bob_account.id, DB[:account_verification_keys].first[:id]

    verify_account_key = /<a href='http:\/\/www\.example\.com\/verify-account\?key=([\w|-]+)'>/i.match(last_mail_body)[1]

    visit "/verify-account?key=#{verify_account_key}"
    assert_current_path "/verify-account"
    click_on "Verify Account"
    assert_current_path "/"
    assert_css ".alert-success"
    assert_content "Your account has been verified"

    visit "/account"
    assert_current_path "/account"
    assert_content "Bob"
  end

  def test_verified_account_can_change_email
    assert_equal 0, mails_count
    new_email = "aliceinwonderland@example.com"
    login!

    visit "/change-login"

    assert_current_path "/change-login"
    assert_content "alice@example.com"

    fill_in "login", with: new_email
    fill_in "password", with: "foobar"
    click_on "Change Email"

    @alice_account.reload
    assert_equal "alice@example.com", @alice_account.email
    assert_current_path "/"
    assert_css ".alert-success"
    assert_content "An email has been sent to your new email verify it"

    visit "/account"
    assert_current_path "/account"
    assert_content "alice@example.com"

    assert_equal 1, mails_count

    assert_equal mail_to(0), new_email # Check email is sent to the new address
    assert_match(/<a href='http:\/\/www\.example\.com\/verify-login-change\?key=/, mail_body(0))
    assert_equal @alice_account.id, DB[:account_login_change_keys].first[:id]

    verify_login_change_key = /<a href='http:\/\/www\.example\.com\/verify-login-change\?key=([\w|-]+)'>/i.match(mail_body(0))[1]

    visit "/verify-login-change?key=#{verify_login_change_key}"

    assert_current_path "/verify-login-change"

    click_on "Verify Email Change"

    assert_current_path "/"
    assert_css ".alert-success"
    assert_content "Your new email has been verified"

    @alice_account.reload
    assert_equal new_email, @alice_account.email

    visit "/account"
    assert_current_path "/account"
    assert_content "Alice"
    assert_content new_email

    logout!

    visit "/login"

    within("form#login-form") do
      fill_in "Email", with: "alice@example.com" # Old email
      fill_in "Password", with: "foobar"
      click_on "Login"
    end

    assert_current_path "/login"
    assert_content "There was an error logging in"

    within("form#login-form") do
      fill_in "Email", with: new_email
      fill_in "Password", with: "foobar"
      click_on "Login"
    end

    assert_current_path "/"
    assert_content "You have been logged in"
  end

  def test_verified_account_can_reset_password_if_forgotten
    visit "/login"
    click_on "Forgot Password?"

    assert_current_path "/reset-password-request"
    fill_in "Email", with: "alice@example.com"
    click_on "Password Reset"

    assert_current_path "/"
    assert_css ".alert-success"
    assert_content "An Email has been sent to reset your password"
    assert_equal 1, mails_count
    assert_match(/<a href='http:\/\/www\.example\.com\/reset-password\?key=/, mail_body(0))
    assert_equal @alice_account.id, DB[:account_password_reset_keys].first[:id]

    reset_password_key = /<a href='http:\/\/www\.example\.com\/reset-password\?key=([\w|-]+)'>/i.match(mail_body(0))[1]

    visit "/reset-password?key=#{reset_password_key}"

    assert_current_path "/reset-password"

    fill_in "Password", with: "supersecret"
    fill_in "Confirm Password", with: "supersecret"
    click_on "Reset Password"

    assert_current_path "/"
    assert_css ".alert-success"
    assert_content "Your password has been reset"

    assert_equal 2, mails_count
    assert_match "You recently requested a password reset,", mail_body(1)

    logout!

    visit "/login"

    within("form#login-form") do
      fill_in "Email", with: "alice@example.com"
      fill_in "Password", with: "foobar" # Old Password
      click_on "Login"
    end

    assert_current_path "/login"
    assert_content "There was an error logging in"

    within("form#login-form") do
      fill_in "Email", with: "alice@example.com"
      fill_in "Password", with: "supersecret"
      click_on "Login"
    end

    assert_current_path "/"
    assert_content "You have been logged in"
  end
end

class RodagenRodauthTest < CapybaraTestCase
  RESTRICTED_PATHES = %w[/account /change-login /change-password /change-user-name
    /close-account /multifactor-auth /multifactor-disable /otp-auth /otp-setup
    /recovery-auth /recovery-codes /security-log].freeze

  ALLOWED_PATHES = %w[/ /create-account /login /logout /reset-password].freeze

  def before_all
    super
    clean_test_db!
  end

  def after_all
    clean_test_db!
    super
  end

  def around
    DB.transaction(rollback: :always, savepoint: true, auto_savepoint: true) do
      super
    end
  end

  def test_user_is_redirected_to_login_page_if_not_signed_in_with_get_requests
    RESTRICTED_PATHES.each do |path|
      visit path
      assert_current_path "/login"
      assert_css ".alert-danger"
      assert_content "Please login to continue"
    end
  end

  def test_all_post_requests_raise_invalid_token_before_authentication_begins
    RESTRICTED_PATHES.each do |path|
      assert_raises(Roda::RodaPlugins::RouteCsrf::InvalidToken) { post path, {} }
    end
  end

  def test_no_authentication_required_to_access_allowed_pages
    # No user logged in
    ALLOWED_PATHES.each do |path|
      visit path
      assert_current_path path
      refute_css ".alert-danger"
      refute_content "Please login to continue"
      refute_content "Alice"
    end
  end

  def test_account_creation_fails_with_invalid_params
    assert_equal 0, mails_count
    visit "/create-account"
    fill_in "user_name", with: "Alice"
    fill_in "login", with: "alice@example.com"
    fill_in "password", with: "fo" # Too short password
    fill_in "password-confirm", with: "fo"
    click_on "Create Account"
    assert_css ".alert-danger"
    assert_content "invalid password, does not meet requirements (minimum 6 characters)"
    assert_equal 0, Account.count
    assert_equal 0, mails_count
  end

  def test_login_pages_has_other_options_than_login
    visit "/login"
    assert_link "Create a New Account"
    assert_link "Forgot Password?"
    assert_link "Resend Verify Account Information"
  end

  def test_request_password_reset_does_not_send_email_to_unknown_account
    visit "/login"
    click_on "Forgot Password?"
    assert_current_path "/reset-password-request"
    fill_in "Email", with: "notregistered@example.com"
    click_on "Password Reset"

    assert_current_path "/reset-password-request"
    assert_css ".alert-danger"
    assert_content "There was an error requesting a password reset"
    assert_equal 0, mails_count
  end
end
