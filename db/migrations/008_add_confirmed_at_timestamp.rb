class AddConfirmedAtTimestampForAlerts < Sequel::Migration
  def up
    alter_table(:alerts) do
      add_column :confirmed_at, Time
    end
  end

  def down
  end
end

