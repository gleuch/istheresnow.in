class CreatePlaces < ActiveRecord::Migration
  def self.up
    create_table :places do |t|
      t.string        :full_name
      t.string        :nickname
      t.string        :city
      t.string        :suburb
      t.string        :state
      t.string        :region
      t.string        :country_code
      t.integer       :postal_code
      t.string        :tags

      t.string        :service_name
      t.decimal       :geo_latitude,          :scale => 4, :precision => 7
      t.decimal       :geo_longitude,         :scale => 4, :precision => 7

      t.boolean       :available,             :default => true
      t.boolean       :active,                :default => true
      t.boolean       :focus,                 :default => false
      t.datetime      :created_at
      t.datetime      :updated_at
    end

    add_index :places, [:geo_latitude, :geo_longitude], :unique => true, :name => 'by_location'
  end

  def self.down
    drop_table :places
  end
end
