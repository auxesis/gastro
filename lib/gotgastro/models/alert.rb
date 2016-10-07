class Alert < Sequel::Model
  plugin :timestamps

  def location
    [self.lat, self.lng].join(',')
  end

  def location=(value)
    lat, lng = value.split(',')
    self.lat = lat
    self.lng = lng
  end
end
