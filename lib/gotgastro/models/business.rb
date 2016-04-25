class Business < Sequel::Model
  plugin :mappable

  def distance_from(loc)
    self.class.distance_between(self, loc, :units => :kms)
  end

  def problems
    Array.new((rand(4) + 1))
  end

  def self.find_near(location, opts={})
    within = opts[:within] || 25
    limit  = opts[:limit]  || 50
    self.dataset.around(location,within).limit(limit).all
  end
end
