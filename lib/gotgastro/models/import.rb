class Import < Sequel::Model
  set_dataset :resets

  plugin :timestamps

  def duration
    if self.updated_at
      self.updated_at - self.created_at
    else
      -1
    end
  end
end
