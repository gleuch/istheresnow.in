class AddHurricaneFlags < ActiveRecord::Migration
  def self.up
    add_column :weathers, :is_hurricane_event, :boolean, :default => false, :after => :is_snow_event
    add_column :weathers, :is_tropical_storm_event, :boolean, :default => false, :after => :is_hurricane_event
  end

  def self.down
    remove_column :weathers, :is_hurricane_event
    remove_column :weathers, :is_tropical_storm_event
  end
end
