class Business < Sequel::Model
  plugin :mappable

  def distance_from(loc)
    self.class.distance_between(self, loc, :units => :kms)
  end

  def problems
    Array.new((rand(4) + 1))
  end
end
