class CreateWeathers < ActiveRecord::Migration
  def self.up
    create_table :weathers do |t|
      t.integer       :place_id
      t.string        :service_name

      t.string        :event_name
      t.decimal       :temp_now,              :scale => 1, :precision => 4
      t.decimal       :temp_high,             :scale => 1, :precision => 4
      t.decimal       :temp_low,              :scale => 1, :precision => 4
      t.decimal       :precip_level,          :scale => 2, :precision => 5

      t.boolean       :is_snow_event,         :default => false
      t.datetime      :last_snow_event
      t.boolean       :is_rain_event,         :default => false
      t.datetime      :last_rain_event

      t.datetime      :recorded_at
      
      t.boolean       :active,                :default => true
      t.datetime      :created_at
      t.datetime      :updated_at
    end

    add_index :weathers, [:place_id, :recorded_at], :unique => true, :name => 'by_recent_place'
  end

  def self.down
    drop_table :weathers
  end
end
