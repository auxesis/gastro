require 'pathname'
require 'yaml'
require 'ostruct'
require 'erb'
require 'json'
require 'mail'

def root
  @root ||= Pathname.new(__FILE__).parent.parent.parent
end

def public_folder
  @public ||= root + 'lib' + 'public'
end

def environment
  ENV['RACK_ENV'] || 'development'
end

def config
  return @config if @config
  config_file = root + 'config' + 'database.yml'
  template = ERB.new(config_file.read, nil, '%')
  @config = YAML.load(template.result(binding))[environment]

  puts "[debug] VCAP_APPLICATION: #{ENV['VCAP_APPLICATION'].inspect}"
  puts "[debug] VCAP_SERVICES: #{ENV['VCAP_SERVICES'].inspect}"
  @config.merge!('vcap_application' => JSON.parse(ENV['VCAP_APPLICATION'])) if ENV['VCAP_APPLICATION']
  @config.merge!('vcap_services' => JSON.parse(ENV['VCAP_SERVICES'])) if ENV['VCAP_SERVICES']

  @config
end

def database_config
  case
  when config['database_uri']
    config['database_uri']
  when config
    config
  else
    raise "No database config present"
  end
end

# Silence deprecation warnings
require 'i18n'
I18n.enforce_available_locales = true

# Setup database connection + models
require 'sequel'
Sequel.extension :core_extensions
puts "[debug] database_config: #{database_config.inspect}"
DB = ::Sequel.connect(database_config)

# Run the migrations in all environments. YOLO.
Sequel.extension :migration
migrations_path = root + 'db' + 'migrations'
begin
  Sequel::Migrator.run(DB, migrations_path)
rescue Sequel::DatabaseConnectionError => e
  puts "Couldn't establish connection to database!"
  puts e.message
  puts "Exiting."
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
  credentials = config['vcap_services']['sendgrid'].first['credentials']

  # Sendgrid mail delivery
  Mail.defaults do
    delivery_method :smtp, {
      :address   => credentials['hostname'],
      :port      => '2525',
      :user_name => credentials['username'],
      :password  => credentials['password'],
      :domain    => 'gotgastroagain.com',
      :authentication       => :plain,
      :enable_starttls_auto => true
    }
  end
end
