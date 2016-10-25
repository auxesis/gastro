require 'json'
require 'sequel/plugins/serialization'
require 'geokit'

Sequel::Model.plugin :dataset_associations
Sequel::Model.plugin :timestamps, :update_on_create => true
Sequel::Model.plugin :validation_helpers
Sequel::Model.plugin :table_select

models_path = Pathname.new(__FILE__).parent.join('models').join('*.rb')
models = Dir.glob(models_path)
models.each { |model| require model }
