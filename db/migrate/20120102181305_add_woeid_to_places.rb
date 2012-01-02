class AddWoeidToPlaces < ActiveRecord::Migration
  def self.up
    add_column :places, :woeid, :string
  end

  def self.down
    remove_column :places, :woeid
  end
end
