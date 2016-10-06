class Alert < Sequel::Model
  plugin :timestamps

  def location=(value)
    lat, lng = value.split(',')
    self.lat = lat
    self.lng = lng
  end

  def before_create
    id = Digest::MD5.new.hexdigest("#{rand(created_at.to_i).to_s}-#{self.email}")
    self.confirmation_id = id
  end
end
