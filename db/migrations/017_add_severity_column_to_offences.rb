class AddSeverityColumnToOffences < Sequel::Migration
  def up
    alter_table(:offences) do
      add_column :severity, String
    end
  end

  def down
  end
end

