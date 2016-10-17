class Alert < Sequel::Model
  plugin :timestamps
  many_to_many :offences

  def location
    Business.new(:lat => self.lat, :lng => self.lng)
  end

  def location=(value)
    lat, lng = value.split(',')
    self.lat = lat
    self.lng = lng
  end
end
