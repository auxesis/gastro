class Alert < Sequel::Model
  plugin :timestamps
  plugin :mappable
  many_to_many :offences

  def location
    Business.new(:lat => self.lat, :lng => self.lng)
  end

  def location=(value)
    lat, lng = value.split(',')
    self.lat = lat
    self.lng = lng
  end

  def alerted?(offence)
    !!AlertsOffences.where(:offence_id => offence.id, :alert_id => self.id).first
  end
end
