require 'pathname'
require 'yaml'
require 'ostruct'
require 'erb'

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
  config_file = root + 'config' + 'database.yaml'
  template = ERB.new(config_file.read, nil, '%')
  @config = YAML.load(template.result(binding))[environment]
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
p ['database_config', database_config]
DB = ::Sequel.connect(database_config)

# Run the migrations in all environments. YOLO.
Sequel.extension :migration
migrations_path = root + 'db' + 'migrations'
Sequel::Migrator.run(DB, migrations_path)

# Load up the models after we've run migrations, per
# http://osdir.com/ml/sequel-talk/2012-01/msg00076.html
require 'gotgastro/models'

# Add dataset method to return points ordered by distance from an origin
module Sequel
  module Plugins
    module Mappable
      module DatasetMethods
        def by_distance(origin, limit=10)
          sql = model.distance_sql(origin).lit
          self.select_append {
            Sequel::SQL::AliasedExpression.new(sql.lit, :distance)
          }.order(:distance).limit(limit)
        end
      end
    end
  end
end


# Stub out any data backfilling we need to do.
class Backfill
  def self.run!
  end
end
Backfill.run!
