class AddImportTrackingColumn < Sequel::Migration
  def up
    alter_table(:alerts_offences) do
      add_column :import_id, Integer
    end
  end

  def down
  end
end

