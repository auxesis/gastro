class ChangeBusinessPrimaryKey < Sequel::Migration
  def up
    drop_table(:businesses)

    create_table(:businesses) do
      String  :id, :primary_key => true
      String  :name
      String  :address
      Float   :lat
      Float   :lng
    end

    alter_table(:offences) do
      set_column_type :business_id, String
    end
  end

  def down
  end
end

