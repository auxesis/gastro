class Offence < Sequel::Model
  plugin :timestamps
  many_to_one :business
  many_to_many :alerts
end
