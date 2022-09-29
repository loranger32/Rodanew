#!/usr/bin/env ruby

require "thor"
require "fileutils"
require "securerandom"

class Rodagen < Thor::Group
  include Thor::Actions

  argument :name
  class_option :"no-rodauth", type: :boolean, default: false
  class_option :"no-bs", type: :boolean, default: false
  class_option :"db-password", type: :string

  def year
    Time.now.year
  end

  def rodauth?
    !options[:"no-rodauth"]
  end

  def bootstrap?
    !options[:"no-bs"]
  end

  # Needed when executing this file from a symlink
  def self.this_file
    File.symlink?(__FILE__) ? File.readlink(__FILE__) : FILE
  end

  def self.source_root
    File.dirname(this_file)
  end

  # Secret for the Roda session and Rodauth HMAC secret, stored in the .env file
  def generate_secret
    SecureRandom.base64(48)
  end

  def standard_db_credentials?
    !options[:"db-password"]
  end

  def set_db_password
    if standard_db_credentials?
      say("Using standard db credentials", :green)
    else
      @db_password = options[:"db-password"]
      say("Using custom db credentials", :green)
    end
  end

  def db_credentials
    @db_credentials ||= standard_db_credentials? ? ENV["PG_CREDENTIALS"] : "#{name}:#{@db_password}"
  end

  def create_dot_env_file
    template("templates/.env.tt", "#{name}/.env")
  end

  def create_gitignore
    copy_file("templates/.gitignore", "#{name}/.gitignore")
  end

  def create_readme
    template("templates/readme.tt", "#{name}/README.md")
  end

  def create_gemfile
    gemfile = rodauth? ? "gemfile_rodauth" : "gemfile_no_rodauth"
    template("templates/#{gemfile}", "#{name}/Gemfile")
  end

  def create_config_ru
    template("templates/config.ru.tt", "#{name}/config.ru")
  end

  def create_procfile
    copy_file("templates/Procfile", "#{name}/Procfile")
  end

  def db_tables
    @db_tables = if rodauth?
    <<-TABLES
