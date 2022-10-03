require "bundler/setup"

if ENV["RACK_ENV"] == "production"
  Bundler.require(:default, :production)
  raise StandardError, "Sendgrid API key not found" unless ENV["SENDGRID_API_KEY"]
else
  require "dotenv"
  Dotenv.load
  if ENV["RACK_ENV"] == "development"
    Bundler.require(:default, :development)
  elsif ENV["RACK_ENV"] == "test"
    Bunlder.require(:default, :test)
  else
    Bunlder.require(:default)
  end
end

require_relative "with_rodauth"

run With_rodauth.freeze.app
