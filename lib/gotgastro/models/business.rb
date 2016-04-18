class Business < Sequel::Model
  plugin :mappable

  def distance_from(loc)
    self.class.distance_between(self, loc, :units => :kms)
  end

  def address
    "61 YORK STREET SYDNEY 2000"
  end

  def problems
    Array.new((rand(4) + 1))
  end
end