tables = [:account_sms_codes,
      :account_recovery_codes,
      :account_otp_keys,
      :account_webauthn_keys,
      :account_webauthn_user_ids,
      :account_session_keys,
      :account_active_session_keys,
      :account_email_auth_keys,
      :account_lockouts,
      :account_login_failures,
      :account_remember_keys,
      :account_login_change_keys,
      :account_verification_keys,
      :account_password_reset_keys,
      :account_authentication_audit_logs,
      :admins,
      :accounts,
      :account_statuses]
      TABLES
    else
      "tables = []"
    end
  end

  def create_rakefile
    template("templates/rakefile.tt", "#{name}/Rakefile")
  end

  def create_standardrb_config_file
    copy_file("templates/.standard.yml", "#{name}/.standard.yml")
  end

  def create_layout_and_home_page
    template("templates/views/layout.haml.tt", "#{name}/views/layout.haml")
    template("templates/views/home.haml.tt", "#{name}/views/home.haml")
    if rodauth?
      template("templates/views/account.haml.tt", "#{name}/views/account.haml")
    end
  end

  def create_error_pages
    directory("templates/views/error_pages", "#{name}/views/error_pages")
  end

  def create_partials
    template("templates/views/partials/_flash.haml.tt", "#{name}/views/partials/_flash.haml")
    if rodauth?
      template("templates/views/partials/_security_log_pagination.haml.tt", "#{name}/views/partials/_security_log_pagination.haml")
    end
  end

  def create_rodauth_templates
    if rodauth?
      directory("templates/views/rodauth", "#{name}/views/rodauth")
      directory("templates/views/mail", "#{name}/views/mails")
      template("templates/views/recovery_codes.haml.tt", "#{name}/views/recovery_codes.haml")
      template("templates/views/change_user_name.haml.tt", "#{name}/views/change_user_name.haml")
      template("templates/views/otp-setup.haml.tt", "#{name}/views/otp-setup.haml")
      template("templates/views/security_log.haml.tt", "#{name}/views/security_log.haml")
      template("templates/views/add-recovery-codes.haml.tt", "#{name}/views/add-recovery-codes.haml")
    end
  end

  def create_helpers
    template("templates/helpers/view_helpers.rb.tt", "#{name}/helpers/view_helpers.rb")
    template("templates/helpers/app_helpers.rb.tt", "#{name}/helpers/app_helpers.rb")
    if rodauth?
      template("templates/helpers/mail_helpers.rb.tt", "#{name}/helpers/mail_helpers.rb")
    end
  end

  def create_public
    copy_file("templates/.gitkeep", "#{name}/public/assets/.gitkeep")
    copy_file("templates/.gitkeep", "#{name}/public/images/.gitkeep")
  end

  def create_models
    if rodauth?
      template("templates/models/account.rb.tt", "#{name}/models/account.rb")
    else
      copy_file("templates/.gitkeep", "#{name}/models/.gitkeep")
    end
  end

  def create_tests
    template("templates/test/unit/unit_test.rb.tt", "#{name}/test/unit/#{name}_test.rb")
    template("templates/test/integration/integration_test.rb.tt", "#{name}/test/integration/#{name}_interation_test.rb")
    if rodauth?
      template("templates/test/test_helpers_rodauth.rb.tt", "#{name}/test/test_helpers.rb")
      template("templates/test/unit/account_unit_test.rb.tt", "#{name}/test/unit/account_test.rb")
      template("templates/test/integration/rodauth_test.rb.tt", "#{name}/test/integration/rodauth_test.rb")
    else
      template("templates/test/test_helpers_no_rodauth.rb.tt", "#{name}/test/test_helpers.rb")
    end
  end

  def create_jobs
    if rodauth?
      template("templates/jobs/truncate_audit_logs_job.rb.tt", "#{name}/jobs/truncate_audit_logs_job.rb")
      template("templates/jobs/send_email_in_production_job.rb.tt", "#{name}/jobs/send_email_in_production_job.rb")
    else
      copy_file("templates/.gitkeep", "#{name}/jobs/.gitkeep")
    end
  end

  def create_db_files
    template("templates/db/db.rb.tt", "#{name}/db/db.rb")
    copy_file("templates/.gitkeep", "#{name}/db/schema/.gitkeep")
    template("templates/db/seed/seed.rb.tt", "#{name}/db/seed/seed.rb")
    if rodauth?
      template("templates/db/migrations/rodauth_migration.rb.tt", "#{name}/db/migrations/001_create_rodauth_tables.rb")
    else
      template("templates/db/migrations/empty_migration.rb.tt", "#{name}/db/migrations/001_first_migration.rb")
    end
  end

  def create_routes_dir
    copy_file("templates/.gitkeep", "#{name}/routes/.gitkeep")
  end

  def create_assets
    template("templates/assets/css/style.css.tt", "#{name}/assets/css/style.css")
    template("templates/assets/js/main.js.tt", "#{name}/assets/js/main.js")
    if bootstrap?
      template("templates/assets/js/bs_tooltip.js.tt", "#{name}/assets/js/bs_tooltip.js")
    end
    if rodauth?
      template("templates/assets/js/recovery_codes.js.tt", "#{name}/assets/js/recovery_codes.js")
    end
  end

  def create_app_file
    template("templates/app.rb.tt", "#{name}/#{name}.rb")
  end

  def create_licence
    if no?("Generate licence ?")
      say "No licence created", :red
    elsif yes?("Use MIT license ?")
      template("templates/mit_licence.tt", "#{name}/LICENCE.txt")
    elsif yes?("Use GNU AGPL license ?")
      template("templates/agpl_licence.tt", "#{name}/LICENCE.txt")
    else
      say "No licence created", :red
    end
  end

  def run_bundle_install
    FileUtils.cd(name) { system("bundle install") }
  end
end

Rodagen.start
