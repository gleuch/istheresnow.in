class CreateWeathers < ActiveRecord::Migration
  def self.up
    create_table :weathers do |t|
      t.integer       :place_id
      t.string        :service_name

      t.string        :event_name
      t.integer       :event_code
      t.decimal       :temp_now,              :scale => 1, :precision => 4
      t.decimal       :temp_high,             :scale => 1, :precision => 4
      t.decimal       :temp_low,              :scale => 1, :precision => 4
      t.decimal       :precip_level,          :scale => 2, :precision => 5

      t.boolean       :is_snow_event,         :default => false
      t.boolean       :is_sleet_event,        :default => false
      t.boolean       :is_rain_event,         :default => false
      t.boolean       :is_wind_event,         :default => false
      t.boolean       :is_storm_event,        :default => false
      t.boolean       :is_sunny_event,        :default => false

      t.boolean       :active,                :default => true
      t.datetime      :recorded_at
      t.datetime      :created_at
      t.datetime      :updated_at
    end

    add_index :weathers, [:place_id, :recorded_at], :unique => true, :name => 'by_recent_place'
  end

  def self.down
    drop_table :weathers
  end
end
