class CreateOffenceTable < Sequel::Migration
  def up
    create_table :offences do
      primary_key :id
      Date        :date
      String      :link
      String      :description, :text => true
      Integer     :business_id
    end

    alter_table(:businesses) do
      add_column :offence_id, Integer
    end
  end

  def down
  end
end

