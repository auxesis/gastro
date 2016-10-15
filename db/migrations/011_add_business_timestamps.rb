class AddBusinessTimestamps < Sequel::Migration
  def up
    alter_table(:businesses) do
      add_column :created_at, Time
      add_column :updated_at, Time
    end
  end

  def down
  end
end
