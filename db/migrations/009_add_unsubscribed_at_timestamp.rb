class AddUnsubscribedAtTimestampForAlerts < Sequel::Migration
  def up
    alter_table(:alerts) do
      add_column :unsubscribed_at, Time
    end
  end

  def down
  end
end

