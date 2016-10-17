class AddAlertToOffenceAssociation < Sequel::Migration
  def up
    create_table :alerts_offences do
      primary_key :id
      Integer     :alerts_id
      Integer     :offences_id
      Time        :created_at
      Time        :updated_at
    end
  end

  def down
    drop_table :alerts_offences
  end
end

