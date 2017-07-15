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

