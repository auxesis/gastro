class Offence < Sequel::Model
  plugin :timestamps
  many_to_one :business
end
