class Import < Sequel::Model
  set_dataset :resets
  one_to_many :alerts_offences

  plugin :timestamps

  def duration
    if self.updated_at
      self.updated_at - self.created_at
    else
      -1
    end
  end
end
