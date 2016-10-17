
class FixOffenceIdColumnType < Sequel::Migration
  def up
    alter_table(:alerts_offences) do
      set_column_type :offence_id, String
    end
  end

  def down
  end
end

