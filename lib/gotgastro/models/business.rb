class Business < Sequel::Model
  plugin :mappable
  one_to_many :offences

  def before_create
    if not self.id
      hash = Digest::MD5
      self.id = hash.hexdigest(self.name)
    end
  end

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
