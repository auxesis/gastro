require 'pathname'
require 'yaml'
require 'ostruct'
require 'erb'
require 'json'
require 'mail'
require 'newrelic_rpm'
require 'configatron'

def root
  @root ||= Pathname.new(__FILE__).parent.parent.parent
end

def public_folder
  @public ||= root + 'lib' + 'public'
end

def environment
  ENV['RACK_ENV'] || 'development'
end

def production?
  environment == 'production'
end

def test?
  environment == 'test'
end

def cdn?
  !!config.cdn_base
end

def fb_app_id?
  !!config.fb_app_id
end

# FIXME(auxesis) how about we don't roll our own logging implementation?
LOG = []

def debug(msg)
  if test?
    LOG << msg
  else
    puts('[DEBUG] ' + msg)
  end
end

def info(msg)
  if test?
    LOG << msg
  else
    puts('[INFO] ' + msg)
  end
end

def database_config
  config_file = root + 'config' + 'database.yml'
  template = ERB.new(config_file.read, nil, '%')
  YAML.load(template.result(binding))[environment]
end

def config
  return configatron if configatron.locked?

  configatron.vcap_applications = JSON.parse(ENV['VCAP_APPLICATION']) if ENV['VCAP_APPLICATION']
  configatron.vcap_services     = JSON.parse(ENV['VCAP_SERVICES'])    if ENV['VCAP_SERVICES']

  configatron.baseurl       = production? ? 'https://gotgastroagain.com' : 'http://localhost:9292'
  configatron.gmaps_api_key = ENV['GMAPS_API_KEY'] || 'AIzaSyDBvlmNsUERDKkeQWX6OCsfR5VoPaD3nWo'

  [
    'CDN_BASE',
    'FB_APP_ID',
    'GASTRO_RESET_TOKEN',
    'MORPH_API_KEY',
    'NEWRELIC_LICENSE_KEY',
  ].each do |var|
    key, value = var.downcase, ENV[var]
    if ENV[var]
      configatron[key] = value
    else
      debug("Warning: environment variable #{var} for key '#{key}' was nil.")
    end
  end

  case
  when database_config['database_uri']
    configatron.database = database_config['database_uri']
  when database_config
    configatron.database = database_config
  else
    raise 'No database config present'
  end

  configatron.lock! if production?

  debug("config: #{configatron.to_hash}")

  configatron
end

# Silence deprecation warnings
require 'i18n'
I18n.enforce_available_locales = true

# Setup database connection + models
require 'sequel'
# Setup New Relic instrumentation for Sequel
Sequel.extension :newrelic_instrumentation
Sequel.extension :core_extensions
debug("config.database: #{config.database}")
DB = ::Sequel.connect(config.database)

# Run the migrations in all environments. YOLO.
Sequel.extension :migration
migrations_path = root + 'db' + 'migrations'
begin
  Sequel::Migrator.run(DB, migrations_path)
rescue Sequel::DatabaseConnectionError => e
  info("Couldn't establish connection to database!")
  info(e.message)
  info("Exiting.")
  exit(1)
end

# Load up the models after we've run migrations, per
# http://osdir.com/ml/sequel-talk/2012-01/msg00076.html
require 'gotgastro/models'

# Add dataset method to return points ordered by distance from an origin
module Sequel
  module Plugins
    module Mappable
      module DatasetMethods
        def by_distance(origin)
          sql = model.distance_sql(origin).lit
          self.select_append {
            Sequel::SQL::AliasedExpression.new(sql.lit, :distance)
          }.order(:distance)
        end
        def around(origin, distance)
          sql = model.distance_sql(origin)
          f_origin_bbox(origin, distance)
          self.select_append {
            Sequel::SQL::AliasedExpression.new(sql.lit, :distance)
          }
          .order(:distance)
          .filter{sql.lit <= distance}
        end
      end
    end
  end
end

# Initialise services for handling data
require 'gotgastro/services'

# Initialise workers for background jobs
require 'gotgastro/workers'

# Stub out any data backfilling we need to do.
class Backfill
  def self.run!
  end
end
Backfill.run!

case environment
when 'development'
  require 'pry'
  # Mailcatcher mail delivery locally
  Mail.defaults do
    delivery_method :smtp, address: 'localhost', port: 1025
  end
when 'production'
  # Sendgrid mail delivery
  Mail.defaults do
    delivery_method :smtp, {
      :address => 'smtp.sendgrid.net',
      :port    => '587',
      :domain  => 'gotgastroagain.com',
      :user_name => ENV['SENDGRID_USERNAME'],
      :password  => ENV['SENDGRID_PASSWORD'],
      :authentication       => :plain,
      :enable_starttls_auto => true,
    }
  end

  credentials  = config['vcap_services']['rediscloud'].first['credentials']
  redis_config = {
    :url      => "redis://#{credentials['hostname']}:#{credentials['port']}/0",
    :password => credentials['password']
  }

  Sidekiq.configure_server {|c| c.redis = redis_config }
  Sidekiq.configure_client {|c| c.redis = redis_config }
end
