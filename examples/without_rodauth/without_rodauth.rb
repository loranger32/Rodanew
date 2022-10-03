require_relative "db/db"

Dir["helpers/*.rb"].each { require_relative _1 }
Dir["jobs/*.rb"].each { require_relative _1 }

class Without_rodauth < Roda
  opts[:root] = File.dirname(__FILE__)

  # General plugins
  plugin :environments
  unless test?
    plugin :enhanced_logger,
      filter: ->(path) { path.start_with?("/assets") },
      trace_missed: true
  end

  include AppHelpers
  include ViewHelpers

  # Security
  secret = ENV["SESSION_SECRET"]
  plugin :sessions, key: "without_rodauth_app.session", secret: secret
  plugin :route_csrf

  plugin :default_headers,
    "Strict-Transport-Security" => "max-age=63072000; includeSubDomains",
    "X-Content-Type-Options" => "nosniff",
    "X-Frame-Options" => "deny",
    "X-XSS-Protection" => "1; mode=block"

  plugin :content_security_policy do |csp|
    csp.default_src :none
    csp.font_src :self, "fonts.gstatic.com"
    csp.img_src :self
    csp.object_src :none
    csp.frame_src :self
    csp.style_src :self, "fonts.googleapis.com", "stackpath.bootstrapcdn.com", "cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css"
    csp.form_action :self
    csp.script_src :self, "cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/js/bootstrap.bundle.min.js"
    csp.connect_src :self
    csp.base_uri :none
    csp.frame_ancestors :none
    csp.block_all_mixed_content
  end

  # Routing
  plugin :hash_routes
  Dir["routes/*.rb"].each { require_relative _1 }

  plugin :status_handler

  status_handler(400) do
    view "error_pages/error_400"
  end

  status_handler(404) do
    view "error_pages/error_404"
  end

  status_handler(403) do
    view "error_pages/error_403"
  end

  # Rendering
  plugin :render, engine: "haml", template_opts: {escape_html: true}
  plugin :partials
  plugin :assets,
    css: %w[style.css],
    js: {main: "main.js", bs_tooltip: "bs_tooltip.js"},
    group_subdirs: false,
    gzip: true,
    timestamp_paths: true
  compile_assets if production?
  plugin :public, gzip: true
  plugin :flash
  plugin :content_for

  # Request / response
  plugin :typecast_params
  alias_method :tp, :typecast_params

  route do |r|
    r.public
    r.assets unless Without_rodauth.production?

    r.root do
      view "home"
    end

    check_csrf!

    r.hash_branches

  end
end
