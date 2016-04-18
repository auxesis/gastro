class AddBusinessAddressTable < Sequel::Migration
  def up
    add_column :businesses, :address, String
  end

  def down
  end
end

