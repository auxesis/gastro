class Business < Sequel::Model
  plugin :mappable
  one_to_many :offences

  def distance_from(loc)
    self.class.distance_between(self, loc, :units => :kms)
  end

  def problems
    offences.size
  end

  def self.find_near(location, opts={})
    within = opts[:within] || 25
    limit  = opts[:limit]  || 50
    self.dataset.around(location,within).limit(limit).all
  end
end
