class CreateAlertsTable < Sequel::Migration
  def up
    create_table :alerts do
      primary_key :id
      Time        :created_at
      Time        :updated_at
      String      :email
      Float       :lat
      Float       :lng
      Float       :distance
      String      :confirmation_id
    end
  end

  def down
  end
end

