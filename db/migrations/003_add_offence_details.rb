class AddOffenceDetails < Sequel::Migration
  def up
    alter_table(:businesses) do
      add_column :description, String, :text => true
      add_column :date, String
    end
  end

  def down
  end
end

