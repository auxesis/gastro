class CreateResetTable < Sequel::Migration
  def up
    create_table :resets do
      primary_key :id
      Time        :created_at
      Time        :updated_at
      String      :ip
      String      :token
    end
  end

  def down
  end
end

