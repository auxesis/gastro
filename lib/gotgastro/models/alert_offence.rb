class AlertsOffences < Sequel::Model
  plugin :timestamps
  many_to_one :imports
end
