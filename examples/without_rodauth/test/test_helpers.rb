ENV["RACK_ENV"] = "test"

require "bundler/setup"
Bundler.require :default, :test
require "minitest/autorun"
require "capybara/minitest"

Dotenv.load "../.env"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

require_relative "../db/db"
require_relative "../without_rodauth"

class HookedTestClass < Minitest::Test
  include Minitest::Hooks

  def clean_test_db!
    tables = []
    tables.each { |table| DB[table].delete }
    tables.each { |table| DB.reset_primary_key_sequence(table) }
  end
end

class CapybaraTestCase < HookedTestClass
  include Capybara::DSL
  include Capybara::Minitest::Assertions
  include Rack::Test::Methods

  Capybara.app = Without_rodauth.freeze.app

  def app
    Capybara.app
  end

  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
