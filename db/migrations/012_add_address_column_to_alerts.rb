class AddAddressColumnToAlerts< Sequel::Migration
  def up
    alter_table(:alerts) do
      add_column :address, String
    end
  end

  def down
  end
end

