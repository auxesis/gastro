class RenameAlertsOffencesJoinColumns < Sequel::Migration
  def up
    alter_table(:alerts_offences) do
      rename_column :alerts_id, :alert_id
      rename_column :offences_id, :offence_id
    end
  end

  def down
  end
end

