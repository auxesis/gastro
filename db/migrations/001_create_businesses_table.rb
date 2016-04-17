class AddBusinessTable < Sequel::Migration
  def up
    create_table :businesses do
      primary_key :id
      String      :name
      Float       :lat
      Float       :lng
    end
  end

  def down
  end
end

