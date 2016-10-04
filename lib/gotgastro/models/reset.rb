class Reset < Sequel::Model
  plugin :timestamps

  def duration
    self.updated_at - self.created_at
  end
end
