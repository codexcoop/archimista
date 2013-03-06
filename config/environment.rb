# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.17' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# PDFKIT
require 'pdfkit'
require 'rtf'

include RTF

customizations_path = Dir[File.join(RAILS_ROOT, "lib", "*.rb")].reject do |path|
  path =~ /.*\/tasks.*/
end

Dir.glob(customizations_path).each do |filepath|
  require filepath.gsub(/.rb/,'')
end

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  config.gem "warden",        :version => "0.10.7"
  config.gem "devise",        :version => "1.0.11"
  config.gem "cancan",        :version => "1.6.7"

  config.gem "acts_as_list",  :version => "0.1.2"
  config.gem "ancestry",      :version => "1.2.4"
  config.gem "will_paginate", :version => "2.3.16"
  config.gem "RedCloth",      :version => "4.2.9"
  config.gem "paperclip",     :version => "2.7.2"
  config.gem "cocaine",       :version => "0.3.2"

  config.gem "pdfkit",        :version => "0.5.1"
  config.gem "rtf",           :version => "0.5.0"
  config.gem "fastercsv",     :version => "1.5.5"

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'Rome'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  config.i18n.load_path += Dir[File.join(RAILS_ROOT, 'config', 'locales', '**', '*.{rb,yml}')]
  config.i18n.default_locale = :it

  # PDFKit middleware
  config.middleware.use PDFKit::Middleware, {
    :margin_top    => '2.5cm',
    :margin_right  => '2cm',
    :margin_bottom => '2.5cm',
    :margin_left   => '2cm',
    :footer_font_size => 8,
    :footer_spacing => 15,
    :footer_center => "[page] di [toPage]"
  }, :only => [ %r[/reports/[0-9]+/(inventory|summary|units|creators|custodian|project)] ]

  config.middleware.use PDFKit::Middleware, {
    :margin_top    => '0.25cm',
    :margin_right  => '0cm',
    :margin_bottom => '0cm',
    :margin_left   => '0cm',
  }, :only => [ %r[/reports/[0-9]+/labels] ]

  if defined?(Footnotes)
    Footnotes::Filter.prefix = 'txmt://open?url=file://%s&amp;line=%d&amp;column=%d'
  end

end

